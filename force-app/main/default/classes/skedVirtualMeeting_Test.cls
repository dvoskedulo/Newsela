@isTest
public class skedVirtualMeeting_Test {
    @TestSetup
    static void makeData(){
        Id loggedInUserId = UserInfo.getUserId();
        AccountTriggerHandler.blnrecurring=true;  
        AccountTriggerHandler.blnQuoteApproveRun = true;
        OpportunityTriggerHandler.blnRecurring = true;        
        ContractTriggerHandler.blnRecurring = true;
        SubscriptionTriggerHandler.blnRecurring = true;

        skedDataFactory.insertCustomSettings();
        TestFactory.insertCustomSettings();


        sked__Region__c region = skedDataFactory.createRegion('Tri-State Region', 'Eastern');        
        insert region;

        sked__Location__c location = skedDataFactory.createLocation('Test Location', region.Id);
        insert location;

        sked__Resource__c resource = skedDataFactory.createResource('Test Resource', UserInfo.getUserID() , region.Id);
        sked__Resource__c otherResource = skedDataFactory.createResource('Test Resource', null , region.Id);
        insert new List<sked__Resource__c>{resource, otherResource};

        sked__Availability_Template__c avaiTemplate = skedDataFactory.createAvailabilityTemplate();
        insert avaiTemplate;

        sked__Availability_Template_Entry__c entry1 = skedDataFactory.createAvailabilityTemplateEntry(avaiTemplate.Id, 'MON');
        sked__Availability_Template_Entry__c entry2 = skedDataFactory.createAvailabilityTemplateEntry(avaiTemplate.Id, 'TUE');
        sked__Availability_Template_Entry__c entry3 = skedDataFactory.createAvailabilityTemplateEntry(avaiTemplate.Id, 'WED');
        sked__Availability_Template_Entry__c entry4 = skedDataFactory.createAvailabilityTemplateEntry(avaiTemplate.Id, 'THU');
        sked__Availability_Template_Entry__c entry5 = skedDataFactory.createAvailabilityTemplateEntry(avaiTemplate.Id, 'FRI');

        List<sked__Availability_Template_Entry__c> lstEntry = new List<sked__Availability_Template_Entry__c>{entry1,entry2,entry3,entry4,entry5};
        insert lstEntry;

        sked__Availability_Template_Resource__c resAvai1 = skedDataFactory.createResourceTemplate(avaiTemplate.Id, resource.Id);
        sked__Availability_Template_Resource__c resAvai2 = skedDataFactory.createResourceTemplate(avaiTemplate.Id, otherResource.Id);
        insert new List<sked__Availability_Template_Resource__c>{ resAvai1, resAvai2} ;  

        Account act = (skedDataFactory.createAccounts('Test Accoount', 1)).get(0);
        act.Inside_Sales_Rep__c = loggedInUserId;
        act.BillingState='NY';

        insert act;

        Contact cont = skedDataFactory.createContact(act.Id, 'Test Contact');
        insert cont;

        List<Site_Setting__c> siteSettings = skedDataFactory.createSiteSettings();
        insert siteSettings;

        List<sked_Question__c> questions  = skedDataFactory.createQuestions(siteSettings);
        insert questions;
    }
    @isTest 
    static void mainTest() {
        skedCommonServices cmService = new skedCommonServices();        
        skedSkeduloApiManager apiManager = new skedSkeduloApiManager();
        list<sked__Region__c> lstReg = [SELECT Id FROM sked__Region__c];
        Account acc = [SELECT Id, Name FROM Account LIMIT 1];
        Contact cont = [SELECT Id FROM Contact LIMIT 1];
        sked__Resource__c resource = [SELECT Id FROM sked__Resource__c LIMIT 1];        
        sked__Job__c job = skedDataFactory.createJobs(acc.Id, cont.Id, lstReg[0].Id, 1).get(0);
        job.sked__Account__c = acc.Id;
        job.sked__Virtual_Meeting_Id__c = '92474512377';
        job.Activity_Medium__c = 'Webinar';
        job.sked__Type__c = cmService.getPicklistValues('sked__job__c', 'sked__Type__c').get(0).id;
        job.sked_Customer_Email__c = 'test@abc.com';
        job.sked_Delivery_Method__c = 'Coordination Call';
        job.sked_Additional_Details__c = 'testing';
        insert job;
        sked__Job_Allocation__c allocation = skedDataFactory.allocateJob(job.Id, resource.Id);
        allocation.sked__Status__c = 'Pending Dispatch';
        insert allocation;
                
        Test.startTest();
        List<string> jobIds = new List<string>();
        jobIds.add(job.Id);
        skedSkeduloApiData.virtualMeeting result = skedVirtualMeetingService.getMeetingDetails('92474512377');
        system.assertEquals('Zoom:92474512377', result.id);
        result = skedVirtualMeetingService.createMeeting(job.Id).result;
        skedVirtualMeetingService.deleteMeeting(jobIds);
        List<string> meeetingIds = new List<string>{'92474512377'};
        skedVirtualMeetingService.deleteMeeting(meeetingIds);
        Test.stopTest();
    }
    @isTest static void testUpdateMeeting() {
        skedCommonServices cmService = new skedCommonServices();        
        skedSkeduloApiManager apiManager = new skedSkeduloApiManager();
        list<sked__Region__c> lstReg = [SELECT Id FROM sked__Region__c];
        Account acc = [SELECT Id, Name FROM Account LIMIT 1];
        Contact cont = [SELECT Id FROM Contact LIMIT 1];
        sked__Resource__c resource = [SELECT Id FROM sked__Resource__c LIMIT 1];        
        sked__Job__c job = skedDataFactory.createJobs(acc.Id, cont.Id, lstReg[0].Id, 1).get(0);
        job.sked__Account__c = acc.Id;
        job.sked__Virtual_Meeting_Id__c = '92474512377';
        job.Activity_Medium__c = 'Webinar';
        job.sked__Type__c = cmService.getPicklistValues('sked__job__c', 'sked__Type__c').get(0).id;
        job.sked_Customer_Email__c = 'test@abc.com';
        job.sked_Delivery_Method__c = 'Coordination Call';
        job.sked_Additional_Details__c = 'testing';
        insert job;
        sked__Job_Allocation__c allocation = skedDataFactory.allocateJob(job.Id, resource.Id);
        allocation.sked__Status__c = 'Pending Dispatch';
        insert allocation;

        Test.startTest();
        List<string> jobIds = new List<string>();
        jobIds.add(job.Id);
        skedVirtualMeetingService.updateMeeting(jobIds);
        Test.stopTest();
    }
    // @isTest static void errorTest() {
    //     skedSkeduloApiManager_MockTest mockTest = new skedSkeduloApiManager_MockTest();
    //     mockTest.calloutMethod = 'virtual_meeting';
    //     mockTest.isErrorMode = true;
    //     Test.setMock(HttpCalloutMock.class, mockTest);
    //     skedSkeduloApiManager apiManager = new skedSkeduloApiManager();
    //     Test.startTest();
    //     Map<String, Object> mapRequest = new Map<String, Object>();
    //     mapRequest.put('agenda', 'New Appointment');
    //     mapRequest.put('topic', 'Treatment - New Client Test');
    //     mapRequest.put('password', '54321');
    //     skedSkeduloApiData.virtualMeetingResult result = apiManager.createMeeting(mapRequest);
    //     result = apiManager.getMeetingDetails('92474512377');
    //     //system.assertEquals('Invalid request', result.message);
    //     Test.stopTest();
    // }
}