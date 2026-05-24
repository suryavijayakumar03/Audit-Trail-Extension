String[] objectNames = 'Metadata_Diff__c,Metadata_Component_Snapshot__c,Metadata_Audit_Event__c,Audit_Run__c'.split(',');
Integer totalDeleted = 0;
for (String objectName : objectNames) {
    try {
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
        if (objectType == null || !objectType.getDescribe().isDeletable() || !objectType.getDescribe().isQueryable()) {
            continue;
        }
        List<SObject> rows = Database.query('SELECT Id FROM ' + objectName + ' LIMIT 200');
        Database.DeleteResult[] results = Database.delete(rows, false);
        for (Database.DeleteResult result : results) {
            if (result.isSuccess()) {
                totalDeleted++;
            }
        }
    } catch (Exception ex) {
        System.debug('Skipped ' + objectName + ': ' + ex.getMessage());
    }
}
System.debug('CLEAR_AUDIT_APP_DATA_DELETED=' + totalDeleted);
