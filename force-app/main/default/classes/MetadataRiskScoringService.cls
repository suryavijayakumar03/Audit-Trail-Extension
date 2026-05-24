public with sharing class MetadataRiskScoringService {
    public class RiskResult {
        @AuraEnabled public String riskLevel;
        @AuraEnabled public Integer riskScore;
        @AuraEnabled public String category;
        @AuraEnabled public Boolean requiresReview;
        @AuraEnabled public String reason;
    }

    public static void scoreEvents(List<Metadata_Audit_Event__c> events) {
        if (events == null) {
            return;
        }
        for (Metadata_Audit_Event__c eventRecord : events) {
            RiskResult result = assess(
                eventRecord.Action__c,
                eventRecord.Section__c,
                eventRecord.Display__c,
                eventRecord.Metadata_Type__c
            );
            eventRecord.Risk_Level__c = result.riskLevel;
            eventRecord.Risk_Score__c = result.riskScore;
            eventRecord.Change_Category__c = result.category;
            eventRecord.Requires_Review__c = result.requiresReview;
            eventRecord.Review_Status__c = result.requiresReview ? 'New' : null;
            eventRecord.Risk_Reason__c = result.reason;
        }
    }

    public static RiskResult assess(String action, String section, String displayText, String metadataType) {
        String haystack = String.join(new List<String>{
            safe(action), safe(section), safe(displayText), safe(metadataType)
        }, ' ').toLowerCase();

        RiskResult result = new RiskResult();
        result.riskLevel = 'Low';
        result.riskScore = 20;
        result.category = 'Other';
        result.requiresReview = false;
        result.reason = 'Low-risk configuration change based on baseline keyword rules.';

        if (matchesAny(haystack, new List<String>{
            'named credential', 'connected app', 'modify all data', 'view all data',
            'manage users', 'author apex', 'customize application', 'security setting'
        })) {
            setResult(result, 'Critical', 95, 'Security', true, 'Critical security or privileged administration change detected.');
        } else if (matchesAny(haystack, new List<String>{
            'flow activated', 'flow deactivated', 'apex class', 'apex trigger',
            'sharing rule', 'remote site setting', 'permission set', 'profile'
        })) {
            String category = matchesAny(haystack, new List<String>{ 'flow', 'apex' }) ? 'Automation' : 'Access Control';
            setResult(result, 'High', 75, category, true, 'High-impact automation, code, integration, sharing, profile, or permission set change detected.');
        } else if (matchesAny(haystack, new List<String>{
            'validation rule', 'record type', 'page layout', 'lightning page',
            'approval process', 'assignment rule', 'email template'
        })) {
            setResult(result, 'Medium', 50, 'Data Model', true, 'Medium-impact business process or user experience configuration change detected.');
        } else if (matchesAny(haystack, new List<String>{
            'custom label', ' tab ', ' app ', 'field created', 'field updated',
            'report', 'dashboard'
        })) {
            String category = matchesAny(haystack, new List<String>{ 'report', 'dashboard' }) ? 'Reporting' : 'UI';
            setResult(result, 'Low', 20, category, false, 'Low-impact metadata change detected.');
        }
        return result;
    }

    private static void setResult(RiskResult result, String level, Integer score, String category, Boolean review, String reason) {
        result.riskLevel = level;
        result.riskScore = score;
        result.category = category;
        result.requiresReview = review;
        result.reason = reason;
    }

    private static Boolean matchesAny(String value, List<String> needles) {
        for (String needle : needles) {
            if (value.contains(needle)) {
                return true;
            }
        }
        return false;
    }

    private static String safe(String value) {
        return String.isBlank(value) ? '' : value;
    }
}
