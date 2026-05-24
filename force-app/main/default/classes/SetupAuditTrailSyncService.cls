public with sharing class SetupAuditTrailSyncService {
    @TestVisible private static SetupAuditTrailProvider provider = new SoqlSetupAuditTrailProvider();

    public class SetupAuditTrailRecord {
        public String sourceId;
        public String action;
        public String section;
        public String displayText;
        public String delegateUser;
        public String changedByName;
        public String changedByUserId;
        public Datetime changedDate;
    }

    public interface SetupAuditTrailProvider {
        List<SetupAuditTrailRecord> getRecentChanges(Integer daysBack);
    }

    public class SoqlSetupAuditTrailProvider implements SetupAuditTrailProvider {
        public List<SetupAuditTrailRecord> getRecentChanges(Integer daysBack) {
            Integer safeDays = daysBack == null || daysBack < 1 ? 1 : daysBack;
            Datetime startDate = System.now().addDays(-safeDays);
            List<SetupAuditTrailRecord> records = new List<SetupAuditTrailRecord>();
            for (SetupAuditTrail trail : [
                SELECT Id, Action, Section, Display, DelegateUser, CreatedById, CreatedBy.Name, CreatedDate
                FROM SetupAuditTrail
                WHERE CreatedDate >= :startDate
                ORDER BY CreatedDate DESC
                LIMIT 2000
            ]) {
                SetupAuditTrailRecord row = new SetupAuditTrailRecord();
                row.sourceId = String.valueOf(trail.Id);
                row.action = trail.Action;
                row.section = trail.Section;
                row.displayText = trail.Display;
                row.delegateUser = trail.DelegateUser;
                row.changedByName = trail.CreatedBy == null ? null : trail.CreatedBy.Name;
                row.changedByUserId = String.valueOf(trail.CreatedById);
                row.changedDate = trail.CreatedDate;
                records.add(row);
            }
            return records;
        }
    }

    public static Id syncRecentChanges(Integer daysBack) {
        Audit_Run__c run = new Audit_Run__c(
            Run_Type__c = 'Setup Audit Sync',
            Status__c = 'Started',
            Started_At__c = System.now(),
            Executed_By__c = UserInfo.getUserId()
        );
        insert run;

        try {
            List<SetupAuditTrailRecord> sourceRecords = provider.getRecentChanges(daysBack);
            List<Metadata_Audit_Event__c> newEvents = buildEvents(sourceRecords, run.Id);
            if (!newEvents.isEmpty()) {
                insert newEvents;
            }
            run.Status__c = 'Completed';
            run.Completed_At__c = System.now();
            run.Total_Records_Processed__c = sourceRecords.size();
            run.New_Changes_Found__c = newEvents.size();
            update run;
        } catch (Exception ex) {
            run.Status__c = 'Failed';
            run.Completed_At__c = System.now();
            run.Error_Message__c = ex.getMessage().left(32768);
            update run;
        }
        return run.Id;
    }

    @TestVisible
    private static List<Metadata_Audit_Event__c> buildEvents(List<SetupAuditTrailRecord> sourceRecords, Id runId) {
        List<Metadata_Audit_Event__c> events = new List<Metadata_Audit_Event__c>();
        if (sourceRecords == null || sourceRecords.isEmpty()) {
            return events;
        }

        Set<String> keys = new Set<String>();
        for (SetupAuditTrailRecord sourceRecord : sourceRecords) {
            keys.add(buildEventKey(sourceRecord));
        }

        Set<String> existingKeys = new Set<String>();
        for (Metadata_Audit_Event__c existing : [
            SELECT Event_Key__c
            FROM Metadata_Audit_Event__c
            WHERE Event_Key__c IN :keys
        ]) {
            existingKeys.add(existing.Event_Key__c);
        }

        for (SetupAuditTrailRecord sourceRecord : sourceRecords) {
            String eventKey = buildEventKey(sourceRecord);
            if (existingKeys.contains(eventKey)) {
                continue;
            }
            Metadata_Audit_Event__c eventRecord = new Metadata_Audit_Event__c();
            eventRecord.Event_Key__c = eventKey;
            eventRecord.Source__c = 'Setup Audit Trail';
            eventRecord.Action__c = sourceRecord.action;
            eventRecord.Section__c = sourceRecord.section;
            eventRecord.Display__c = sourceRecord.displayText;
            eventRecord.Delegate_User__c = sourceRecord.delegateUser;
            eventRecord.Changed_By_Name__c = sourceRecord.changedByName;
            eventRecord.Changed_By_UserId__c = sourceRecord.changedByUserId;
            eventRecord.Changed_Date__c = sourceRecord.changedDate;
            eventRecord.Metadata_Type__c = inferMetadataType(sourceRecord);
            eventRecord.Component_Name__c = sourceRecord.section;
            eventRecord.Component_Full_Name__c = String.isBlank(sourceRecord.displayText) ? sourceRecord.action : sourceRecord.displayText.left(255);
            eventRecord.Is_Authorized__c = false;
            eventRecord.Audit_Run__c = runId;
            events.add(eventRecord);
        }
        MetadataRiskScoringService.scoreEvents(events);
        return events;
    }

    private static String buildEventKey(SetupAuditTrailRecord sourceRecord) {
        if (!String.isBlank(sourceRecord.sourceId)) {
            return 'SetupAuditTrail:' + sourceRecord.sourceId;
        }
        return EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(String.join(new List<String>{
            String.valueOf(sourceRecord.changedDate), sourceRecord.action, sourceRecord.section, sourceRecord.displayText, sourceRecord.changedByUserId
        }, '|'))));
    }

    private static String inferMetadataType(SetupAuditTrailRecord sourceRecord) {
        String text = String.join(new List<String>{ sourceRecord.action, sourceRecord.section, sourceRecord.displayText }, ' ').toLowerCase();
        Map<String, String> mappings = new Map<String, String>{
            'apex class' => 'ApexClass',
            'apex trigger' => 'ApexTrigger',
            'flow' => 'Flow',
            'permission set' => 'PermissionSet',
            'profile' => 'Profile',
            'named credential' => 'NamedCredential',
            'connected app' => 'ConnectedApp',
            'validation rule' => 'ValidationRule',
            'record type' => 'RecordType',
            'page layout' => 'Layout',
            'lightning page' => 'FlexiPage',
            'report' => 'Report',
            'dashboard' => 'Dashboard'
        };
        for (String key : mappings.keySet()) {
            if (text.contains(key)) {
                return mappings.get(key);
            }
        }
        return sourceRecord.section;
    }
}
