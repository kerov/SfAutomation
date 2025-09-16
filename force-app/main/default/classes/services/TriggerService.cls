public class TriggerService {

    public static void execute() {
        String sobjectType = getSObjectTypeFromContext();
        execute(sobjectType);
    }

    public static void execute(String sobjectType) {
        TriggerHandlerDomain.newInstance(sobjectType).executeHandlers();
    }

    private static String getSObjectTypeFromContext() {
        return Trigger.isDelete 
            ? Trigger.old[0].getSObjectType().getDescribe().getName() 
            : Trigger.new[0].getSObjectType().getDescribe().getName();
    }
}