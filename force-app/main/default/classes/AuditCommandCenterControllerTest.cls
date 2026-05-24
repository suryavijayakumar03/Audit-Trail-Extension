@IsTest
private class AuditCommandCenterControllerTest {
    @IsTest
    static void returnsDashboardData() {
        Audit_Run__c run = new Audit_Run__c(Run_Type__c = 'Manual Scan', Status__c = 'Completed', Started_At__c = System.now(), Completed_At__c = System.now(), Executed_By__c = UserInfo.getUserId());
        insert run;
        insert new Metadata_Audit_Event__c(
            Event_Key__c = 'test-event-1',
            Source__c = 'Manual',
            Action__c = 'Named Credential changed',
            Changed_Date__c = System.now(),
            Risk_Level__c = 'Critical',
            Risk_Score__c = 95,
            Change_Category__c = 'Security',
            Requires_Review__c = true,
            Review_Status__c = 'New',
            Is_Authorized__c = false,
            Audit_Run__c = run.Id
        );

        Test.startTest();
        AuditCommandCenterController.DashboardSummary summary = AuditCommandCenterController.getDashboardSummary();
        List<Metadata_Audit_Event__c> highRisk = AuditCommandCenterController.getRecentHighRiskEvents();
        List<Metadata_Audit_Event__c> queue = AuditCommandCenterController.getReviewQueue();
        List<Audit_Run__c> runs = AuditCommandCenterController.getRecentAuditRuns();
        List<AuditCommandCenterController.CountBucket> riskCounts = AuditCommandCenterController.getRiskCounts();
        List<AuditCommandCenterController.CountBucket> categoryCounts = AuditCommandCenterController.getCategoryCounts();
        Test.stopTest();

        System.assertEquals(1, summary.totalMetadataChanges);
        System.assertEquals(1, highRisk.size());
        System.assertEquals(1, queue.size());
        System.assertEquals(1, runs.size());
        System.assertEquals(false, riskCounts.isEmpty());
        System.assertEquals(false, categoryCounts.isEmpty());
    }
}
