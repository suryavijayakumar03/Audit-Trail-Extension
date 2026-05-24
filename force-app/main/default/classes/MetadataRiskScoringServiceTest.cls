@IsTest
private class MetadataRiskScoringServiceTest {
    @IsTest
    static void scoresCriticalSecurityChanges() {
        MetadataRiskScoringService.RiskResult result = MetadataRiskScoringService.assess(
            'Changed Named Credential',
            'Security',
            'Named Credential changed for integration',
            'NamedCredential'
        );
        System.assertEquals('Critical', result.riskLevel);
        System.assertEquals(true, result.requiresReview);
        System.assertEquals('Security', result.category);
    }

    @IsTest
    static void scoresHighAutomationChanges() {
        Metadata_Audit_Event__c eventRecord = new Metadata_Audit_Event__c(Action__c = 'Apex Class changed');
        MetadataRiskScoringService.scoreEvents(new List<Metadata_Audit_Event__c>{ eventRecord });
        System.assertEquals('High', eventRecord.Risk_Level__c);
        System.assertEquals(true, eventRecord.Requires_Review__c);
    }
}
