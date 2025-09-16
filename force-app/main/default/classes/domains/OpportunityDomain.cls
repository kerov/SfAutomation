public with sharing class OpportunityDomain {

    private List<Opportunity> opportunities;
    private Map<Id, Opportunity> oldOpportunityMap;

    public OpportunityDomain(List<Opportunity> opportunities) {
        this.opportunities = opportunities;
    }

    public OpportunityDomain(List<Opportunity> opportunities, Map<Id, Opportunity> oldOpportunityMap) {
        this.opportunities = opportunities;
        this.oldOpportunityMap = oldOpportunityMap;
    }

    public List<Opportunity> getOpportunitiesWithStageChanges() {
        List<Opportunity> changedOpportunities = new List<Opportunity>();

        for (Opportunity opp : opportunities) {
            if (hasStageChanged(opp)) {
                changedOpportunities.add(opp);
            }
        }

        return changedOpportunities;
    }

    private Boolean hasStageChanged(Opportunity opportunity) {
        if (oldOpportunityMap == null || !oldOpportunityMap.containsKey(opportunity.Id)) {
            return false;
        }

        Opportunity oldOpportunity = oldOpportunityMap.get(opportunity.Id);
        return opportunity.StageName != oldOpportunity.StageName;
    }
}