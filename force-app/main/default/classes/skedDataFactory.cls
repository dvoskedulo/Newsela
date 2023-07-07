/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-10-2021
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class skedDataFactory {

    public static final String strImplementerSchedulerUser='scheduling Profile';
	/*
    * Initializes a list of Account
    */
    public static List<Account> createAccounts(String basename, Integer count){
        List<Account> records = new List<Account>();
        for( Integer i=0; i< count; i++ ){
            Account reccord = new Account(   
                                            Name            = basename + String.valueOf(i),
                                            ShippingStreet  = '79 McLachlan St Fortitude Valley',
                                            Account_Tier__c = 'Certified Lecture'
                                        ) ;
            
            records.add( reccord);
        }
        return records;
    }
    /*
    * Initializes a Contact
    */
    public static Contact createContact(Id accountId, String name){
        return new Contact(
                FirstName       = name,
                LastName        = name,
                AccountId       = accountId, 
            	MobilePhone		= '12017782706',
                Birthdate       = System.today().addDays(-10000),
                otherStreet     = 'Test',
                otherCity       = 'Test',
                otherState      = 'Test',
                otherPostalCode = 'Test',
                otherCountry    = 'Test',
                Phone           = '1234567890',
                Email           = 'test@test.com'
            );
    }
    
    /*
    * Initializes a list of Job
    */
    public static List<sked__Job__c> createJobs(Id accountId, Id contactId, Id regionId, Integer count){
        List<sked__Job__c> records = new List<sked__Job__c>();
        for( Integer i=0; i< count; i++ ){
            sked__Job__c reccord = new sked__Job__c( 
                                            sked__Account__c        = accountId,
                							sked__Contact__c		= contactId,
                                            sked__Start__c          = Datetime.newInstance(Date.today(), Time.newInstance(9,0,0,0)),
                                            sked__Finish__c         = Datetime.newInstance(Date.today(), Time.newInstance(9,0,0,0)).addHours(1),
                                            sked__Duration__c       = 60,
                                            sked__Region__c         = regionId,
                                            sked__Address__c        = '79 mclachlan',
                                            sked__GeoLocation__Latitude__s = -27.457733,
                                            sked__GeoLocation__Longitude__s = 153.037081,
                							sked__Job_Status__c 	= skedConstants.JOB_STATUS_PENDING_ALLOCATION
                                        ) ;
            
            records.add( reccord);
        }
        return records;
    }
    
    /*
    * Initializes a Region
    */
    public static sked__Region__c createRegion(String name, String timezone){
        
        sked__Region__c region = new sked__Region__c(
            Name = name,
            sked__Timezone__c = timezone==null?'Australia/Melbourne':timezone,
            sked__Country_Code__c = 'AU'
        );
            
        return region;
    }

    /*
    * Allocate a job to a resource
    */
    public static sked__Job_Allocation__c allocateJob(Id jobId, Id resourceId){
        return new sked__Job_Allocation__c(
                sked__Job__c            = jobId,
                sked__Resource__c       = resourceId,
                sked__Assigned_To__c    = resourceId,
                sked__Time_Start_Travel__c   = System.now().addHours(-2),
                sked__Time_In_Progress__c    = System.now().addHours(-1),
                sked__Time_Completed__c    = System.now()
            );
    }

    /*
    * Initializes a Resource
    */
    public static sked__Resource__c createResource(String name, Id userId, Id regionId){
        return new sked__Resource__c(
                name                    = name,
                sked__Resource_Type__c  = 'Person',
                sked__Primary_Region__c = regionId,
                sked__Category__c       = 'Customer Service',
                sked__Country_Code__c   = 'AU',
                sked__Home_Address__c   = '24 Tuckett Rd, Salisbury, Queensland, AUS',
                sked__Is_Active__c      = true,
                sked__Weekly_Hours__c   = 40,
                sked__User__c           = userId,                
                sked__GeoLocation__Latitude__s = -27.457730,
                sked__GeoLocation__Longitude__s = 153.037080,
                sked__Email__c = 'test@abc.com'
            );
    }      	

    public static sked__Location__c createLocation(String name, Id regionId){
        sked__Location__c loc = new sked__Location__c();
        loc.name = name;
        loc.sked__Address__c = '24 Tuckett Rd, Salisbury, Queensland, AUS';
        loc.sked__GeoLocation__Latitude__s = -27.457730;
        loc.sked__GeoLocation__Longitude__s = 153.037080;
        if ( regionId != null ) {
            loc.sked__Region__c = regionId;
        }
        return loc;
    }

    public static sked__Resource_tag__c createResourceTag(Id resourceId, Id tagId) {
        return new sked__Resource_tag__c(
            sked__Resource__c = resourceId,
            sked__tag__c = tagId
        );        
    }        

    public static sked__Tag__c createTag(String name) {
		sked__Tag__c t = new sked__Tag__c();
		t.Name = name;
		t.sked__Type__c = 'Skill';
		t.sked__Classification__c = 'Global';
		return t;
	}    

    //Create resource template
    public static sked__Availability_Template_Resource__c createResourceTemplate(String avaiTemplateId, String resId) {
        sked__Availability_Template_Resource__c resAvai = new sked__Availability_Template_Resource__c(
            sked__Availability_Template__c = avaiTemplateId,
            sked__Resource__c = resId
        );

        return resAvai;
    }

    //Create availability templateEntry
    public static sked__Availability_Template__c createAvailabilityTemplate() {
        sked__Availability_Template__c template = new sked__Availability_Template__c(
            sked__Global__c = true
        );

        return template;
    }

    //Create availability template entry
    public static sked__Availability_Template_Entry__c createAvailabilityTemplateEntry(String avaiTempId, String weekDay) {
        sked__Availability_Template_Entry__c templateEntry = new sked__Availability_Template_Entry__c(
            sked__Availability_Template__c = avaiTempId,
            sked__Is_Available__c = true,
            sked__Weekday__c = weekDay,
            sked__Start_Time__c = 800,
            sked__Finish_Time__c = 1800
        );

        return templateEntry;
    }

    public static String getOptimizeResult(List<String> jobIds, List<String> resIds) {
        String result = skedOptimizationResultRespone;
        for (Integer i = 0; i < jobIds.size(); i++) {
            result = result.replace('{job' + (i+1) + '}', jobIds[i]);
        }

        for (Integer i = 0; i < resIds.size(); i++) {
            result = result.replace('{res' + (i+1) + '}', resIds[i]);
        }

        return result;
    }

    // public static skedAvailabilityPatternData getWeeklyPatternData() {
    //     skedAvailabilityPatternData weeklyPatternData = new skedAvailabilityPatternData();
    //     weeklyPatternData.type = 'weekly';
    //     weeklyPatternData.repeatWeeks = 1;
    //     List<string> weekdays = new List<string> {'sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'};
    //     weeklyPatternData.days = new List<skedAvailabilityPatternData.dayModel>();
    //     for (string weekday : weekdays) {
    //         skedAvailabilityPatternData.dayModel day = new skedAvailabilityPatternData.dayModel();
    //         day.weekday = weekday;
    //         day.intervals = new List<skedAvailabilityPatternData.intervalModel>();
    //         skedAvailabilityPatternData.intervalModel interval = new skedAvailabilityPatternData.intervalModel();
    //         interval.startTime = '09:00';
    //         interval.endTime = '18:00';
    //         day.intervals.add(interval);
    //         weeklyPatternData.days.add(day);
    //     }
    //     return weeklyPatternData;
    // }

    // public static sked__Availability_Pattern__c createWeekPattern() {
    //     sked__Availability_Pattern__c testWeeklyPattern1 = new sked__Availability_Pattern__c(
    //     	Name = 'Test Weekly Pattern 1',
    //         sked__Hash__c = 'weeklyPatternHash',
    //         sked__Pattern__c = Json.serialize(getWeeklyPatternData())
    //     );
    //     return testWeeklyPattern1;
    // }

    public static sked__Availability_Pattern_Resource__c createPatternResource(Id resourceId, Id patternId) {
        return new sked__Availability_Pattern_Resource__c(
            sked__Resource__c = resourceId,
            sked__Availability_Pattern__c = patternId,
            sked__Start__c = Date.today(),
            sked__End__c = null
        );        
    }
    
    public static List<Site_Setting__c> createSiteSettings() {
        //Create site setting
        String defaultSettingJSO = '{"Name":"Default","Logo_URL__c":"https://sforce.co/2VtSotz","Test_Code__c":"TH99","Default_Ordering_Provider__c":"","Landing_Page__c":"<h1><br></h1>","Ineligible_Page__c":"<h1><br></h1>","Screening_Question__c":"<h1><br></h1>","SMS_Template__c":"New booking Confirmation Number [ConfirmationNumber]. [ScheduledDate], [ScheduledTime]. [LocationName]- [LocationAddress]. QR Code [QRCodeURL] [QRCodeImage] [FirstName] [LastName] [FullName] [Email] [Mobile] [ScheduledDateTime] [LogoURL] [Other]","Default_Setting__c":true,"Email_Subject__c":"Thank you for your booking - Confirmation Number [ConfirmationNumber]","SendGrid_Email__c":"noreply@bioreference-appointments.com"}';
        Site_Setting__c defaultSetting = (Site_Setting__c) JSON.deserialize(
          defaultSettingJSO,
          Site_Setting__c.class
        );
        defaultSetting.Email_Body__c = 'Test email';
        defaultSetting.Email_Template__c = '{0} {1}';
        defaultSetting.Email_Subject_Reminder__c = defaultSetting.Email_Subject__c;
        defaultSetting.Email_Body_Reminder__c = defaultSetting.Email_Body__c;
        defaultSetting.SMS_Template_Reminder__c = defaultSetting.SMS_Template__c;
        defaultSetting.Calendar_Template__c = '[CalendarStart] [CalendarEnd] [Location]';
        defaultSetting.Email_Template__c = '{0} {1}';
        defaultSetting.Reminder_Options__c = 'scheduledTime: 11am\r\ndaysBefore: 1,5';        
    
        Site_Setting__c mta = defaultSetting.clone(
          false,
          false,
          false,
          false
        );
        mta.Default_Setting__c = false;
        mta.Name = 'MTA';
    
        return new List<Site_Setting__c>{ defaultSetting, mta };
         
    }

    public static List<sked_Question__c> createQuestions(List<Site_Setting__c> siteSettings) {
        List<sked_Question__c> questions = new List<sked_Question__c>();
        for (Site_Setting__c ss : siteSettings) {
            questions.add(
                new sked_Question__c(
                RecordTypeId = getRecordTypeIdByName(
                    sked_Question__c.sObjectType,
                    'Survey'
                ),
                Question__c = 'Which session would you like to book?',
                Short_Question__c = 'occupation',
                Answers__c = 'Professional\r\nStudent\r\nOther',
                Is_Active__c = true,
                Data_Type__c = 'Picklist',
                Site_Setting__c = ss.Id,
                Option_Format__c = 'aaa---bbb'
                )
            );
          questions.add(
            new sked_Question__c(
                RecordTypeId = getRecordTypeIdByName(
                    sked_Question__c.sObjectType,
                    'Screening'
                ),
                Question__c = 'Gender',
                Short_Question__c = 'Gender',
                Answers__c = 'Male\r\n Female\r\n',
                Is_Active__c = true,
                Data_Type__c = 'Picklist',
                Site_Setting__c = ss.Id,
                Option_Format__c = 'aaa---bbb'
                )
            );
          questions.add(
            new sked_Question__c(
                RecordTypeId = getRecordTypeIdByName(
                    sked_Question__c.sObjectType,
                    'Screening'
                ),
                Question__c = 'Healthcare Id',
                Short_Question__c = 'healthcare id',
                Is_Active__c = true,
                Data_Type__c = 'Text',
                Site_Setting__c = ss.Id,
                Option_Format__c = 'aaa---bbb'
                )
            );
        }        
        return questions;
      }

    // public static Date mondayNextWeek(){
    //     Date d = Date.newInstance(2017, 1, 2);
    //     integer dayDiff = d.daysBetween(system.today());
    //     return system.today().addDays( 7 - Math.mod(dayDiff, 7));
    // }

    public static user newUser(){
        String TimeZoneSidKey = UserInfo.getTimeZone().getID();
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User u = new User(Alias = 'admin', Email='MM_Admin@mainMark.com',
            EmailEncodingKey='UTF-8', LastName='Admin', LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', ProfileId = p.Id,
            TimeZoneSidKey=TimeZoneSidKey, UserName='MM_Admin@mainMark.com');

        return u;
    }

    public static SBQQ__Subscription__c createSubscription(Id quoteLineId, Id productId, Id accId, Id contractId) {
        return new SBQQ__Subscription__c(            
            SBQQ__QuoteLine__c=quoteLineId,
            SBQQ__Product__c=productId,
            SBQQ__SubscriptionStartDate__c=Date.Today().addDays(-100),
            SBQQ__SubscriptionEndDate__c=Date.Today().addDays(120),
            SBQQ__Quantity__c=1,
            SBQQ__Account__c=accId,
            Account_Provisioned__c=accId,SBQQ__Contract__c=contractId,
            PD_Events_Scheduled__c = 3
        );
    }

    public static Contract createContract (Id accId, Id oppId, Id quoteId) {
        return new Contract(
            AccountId=accId,
            SBQQ__Opportunity__c=oppId,
            SBQQ__Quote__c=quoteId,
            StartDate=Date.Today().addDays(-100),
            Status='Draft',
            ContractTerm=12
        );
    }

    // Subscription product:
    /** Create product **/
    public static Product2 createProduct(String name, String productType, String productCode) {
        Product2 obj = (Product2)Product2.sObjectType.newSObject(
            null, // null will make it the default record type for the user
            true // loadDefaultValues
        );
        obj.Name = name;
        obj.isActive = true;
        obj.ProductCode = productCode;
        obj.SBQQ__QuantityEditable__c = true;
        obj.SBQQ__DefaultQuantity__c = 1.0;
        obj.SBQQ__AssetConversion__c = 'One per quote line';
        obj.SBQQ__SubscriptionCategory__c = 'Bundle';
        obj.Product_License__c = 'pro';
        obj.Family = 'Professional Learning';
        obj.Product_Sub__c = 'In-person';

        if(productType == 'Subscription') {
            obj.SBQQ__SubscriptionTerm__c = 12;
            obj.SBQQ__SubscriptionType__c = 'Renewable';
            obj.SBQQ__SubscriptionPricing__c = 'Fixed Price';
            obj.SBQQ__PricingMethod__c = 'List';
            obj.SBQQ__SubscriptionBase__c = 'Regular';
        } else if(productType == 'Non-Subscription') {
            obj.SBQQ__SubscriptionBase__c = 'List';
        }

        // Required to Order a quote when Billing is installed:
        obj.SBQQ__ChargeType__c = 'Recurring';
        obj.SBQQ__BillingType__c = 'Advance';
        obj.SBQQ__BillingFrequency__c = 'Other';        
        obj.Number_of_Sessions__c = 5;
        return obj;
    }

    /** Create pricebook entry **/
    public static PricebookEntry createPriceBookEntry(Product2 product, Pricebook2 priceBook) {
        PricebookEntry obj = (PricebookEntry)PricebookEntry.sObjectType.newSObject(
            null, // null will make it the default record type for the user
            true // loadDefaultValues
        );
        obj.UnitPrice = 100;
        obj.Pricebook2Id = priceBook == null ? Test.getStandardPricebookId() : priceBook.Id;
        obj.Product2Id = product.Id;
        obj.isActive = true;

        return obj;
    }

    /** Create quote **/
    public static SBQQ__Quote__c createQuote(Id accId, Id oppId, Boolean isPrimary) {
        SBQQ__Quote__c obj = (SBQQ__Quote__c)SBQQ__Quote__c.sObjectType.newSObject(
            null, // null will make it the default record type for the user
            true // loadDefaultValues
        );
        obj.SBQQ__Primary__c = isPrimary;
        obj.SBQQ__StartDate__c = Date.today();
        obj.SBQQ__BillingFrequency__c = 'Upfront in full';
        obj.Billing_Frequency_Comments__c = 'TestBillingFreqComments';
        obj.Billing_Schedule__c = 'Upon Contract Signature/Upon Order Execution';
        obj.Billing_Schedule_Notes__c = 'TestBillingNotes';
        //obj.SBQQ__EndDate__c = Date.today().addMonths(1);
        obj.SBQQ__Opportunity2__c = oppId == null ? null : oppId;
        obj.SBQQ__SubscriptionTerm__c = 12;
        obj.SBQQ__ExpirationDate__c = Date.today() + 30;
        obj.SBQQ__Account__c = accId == null ? null : accId;
        obj.SBQQ__Type__c = 'Quote';
        return obj;
    }

    public static Opportunity createOpportunity(Id standardPricebookId, Id accId, Id recordTypeId) {
        return new Opportunity(
            Federal_Funds__c='Grant',
            Pricebook2Id = standardPricebookId,
            AccountId=accId,
            RecordTypeId = recordTypeId, 
            StageName = 'Open', 
            CloseDate = System.today(), 
            Name ='TestFactory.OpportunityDefaults'
        );
    }

    // Method to create quote lines:
    public static list<SBQQ__QuoteLine__c> setupQuoteLines(list<Account> quoteLineAccList,List<SBQQ__Quote__c> quoteList, List<Product2> productList, List<PricebookEntry> standardPbEntryList) {
        // Create quote lines for each quote (# of quote lines per quote = # of products created above):
        List<SBQQ__QuoteLine__c> quoteLineList = new List<SBQQ__QuoteLine__c>();
        for(SBQQ__Quote__c q : quoteList) {
            for(Integer i = 0; i < productList.size(); i++) {
                for(Integer j = 0; j < quoteLineAccList.size(); j++) {
                    // For each quote, create as many quote lines as there are products:
                    SBQQ__QuoteLine__c ql = createQuoteLine(
                        quoteLineAccList[j],
                        productList[i],      // Product2 product, 
                        standardPbEntryList[i],  // PriceBookEntry pbe
                        q
                    );
                    quoteLineList.add(ql);
                }
            }
        }
        return quoteLineList;
        
    }

    /** Create quote line **/
    public static SBQQ__QuoteLine__c createQuoteLine(Account acct,Product2 product, PriceBookEntry pbe, SBQQ__Quote__c quote) {
        SBQQ__QuoteLine__c obj = (SBQQ__QuoteLine__c)SBQQ__QuoteLine__c.sObjectType.newSObject(
            null, // null will make it the default record type for the user
            true // loadDefaultValues
        );
        obj.School__c=acct.Id;
        obj.SBQQ__Product__c = product.Id;
        obj.SBQQ__Quote__c = quote.Id;
        obj.SBQQ__PricebookEntryId__c = pbe == null ? null : pbe.Id;
        obj.SBQQ__PricingMethod__c = 'List';
        obj.SBQQ__StartDate__c = Date.today();
        obj.SBQQ__ListPrice__c = 100;
        obj.SBQQ__Quantity__c = 1;
        obj.SBQQ__PriorQuantity__c = 0;
        obj.SBQQ__RegularPrice__c = 100;
        obj.SBQQ__NetPrice__c = 100;
        obj.SBQQ__Number__c = 1;
        obj.SBQQ__ProrateMultiplier__c = 1;
        obj.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        obj.SBQQ__SubscriptionScope__c = 'Quote';
        obj.SBQQ__DefaultSubscriptionTerm__c = 1;
        obj.SBQQ__ChargeType__c = product.SBQQ__ChargeType__c;
        obj.SBQQ__BillingType__c = product.SBQQ__BillingType__c;
        obj.SBQQ__BillingFrequency__c = product.SBQQ__BillingFrequency__c;

        return obj;
    }

    public static Map<String, Profile> mapProfiles {
        get {
            if (mapProfiles==null) {
                mapProfiles = new Map<String, Profile>();
                List<String> lstProfileNames = new List<String>{strImplementerSchedulerUser};
                        List<Profile> lstProfiles = [SELECT ID, Name FROM Profile WHERE Name in : lstProfileNames];
                for(Profile theProfile: lstProfiles) {
                    mapProfiles.put(theProfile.Name, theProfile);
                }
            }
            return mapProfiles;
        }
        set;
    }

    //this inc
    public static void insertCustomSettings() {         
        
        ID profileID = mapProfiles.get(strImplementerSchedulerUser).Id;
        List<SObject> settingsToInsert = new List<SObject>();  
       
        insert new Region_Mapping__c(Name='TestRegionMapping',Country__c='*OTHER*',States__c='*OTHER*',DefaultRegionforUnspecifiedZIPCodes__c=true,
        Key_Account_Sales_Rep__c='jonathan.kreinin',Field_Sales_Rep__c='jonathan.kreinin',Inside_Sales_Rep__c='jonathan.kreinin',Base_Sales_Rep__c='jonathan.kreinin',
        Key_Account_SDR__c='lisa.burge',Base_SDR__c='lisa.burge',Field_SDR__c='lisa.burge',Inside_SDR__c='lisa.burge',
        School_AM_SDR__c='sydney.price',District_AM_SDR__c='sydney.price',Small_District_AM_SDR__c='sydney.price',Teacher_AM_SDR__c='sydney.price',
        Small_District_AM__c='belinda.paladino',District_AM__c='belinda.paladino',School_AM__c='belinda.paladino',Teacher_AM__c='belinda.paladino',
        Curricular_Solutions__c='walt.peters',
        Learning_Engagement_Manager__c='danielle.edgeman',
        Pilot_Learning_Engagement_Manager__c='danielle.edgeman',
        Implementation_Specialist__c='karolina.dryjanska',
        Pilot_Implementation_Specialist__c='eben.flournoy',
        Regional_Marketing_Manager__c='nicole.bono');
        
        
        settingsToInsert.add(new NameValueSettings__c(Name='ProductsNotSelectableOnDistrictPilots',Value__c='01t1S000002j6NTQAY'));
        settingsToInsert.add(new NameValueSettings__c(Name='TaskActivityResultValForOppCreation',Value__c='Reached,Reached During Meeting time,Reached Later,Reached Later (Email),Reached Later (Phone),Reached On First Call'));
        settingsToInsert.add(new NameValueSettings__c(Name='EmailAddresses For Automation Errors',Value__c='test@gmail.com'));
        settingsToInsert.add(new NameValueSettings__c(Name='EmailAddresses LicenseAPIErrors',Value__c='test@gmail.com'));
        settingsToInsert.add(new NameValueSettings__c(Name='SafetyNetSDRAcctOwner',Value__c=UserInfo.getUserId()));
        settingsToInsert.add(new NameValueSettings__c(Name='TaskUserRolesForOppCreation',Value__c='00E1S000000IX7xUAG,00E37000000EI8wEAG'));

        settingsToInsert.add(new NameValueSettings__c(Name='DefaultSDR PDConsultation MarketoReq',Value__c='00537000002DyHYAA0'));
          
        settingsToInsert.add(new NameValueSettings__c(Name='MarketoEcommerceRolesForOppCreation',Value__c='00E3D000000xscqUAA'));
        settingsToInsert.add(new NameValueSettings__c(Name='Live Chat SDR Owners',Value__c='00E3D000000xscqUAA'));
        

        settingsToInsert.add(new NameValueSettings__c(Name='High Touch Case Owner',Value__c='00537000004lneTAAQ'));
        settingsToInsert.add(new NameValueSettings__c(Name='Tech Touch Case Owner',Value__c='00537000001wg2oAAA'));
       
        settingsToInsert.add(new NameValueSettings__c(Name='New York DOE Account Id',Value__c='00137000004WVwxAAG'));
        settingsToInsert.add(new NameValueSettings__c(Name='NY Comp Marketo Task Owner',Value__c='0051S000005hMzhQAE'));
       
        settingsToInsert.add(new NameValueSettings__c(Name='Account Owner for GTI Licenses',Value__c='003370000087FcrAAE'));
       
       
        settingsToInsert.add(new NameValueSettings__c(Name='FS Roles',Value__c='00E1S000000IX6pUAG,00E1S000000IX6uUAG,00E3D0000011VTUUA2,00E3D0000011VTZUA2,00E1S000000IX6zUAG,00E1S000000IX7JUAW,00E3D0000011VTeUAM,00E3D0000011VUXUA2'));
        settingsToInsert.add(new NameValueSettings__c(Name='FS Roles2',Value__c='00E3D0000011VTjUAM,00E1S000000IX74UAG,00E1S000000IX7iUAG,00E3D0000011VToUAM,00E3D0000011VTtUAM,00E1S000000IX7EUAW,00E1S000000IX7OUAW,00E1S000000IX8lUAG,00E1S000000IX8qUAG,00E3D0000011VUSUA2'));
        settingsToInsert.add(new NameValueSettings__c(Name='FS Roles3',Value__c='00E3D0000011VTyUAM,00E3D0000011VU3UAM,00E1S000000IX7TUAW,00E1S000000IX7YUAW,00E3D0000011VU8UAM,00E3D0000011VUDUA2,00E1S000000IX7dUAG,00E1S000000IX7sUAG,00E3D0000011VUIUA2,00E3D0000011VUNUA2'));
        

        settingsToInsert.add(new NameValueSettings__c(Name='CSMRoleId',Value__c='00E1S000000IX6pUAG,00E1S000000IX6uUAG,00E3D0000011VTUUA2,00E3D0000011VTZUA2,00E1S000000IX6zUAG,00E1S000000IX7JUAW,00E3D0000011VTeUAM,00E3D0000011VUXUA2'));
        settingsToInsert.add(new NameValueSettings__c(Name='CSMRoleId2',Value__c='00E3D0000011VSvUAM,00E3D0000011VUmUAM,00E1S0000011WAdUAM,00E1S0000011WAiUAM,00E3D0000011VTAUA2,00E3D0000011VTFUA2,00E3D0000011VTKUA2,00E3D0000011VTPUA2'));
        
        
        
        
        settingsToInsert.add(new NameValueSettings__c(Name='Scheduling User Profile',Value__c=profileID));
        
        settingsToInsert.add(new NameValueSettings__c(Name='SystemAdminProfileId',Value__c='00e37000000g55CAAQ'));
        settingsToInsert.add(new NameValueSettings__c(Name='CSM Realignment Threshold',Value__c='6'));
        settingsToInsert.add(new NameValueSettings__c(Name='Threshold Opp or Account Owner',Value__c='00537000002CetkAAC'));
        settingsToInsert.add(new NameValueSettings__c(Name='Interrupting Robot User',Value__c='00537000000L3pjAAC'));
      
        settingsToInsert.add(new NameValueSettings__c(Name='CUCaseOwnerWestCentralMidwest',Value__c='0051S000005hKiyQAE'));
        settingsToInsert.add(new NameValueSettings__c(Name='CUCaseOwnerMissingState',Value__c='00537000002ESjSAAW'));
        settingsToInsert.add(new NameValueSettings__c(Name='CUCaseOwnerNETriSEMidAtlantic',Value__c='0051S000005SbihQAC'));
       


        settingsToInsert.add(new NameValueSettings__c(Name='Live Chat SDR Owners',Value__c=UserInfo.getUserId()));
        

        settingsToInsert.add(new NameValueSettings__c(Name='ProfileOpenSDROppEventSchEventOverride',Value__c='00e37000000hVjwAAE,00e37000000g55CAAQ'));
      
      
        settingsToInsert.add(new NameValueSettings__c(Name='RenewalSiteProfileId',Value__c='00e37000000kv4QAAQ'));
        settingsToInsert.add(new NameValueSettings__c(Name='CustomUnitsSiteProfileId',Value__c='00e37000000MnpfAAC'));
        
        settingsToInsert.add(new NameValueSettings__c(Name='SDRRoleId1',Value__c='00E1S000000IX7xUAG,00E37000000EI8wEAG,00E1S000000IX82UAG,00E3D0000011VUcUAM'));
        settingsToInsert.add(new NameValueSettings__c(Name='SDRRoleId2',Value__c='00E37000000daZpEAI'));
        settingsToInsert.add(new NameValueSettings__c(Name='Users for Custom Unit Build Feed',Value__c='00537000002ESjSAAW,00537000000LO0QAAW'));
        settingsToInsert.add(new NameValueSettings__c(Name='EngagementStartegyUserIds',Value__c='00537000000LO0GAAW,00537000000wsCkAAI,00537000001wg2oAAA'));
        settingsToInsert.add(new NameValueSettings__c(Name='MarketoUserId',Value__c='00537000002EZVmAAO'));
        settingsToInsert.add(new NameValueSettings__c(Name='UserProfilesForClosedOppChanges',Value__c=UserInfo.getUserId()));
       /* settingsToInsert.add(new NameValueSettings__c(Name='Pilot Product Ids',Value__c='01t37000001atxZAAQ,01t37000001PeoqAAC,01t37000001akIiAAI,01t37000001akIsAAI,01t37000001akInAAI,01t37000001YV5SAAW,,01t37000001akIdAAI,01t37000001L6W9AAK,01t37000001atxUAAQ,01t37000001bJS4AAM'));      
        settingsToInsert.add(new NameValueSettings__c(Name='Pilot Product Ids2',Value__c='01t1S000001M5XnQAK'));   
        settingsToInsert.add(new NameValueSettings__c(Name='Pilot Product Ids3',Value__c='01t1S000002mzvvQAA'));  
        settingsToInsert.add(new NameValueSettings__c(Name='Pilot Product Ids4',Value__c='01t1S000002mzwJQAQ'));  
        settingsToInsert.add(new NameValueSettings__c(Name='Pilot Product Ids5',Value__c='01t1S000002mzw7QAA'));     
       */
       
        settingsToInsert.add(new NameValueSettings__c(Name='Subjects for Custom Units',Value__c='Social Studies,ELA - Skills,ELA - Novel,Science,Other'));
        //settingsToInsert.add(new NameValueSettings__c(Name='LiveChatTaskActResValForOppCreation',Value__c='Reached On First Call'));
        
        settingsToInsert.add(new ProcessTriggers__c(SetupOwnerId=UserInfo.getUserId(),Turn_Off_Triggers__c=false));
        

        database.insert(settingsToInsert,false);                           
    }

    public static Id getRecordTypeIdByName(
        Schema.sObjectType objectType,
        String name
    ) {
        Schema.RecordTypeInfo rtInfo = objectType.getDescribe()
        .getRecordTypeInfosByName()
        .get(name);
        if (rtInfo != null) {
        return rtInfo.getRecordTypeId();
        }
        return null;
    }

        

    public static String createXMLDoc() {  //create a XML Document String for Attendee. The number of Item is 1.
        DOM.Document doc = new DOM.Document();
        DOM.XmlNode rootNode = doc.createRootElement('UserDetailsTransaction', null, null);

        //add channel information
        DOM.XmlNode channel = rootNode.addChildElement('userDetails', null, null); 
        //add item 
        DOM.XmlNode item = channel.addChildElement('user', null, null);
        //add title
        DOM.XmlNode title = item.addChildElement('First_Name', null, null).addTextNode('Amit');
        //add description
        DOM.XmlNode description = item.addChildElement('Last_Name', null, null).addTextNode('KIM');
        //add link
        DOM.XmlNode link = item.addChildElement('NUID', null, null).addTextNode('Z973975');
        //add description
        DOM.XmlNode pubDate = item.addChildElement('Location_Description', null, null).addTextNode('Panorama City MOB #3');
        //add source
        DOM.XmlNode source = item.addChildElement('Start_Date', null, null).addTextNode('2016-02-08 00:00:00');
        //add source
        DOM.XmlNode entityCode = item.addChildElement('Entity_Code', null, null).addTextNode('06');
        DOM.XmlNode locationNumber = item.addChildElement('Location_Number', null, null).addTextNode('CA2572');
        DOM.XmlNode costCenterName = item.addChildElement('Cost_Center_Name', null, null).addTextNode('Family Medicine-Regular Clinic');
        DOM.XmlNode departmentName = item.addChildElement('Department_Name', null, null).addTextNode('Family Medicine-Regular Clinic');
        DOM.XmlNode entityName = item.addChildElement('Entity_Name', null, null).addTextNode('Medical Group'); 
        DOM.XmlNode regionName = item.addChildElement('Region_Name', null, null).addTextNode('Southern California'); 
        DOM.XmlNode Status = item.addChildElement('Status', null, null).addTextNode('Active'); 
        DOM.XmlNode Email = item.addChildElement('Email', null, null).addTextNode('test.kp@kp.org'); 
        DOM.XmlNode jobDescription = item.addChildElement('Job_Description', null, null).addTextNode('Family Medicine'); 
        DOM.XmlNode siteID = item.addChildElement('Site_ID', null, null).addTextNode('PNC'); 
        DOM.XmlNode regionCode = item.addChildElement('Region_Code', null, null).addTextNode('08'); 
        DOM.XmlNode costCenterCode = item.addChildElement('Cost_Center_Code', null, null).addTextNode('8335'); 
        DOM.XmlNode workForceClass = item.addChildElement('Workforce_Class', null, null).addTextNode('Employee'); 
        DOM.XmlNode contactPhone = item.addChildElement('Contact_Phone', null, null).addTextNode('818-375-2422'); 
        String xmlString = doc.toXMLString();
        xmlString = xmlString.remove('<?xml version="1.0" encoding="UTF-8"?>');
        System.debug('xmlString ' + xmlString);
        return xmlString;
    }

    public static String skedOptimizationResultRespone = '{"result":{"score":{"hardScore":0,"mediumScore":-150,"softScore":-195},"timeToSolve":2293,"routes":[{"resourceId":"{res1}","resourceName":"MM ALT 1","route":[{"jobId":"{job1}","jobName":"JOB-0201","start":"2020-04-11T13:00:00.000Z","duration":60,"travelTime":0,"type":"job"}]},{"resourceId":"{res2}","resourceName":"Inspector ATL2","route":[{"jobId":"{job2}","jobName":"JOB-0302","start":"2020-04-11T13:00:00.000Z","duration":60,"travelTime":0,"type":"job"}]}],"unscheduled":[{"jobId":"{job3}","jobName":"JOB-0216","jobReasons":["Time Constraint: Must start after end of scheduling window","Time Constraint: Must end before start of scheduling window"],"resourceReasons":{"a0c1k000001UBADAA4":{"name":"MM ALT 1","address":"296 Springs Xing Canton, GA 30114, USA","reasons":[]},"a0c1k000001tX3dAAE":{"name":"Inspector ATL1","address":"823 Ash St, Canton, GA 30114","reasons":["Required Attribute: Missing Market Management"]},"a0c1k000001tX3iAAE":{"name":"Inspector ATL2","address":"295 Springs Xing Canton, GA 30114","reasons":["Required Attribute: Missing Market Management"]},"a0c1k000001ty4nAAA":{"name":"MM ALT 2","address":"400 Springs Xing Canton, GA 30114, USA","reasons":[]}}}]}}';

    /************************************************ Nested classes ****************************************************/
    public class skedMockDataFactory {
        public skedMockDataFactory(){}
        public HTTPResponse getGetMeetingDetailsResponse(HTTPRequest req, boolean isErrorMode) {
            string jsonBody = req.getBody();
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            if (isErrorMode == true) {
                Map<String, Object> result = new Map<String, Object>();
                result.put('errorType', 'ErrorType');
                result.put('message', 'Invalid request');
                res.setBody(Json.serialize(result));
            } else {
                skedSkeduloApiData.virtualMeetingResult result = getBasicMeetingResult();
                res.setBody(Json.serialize(result));
            }
            res.setStatusCode(isErrorMode ? 400 : 200);
            return res;
        }
        public HTTPResponse getCreateMeetingResponse(HTTPRequest req, boolean isErrorMode) {
            string jsonBody = req.getBody();
            Map<string, object> mapBody = (Map<string, object>)Json.deserializeUntyped(jsonBody);
            string agenda = string.valueOf(mapBody.get('agenda'));
            string password = string.valueOf(mapBody.get('password'));
            string topic = string.valueOf(mapBody.get('topic'));
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            if (isErrorMode == true) {
                skedSkeduloApiData.message message = new skedSkeduloApiData.message();
                message.code = 101;
                message.message = 'Invalid request';
                Map<String, Object> result = new Map<String, Object>();
                result.put('errorType', 'ErrorType');
                result.put('message', message);
                res.setBody(Json.serialize(result));
            } else {
                skedSkeduloApiData.virtualMeetingResult result = getBasicMeetingResult();
                result.result.password = password;
                result.result.zoom.agenda = agenda;
                result.result.zoom.topic = topic;
                res.setBody(Json.serialize(result));
            }
            res.setStatusCode(isErrorMode ? 400 : 200);
            return res;
        }
        public HTTPResponse getUpdateMeetingResponse(HTTPRequest req, boolean isErrorMode) {
            string jsonBody = req.getBody();
            Map<string, object> mapBody = (Map<string, object>)Json.deserializeUntyped(jsonBody);
            string agenda = string.valueOf(mapBody.get('agenda'));
            string password = string.valueOf(mapBody.get('password'));
            string topic = string.valueOf(mapBody.get('topic'));
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            skedSkeduloApiData.virtualMeetingResult result = getBasicMeetingResult();
            result.result.password = password;
            result.result.zoom.agenda = agenda;
            result.result.zoom.topic = topic;
            res.setBody(Json.serialize(result));
            res.setStatusCode(isErrorMode ? 400 : 200);
            return res;
        }
        public HTTPResponse getDeleteMeetingResponse(HTTPRequest req, boolean isErrorMode) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(isErrorMode ? 400 : 200);
            return res;
        }
        private skedSkeduloApiData.virtualMeetingResult getBasicMeetingResult() {
            skedSkeduloApiData.zoomSettings settingsResult = new skedSkeduloApiData.zoomSettings();
            settingsResult.waiting_room = true;
            skedSkeduloApiData.zoom zoomResult = new skedSkeduloApiData.zoom();
            zoomResult.agenda = 'Appointment';
            zoomResult.timezone = 'America/Los_Angeles';
            zoomResult.topic = 'Treatment - Client Test';
            zoomResult.type = 3;
            zoomResult.settings = settingsResult;
            skedSkeduloApiData.virtualMeeting meetingResult = new skedSkeduloApiData.virtualMeeting();
            meetingResult.hostUrl = 'https://skedulo.zoom.us/s/92474512377';
            meetingResult.id = 'Zoom:92474512377';
            meetingResult.inviteeUrl = 'https://skedulo.zoom.us/j/92474512377?pwd=dC9SbzlKZjRtaXJKa05lUnVKeHRBdz09';
            meetingResult.password = '123456';
            meetingResult.zoom = zoomResult;
            skedSkeduloApiData.virtualMeetingResult result = new skedSkeduloApiData.virtualMeetingResult();
            result.result = meetingResult;
            return result;
        }
    }
       
}