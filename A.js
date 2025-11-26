import { LightningElement, api, track } from 'lwc';
import getOpportunityStage from '@salesforce/apex/OpportunityStatusController.getOpportunityStage';
import getConfigData from '@salesforce/apex/OpportunityStatusController.getConfigData';

export default class OpportunityStatusCheck extends LightningElement {
    @api opportunityId;
    @track timer = 0;
    @track maxSeconds = 90;
    @track progress = 0;
    @track message = 'Please wait for few minutes while we work with your application...';
    @track isLowBandwidth = false;
    @track showVideo = true;
    @track finalState = '';
    @track redirectUrl = '';

    intervalId;

    connectedCallback() {
        this.detectBandwidth();
        this.initComponent();
    }

    detectBandwidth() {
        // network API - simplistic check
        const connection = navigator.connection || navigator.mozConnection || navigator.webkitConnection;

        if (connection && connection.downlink && connection.downlink < 1) {
            this.isLowBandwidth = true;
            this.showVideo = false;
        }
    }

    async initComponent() {
        try {
            const config = await getConfigData({ oppId: this.opportunityId });

            this.maxSeconds = parseInt(config.maxSeconds);
            this.redirectUrl = `${config.baseUrl}?secret_key=${config.secretKey}`;

            this.startTimerAndPolling();

        } catch (err) {
            this.finalState = 'error';
            this.message = 'An unexpected error occurred.';
        }
    }

    startTimerAndPolling() {
        this.intervalId = setInterval(async () => {
            this.timer++;
            this.progress = (this.timer / this.maxSeconds) * 100;

            // every 5 seconds — check Opportunity stage
            if (this.timer % 5 === 0) {
                const stage = await getOpportunityStage({ oppId: this.opportunityId });

                if (stage === 'Approved') {
                    clearInterval(this.intervalId);
                    this.finalState = 'approved';
                    this.message = 'Your application is approved! Redirecting...';
                    
                    setTimeout(() => {
                        window.location.href = this.redirectUrl;
                    }, 5000);

                    return;
                }

                if (stage === 'Declined') {
                    clearInterval(this.intervalId);
                    this.finalState = 'declined';
                    this.message = 'Sorry, we could not approve at this moment.';
                    return;
                }
            }

            // Timeout
            if (this.timer >= this.maxSeconds) {
                clearInterval(this.intervalId);
                this.finalState = 'timeout';
                this.message = 'We need more time to work on your application and we will get back.';
            }

        }, 1000);
    }

    get showManualLink() {
        return this.finalState === 'approved';
    }
}
