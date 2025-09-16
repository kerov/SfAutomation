public class OpportunityStageApiTriggerHandler extends TriggerHandler {

    protected override void executeAfterUpdate(
        List<SObject> updatedRecords,
        Map<Id, SObject> updatedRecordsById,
        List<SObject> oldRecords,
        Map<Id, SObject> oldRecordsById
    ) {
        List<Opportunity> updatedOpportunities = (List<Opportunity>) updatedRecords;
        Map<Id, Opportunity> oldOpportunityMap = (Map<Id, Opportunity>) oldRecordsById;

        handleStageChanges(updatedOpportunities, oldOpportunityMap);
    }

    private void handleStageChanges(List<Opportunity> updatedOpportunities, Map<Id, Opportunity> oldOpportunityMap) {
        OpportunityDomain oppDomain = new OpportunityDomain(updatedOpportunities, oldOpportunityMap);
        List<Opportunity> opportunitiesWithStageChanges = oppDomain.getOpportunitiesWithStageChanges();

        if (opportunitiesWithStageChanges.isEmpty()) {
            return;
        }

        processStageChanges(opportunitiesWithStageChanges);
    }

    private void processStageChanges(List<Opportunity> opportunities) {
        List<Opportunity_Api_Log__c> webhookLogs = new List<Opportunity_Api_Log__c>();
        List<OpportunityStageChanged__e> platformEvents = new List<OpportunityStageChanged__e>();

        for (Opportunity opp : opportunities) {
            Opportunity_Api_Log__c log = new Opportunity_Api_Log__c(
                Opportunity__c = opp.Id,
                Status__c = 'Pending',
                Job_Name__c = 'OpportunityWebhookProcessor',
                ErrorMessage__c = null
            );
            webhookLogs.add(log);

            OpportunityStageChanged__e event = new OpportunityStageChanged__e(
                OpportunityId__c = opp.Id
            );
            platformEvents.add(event);
        }

        if (!webhookLogs.isEmpty()) {
            try {
                insert webhookLogs;
            } catch (Exception e) {
                Logger.error('Error inserting webhook logs: ' + e.getMessage())
                    .setRecordId((Id)null)
                    .addTag('OpportunityStageApiTriggerHandler');
                throw e;
            }
        }

        if (!platformEvents.isEmpty()) {
            try {
                EventBus.publish(platformEvents);
            } catch (Exception e) {
                Logger.error('Error publishing platform events: ' + e.getMessage())
                    .setRecordId((Id)null)
                    .addTag('OpportunityStageApiTriggerHandler');
                throw e;
            }
        }
    }
}