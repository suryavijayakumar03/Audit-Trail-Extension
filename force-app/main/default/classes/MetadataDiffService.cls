public with sharing class MetadataDiffService {
    public static Metadata_Diff__c compareSnapshots(Id previousSnapshotId, Id currentSnapshotId, Id auditEventId) {
        Metadata_Component_Snapshot__c previousSnapshot = previousSnapshotId == null ? null : [
            SELECT Id, Component_Hash__c, Snapshot_Body__c FROM Metadata_Component_Snapshot__c WHERE Id = :previousSnapshotId LIMIT 1
        ];
        Metadata_Component_Snapshot__c currentSnapshot = currentSnapshotId == null ? null : [
            SELECT Id, Component_Hash__c, Snapshot_Body__c FROM Metadata_Component_Snapshot__c WHERE Id = :currentSnapshotId LIMIT 1
        ];

        String diffType = 'Unknown';
        if (previousSnapshot == null && currentSnapshot != null) {
            diffType = 'Added';
        } else if (previousSnapshot != null && currentSnapshot == null) {
            diffType = 'Deleted';
        } else if (previousSnapshot != null && currentSnapshot != null && previousSnapshot.Component_Hash__c != currentSnapshot.Component_Hash__c) {
            diffType = 'Modified';
        }

        if (diffType == 'Unknown') {
            return null;
        }

        Metadata_Diff__c diff = new Metadata_Diff__c(
            Metadata_Audit_Event__c = auditEventId,
            Previous_Snapshot__c = previousSnapshotId,
            Current_Snapshot__c = currentSnapshotId,
            Diff_Type__c = diffType,
            Diff_Summary__c = 'Snapshot comparison detected ' + diffType + ' metadata.',
            Before_Value__c = previousSnapshot == null ? null : previousSnapshot.Snapshot_Body__c,
            After_Value__c = currentSnapshot == null ? null : currentSnapshot.Snapshot_Body__c,
            Is_Rollback_Possible__c = previousSnapshot != null,
            Rollback_Notes__c = previousSnapshot == null ? 'No prior snapshot is available.' : 'Rollback may be possible by restoring the previous snapshot through a controlled deployment.'
        );
        insert diff;
        return diff;
    }
}
