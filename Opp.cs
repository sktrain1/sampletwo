public with sharing class OpportunityStatusController {

    @AuraEnabled(cacheable=false)
    public static String getOpportunityStage(String oppId) {
        Opportunity opp = [
            SELECT StageName
            FROM Opportunity
            WHERE Id = :oppId
            LIMIT 1
        ];
        return opp.StageName;
    }

    @AuraEnabled(cacheable=false)
    public static Map<String, String> getConfigData(String oppId) {

        Opportunity opp = [
            SELECT Secret_Key__c
            FROM Opportunity
            WHERE Id = :oppId
            LIMIT 1
        ];

        ThirdPartyConfig__c config = ThirdPartyConfig__c.getInstance();

        String baseUrl = (System.isSandbox() ?
            config.Sandbox_URL__c :
            config.Production_URL__c
        );

        Map<String, String> result = new Map<String, String>();
        result.put('baseUrl', baseUrl);
        result.put('secretKey', opp.Secret_Key__c);
        result.put('maxSeconds', String.valueOf(config.Max_Wait_Seconds__c));

        return result;
    }
}
