List<String> objectNames = new List<String>{
    'Metadata_Diff__c',
    'Metadata_Component_Snapshot__c',
    'Metadata_Audit_Event__c',
    'Metadata_Risk_Assessment__c',
    'Audit_Run__c',
    'Task',
    'Event',
    'Case',
    'Opportunity',
    'Lead',
    'Contact',
    'Account',
    'CampaignMember',
    'Campaign',
    'Product2',
    'PricebookEntry',
    'Contract',
    'Order',
    'Asset',
    'ContentDocument'
};

Integer totalDeleted = 0;
List<String> messages = new List<String>();

for (String objectName : objectNames) {
    Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
    if (objectType == null || !objectType.getDescribe().isDeletable() || !objectType.getDescribe().isQueryable()) {
        messages.add(objectName + ': skipped');
        continue;
    }

    Integer objectDeleted = 0;
    Boolean keepGoing = true;
    while (keepGoing) {
        List<SObject> rows = Database.query('SELECT Id FROM ' + objectName + ' LIMIT 200');
        if (rows.isEmpty()) {
            keepGoing = false;
        } else {
            Database.DeleteResult[] results = Database.delete(rows, false);
            Integer successfulThisBatch = 0;
            for (Database.DeleteResult result : results) {
                if (result.isSuccess()) {
                    successfulThisBatch++;
                }
            }
            objectDeleted += successfulThisBatch;
            totalDeleted += successfulThisBatch;
            keepGoing = rows.size() == 200 && successfulThisBatch > 0;
        }
    }
    messages.add(objectName + ': deleted ' + objectDeleted);
}

System.debug('FULL_CLEAN_SLATE_TOTAL_DELETED=' + totalDeleted);
System.debug('FULL_CLEAN_SLATE_DETAILS=' + String.join(messages, ' | '));
