public class OpportunityWebhookProcessor implements Queueable, Database.AllowsCallouts {

    private static Api_Configuration__mdt apiConfig;
    private OpportunityApiLogSelector logSelector;

    public OpportunityWebhookProcessor() {}

    public void execute(QueueableContext context) {
        this.logSelector = new OpportunityApiLogSelector();
        try {
            processWebhookLogs();
        } catch (Exception e) {
            Logger.error('Error in OpportunityWebhookProcessor: ' + e.getMessage())
                .setRecordId((Id)null)
                .addTag('OpportunityWebhookProcessor');
            Logger.saveLog();
        }
    }

    private static Api_Configuration__mdt getApiConfiguration() {
        if (apiConfig == null) {
            List<Api_Configuration__mdt> configs = [
                SELECT API_Endpoint__c, Max_Retries__c, Timeout__c, Is_Active__c, Batch_Size__c
                FROM Api_Configuration__mdt
                WHERE Is_Active__c = true
                LIMIT 1
            ];
            apiConfig = configs[0];
        }
        return apiConfig;
    }

    private void processWebhookLogs() {
        Api_Configuration__mdt config = getApiConfiguration();
        Integer batchSize = config.Batch_Size__c != null ? Integer.valueOf(config.Batch_Size__c) : 50;

        List<Opportunity_Api_Log__c> logsToProcess = logSelector.selectPendingAndRetryingLogs(
            Integer.valueOf(config.Max_Retries__c),
            batchSize
        );

        if (logsToProcess.isEmpty()) {
            return;
        }

        List<Opportunity_Api_Log__c> logsToUpdate = new List<Opportunity_Api_Log__c>();

        for (Opportunity_Api_Log__c log : logsToProcess) {
            try {
                log.LastAttempt__c = DateTime.now();
                log.Payload__c = createPayload(log.Opportunity__r);
                log.Job_Name__c = 'OpportunityWebhookProcessor';

                Boolean success = makeWebhookCallout(log.Payload__c, config);

                if (success) {
                    log.Status__c = 'Success';
                    log.ErrorMessage__c = null;
                } else {
                    handleFailedLog(log);
                }
                logsToUpdate.add(log);
            } catch (Exception e) {
                Logger.error('Error processing individual log: ' + e.getMessage())
                    .setRecordId(log.Id)
                    .addTag('OpportunityWebhookProcessor');
                Logger.saveLog();

                log.Status__c = 'Failed';
                log.ErrorMessage__c = 'Processing error: ' + e.getMessage();
                log.LastAttempt__c = DateTime.now();
                log.RetryCount__c = (log.RetryCount__c == null ? 1 : log.RetryCount__c + 1);
                logsToUpdate.add(log);
            }
        }

        if (!logsToUpdate.isEmpty()) {
            try {
                update logsToUpdate;
            } catch (Exception e) {
                Logger.error('Error updating final batch: ' + e.getMessage())
                    .setRecordId((Id)null)
                    .addTag('OpportunityWebhookProcessor');
                Logger.saveLog();
            }
        }

        checkAndRestartProcessing();
    }

    private String createPayload(Opportunity opp) {
        Map<String, Object> payload = new Map<String, Object>{
            'Id' => opp.Id,
            'Name' => opp.Name,
            'Amount' => opp.Amount,
            'OwnerEmail' => opp.Owner.Email,
            'Stage' => opp.StageName
        };

        return JSON.serialize(payload);
    }

    private Boolean makeWebhookCallout(String payload, Api_Configuration__mdt config) {
        try {
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(config.API_Endpoint__c);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setTimeout(Integer.valueOf(config.Timeout__c));
            request.setBody(payload);

            HttpResponse response = http.send(request);

            return response.getStatusCode() >= 200 && response.getStatusCode() < 300;

        } catch (Exception e) {
            Logger.error('HTTP callout failed: ' + e.getMessage())
                .setRecordId((Id)null)
                .addTag('OpportunityWebhookProcessor');
            Logger.saveLog();
            return false;
        }
    }

    private void handleFailedLog(Opportunity_Api_Log__c log) {
        Api_Configuration__mdt config = getApiConfiguration();
        log.LastAttempt__c = DateTime.now();
        log.RetryCount__c = (log.RetryCount__c == null ? 1 : log.RetryCount__c + 1);

        if (log.RetryCount__c < config.Max_Retries__c) {
            log.Status__c = 'Retrying';
            log.ErrorMessage__c = 'HTTP callout failed - retry attempt ' + log.RetryCount__c;
        } else {
            log.Status__c = 'Failed';
            log.ErrorMessage__c = 'HTTP callout failed after ' + log.RetryCount__c + ' attempts - max retries exceeded';
        }
    }

    private void checkAndRestartProcessing() {
        Api_Configuration__mdt config = getApiConfiguration();

        Integer pendingCount = [
            SELECT COUNT()
            FROM Opportunity_Api_Log__c
            WHERE Job_Name__c = 'OpportunityWebhookProcessor'
            AND Status__c = 'Pending'
        ];

        Integer retryingCount = [
            SELECT COUNT()
            FROM Opportunity_Api_Log__c
            WHERE Job_Name__c = 'OpportunityWebhookProcessor'
            AND Status__c = 'Retrying'
            AND (RetryCount__c < :config.Max_Retries__c OR RetryCount__c = null)
        ];

        Boolean hasPendingLogs = (pendingCount > 0 || retryingCount > 0);

        if (hasPendingLogs) {
            try {
                Database.executeBatch(new OpportunityWebhookBatch(), 1);
            } catch (Exception e) {
                Logger.error('Failed to restart webhook processor: ' + e.getMessage())
                    .setRecordId((Id)null)
                    .addTag('OpportunityWebhookProcessor');
                Logger.saveLog();
            }
        }
    }
}