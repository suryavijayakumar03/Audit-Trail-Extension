@IsTest
private class SetupAuditTrailSyncServiceTest {
    private class FakeProvider implements SetupAuditTrailSyncService.SetupAuditTrailProvider {
        public List<SetupAuditTrailSyncService.SetupAuditTrailRecord> getRecentChanges(Integer daysBack) {
            SetupAuditTrailSyncService.SetupAuditTrailRecord first = new SetupAuditTrailSyncService.SetupAuditTrailRecord();
            first.sourceId = 'audit-1';
            first.action = 'Apex Class changed';
            first.section = 'Apex Classes';
            first.displayText = 'Apex Class changed: BillingService';
            first.changedByName = 'Test User';
            first.changedByUserId = UserInfo.getUserId();
            first.changedDate = System.now();

            SetupAuditTrailSyncService.SetupAuditTrailRecord duplicate = new SetupAuditTrailSyncService.SetupAuditTrailRecord();
            duplicate.sourceId = 'audit-2';
            duplicate.action = 'Profile changed';
            duplicate.section = 'Profiles';
            duplicate.displayText = 'Profile changed: System Administrator';
            duplicate.changedByName = 'Test User';
            duplicate.changedByUserId = UserInfo.getUserId();
            duplicate.changedDate = System.now();
            return new List<SetupAuditTrailSyncService.SetupAuditTrailRecord>{ first, duplicate };
        }
    }

    private class ThrowingProvider implements SetupAuditTrailSyncService.SetupAuditTrailProvider {
        public List<SetupAuditTrailSyncService.SetupAuditTrailRecord> getRecentChanges(Integer daysBack) {
            throw new AuditException('provider failed');
        }
    }

    private class AuditException extends Exception {}

    @IsTest
    static void syncCreatesRunAndAvoidsDuplicatesAcrossRuns() {
        SetupAuditTrailSyncService.provider = new FakeProvider();

        Test.startTest();
        Id firstRunId = SetupAuditTrailSyncService.syncRecentChanges(7);
        Id secondRunId = SetupAuditTrailSyncService.syncRecentChanges(7);
        Test.stopTest();

        System.assertNotEquals(null, firstRunId);
        System.assertNotEquals(null, secondRunId);
        System.assertEquals(2, [SELECT COUNT() FROM Metadata_Audit_Event__c]);
        List<Audit_Run__c> runs = [SELECT Status__c, New_Changes_Found__c FROM Audit_Run__c ORDER BY CreatedDate ASC];
        System.assertEquals('Completed', runs[0].Status__c);
        System.assertEquals(2, runs[0].New_Changes_Found__c);
        System.assertEquals(0, runs[1].New_Changes_Found__c);
    }

    @IsTest
    static void syncMarksRunFailedWhenProviderThrows() {
        SetupAuditTrailSyncService.provider = new ThrowingProvider();

        Test.startTest();
        Id runId = SetupAuditTrailSyncService.syncRecentChanges(1);
        Test.stopTest();

        Audit_Run__c run = [SELECT Status__c, Error_Message__c FROM Audit_Run__c WHERE Id = :runId];
        System.assertEquals('Failed', run.Status__c);
        System.assert(run.Error_Message__c.contains('provider failed'));
    }
}
