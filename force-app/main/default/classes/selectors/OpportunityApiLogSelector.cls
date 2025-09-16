public with sharing class OpportunityApiLogSelector {

    public List<Opportunity_Api_Log__c> selectPendingAndRetryingLogs(Integer maxRetries, Integer batchSize) {
        return [
            SELECT Id, Opportunity__c, Status__c, Payload__c, RetryCount__c, LastAttempt__c,
                    Opportunity__r.Id, Opportunity__r.Name, Opportunity__r.Amount,
                    Opportunity__r.StageName, Opportunity__r.Owner.Email
            FROM Opportunity_Api_Log__c
            WHERE Job_Name__c = 'OpportunityWebhookProcessor'
            AND (RetryCount__c < :maxRetries OR RetryCount__c = null)
            AND Status__c IN ('Pending', 'Retrying')
            ORDER BY CreatedDate ASC
            LIMIT :batchSize
        ];
    }

    public Boolean hasPendingLogs(Integer maxRetries) {
        List<Opportunity_Api_Log__c> logs = [
            SELECT Id
            FROM Opportunity_Api_Log__c
            WHERE Job_Name__c = 'OpportunityWebhookProcessor'
            AND (RetryCount__c < :maxRetries OR RetryCount__c = null)
            AND Status__c IN ('Pending', 'Retrying')
            LIMIT 1
        ];

        return !logs.isEmpty();
    }

    public Boolean isWebhookProcessorRunning() {
        List<AsyncApexJob> runningJobs = [
            SELECT Id, Status, ApexClass.Name
            FROM AsyncApexJob
            WHERE ApexClass.Name = 'OpportunityWebhookProcessor'
            AND Status IN ('Holding', 'Queued', 'Preparing', 'Processing')
            LIMIT 1
        ];
        return !runningJobs.isEmpty();
    }

}