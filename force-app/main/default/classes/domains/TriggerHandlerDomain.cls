public with sharing class TriggerHandlerDomain {

    private List<Trigger_Handler__mdt> triggerHandlers;
    private TriggerHandlerSelector selector;


    public TriggerHandlerDomain(List<Trigger_Handler__mdt> triggerHandlers) {
        this.triggerHandlers = triggerHandlers;
        this.selector = new TriggerHandlerSelector();
    }

    public static TriggerHandlerDomain newInstance(String sobjectType) {
        TriggerHandlerSelector selector = new TriggerHandlerSelector();
        List<Trigger_Handler__mdt> handlers = selector.selectBySObjectType(sobjectType);
        return new TriggerHandlerDomain(handlers);
    }

    public void executeHandlers() {
        for (Trigger_Handler__mdt handlerMdt : triggerHandlers) {
            executeIndividualHandler(handlerMdt);
        }
    }

    private void executeIndividualHandler(Trigger_Handler__mdt handlerMdt) {
        try {
            instantiateHandler(handlerMdt.Handler_Name__c).execute();
        } catch (Exception e) {
            Logger.error('Error executing trigger handler: ' + handlerMdt.Handler_Name__c + ' - ' + e.getMessage())
                .setRecordId((Id)null)
                .addTag('TriggerHandlerDomain');
            throw e;
        }
    }

    private TriggerHandler instantiateHandler(String handlerClassName) {
        try {
            Type handlerType = Type.forName(handlerClassName);
            return (TriggerHandler) handlerType.newInstance();
        } catch (Exception e) {
            Logger.error('Error instantiating trigger handler: ' + handlerClassName + ' - ' + e.getMessage())
                .setRecordId((Id)null)
                .addTag('TriggerHandlerDomain');
            throw e;
        }
    }
}