public class OpportunityWebhookBatch implements Database.Batchable<Integer>, Database.AllowsCallouts {

    public Iterable<Integer> start(Database.BatchableContext context) {
        return new List<Integer>{1};
    }

    public void execute(Database.BatchableContext context, List<Integer> scope) {
        try {
            System.enqueueJob(new OpportunityWebhookProcessor());
        } catch (Exception e) {
            Logger.error('Failed to start webhook processor from batch: ' + e.getMessage())
                .setRecordId((Id)null)
                .addTag('OpportunityWebhookBatch');
            Logger.saveLog();
        }
    }

    public void finish(Database.BatchableContext context) {}
}