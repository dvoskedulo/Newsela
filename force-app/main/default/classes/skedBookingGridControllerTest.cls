/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-10-2021
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public  class skedBookingGridControllerTest {
    public static Id standardPricebookId=Test.getStandardPricebookId();
    public static Id recordTypeIDForOpportunities = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('New Business Opportunity').getRecordTypeId();
    public static String deliveryMethod = '';
    public static String productType = '';

    @TestSetup
    static void makeData(){
        Id loggedInUserId = UserInfo.getUserId();
        AccountTriggerHandler.blnrecurring=true;  
        AccountTriggerHandler.blnQuoteApproveRun = true;
        OpportunityTriggerHandler.blnRecurring = true;        
        ContractTriggerHandler.blnRecurring = true;
        SubscriptionTriggerHandler.blnRecurring = true;

        TestFactory.insertCustomSettings();
        skedDataFactory.insertCustomSettings();

        sked__Region__c region = skedDataFactory.createRegion('East Region', 'Eastern');        
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

        act.Account_Tier__c = 'Certified Online Training';

        update act;

        sked__Tag__c tag = new sked__Tag__c(
            Name = 'Certified Online Training'
        );
        insert tag;

        List<sked__Tag__c> tags = [SELECT Id FROM sked__Tag__c WHERE Name = 'Certified Online Training'];
        sked__Resource_Tag__c resourceTag = new sked__Resource_Tag__c(
            sked__Resource__c = resource.Id,
            sked__Tag__c = tags[0].Id
        );
        insert resourceTag;

        Contact cont = skedDataFactory.createContact(act.Id, 'Test Contact');
        insert cont;

        Product2 p = skedDataFactory.createProduct(
                'Subscription Product XYZ', // String name
                'Subscription',                 // String productType
                'SBP-XYZ-111'             // String productCode                                
            );
        insert p;

        PricebookEntry pbEntry = skedDataFactory.createPriceBookEntry(
                p,      // Product2 product
                null   // Pricebook2 priceBook (Null will make it default to the Standard Pricebook)               
            );
        insert pbEntry;
        
        Opportunity o = skedDataFactory.createOpportunity(standardPricebookId, act.Id, recordTypeIDForOpportunities);
        o.OwnerId = loggedInUserId;
        insert o;
        OpportunityTriggerHandler.blnRecurring = false;

        System.debug('opp owner@' + o.OwnerId);
        // Opportunity o = createOpportunity('testName', 'Closed', System.today().addDays(1), act);
        // insert o;

        SBQQ__Quote__c q = skedDataFactory.createQuote(act.Id, o.Id, true);
        insert q;
        
        Contract c = skedDataFactory.createContract(act.Id, o.Id, q.Id) ;
        c.Has_Essentials__c = true;
        c.Has_ELA__c = true;
        c.Has_SEL__c = true;
        c.Has_Social_Studies__c = true;
        c.Has_Science__c = true;
        insert c;        
        c.Status='Activated';
        update c;
        ContractTriggerHandler.blnRecurring = false;
        
        SBQQ__QuoteLine__c quoteLine = (skedDataFactory.setupQuoteLines(new list<Account> {act}, new List<SBQQ__Quote__c> {q}, new List<Product2> {p}, new List<PricebookEntry> {pbEntry})).get(0);
        insert quoteLine;

        
        SBQQ__Subscription__c s = skedDataFactory.createSubscription(quoteLine.Id, p.Id, act.Id, c.Id);
        insert s;

        List<Site_Setting__c> siteSettings = skedDataFactory.createSiteSettings();
        insert siteSettings;

        List<sked_Question__c> questions  = skedDataFactory.createQuestions(siteSettings);
        insert questions;
    }

    @isTest
    static void getSubscriptionInfo() {   
        Test.startTest();
        skedModels.bookingGridQueryModel queryModel = buildBookingRequest();
        Date validStartDate = (Date)JSON.deserialize('"' + queryModel.startDateISO + '"', Date.class);
        sked__Resource__c resource = [SELECT ID FROM sked__Resource__c LIMIT 1];

        list<sked__Region__c> lstReg = [SELECT Id FROM sked__Region__c];
        Account acc = [SELECT Id, Name FROM Account LIMIT 1];
        Contact cont = [SELECT Id FROM Contact LIMIT 1];   
        sked__Job__c job = skedDataFactory.createJobs(acc.Id, cont.Id, lstReg[0].Id, 1).get(0);
        job.sked__Type__c = 'In-Person';
        job.sked_Delivery_Method__c = 'In Person';
        job.sked_Additional_Details__c = 'Test';
        job.sked__Start__c = Datetime.newInstance(validStartDate.addDays(1), Time.newInstance(8,0,0,0));
        job.sked__Finish__c = Datetime.newInstance(validStartDate.addDays(1), Time.newInstance(9,0,0,0));
        insert job;

        sked__Job_Allocation__c jobAllocation = new sked__Job_Allocation__c(
            sked__Job__c = job.Id,
            sked__Resource__c = resource.Id
        );
        insert jobAllocation;

        sked__Job__c nextJob = job.clone();
        nextJob.sked__Start__c = Datetime.newInstance(validStartDate.addDays(2), Time.newInstance(8,0,0,0));
        nextJob.sked__Finish__c = Datetime.newInstance(validStartDate.addDays(2), Time.newInstance(9,0,0,0));
        insert nextJob;

        sked__Job_Allocation__c jobAllocation1 = new sked__Job_Allocation__c(
            sked__Job__c = nextJob.Id,
            sked__Resource__c = resource.Id
        );
        insert jobAllocation1;

        sked__Activity__c activity = new sked__Activity__c(
            sked__Address__c = 'Test',
            sked__Resource__c = resource.Id,
            sked__Start__c = Datetime.newInstance(validStartDate.addDays(1), Time.newInstance(10,0,0,0)),
            sked__End__c = Datetime.newInstance(validStartDate.addDays(1), Time.newInstance(11,0,0,0)),
            sked__GeoLocation__Latitude__s = -27.457730,
            sked__GeoLocation__Longitude__s = 153.037080
        );
        insert activity;
        activity.sked__Address__c = '123 Test';
        update activity;
        
        sked__Availability__c availability = new sked__Availability__c(
            sked__Resource__c = resource.Id,
            sked__Start__c = Datetime.newInstance(validStartDate.addDays(1), Time.newInstance(10,0,0,0)),
            sked__Finish__c = Datetime.newInstance(validStartDate.addDays(1), Time.newInstance(11,0,0,0)),
            sked__Is_available__c = false
        );
        insert availability;

        skedResponse response = skedBookingGridController.getBookingGrid(queryModel);
        System.debug('response@' + JSON.serialize(response));
        skedModels.bookingGridModel bookingGrid = (skedModels.bookingGridModel)response.data;
      
        Test.stopTest();
    }

    @isTest
    static void getTrainingLocations() {
        
        skedModels.InputRequest request = new skedModels.InputRequest();
        request.searchingName = 'Test';
        Test.startTest();
        skedResponse response = skedBookingGridController.getTrainingLocations(request);
        Test.stopTest();
        System.debug('response@' + JSON.serialize(response));
        List<skedModels.BaseModel> results = (List<skedModels.BaseModel>)response.data;
        
    }

    @isTest static void testGetAddressGeoLocation() {
        skedModels.AddressGeolocationRequest request = new skedModels.AddressGeolocationRequest();
        request.address = 'testing address';         
        skedResponse response = skedBookingGridController.getAddressGeoLocation(request);
        System.debug('response@' + JSON.serialize(response));        
        request.placeId = '123';
        response = skedBookingGridController.getAddressGeoLocation(request);
        System.debug('response@' + JSON.serialize(response));
        skedModels.AddressModel addr = (skedModels.AddressModel)response.data;
       
    }

    @isTest static void getAddresses() {
        Test.startTest(); 
        // Test.setMock(HttpCalloutMock.class, mock);
        skedResponse response = skedBookingGridController.getAddresses('address');        
        System.debug('result@' + JSON.serialize(response));
        skedModels.AutoCompleteResponse result = (skedModels.AutoCompleteResponse)response.data;
       
        Test.stopTest();
    }

    @isTest
    static void getConfig() {
        SBQQ__Subscription__c subObj = [SELECT Id, SBQQ__StartDate__c FROM SBQQ__Subscription__c LIMIT 1];
        Contract contract =  [SELECT Id, Has_Essentials__c FROM Contract LIMIT 1];
        skedBookingGridController.configRequest request  = new skedBookingGridController.configRequest ();
        request.subscriptionId = subObj.Id;
        Test.startTest();
        skedResponse response = skedBookingGridController.getConfig(request);
        System.debug('result@' + JSON.serialize(response));
        Test.stopTest();
        skedModels.config c = (skedModels.config)response.data;
       
    }

    @isTest
    static void scheduleJob() {
        Test.startTest();
        skedModels.JobCreationRequest request = buildJobRequest();        
        skedResponse response = skedBookingGridController.scheduleJob(request);
        System.debug('response!' + response);        
      
        
        skedModels.bookingGridQueryModel queryModel = buildBookingRequest();
        response = skedBookingGridController.getBookingGrid(queryModel);
        Test.stopTest();
        System.debug('response@' + JSON.serialize(response));
        skedModels.bookingGridModel bookingGrid = (skedModels.bookingGridModel)response.data;
       
    }

    @isTest
    static void otherTest() {
        Location loc1 = Location.newInstance(28.635308, 77.22496);
        Location loc2 = Location.newInstance(-27.457733, 153.037081);

        skedModels.Geometry geometry = new skedModels.Geometry(loc2);
        
        skedSkeduloApiData.geometry geo1 = new skedSkeduloApiData.geometry(loc1);
        skedSkeduloApiData.geometry geo2 = new skedSkeduloApiData.geometry(geometry);

        skedTravelTimeServiceBase service = new skedTravelTimeServiceBase();
        service.getJourney(loc1, loc2);
        service.getJourney(geo1, geo2);
    }

    static skedModels.bookingGridQueryModel buildBookingRequest() {
        SBQQ__Subscription__c subObj = [SELECT Id, SBQQ__StartDate__c FROM SBQQ__Subscription__c LIMIT 1];
        skedModels.SubscriptionInfoResponse subInfo = getSubInfo(subObj.Id);        
        String configKey = subInfo.productType.id + ':' + subInfo.deliveryMethods.get(0).id;
        sked_Delivery_Method_Setting__mdt setting = skedSetting.instance.bookingGrid.getConfig(configKey);
        Date validStartDate = getValidStartDate(Integer.valueOf(setting.sked_Start_Date_Buffer__c), subObj.SBQQ__StartDate__c);

        skedModels.ConfigurationRequest configRequest = new skedModels.ConfigurationRequest();
        skedModels.Subscription sub = new skedModels.Subscription();
        sub.id = subObj.Id;
        configRequest.subscription = sub;
        configRequest.productType = subInfo.productType.id;
        configRequest.deliveryMethod = subInfo.deliveryMethods.get(0).id;
        skedResponse response = skedBookingGridController.getConfigData(configRequest);
        System.debug('response@' + JSON.serialize(response));
        skedModels.ConfigurationResponse deliverySetting = (skedModels.ConfigurationResponse)response.data;
       
        
        
        skedModels.bookingGridQueryModel queryModel = new skedModels.bookingGridQueryModel();
        queryModel.startDateISO = (JSON.serialize(validStartDate)).replace('"', '');
        queryModel.endDateISO = (JSON.serialize(validStartDate.addDays(1))).replace('"', '');
        queryModel.startTimeInt = deliverySetting.gridStart;
        queryModel.endTimeInt = deliverySetting.gridEnd;
        queryModel.timeslotStep = deliverySetting.interval;
        queryModel.jobDuration = deliverySetting.jobDuration;
        queryModel.productType = subInfo.productType.id;
        queryModel.deliveryMethod = subInfo.deliveryMethods.get(0).id;
        queryModel.region = subInfo.region;
        queryModel.subscription  = sub;
        skedModels.Geometry geometry = new skedModels.Geometry('24 Tuckett Rd, Salisbury, Queensland, AUS', -27.457730, 153.037080);
        queryModel.geometry = geometry;
        return queryModel;
    }

    public static skedModels.JobCreationRequest buildJobRequest() {
        // skedCommonServices cmService = new skedCommonServices();
        SBQQ__Subscription__c subObj = [SELECT Id, SBQQ__StartDate__c FROM SBQQ__Subscription__c LIMIT 1];
        skedModels.Subscription sub = new skedModels.Subscription();
        sub.id = subObj.Id;
        sub.account = new skedModels.AccountModel();
        sub.account.id = [SELECT Id FROM Account LIMIT 1].Id;
        skedModels.AddressGeolocationRequest geoRequest = new skedModels.AddressGeolocationRequest();
        geoRequest.address = 'testing address';
        geoRequest.placeId = '123';
        skedResponse response = skedBookingGridController.getAddressGeoLocation(geoRequest);
        System.debug('response@' + JSON.serialize(response));
        skedModels.AddressModel addr = (skedModels.AddressModel)response.data;

        skedModels.SubscriptionInfoResponse subInfo = getSubInfo(subObj.Id);
        String configKey = subInfo.productType.id + ':' + subInfo.deliveryMethods.get(0).id;
        sked_Delivery_Method_Setting__mdt setting = skedSetting.instance.bookingGrid.getConfig(configKey);
        Date validStartDate = getValidStartDate(Integer.valueOf(setting.sked_Start_Date_Buffer__c), subObj.SBQQ__StartDate__c);
        
        skedModels.JobCreationRequest request = new skedModels.JobCreationRequest();                
        skedModels.JobModel jobModel = new skedModels.JobModel();
        jobModel.address = addr;        
        jobModel.jobDate = JSON.serialize(validStartDate).replace('"', '');
        jobModel.startTime = 900;
        jobModel.endTime = 1000;
        jobModel.duration = 60;     
        jobModel.deliveryMethod = subInfo.deliveryMethods.get(0).id;
        jobModel.jobType = 'In-Person';
        jobModel.customerEmail = 'test@abc.com';
        jobModel.customerName = 'test';
        jobModel.customerPhoneNo = '09999999';

        List<skedModels.ResourceModel> availableResources = new List<skedModels.ResourceModel>();
        skedModels.ResourceModel resourceModel = new skedModels.ResourceModel();
        resourceModel.id = [SELECT Id FROM sked__Resource__c LIMIT 1].Id;
        availableResources.add(resourceModel);
        request.job = jobModel;
        request.availableResources = availableResources;
        request.subscription = sub;

        skedModels.SurveyModel survey = new skedModels.SurveyModel();        
        survey.question = 'What is your desired focus for this session? What goals does your school or district have for using Newsela this school year?';
        survey.answer = 'testing';
        List<skedModels.SurveyModel> surveys = new List<skedModels.SurveyModel>{survey};
        request.surveys = surveys;

        return request;
    }

    @isTest static void testModels() {
        skedResponse response = new skedResponse();
        try {
            skedObjectSelector selector = skedObjectSelector.newInstance(Site_Setting__c.sObjectType);
            selector.filter('Default_Setting__c != true');
            List<Site_Setting__c> siteSettings = Database.query( selector.getQuery() );
            for (Site_Setting__c setting : siteSettings) {
                skedModels.SiteSetting defaultSiteSetting = new skedModels.SiteSetting().init( setting );
                defaultSiteSetting.addQuestions(setting.Questions__r);                    
            }
            skedCommonServices cmService = new skedCommonServices();
            List<skedModels.BaseModel> contactModels = cmService.searchByName('Test', 'Account', 'start with', null, 1);
            skedExceptionHandler.CustomException customEx = new skedExceptionHandler.CustomException(200, 'OK', 'success');    
            customEx = new skedExceptionHandler.CustomException('OK', 'success');    
            
            integer a = 1/0;
        }
        catch(Exception ex) {
            response.getErrorMessage(ex);
        }
    }

    static skedModels.SubscriptionInfoResponse getSubInfo(Id subId){        
        skedModels.SubscriptionInfoRequest request = new skedModels.SubscriptionInfoRequest();
        request.subId = subId;        
        skedResponse response = skedBookingGridController.getSubscriptionInfo(request);        
        System.debug('response@' + JSON.serialize(response));
        skedModels.SubscriptionInfoResponse subInfo = (skedModels.SubscriptionInfoResponse)response.data;          
        return subInfo;
    }

    static date getValidStartDate(Integer startDateBuffer, Date subStartDate) {
        Date validStartDate;                    

        Date today = date.today();            
        if ( subStartDate > today.addDays(startDateBuffer) ) {
            validStartDate = subStartDate;
        }
        else {
            validStartDate = today.addDays(startDateBuffer);
        }
        return validStartDate;
    }

    static Map<String, String> mapDeliveryMethodToJobType() {
        return new Map<String, String> {
            'Virtual' => 'Virtual',
            'In Person' => 'In-Person',
            'Call' => 'Call'
        };
    }

}