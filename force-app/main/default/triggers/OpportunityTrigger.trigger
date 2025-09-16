/**
 * @description Trigger for Opportunity object using metadata-driven handler execution
 * Executes all active trigger handlers configured in Trigger_Handler__mdt
 * SObject type is automatically determined from trigger context
 * @author Salesforce Automation Team
 * @version 2.0
 */
trigger OpportunityTrigger on Opportunity (before insert, before update, before delete,
                                         after insert, after update, after delete, after undelete) {
    TriggerService.execute();
}