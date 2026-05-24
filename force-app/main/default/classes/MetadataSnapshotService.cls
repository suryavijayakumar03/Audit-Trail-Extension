public with sharing class MetadataSnapshotService {
    public static String generateHash(String metadataBody) {
        return EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(String.valueOf(metadataBody))));
    }

    public static Metadata_Component_Snapshot__c storeSnapshot(String metadataType, String componentName, String componentFullName, String metadataBody, String snapshotSource, Id auditRunId) {
        for (Metadata_Component_Snapshot__c prior : [
            SELECT Id, Is_Current__c
            FROM Metadata_Component_Snapshot__c
            WHERE Component_Full_Name__c = :componentFullName
            AND Metadata_Type__c = :metadataType
            AND Is_Current__c = true
        ]) {
            prior.Is_Current__c = false;
            update prior;
        }

        Metadata_Component_Snapshot__c snapshot = new Metadata_Component_Snapshot__c(
            Snapshot_Key__c = generateHash(String.join(new List<String>{ metadataType, componentFullName, String.valueOf(System.now().getTime()) }, '|')),
            Metadata_Type__c = metadataType,
            Component_Name__c = componentName,
            Component_Full_Name__c = componentFullName,
            Component_Hash__c = generateHash(metadataBody),
            Snapshot_Body__c = metadataBody,
            Snapshot_Date__c = System.now(),
            Snapshot_Source__c = String.isBlank(snapshotSource) ? 'Manual' : snapshotSource,
            Is_Current__c = true,
            Audit_Run__c = auditRunId
        );
        insert snapshot;
        return snapshot;
    }
}
