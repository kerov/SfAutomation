trigger OpportunityStageChangedTrigger on OpportunityStageChanged__e (after insert) {
    TriggerService.execute();
}