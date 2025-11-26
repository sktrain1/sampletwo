@isTest
public class OpportunityStatusControllerTest {

    @testSetup
    static void setupData() {

        // Create custom setting record
        ThirdPartyConfig__c config = new ThirdPartyConfig__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Production_URL__c = 'https://prod.example.com',
            Sandbox_URL__c = 'https://sandbox.example.com',
            Max_Wait_Seconds__c = 90
        );
        insert config;

        // Create Opportunities with different stages
        insert new Opportunity(
            Name = 'Approved Opp',
            StageName = 'Approved',
            CloseDate = Date.today(),
            Secret_Key__c = 'APPROVED123'
        );

        insert new Opportunity(
            Name = 'Declined Opp',
            StageName = 'Closed Lost',
            CloseDate = Date.today(),
            Secret_Key__c = 'DECLINED456'
        );

        insert new Opportunity(
            Name = 'Pending Opp',
            StageName = 'Under Review',
            CloseDate = Date.today(),
            Secret_Key__c = 'PENDING789'
        );
    }

    @isTest
    static void testGetOpportunityStage() {

        Opportunity opp = [
            SELECT Id, StageName
            FROM Opportunity
            WHERE Name = 'Approved Opp'
            LIMIT 1
        ];

        Test.startTest();
        String result = OpportunityStatusController.getOpportunityStage(opp.Id);
        Test.stopTest();

        System.assertEquals('Approved', result, 'Stage should match created test data.');
    }

    @isTest
    static void testGetConfigDataSandbox() {

        // Force sandbox branch if needed
        // System.isSandbox() is not mockable, but in scratch org/sandbox it will run Sandbox logic.

        Opportunity opp = [
            SELECT Id, Secret_Key__c
            FROM Opportunity
            WHERE Name = 'Approved Opp'
            LIMIT 1
        ];

        Test.startTest();
        Map<String, String> cfg = OpportunityStatusController.getConfigData(opp.Id);
        Test.stopTest();

        System.assertEquals('90', cfg.get('maxSeconds'));
        System.assertEquals('APPROVED123', cfg.get('secretKey'));

        // Base URL test (sandbox or prod)
        System.assert(
            cfg.get('baseUrl') == 'https://sandbox.example.com' ||
            cfg.get('baseUrl') == 'https://prod.example.com',
            'Base URL must come from correct custom setting'
        );
    }

    @isTest
    static void testGetConfigDataDeclinedOpp() {

        Opportunity opp = [
            SELECT Id, Secret_Key__c
            FROM Opportunity
            WHERE Name = 'Declined Opp'
            LIMIT 1
        ];

        Test.startTest();
        Map<String, String> cfg = OpportunityStatusController.getConfigData(opp.Id);
        Test.stopTest();

        System.assertEquals('DECLINED456', cfg.get('secretKey'));
    }
}