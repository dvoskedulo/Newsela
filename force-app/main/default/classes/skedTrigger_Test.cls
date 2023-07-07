@isTest
public class skedTrigger_Test {
    @TestSetup
    static void makeData(){
        List<Site_Setting__c> siteSettings = skedDataFactory.createSiteSettings();
        insert siteSettings;

        List<sked_Question__c> questions  = skedDataFactory.createQuestions(siteSettings);
        insert questions;

        skedCommonServices cmService = new skedCommonServices();
        //create custom setting
        TestFactory.insertCustomSettings();

        //create region
        sked__region__c region = new sked__region__c(
            name = 'test region',
            sked__timezone__c = 'America/Los_Angeles'
        );
        insert region;

        //create job
        sked__job__c job = new sked__job__c(
            sked__start__c = system.now(),
            sked__finish__c = system.now().addHours(1),
            sked__duration__c = 60,
            Event_Subject__c = 'test event subject',
            sked__job_status__c = skedConstants.JOB_STATUS_PENDING_ALLOCATION,
            Activity_Medium__c = 'Webinar',
            sked__region__c = region.id,
            sked__Type__c = cmService.getPicklistValues('sked__job__c', 'sked__Type__c').get(0).id,
            sked_Customer_Email__c = 'test@abc.com',
            sked_Delivery_Method__c = 'Coordination Call',
            sked_Additional_Details__c = 'testing',
            sked__Address__c = 'test'
        );
        insert job;

        //create resource
        sked__resource__c res = new sked__resource__c(
            name = 'test resource',
            sked__primary_region__c = region.id,
            sked__Resource_Type__c = 'Person',
            sked__User__c = UserInfo.getUserId(),
            sked__Email__c = 'test@abc.com'
        );
        insert res;

        //insert job allocation
        sked__job_allocation__c ja = new sked__job_allocation__c(
            sked__resource__c = res.id,
            sked__job__c = job.id,
            sked__status__c = skedConstants.JA_STATUS_PENDING_DISPATCH
        );
        insert ja;
    }
    static testmethod void jobTrigger_eventTrigger_test() {
        List<sked__job_allocation__c> jas = [select id from sked__job_allocation__c];
        List<sked__job__c> jobs = [select id from sked__job__c];
        List<sked__resource__c> resources = [select id from sked__resource__c];
        
        sked__job_allocation__c ja = jas.get(0);
        sked__job__c job = jobs.get(0);
        sked__resource__c res = resources.get(0);
            
        test.startTest();
        ja.sked__status__c = skedConstants.JA_STATUS_CONFIRMED;
        update ja;
        
        List<Event> checkEvents = [select id, subject from event];
        List<sked__Activity__c> checkActs = [select id from sked__activity__c];
        
        System.assert(checkActs.isEmpty());
        System.assert(!checkEvents.isEmpty() && String.isNotBlank(checkEvents.get(0).subject));

        job.sked__Description__c = 'test update event description';
        update job;

        List<event> checkEvents2 = [select id, Description from event where sked__job_allocation__c = :ja.id]; 
        System.assert(!checkEvents2.isEmpty() && checkEvents2.get(0).Description == job.sked__Description__c);

        //delete checkEvents2;
        List<sked__Activity__c> skedActs = [select id from sked__activity__c where sked__Event_Id__c != null];
        System.assert(skedActs.isEmpty());

        sked__Activity__c newAct = new sked__Activity__c(
            sked__resource__c = res.id,
            sked__start__c = system.now(),
            sked__end__c = system.now().addHours(1)
        );
        insert newAct;

        List<Event> checkEvents3 = [select id from event where sked__Activity__c = :newAct.id];
        System.assert(!checkEvents3.isEmpty());

        Event e = new Event(
            OwnerId                     = UserInfo.getUserId(),
            Location                    = 'test address',
            StartDateTime               = System.now(),
            EndDateTime                 = System.now().addHours(1),
            Subject                     = 'test event subject'
        );
        insert e;

        List<sked__Activity__c> acts = [select id from sked__activity__c where sked__Event_Id__c =:e.id];
        System.assert(!acts.isEmpty());
        test.stopTest();        
    }
}