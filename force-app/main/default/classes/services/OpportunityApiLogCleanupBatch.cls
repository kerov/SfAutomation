public class OpportunityApiLogCleanupBatch implements Database.Batchable<SObject>, Schedulable {

    private static final Integer RETENTION_DAYS = 3;

    public Database.QueryLocator start(Database.BatchableContext context) {
        DateTime cutoffTime = DateTime.now().addDays(-RETENTION_DAYS);

        return Database.getQueryLocator([
            SELECT Id
            FROM Opportunity_Api_Log__c
            WHERE CreatedDate < :cutoffTime
        ]);
    }

    public void execute(Database.BatchableContext context, List<SObject> scope) {
        List<Opportunity_Api_Log__c> logsToDelete = (List<Opportunity_Api_Log__c>) scope;

        try {
            delete logsToDelete;
        } catch (Exception e) {
            Logger.error('Error deleting old Opportunity API Log records: ' + e.getMessage())
                .setRecordId((Id)null)
                .addTag('OpportunityApiLogCleanupBatch');
        }
    }

    public void finish(Database.BatchableContext context) {
    }

    public void execute(SchedulableContext context) {
        Database.executeBatch(new OpportunityApiLogCleanupBatch(), 200);
    }
}