public with sharing class DataMigrationController {

    @AuraEnabled
    public static Id startMigration(
        Id programsFileId,
        Id chaptersFileId,
        Id programChaptersFileId,
        Id productTemplatesFileId
    ) {
        Migration_Job__c job = new Migration_Job__c(
            Status__c = 'Queued'
        );
        insert job;

        Database.executeBatch(
            new DataMigrationBatch(
                programsFileId,
                chaptersFileId,
                programChaptersFileId,
                productTemplatesFileId,
                job.Id
            ),
            200
        );

        return job.Id;
    }

    @AuraEnabled(cacheable=false)
    public static Migration_Job__c getJobStatus(Id jobId) {
        return [
            SELECT Id,
                   Status__c,
                   Programs_Inserted__c,
                   Chapters_Inserted__c,
                   Program_Chapters_Inserted__c,
                   Product_Templates_Inserted__c,
                   Programs_Error_File_Id__c,
                   Chapters_Error_File_Id__c,
                   Program_Chapters_Error_File_Id__c,
                   Templates_Error_File_Id__c
            FROM Migration_Job__c
            WHERE Id = :jobId
        ];
    }

    @AuraEnabled
    public static void cleanAllData() {
        DataCleanupUtility.cleanAllData();
    }
}
