@IsTest
private class MetadataAuditSchedulerTest {
    private class EmptyProvider implements SetupAuditTrailSyncService.SetupAuditTrailProvider {
        public List<SetupAuditTrailSyncService.SetupAuditTrailRecord> getRecentChanges(Integer daysBack) {
            return new List<SetupAuditTrailSyncService.SetupAuditTrailRecord>();
        }
    }

    @IsTest
    static void schedulerExecutesSync() {
        SetupAuditTrailSyncService.provider = new EmptyProvider();

        Test.startTest();
        String jobId = System.schedule('Test Daily Metadata Audit Sync', '0 0 2 * * ?', new MetadataAuditScheduler());
        Test.stopTest();

        System.assertNotEquals(null, jobId);
        System.assertEquals(1, [SELECT COUNT() FROM Audit_Run__c WHERE Status__c = 'Completed']);
    }

    @IsTest
    static void scheduleDailyReturnsJobId() {
        SetupAuditTrailSyncService.provider = new EmptyProvider();
        Test.startTest();
        String jobId = MetadataAuditScheduler.scheduleDaily();
        Test.stopTest();
        System.assertNotEquals(null, jobId);
    }
}
