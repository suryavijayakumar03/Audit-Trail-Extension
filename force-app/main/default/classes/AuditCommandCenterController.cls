public with sharing class AuditCommandCenterController {
    public class DashboardSummary {
        @AuraEnabled public Integer totalMetadataChanges;
        @AuraEnabled public Integer criticalRiskChanges;
        @AuraEnabled public Integer highRiskChanges;
        @AuraEnabled public Integer changesRequiringReview;
        @AuraEnabled public Integer unauthorizedChanges;
        @AuraEnabled public String lastAuditRunStatus;
        @AuraEnabled public Datetime lastAuditRunDateTime;
    }

    public class CountBucket {
        @AuraEnabled public String label;
        @AuraEnabled public Integer value;
        public CountBucket(String label, Integer value) {
            this.label = label;
            this.value = value;
        }
    }

    @AuraEnabled(cacheable=true)
    public static DashboardSummary getDashboardSummary() {
        DashboardSummary summary = new DashboardSummary();
        summary.totalMetadataChanges = [SELECT COUNT() FROM Metadata_Audit_Event__c];
        summary.criticalRiskChanges = [SELECT COUNT() FROM Metadata_Audit_Event__c WHERE Risk_Level__c = 'Critical'];
        summary.highRiskChanges = [SELECT COUNT() FROM Metadata_Audit_Event__c WHERE Risk_Level__c = 'High'];
        summary.changesRequiringReview = [SELECT COUNT() FROM Metadata_Audit_Event__c WHERE Requires_Review__c = true AND Review_Status__c IN ('New', 'In Review')];
        summary.unauthorizedChanges = [SELECT COUNT() FROM Metadata_Audit_Event__c WHERE Is_Authorized__c = false];
        List<Audit_Run__c> runs = [SELECT Status__c, Completed_At__c, Started_At__c FROM Audit_Run__c ORDER BY Started_At__c DESC LIMIT 1];
        if (!runs.isEmpty()) {
            summary.lastAuditRunStatus = runs[0].Status__c;
            summary.lastAuditRunDateTime = runs[0].Completed_At__c == null ? runs[0].Started_At__c : runs[0].Completed_At__c;
        }
        return summary;
    }

    @AuraEnabled(cacheable=true)
    public static List<Metadata_Audit_Event__c> getRecentHighRiskEvents() {
        return [
            SELECT Id, Name, Action__c, Section__c, Display__c, Changed_By_Name__c, Changed_Date__c,
                   Metadata_Type__c, Component_Name__c, Risk_Level__c, Risk_Score__c, Risk_Reason__c
            FROM Metadata_Audit_Event__c
            WHERE Risk_Level__c IN ('High', 'Critical')
            ORDER BY Changed_Date__c DESC NULLS LAST
            LIMIT 10
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Metadata_Audit_Event__c> getReviewQueue() {
        return [
            SELECT Id, Name, Action__c, Section__c, Changed_By_Name__c, Changed_Date__c,
                   Risk_Level__c, Risk_Score__c, Review_Status__c
            FROM Metadata_Audit_Event__c
            WHERE Requires_Review__c = true AND Review_Status__c IN ('New', 'In Review')
            ORDER BY Risk_Score__c DESC NULLS LAST, Changed_Date__c DESC NULLS LAST
            LIMIT 10
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Audit_Run__c> getRecentAuditRuns() {
        return [
            SELECT Id, Name, Run_Type__c, Status__c, Started_At__c, Completed_At__c,
                   Total_Records_Processed__c, New_Changes_Found__c, Error_Message__c
            FROM Audit_Run__c
            ORDER BY Started_At__c DESC NULLS LAST
            LIMIT 10
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<CountBucket> getRiskCounts() {
        return aggregateCounts('Risk_Level__c');
    }

    @AuraEnabled(cacheable=true)
    public static List<CountBucket> getCategoryCounts() {
        return aggregateCounts('Change_Category__c');
    }

    private static List<CountBucket> aggregateCounts(String fieldName) {
        String queryText = 'SELECT ' + fieldName + ' labelValue, COUNT(Id) recordCount FROM Metadata_Audit_Event__c GROUP BY ' + fieldName + ' ORDER BY ' + fieldName;
        List<CountBucket> buckets = new List<CountBucket>();
        for (AggregateResult result : Database.query(queryText)) {
            buckets.add(new CountBucket(String.valueOf(result.get('labelValue')), Integer.valueOf(result.get('recordCount'))));
        }
        return buckets;
    }
}
