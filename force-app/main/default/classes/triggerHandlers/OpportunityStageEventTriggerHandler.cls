public class OpportunityStageEventTriggerHandler extends TriggerHandler {

    protected override void executeAfterInsert(
        List<SObject> newRecords,
        Map<Id, SObject> newRecordsById
    ) {
        List<OpportunityStageChanged__e> events = (List<OpportunityStageChanged__e>) newRecords;
        try {
            processStageChangedEvents(events);
        } catch (Exception e) {
            Logger.error('Error in OpportunityStageEventTriggerHandler: ' + e.getMessage())
                .setRecordId((Id)null)
                .addTag('OpportunityStageEventTriggerHandler');
        }
    }

    private void processStageChangedEvents(List<OpportunityStageChanged__e> events) {
        if (isWebhookProcessorRunning()) {
            return;
        }
        try {
            System.enqueueJob(new OpportunityWebhookProcessor());
        } catch (Exception e) {
            Logger.error('Could not start webhook processor: ' + e.getMessage())
                .setRecordId((Id)null)
                .addTag('OpportunityStageEventTriggerHandler');
        }
    }

    private Boolean isWebhookProcessorRunning() {
        Integer runningJobs = [
            SELECT COUNT()
            FROM AsyncApexJob
            WHERE ApexClass.Name IN ('OpportunityWebhookProcessor', 'OpportunityWebhookBatch')
            AND Status IN ('Holding', 'Queued', 'Preparing', 'Processing')
        ];

        return runningJobs > 0;
    }
}