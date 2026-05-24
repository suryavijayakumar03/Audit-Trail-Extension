global with sharing class MetadataAuditScheduler implements Schedulable {
    global void execute(SchedulableContext context) {
        SetupAuditTrailSyncService.syncRecentChanges(1);
    }

    public static String scheduleDaily() {
        return System.schedule('Daily Metadata Audit Sync', '0 0 2 * * ?', new MetadataAuditScheduler());
    }
}
