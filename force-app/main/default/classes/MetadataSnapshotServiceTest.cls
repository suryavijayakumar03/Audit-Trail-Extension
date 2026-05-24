@IsTest
private class MetadataSnapshotServiceTest {
    @IsTest
    static void storesSnapshotAndMarksPriorAsNotCurrent() {
        String firstHash = MetadataSnapshotService.generateHash('<xml>one</xml>');
        String secondHash = MetadataSnapshotService.generateHash('<xml>two</xml>');
        System.assertNotEquals(firstHash, secondHash);

        Metadata_Component_Snapshot__c firstSnapshot = MetadataSnapshotService.storeSnapshot('ApexClass', 'BillingService', 'BillingService', '<xml>one</xml>', 'Manual', null);
        Metadata_Component_Snapshot__c secondSnapshot = MetadataSnapshotService.storeSnapshot('ApexClass', 'BillingService', 'BillingService', '<xml>two</xml>', 'Manual', null);

        firstSnapshot = [SELECT Is_Current__c FROM Metadata_Component_Snapshot__c WHERE Id = :firstSnapshot.Id];
        secondSnapshot = [SELECT Is_Current__c FROM Metadata_Component_Snapshot__c WHERE Id = :secondSnapshot.Id];
        System.assertEquals(false, firstSnapshot.Is_Current__c);
        System.assertEquals(true, secondSnapshot.Is_Current__c);
    }
}
