public abstract class TriggerHandler {
    
    public void execute() {
        String handlerName = getClassName();

        try {
            dispatchTriggerOperation();
        } catch (Exception e) {
            handleTriggerException(e, handlerName);
        }
    }

    private void dispatchTriggerOperation() {
        switch on Trigger.operationType {
            when BEFORE_INSERT {
                executeBeforeInsert(Trigger.new);
            }
            when BEFORE_UPDATE {
                executeBeforeUpdate(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
            }
            when BEFORE_DELETE {
                executeBeforeDelete(Trigger.old, Trigger.oldMap);
            }
            when AFTER_INSERT {
                executeAfterInsert(Trigger.new, Trigger.newMap);
            }
            when AFTER_UPDATE {
                executeAfterUpdate(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
            }
            when AFTER_DELETE {
                executeAfterDelete(Trigger.old, Trigger.oldMap);
            }
            when AFTER_UNDELETE {
                executeAfterUndelete(Trigger.new, Trigger.newMap);
            }
        }
    }

    protected virtual void executeBeforeInsert(List<SObject> newRecords) {}
    protected virtual void executeBeforeUpdate(List<SObject> updatedRecords, Map<Id, SObject> updatedRecordsById, List<SObject> oldRecords, Map<Id, SObject> oldRecordsById) {}
    protected virtual void executeBeforeDelete(List<SObject> deletedRecords, Map<Id, SObject> deletedRecordsById) {}
    protected virtual void executeAfterInsert(List<SObject> newRecords, Map<Id, SObject> newRecordsById) {}
    protected virtual void executeAfterUpdate(List<SObject> updatedRecords, Map<Id, SObject> updatedRecordsById, List<SObject> oldRecords, Map<Id, SObject> oldRecordsById) {}
    protected virtual void executeAfterDelete(List<SObject> deletedRecords, Map<Id, SObject> deletedRecordsById) {}
    protected virtual void executeAfterUndelete(List<SObject> undeletedRecords, Map<Id, SObject> undeletedRecordsById) {}

    private void handleTriggerException(Exception e, String handlerName) {
        String errorMessage = 'Error in ' + handlerName + ': ' + e.getMessage() +
                            ' | Stack Trace: ' + e.getStackTraceString();

        Logger.error(errorMessage)
            .setRecordId((Id)null)
            .addTag('TriggerHandler');

        throw e;
    }

    private String getClassName() {
        return String.valueOf(this).split(':')[0];
    }
}