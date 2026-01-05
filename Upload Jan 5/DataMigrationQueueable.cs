public class DataMigrationQueueable implements Queueable {

    private Id programsFileId;
    private Id chaptersFileId;
    private Id programChaptersFileId;
    private Id productTemplatesFileId;
    private Id jobId;

    public DataMigrationQueueable(
        Id programsFileId,
        Id chaptersFileId,
        Id programChaptersFileId,
        Id productTemplatesFileId,
        Id jobId
    ) {
        this.programsFileId = programsFileId;
        this.chaptersFileId = chaptersFileId;
        this.programChaptersFileId = programChaptersFileId;
        this.productTemplatesFileId = productTemplatesFileId;
        this.jobId = jobId;
    }

    public void execute(QueueableContext context) {

        try {
            // ✅ Re-query job record
            Migration_Job__c job = [
                SELECT Id, Status__c
                FROM Migration_Job__c
                WHERE Id = :jobId
                LIMIT 1
            ];

            job.Status__c = 'Parsing CSV';
            update job;

            List<Map<String,String>> programs =
                DataMigrationController.parseCsv(programsFileId);

            List<Map<String,String>> chapters =
                DataMigrationController.parseCsv(chaptersFileId);

            List<Map<String,String>> programChapters =
                DataMigrationController.parseCsv(programChaptersFileId);

            List<Map<String,String>> productTemplates =
                DataMigrationController.parseCsv(productTemplatesFileId);

            job.Status__c = 'Processing';
            update job;

            Database.executeBatch(
                new DataMigrationBatch(
                    programs,
                    chapters,
                    programChapters,
                    productTemplates,
                    jobId
                ),
                200
            );

        } catch (Exception e) {

            // 🔴 Capture async failure
            update new Migration_Job__c(
                Id = jobId,
                Status__c = 'Error: ' + e.getMessage().left(255)
            );

            System.debug('DataMigrationQueueable FAILED: ' + e);
        }
    }
}
