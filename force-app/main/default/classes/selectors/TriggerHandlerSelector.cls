public with sharing class TriggerHandlerSelector {

    public List<Trigger_Handler__mdt> selectBySObjectType(String sobjectType) {
        try {
            List<Trigger_Handler__mdt> handlers = [
                SELECT Id, DeveloperName, Handler_Name__c, Object__c,
                       Order__c, Is_Active__c
                FROM Trigger_Handler__mdt
                WHERE Object__c = :sobjectType
                  AND Is_Active__c = true
                ORDER BY Order__c ASC NULLS LAST, DeveloperName ASC
            ];

            return handlers;
        } catch (Exception e) {
            Logger.error('Error querying trigger handlers for ' + sobjectType + ': ' + e.getMessage())
                .setRecordId((Id)null)
                .addTag('TriggerHandlerSelector');
            Logger.saveLog();
            throw e;
        }
    }
}