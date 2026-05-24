# Advanced Metadata Audit Trail

## Project Overview

Advanced Metadata Audit Trail is a Salesforce DX, Salesforce-native MVP for an advanced metadata/configuration audit experience. It creates a Lightning app named **Auditing Application** with an **Audit Command Center** dashboard, metadata audit events, audit runs, metadata snapshots, metadata diffs, and configurable risk rules.

The MVP extends Salesforce Setup Audit Trail by copying recent Setup Audit Trail activity into custom audit objects, applying risk scoring, and presenting executive and admin-friendly review queues.

## Business Purpose

Salesforce Setup Audit Trail is valuable, but it is difficult to triage at scale. This app adds:

- KPI visibility for metadata/configuration changes.
- Critical/high-risk classification.
- Review queue tracking.
- Audit run history.
- Snapshot and diff framework for future before/after metadata comparison.
- Portable Salesforce DX source that can be validated in a Dev Org and later deployed to a company sandbox.

## User Journey

1. Open App Launcher.
2. Select **Auditing Application**.
3. Land on **Audit Command Center**.
4. Review KPI cards, high-risk changes, review queue, risk/category counts, and recent audit runs.
5. Open related tabs for Metadata Audit Events, Audit Runs, Metadata Snapshots, Metadata Diffs, and Risk Rules.

## Components Created

- Lightning App: `Auditing_Application`
- App Page: `Audit_Command_Center`
- LWC: `auditCommandCenter`
- Custom Objects: `Audit_Run__c`, `Metadata_Audit_Event__c`, `Metadata_Component_Snapshot__c`, `Metadata_Diff__c`, `Metadata_Risk_Assessment__c`
- Custom Tabs for each object plus Audit Command Center
- Apex: `SetupAuditTrailSyncService`, `MetadataRiskScoringService`, `AuditCommandCenterController`, `MetadataAuditScheduler`, `MetadataSnapshotService`, `MetadataDiffService`
- Tests for all Apex services/controllers
- Permission Set: `Metadata_Audit_Admin`
- Anonymous Apex helper: `scripts/apex/runInitialAuditSync.apex`

## Deploy to Personal Dev Org

```bash
sf project deploy start --source-dir force-app --target-org personalDevOrg --test-level RunSpecifiedTests --tests SetupAuditTrailSyncServiceTest --tests MetadataRiskScoringServiceTest --tests AuditCommandCenterControllerTest --tests MetadataAuditSchedulerTest --tests MetadataSnapshotServiceTest --tests MetadataDiffServiceTest
```

Assign permission set:

```bash
sf org assign permset --name Metadata_Audit_Admin --target-org personalDevOrg
```

Run initial sync:

```apex
SetupAuditTrailSyncService.syncRecentChanges(30);
```

Or run the included script:

```bash
sf apex run --file scripts/apex/runInitialAuditSync.apex --target-org personalDevOrg
```

Schedule daily sync:

```apex
MetadataAuditScheduler.scheduleDaily();
```

## Export from Dev Org

```bash
sf project retrieve start --target-org <dev-org-alias>
```

## Validate Company Sandbox Deployment

```bash
sf project deploy validate --target-org <company-sandbox-alias> --test-level RunLocalTests
```

## Deploy to Company Sandbox

```bash
sf project deploy start --target-org <company-sandbox-alias> --test-level RunLocalTests
```

Assign permission set:

```bash
sf org assign permset --name Metadata_Audit_Admin --target-org <company-sandbox-alias>
```

Run initial sync:

```apex
SetupAuditTrailSyncService.syncRecentChanges(30);
```

Schedule daily sync:

```apex
MetadataAuditScheduler.scheduleDaily();
```

## Reports and Dashboard

Reports and dashboard metadata can be org-sensitive because folders, report types, and dashboard running-user settings vary by org. For this MVP, create these manually if needed:

- Report Folder: Metadata Audit Reports
- Reports: High Risk Metadata Changes, Critical Changes, Changes Requiring Review, Changes by User, Audit Runs Status, Changes by Category
- Dashboard: Metadata Audit Executive Dashboard

Use the custom report-enabled objects as the report source.

## Leadership Demo Script

1. Open App Launcher.
2. Select **Auditing Application**.
3. Show **Audit Command Center**.
4. Explain KPI cards: total changes, critical/high risk, review required, unauthorized changes, and last audit run.
5. Show recent high-risk changes.
6. Show the review queue.
7. Open a Metadata Audit Event.
8. Explain risk score, risk reason, review status, and authorization fields.
9. Show Audit Runs and explain sync traceability.
10. Explain roadmap: Metadata API snapshot engine, Git comparison, CI/CD integration, approval integration, AI risk summary, and rollback recommendation.

## Known Limitations

- This MVP mainly syncs Salesforce Setup Audit Trail.
- Apex cannot deeply retrieve all metadata XML without Metadata API or Tooling API integration.
- Full before/after metadata diffing is better with Salesforce CLI, Git, or an external service.
- Reports and dashboard metadata may require manual adjustment depending on the target org.
- Production rollout must go through sandbox validation, security review, peer review, and an approved release process.
- Dev Org `RunLocalTests` validation can fail because of unrelated pre-existing org tests or trigger coverage; company sandbox validation should still use `RunLocalTests`.

## Future Roadmap

- Metadata API snapshot ingestion.
- Salesforce CLI metadata snapshot export.
- Git-based before/after comparison.
- CI/CD deployment correlation.
- Change approval integration.
- AI-generated risk summaries.
- Rollback recommendations and guided restore plans.
