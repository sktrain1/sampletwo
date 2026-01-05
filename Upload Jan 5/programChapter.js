import { LightningElement, track } from 'lwc';
import startMigration from '@salesforce/apex/DataMigrationController.startMigration';
import getJobStatus from '@salesforce/apex/DataMigrationController.getJobStatus';
import cleanAllData from '@salesforce/apex/DataMigrationController.cleanAllData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ProgramChapter extends LightningElement {

    uploadParentId = '000000000000000AAA';

    @track uploadedFiles = {
        programs: null,
        chapters: null,
        programChapters: null,
        productTemplates: null
    };

    @track totals = {
        programs: 0,
        chapters: 0,
        programChapters: 0,
        productTemplates: 0
    };

    isLoading = false;
    status;
    jobId;
    polling;
    progress = {};

    /* ========= FILE UPLOAD ========= */

    handleProgramsUpload(e) {
        this.uploadedFiles.programs = e.detail.files[0].contentVersionId;
    }
    handleChaptersUpload(e) {
        this.uploadedFiles.chapters = e.detail.files[0].contentVersionId;
    }
    handleProgramChaptersUpload(e) {
        this.uploadedFiles.programChapters = e.detail.files[0].contentVersionId;
    }
    handleProductTemplatesUpload(e) {
        this.uploadedFiles.productTemplates = e.detail.files[0].contentVersionId;
    }

    /* ========= COMPUTED ========= */

    get disableStart() {
        return !Object.values(this.uploadedFiles).every(v => v);
    }

    get totalPrograms() { return this.totals.programs; }
    get totalChapters() { return this.totals.chapters; }
    get totalProgramChapters() { return this.totals.programChapters; }
    get totalProductTemplates() { return this.totals.productTemplates; }

    get insertedPrograms() { return this.progress.Programs_Inserted__c || 0; }
    get insertedChapters() { return this.progress.Chapters_Inserted__c || 0; }
    get insertedProgramChapters() { return this.progress.Program_Chapters_Inserted__c || 0; }
    get insertedProductTemplates() { return this.progress.Product_Templates_Inserted__c || 0; }

    /* ========= MIGRATION ========= */

    startMigration() {
        this.isLoading = true;
        this.status = 'Processing...';

        startMigration({
                programsFileId: this.uploadedFiles.programs,
                chaptersFileId: this.uploadedFiles.chapters,
                programChaptersFileId: this.uploadedFiles.programChapters,
                productTemplatesFileId: this.uploadedFiles.productTemplates
            })
            .then(jobId => {
                this.jobId = jobId;
                this.polling = setInterval(() => this.checkStatus(), 3000);
            })
            .catch(e => this.handleError(e));
    }

    checkStatus() {
        getJobStatus({ jobId: this.jobId })
            .then(job => {
                this.progress = job;
                this.status = job.Status__c;

                if (job.Status__c.startsWith('Completed') || job.Status__c === 'Error') {
                    clearInterval(this.polling);
                    this.isLoading = false;
                }
            })
            .catch(e => this.handleError(e));
    }

    /* ========= ERROR DOWNLOAD ========= */

    get programsErrorUrl() {
        return this.progress.Programs_Error_File_Id__c ?
            `/sfc/servlet.shepherd/version/download/${this.progress.Programs_Error_File_Id__c}` :
            null;
    }
    get chaptersErrorUrl() {
        return this.progress.Chapters_Error_File_Id__c ?
            `/sfc/servlet.shepherd/version/download/${this.progress.Chapters_Error_File_Id__c}` :
            null;
    }
    get programChaptersErrorUrl() {
        return this.progress.Program_Chapters_Error_File_Id__c ?
            `/sfc/servlet.shepherd/version/download/${this.progress.Program_Chapters_Error_File_Id__c}` :
            null;
    }
    get templatesErrorUrl() {
        return this.progress.Templates_Error_File_Id__c ?
            `/sfc/servlet.shepherd/version/download/${this.progress.Templates_Error_File_Id__c}` :
            null;
    }

    downloadProgramsErrors() { window.open(this.programsErrorUrl); }
    downloadChaptersErrors() { window.open(this.chaptersErrorUrl); }
    downloadProgramChaptersErrors() { window.open(this.programChaptersErrorUrl); }
    downloadTemplatesErrors() { window.open(this.templatesErrorUrl); }

    /* ========= UTIL ========= */

    handleRefresh() {
        if (this.polling) clearInterval(this.polling);
        this.uploadedFiles = {
            programs: null,
            chapters: null,
            programChapters: null,
            productTemplates: null
        };
        this.progress = {};
        this.jobId = null;
        this.status = null;
    }

    handleCleanData() {
        cleanAllData()
            .then(() => this.toast('Success', 'All data erased', 'success'))
            .catch(e => this.handleError(e));
    }

    handleError(error) {
        if (this.polling) clearInterval(this.polling);
        this.isLoading = false;
        this.toast('Error',
            error.body ? error.body.message : error.message,
            'error'
        );
    }

    toast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }
}