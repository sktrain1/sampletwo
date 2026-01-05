public with sharing class DataMigrationController {

    @AuraEnabled
    public static Id startMigration(
        Id programsFileId,
        Id chaptersFileId,
        Id programChaptersFileId,
        Id productTemplatesFileId
    ) {
        Migration_Job__c job = new Migration_Job__c(
            Status__c = 'Processing'
        );
        insert job;

        List<Map<String,String>> programs = parseCsv(programsFileId);
        List<Map<String,String>> chapters = parseCsv(chaptersFileId);
        List<Map<String,String>> programChapters = parseCsv(programChaptersFileId);
        List<Map<String,String>> productTemplates = parseCsv(productTemplatesFileId);

        DataMigrationBatch batch = new DataMigrationBatch(
            programs,
            chapters,
            programChapters,
            productTemplates,
            job.Id
        );

        Database.executeBatch(batch, 200);
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

    private static List<Map<String,String>> parseCsv(Id contentVersionId) {
        ContentVersion cv = [
            SELECT VersionData
            FROM ContentVersion
            WHERE Id = :contentVersionId
        ];

        List<String> rows = cv.VersionData.toString().split('\n');
        //List<String> headers = rows[0].split(',');

        List<String> headers = rows[0].replace('\uFEFF','').split(',');

        List<Map<String,String>> data = new List<Map<String,String>>();

        for (Integer i = 1; i < rows.size(); i++) {
            if (String.isBlank(rows[i])) continue;

            List<String> cols = rows[i].split(',');
            Map<String,String> rowMap = new Map<String,String>();

            for (Integer j = 0; j < headers.size(); j++) {
                rowMap.put(headers[j].trim(),
                    j < cols.size() ? cols[j].trim() : null);
            }
            data.add(rowMap);
        }
        return data;
    }

    private static List<Map<String,String>> parseCsv(Id contentVersionId) {
    ContentVersion cv = [
        SELECT VersionData
        FROM ContentVersion
        WHERE Id = :contentVersionId
    ];

    // Explicit UTF-8 decoding
    String csv = cv.VersionData.toString();

    // Normalize line endings (handles Windows / Mac / Linux)
    csv = csv.replace('\r\n', '\n').replace('\r', '\n');

    List<String> rows = csv.split('\n');

    // Remove BOM if present
    List<String> headers = rows[0].replace('\uFEFF', '').split(',');

    List<Map<String,String>> data = new List<Map<String,String>>();

    for (Integer i = 1; i < rows.size(); i++) {
        if (String.isBlank(rows[i])) continue;

        List<String> cols = rows[i].split(',');
        Map<String,String> rowMap = new Map<String,String>();

        for (Integer j = 0; j < headers.size(); j++) {
            rowMap.put(
                headers[j].trim(),
                j < cols.size() ? cols[j].trim() : null
            );
        }
        data.add(rowMap);
    }
    return data;
}

    @AuraEnabled
    public static void cleanAllData() {
        DataCleanupUtility.cleanAllData();
    }
}
