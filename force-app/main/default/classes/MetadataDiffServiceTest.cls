@IsTest
private class MetadataDiffServiceTest {
    @IsTest
    static void createsModifiedDiffWhenHashesChange() {
        Metadata_Component_Snapshot__c previousSnapshot = MetadataSnapshotService.storeSnapshot('Flow', 'OrderFlow', 'OrderFlow', '<flow>v1</flow>', 'Manual', null);
        Metadata_Component_Snapshot__c currentSnapshot = MetadataSnapshotService.storeSnapshot('Flow', 'OrderFlow', 'OrderFlow', '<flow>v2</flow>', 'Manual', null);
        Metadata_Audit_Event__c eventRecord = new Metadata_Audit_Event__c(Event_Key__c = 'diff-event', Source__c = 'Manual', Action__c = 'Flow activated', Risk_Level__c = 'High');
        insert eventRecord;

        Metadata_Diff__c diff = MetadataDiffService.compareSnapshots(previousSnapshot.Id, currentSnapshot.Id, eventRecord.Id);

        System.assertNotEquals(null, diff);
        System.assertEquals('Modified', diff.Diff_Type__c);
        System.assertEquals(true, diff.Is_Rollback_Possible__c);
    }

    @IsTest
    static void returnsNullWhenHashesMatch() {
        Metadata_Component_Snapshot__c snapshot = MetadataSnapshotService.storeSnapshot('CustomLabel', 'LabelA', 'LabelA', '<label>same</label>', 'Manual', null);
        Metadata_Diff__c diff = MetadataDiffService.compareSnapshots(snapshot.Id, snapshot.Id, null);
        System.assertEquals(null, diff);
    }
}
