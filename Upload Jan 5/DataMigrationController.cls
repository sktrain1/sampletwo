public with sharing class DataMigrationController {

    /* ============================================================
       PUBLIC METHODS
       ============================================================ */

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

        List<Map<String,String>> programs =
            parseCsv(programsFileId);

        List<Map<String,String>> chapters =
            parseCsv(chaptersFileId);

        List<Map<String,String>> programChapters =
            parseCsv(programChaptersFileId);

        List<Map<String,String>> productTemplates =
            parseCsv(productTemplatesFileId);

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

    @AuraEnabled
    public static void cleanAllData() {
        DataCleanupUtility.cleanAllData();
    }

    /* ============================================================
       CSV PARSING (NO REGEX)
       ============================================================ */

    private static List<Map<String,String>> parseCsv(Id contentVersionId) {
        ContentVersion cv = [
            SELECT VersionData
            FROM ContentVersion
            WHERE Id = :contentVersionId
        ];

        // Decode as UTF-8
        String csv;
        try {
            csv = cv.VersionData.toString();
        } catch (Exception e) {
            throw new AuraHandledException(
                'Invalid file encoding. Please upload a CSV saved as UTF-8.'
            );
        }

        // Split lines WITHOUT regex
        List<String> rows = splitLines(csv);
        if (rows.isEmpty()) return new List<Map<String,String>>();

        // Parse headers (remove BOM)
        List<String> headers = parseCsvLine(
            rows[0].replace('\uFEFF','')
        );

        List<Map<String,String>> data = new List<Map<String,String>>();

        for (Integer i = 1; i < rows.size(); i++) {
            if (String.isBlank(rows[i])) continue;

            List<String> cols = parseCsvLine(rows[i]);
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

    /* ============================================================
       LINE SPLITTER (NO split(), NO REGEX)
       ============================================================ */

    private static List<String> splitLines(String text) {
        List<String> lines = new List<String>();
        String current = '';

        for (Integer i = 0; i < text.length(); i++) {
            String c = text.substring(i, i + 1);

            if (c == '\n') {
                lines.add(current);
                current = '';
            } else if (c != '\r') {
                current += c;
            }
        }

        if (current != '') {
            lines.add(current);
        }
        return lines;
    }

    /* ============================================================
       CSV LINE PARSER (QUOTES + COMMAS SAFE)
       ============================================================ */

    private static List<String> parseCsvLine(String line) {
        List<String> result = new List<String>();
        Boolean inQuotes = false;
        String current = '';

        for (Integer i = 0; i < line.length(); i++) {
            String c = line.substring(i, i + 1);

            if (c == '"') {
                inQuotes = !inQuotes;
            } else if (c == ',' && !inQuotes) {
                result.add(current);
                current = '';
            } else {
                current += c;
            }
        }
        result.add(current);
        return result;
    }
}
