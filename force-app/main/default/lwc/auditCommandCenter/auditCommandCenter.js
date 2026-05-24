import { LightningElement, wire } from 'lwc';
import getDashboardSummary from '@salesforce/apex/AuditCommandCenterController.getDashboardSummary';
import getRecentHighRiskEvents from '@salesforce/apex/AuditCommandCenterController.getRecentHighRiskEvents';
import getReviewQueue from '@salesforce/apex/AuditCommandCenterController.getReviewQueue';
import getRecentAuditRuns from '@salesforce/apex/AuditCommandCenterController.getRecentAuditRuns';
import getRiskCounts from '@salesforce/apex/AuditCommandCenterController.getRiskCounts';
import getCategoryCounts from '@salesforce/apex/AuditCommandCenterController.getCategoryCounts';

const EVENT_COLUMNS = [
    { label: 'Event', fieldName: 'Name' },
    { label: 'Action', fieldName: 'Action__c' },
    { label: 'Risk', fieldName: 'Risk_Level__c' },
    { label: 'Score', fieldName: 'Risk_Score__c', type: 'number' },
    { label: 'Changed By', fieldName: 'Changed_By_Name__c' }
];

const REVIEW_COLUMNS = [
    { label: 'Event', fieldName: 'Name' },
    { label: 'Action', fieldName: 'Action__c' },
    { label: 'Risk', fieldName: 'Risk_Level__c' },
    { label: 'Status', fieldName: 'Review_Status__c' }
];

const RUN_COLUMNS = [
    { label: 'Run', fieldName: 'Name' },
    { label: 'Type', fieldName: 'Run_Type__c' },
    { label: 'Status', fieldName: 'Status__c' },
    { label: 'Processed', fieldName: 'Total_Records_Processed__c', type: 'number' },
    { label: 'New Changes', fieldName: 'New_Changes_Found__c', type: 'number' }
];

export default class AuditCommandCenter extends LightningElement {
    summary;
    highRiskEvents = [];
    reviewQueue = [];
    auditRuns = [];
    riskCounts = [];
    categoryCounts = [];
    eventColumns = EVENT_COLUMNS;
    reviewColumns = REVIEW_COLUMNS;
    runColumns = RUN_COLUMNS;

    @wire(getDashboardSummary)
    wiredSummary({ data }) {
        if (data) {
            this.summary = data;
        }
    }

    @wire(getRecentHighRiskEvents)
    wiredHighRisk({ data }) {
        if (data) {
            this.highRiskEvents = data;
        }
    }

    @wire(getReviewQueue)
    wiredQueue({ data }) {
        if (data) {
            this.reviewQueue = data;
        }
    }

    @wire(getRecentAuditRuns)
    wiredRuns({ data }) {
        if (data) {
            this.auditRuns = data;
        }
    }

    @wire(getRiskCounts)
    wiredRiskCounts({ data }) {
        if (data) {
            this.riskCounts = this.withBars(data);
        }
    }

    @wire(getCategoryCounts)
    wiredCategoryCounts({ data }) {
        if (data) {
            this.categoryCounts = this.withBars(data);
        }
    }

    get hasRecords() {
        return (this.summary?.totalMetadataChanges || 0) > 0;
    }

    get kpis() {
        const summary = this.summary || {};
        return [
            { label: 'Total Metadata Changes', value: summary.totalMetadataChanges || 0, className: 'kpi' },
            { label: 'Critical Risk Changes', value: summary.criticalRiskChanges || 0, className: 'kpi kpi-critical' },
            { label: 'High Risk Changes', value: summary.highRiskChanges || 0, className: 'kpi kpi-high' },
            { label: 'Changes Requiring Review', value: summary.changesRequiringReview || 0, className: 'kpi kpi-review' },
            { label: 'Unauthorized Changes', value: summary.unauthorizedChanges || 0, className: 'kpi kpi-unauthorized' },
            { label: 'Last Audit Run Status', value: summary.lastAuditRunStatus || 'Not Run', className: 'kpi' },
            { label: 'Last Audit Run Date/Time', value: this.formatDate(summary.lastAuditRunDateTime), className: 'kpi' }
        ];
    }

    withBars(items) {
        const max = Math.max(...items.map((item) => item.value), 1);
        return items.map((item) => ({
            ...item,
            label: item.label || 'Unspecified',
            style: `width: ${Math.max((item.value / max) * 100, 6)}%`
        }));
    }

    formatDate(value) {
        if (!value) {
            return 'Not Run';
        }
        return new Intl.DateTimeFormat(undefined, { dateStyle: 'short', timeStyle: 'short' }).format(new Date(value));
    }
}
