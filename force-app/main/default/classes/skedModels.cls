/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 03-22-2021
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   01-25-2021   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
global class skedModels {
    public virtual class BaseModel {
        public String id;
        public String name;

        public BaseModel(SObject queriedObject ) {
            this.id = String.valueOf(queriedObject.get('Id'));
            this.name = String.valueOf(queriedObject.get('Name'));
        }

        public BaseModel(String id, String name) {
            this.id = id;
            this.name = name;
        }

        public BaseModel(){}
    }

    public class RegionModel extends BaseModel {
        public String timezoneSidId;
        public RegionModel(){}
        public RegionModel(sked__Region__c skedRegion) {
            super(skedRegion);
            this.timezoneSidId = skedRegion.sked__Timezone__c;
        }
    }

    public virtual class ResourceModel extends BaseModel implements Comparable {
        public RegionModel region;        
        public List<Id> tagIds;        
        public String resourceRequirementId;
        public String photoUrl;
        public String mobilePhone;
        public Integer battingOrder;
        public ResourceModel(){            
            this.tagIds = new List<Id>();
        }
        public ResourceModel(sked__Resource__c skedResource) {
            super(skedResource);            
            this.tagIds = new List<Id>();            
            // if ( skedResource.sked__Primary_Region__c != NULL ) {
            //     this.region = new RegionModel(skedResource.sked__Primary_Region__r);
            // }                        
            
            // if ( !skedResource.sked__ResourceTags__r.isEmpty() )  {
            //     for ( sked__Resource_Tag__c rsTag : skedResource.sked__ResourceTags__r ) {
            //         this.tagIds.add(rsTag.sked__Tag__c);
            //     }
            // }
            if ( skedResource.sked__User__c != null ) {
                // this.photoUrl = skedResource.sked__User__r.smallPhotoUrl;
            }           
            this.mobilePhone = skedResource.sked__Mobile_Phone__c;            
        }

        public virtual Integer compareTo(Object compareTo) {
            ResourceModel compareToRecord = (ResourceModel)compareTo;
            Integer returnValue = 0;
            
            if (battingOrder > compareToRecord.battingOrder) {
                returnValue = 1;
            } else if (battingOrder < compareToRecord.battingOrder) {
                returnValue = -1;
            }
            return returnValue;   
        }
    }

    public class JobTypeModel extends BaseModel {
        public Integer duration;
        public Integer paddingTime;
        public JobTypeModel(String id, String name) {
            super(id, name);
        }        
        public JobTypeModel(){}
    }

    public class Geometry {
        public string address;
        public decimal lat;
        public decimal lng;

        public Geometry(){}
        
        public Geometry(string address, decimal lat, decimal lng) {
            this.address = address;
            this.lat = lat;
            this.lng = lng;
        }
        
        public Geometry(Location geoLocation) {
            this.lat = geoLocation.getLatitude();
            this.lng = geoLocation.getLongitude();
        }
    } 

    public class AccountModel extends BaseModel {
        public String timezone;
        
        public AccountModel() {}
        public AccountModel(Account act) {
            super(act);     
            this.timezone = act.Timezone_c__c;       
        }
    }   
    
    public class OptionModel extends BaseModel {
        public Boolean seletable;
        public OptionModel(String id, String name) {
            super(id, name);            
        }
    }

    public virtual class eventModel extends BaseModel {
        public String eventDate;
        public integer startTime;
        public integer endTime;   
        public Integer duration;
        public String description;
        public Geometry geometry;
        public String status;
        public String objectType;
        public String eventType;
    }

    public virtual class ActivityModel extends eventModel {        

    }

    public virtual class JobModel extends eventModel {                
        public string jobDate;
        public string jobType;
        public RegionModel region;
        public Account account;
        public String notes;
        public AddressModel address;
        public BaseModel contact;
        public LocationModel location;
        public string deliveryMethod;
        public string customerName;
        public string customerEmail;
        public string customerPhoneNo;
        public string locationText;
    }

    public class SurveyModel {
        public String id;
        public String question;
        public String answer;
    }

    public class MyAgendaRequest {
        public String startDate;
        public String endDate;
    }

    public class MyAgendaResponse {
        public String resourceId;
        public Map<String, List<eventModel>> eventsInDate;
        public MyAgendaResponse() {
            this.eventsInDate = new Map<String, List<eventModel>>(); 
        }
    }

    public class ViewData {
        public String skedApiSession;
    }

    public class PlaceInfoModel {
        public String street;
        public String State;
        public String PostalCode;
        public String Country;                  
    }

    public class AutoCompleteResponse {
        public String skedApiSession;
        public List<skedSkeduloApiData.Prediction> predictions;
    }

    global class AddressGeolocationRequest {
        public String address;
        public String placeId;
        public String skedApiSession;
    }

    global class SubscriptionInfoRequest {
        public string subId;
    }

    global class ProductTypeModel extends BaseModel{
        public ProductTypeModel(String id, String name){
            super(id, name);            
        }
        public Boolean locationRequired;
    }

    global class SubscriptionInfoResponse {
		public skedModels.BaseModel account;
        public skedModels.ProductTypeModel productType;
        public List<skedModels.BaseModel> deliveryMethods;
        public RegionModel region;
        
        public SubscriptionInfoResponse() {            
            this.deliveryMethods = new List<skedModels.BaseModel>();              
        }
    }  

    global class Subscription extends BaseModel  {
        public skedModels.BaseModel account;
    }

    public class LocationModel extends BaseModel {
        public RegionModel region;
        public AddressModel address;
        public LocationModel(){}
        public LocationModel(sked__Location__c skedLocation) {
            super(skedLocation);
            if ( skedLocation.sked__Region__c != NULL ) {
                this.region = new RegionModel(skedLocation.sked__Region__r);
            }
            this.address = new AddressModel(skedLocation);
        }
    }    

    public class AddressModel {
        public Geometry geometry;
        public String placeId;
        public PlaceInfoModel placeInfo;

        public AddressModel() {
        }
        public AddressModel(sked__Location__c skedLocation) {
            if ( skedLocation.sked__GeoLocation__c != null )
            this.geometry = new Geometry(skedLocation.sked__GeoLocation__c);
            this.geometry.address = skedLocation.sked__Address__c;
        }
    }

    global virtual class InputRequest {
        public string searchingName;
        public string operator;
        //object searching
        public String objectName;
    }

    global class ConfigurationRequest {
        public Subscription subscription;        
        public string productType;
        public string deliveryMethod;         
    }

    global class ConfigurationResponse {
        public String defaultStartDate;        
        public Integer numberOfDays;
        public Integer jobDuration;
        public Integer interval;
        public Integer gridStart;
        public Integer gridEnd;
    }

    global class bookingGridQueryModel {
        public skedModels.RegionModel region;   
        public skedModels.LocationModel location; 
        public skedModels.Geometry geometry;
        public string startDateISO;
        public string endDateISO;
        public integer startTimeInt;
        public integer endTimeInt;
        public integer jobDuration;
        public string jobType;
        public integer timeslotStep;          
        public string productType;
        public string deliveryMethod;
        public Subscription subscription;
        public String defaultStartDate;

                
        public transient Date startDate;
        public transient Date endDate;
        public transient DateTime startTime;
        public transient DateTime endTime;
        public transient Location jobLocation;
    }

    global class bookingGridModel {
    	public string timezone;
    	public List<bookingGridRowModel> rows;
        // public List<skedModels.ResourceModel> resources;

    	public transient Map<string, slotModel> mapSlot;

    	public bookingGridModel() {
    		this.rows = new List<bookingGridRowModel>();
    		this.mapSlot = new Map<string, slotModel>();
            // this.resources = new List<skedModels.ResourceModel>();
    	}
    }

    global class bookingGridRowModel {
    	public integer startTimeInt;
    	public List<slotModel> slots;

    	public bookingGridRowModel() {
    		this.slots = new List<slotModel>();
    	}
    }

    global class slotModel {
        public string slotDate;
        public integer slotTime;
        public integer noOfQualifiedResources;
        public integer noOfAvailableResources;
        public List<skedModels.ResourceModel> availableResources;
        
        public transient string slotKey;
        public transient DateTime startTime;
        
        public slotModel() {
        	this.noOfQualifiedResources = 0;
        	this.noOfAvailableResources = 0;
            this.availableResources = new List<skedModels.ResourceModel>();
        }
    }

    public class SiteSetting extends BaseModel {
        @AuraEnabled
        public String logoUrl {get;set;}

        @AuraEnabled
        public String siteDescription {get;set;}

        @AuraEnabled
        public String senderEmail {get;set;}

        @AuraEnabled
        public String sendGridEmail {get;set;}

        @AuraEnabled
        public String testType {get;set;}

        @AuraEnabled
        public String orderingProviderId {get;set;}

        @AuraEnabled
        public String landingPage {get;set;}

        @AuraEnabled
        public String surveyPage {get;set;}

        @AuraEnabled
        public String verificationPage {get;set;}

        @AuraEnabled
        public String verificationError {get;set;}

        @AuraEnabled
        public String confirmationPage {get;set;}

        @AuraEnabled
        public String maintenancePage {get;set;}

        @AuraEnabled
        public String ineligiblePage {get;set;}

        @AuraEnabled
        public String screeningQuestionPage {get;set;}

        @AuraEnabled
        public String senderName {get;set;}

        @AuraEnabled
        public String domain {get;set;}

        @AuraEnabled
        public boolean isDefault {get;set;}

        @AuraEnabled
        public boolean enableBookingQuestions {get;set;}

        @AuraEnabled
        public boolean enableServiceFilter {get;set;}

        @AuraEnabled
        public Integer clearClientInfoAfter {get;set;}

        @AuraEnabled
        public String defaultSite {get;set;}

        @AuraEnabled
        public String primaryColor {get;set;}

        @AuraEnabled
        public Integer cancellationDays {get;set;}

        @AuraEnabled
        public Integer rescheduleDays {get;set;}

        public transient String emailSubject;
        public transient String emailBody;
        public transient String emailTemplate;
        public transient String smsTemplate;
        public transient String cancelledEmailSubject;
        public transient String cancelledEmailBody;
        public transient String cancelledSMSTemplate;
        public transient String reminderEmailSubject;
        public transient String reminderEmailBody;
        public transient String reminderSMSTemplate;

        public transient String reminderOptions;
        public transient String calendarTemplate;

        @AuraEnabled
        public Decimal searchDistance {get;set;}

        @AuraEnabled
        public Integer bufferDay {get;set;}

        @AuraEnabled
        public boolean showInsuranceInfo {get;set;}

        @AuraEnabled
        public String mobilePhlebTestCode {get;set;}

        @AuraEnabled
        public List<Question> screeningQuestions {get;set;}

        @AuraEnabled
        public List<Question> bookingQuestions {get;set;}

        @AuraEnabled
        public List<Question> verificationQuestions {get;set;}

        @AuraEnabled
        public Survey survey {get;set;}

        @AuraEnabled
        public String visitRequestedMessage {get;set;}

        @AuraEnabled
        public String visitRequestedVerbiage {get;set;}

        @AuraEnabled
        public String timeConfirmedMessage {get;set;}

        @AuraEnabled
        public String timeConfirmedVerbiage {get;set;}

        @AuraEnabled
        public String onTheWayMessage {get;set;}

        @AuraEnabled
        public String onTheWayVerbiage {get;set;}

        @AuraEnabled
        public String arrivedMessage {get;set;}

        @AuraEnabled
        public String arrivedVerbiage {get;set;}

        @AuraEnabled
        public String lateCancelMessage {get;set;}

        @AuraEnabled
        public String lateModifyMessage {get;set;}

        @AuraEnabled
        public boolean showingVirtualSuccessfullyMessage {get;set;}

        public SiteSetting init (Site_Setting__c setting) {
            id                  = setting.Id;
            name                = setting.Name;
            isDefault           = setting.Default_Setting__c;
            if (name.equalsIgnoreCase('magnacare')) {
                showInsuranceInfo = true;
            }
            logoUrl             = setting.Logo_Url__c;
            siteDescription     = setting.Site_Description__c;
            senderEmail         = setting.SendGrid_Email__c;
            testType            = setting.Test_Code__c;
            orderingProviderId  = setting.Default_Ordering_Provider__c;
            reminderOptions          = setting.Reminder_Options__c;
            searchDistance          = setting.Search_Distance__c;
            calendarTemplate        = setting.Calendar_Template__c;
            defaultSite         = setting.Default_Site__c;
            enableBookingQuestions = setting.Enable_Booking_Questions__c;
            enableServiceFilter     = setting.Service_Filter_On_Off__c;
            clearClientInfoAfter    = setting.Clear_Patient_Info_After__c==null?60: Integer.valueOf(setting.Clear_Patient_Info_After__c);
            bufferDay               = setting.Buffer_Day__c==null?5: Integer.valueOf(setting.Buffer_Day__c);
            mobilePhlebTestCode     = setting.MP_Test_Code__c;

            landingPage         = setting.Landing_Page__c;
            surveyPage          = setting.Survey_Page__c;
            verificationPage    = setting.Verification_Page__c;
            verificationError   = setting.Verification_Error__c;
            confirmationPage    = setting.Confirmation_Page__c;
            maintenancePage     = setting.Maintenance_Page__c;
            ineligiblePage      = setting.Ineligible_Page__c;
            screeningQuestionPage    = setting.Screening_Question__c;
            emailSubject           = setting.Email_Subject__c;
            emailBody           = setting.Email_Body__c;
            emailTemplate           = setting.Email_Template__c;
            smsTemplate         = setting.SMS_Template__c;
            domain              = setting.Domain__c;
            cancelledEmailSubject   = setting.Email_Subject_Cancellation__c;
            cancelledEmailBody      = setting.Email_Body_Cancellation__c;
            cancelledSMSTemplate    = setting.SMS_Template_Cancellation__c;
            reminderEmailSubject   = setting.Email_Subject_Reminder__c;
            reminderEmailBody      = setting.Email_Body_Reminder__c;
            reminderSMSTemplate    = setting.SMS_Template_Reminder__c;
            showingVirtualSuccessfullyMessage = setting.Showing_Virtual_Successfully_Message__c;

            if (setting.Default_Setting__c != true) {
                if ( useDefault(logoUrl) ) logoUrl  = skedSetting.instance.defaultSiteSetting.logoUrl;
                if ( useDefault(siteDescription) ) siteDescription  = skedSetting.instance.defaultSiteSetting.siteDescription;
                if ( useDefault(senderEmail) ) senderEmail  = skedSetting.instance.defaultSiteSetting.senderEmail;
                if ( useDefault(testType) ) testType  = skedSetting.instance.defaultSiteSetting.testType;
                if ( useDefault(landingPage) ) landingPage  = skedSetting.instance.defaultSiteSetting.landingPage;
                if ( useDefault(surveyPage) ) surveyPage  = skedSetting.instance.defaultSiteSetting.surveyPage;
                if ( useDefault(verificationPage) ) verificationPage  = skedSetting.instance.defaultSiteSetting.verificationPage;
                if ( useDefault(confirmationPage) ) confirmationPage  = skedSetting.instance.defaultSiteSetting.confirmationPage;
                if ( useDefault(maintenancePage) ) maintenancePage  = skedSetting.instance.defaultSiteSetting.maintenancePage;
                if ( useDefault(ineligiblePage) ) ineligiblePage  = skedSetting.instance.defaultSiteSetting.ineligiblePage;
                if ( useDefault(screeningQuestionPage) ) screeningQuestionPage  = skedSetting.instance.defaultSiteSetting.screeningQuestionPage;
                if ( useDefault(emailSubject) ) emailSubject  = skedSetting.instance.defaultSiteSetting.emailSubject;
                if ( useDefault(emailBody) ) emailBody  = skedSetting.instance.defaultSiteSetting.emailBody;
                if ( useDefault(emailTemplate) ) emailTemplate  = skedSetting.instance.defaultSiteSetting.emailTemplate;
                if ( useDefault(smsTemplate) ) smsTemplate  = skedSetting.instance.defaultSiteSetting.smsTemplate;
                if ( useDefault(domain) ) domain  = skedSetting.instance.defaultSiteSetting.domain;
                if ( useDefault(cancelledEmailSubject) ) cancelledEmailSubject  = skedSetting.instance.defaultSiteSetting.cancelledEmailSubject;
                if ( useDefault(cancelledEmailBody) ) cancelledEmailBody  = skedSetting.instance.defaultSiteSetting.cancelledEmailBody;
                if ( useDefault(cancelledSMSTemplate) ) cancelledSMSTemplate  = skedSetting.instance.defaultSiteSetting.cancelledSMSTemplate;
                if ( useDefault(reminderEmailSubject) ) reminderEmailSubject  = skedSetting.instance.defaultSiteSetting.reminderEmailSubject;
                if ( useDefault(reminderEmailBody) ) reminderEmailBody  = skedSetting.instance.defaultSiteSetting.reminderEmailBody;
                if ( useDefault(reminderSMSTemplate) ) reminderSMSTemplate  = skedSetting.instance.defaultSiteSetting.reminderSMSTemplate;
                if ( useDefault(calendarTemplate) ) calendarTemplate  = skedSetting.instance.defaultSiteSetting.calendarTemplate;

                if ( searchDistance == null) searchDistance  = skedSetting.instance.defaultSiteSetting.searchDistance;
                if ( bufferDay == null) bufferDay  = skedSetting.instance.defaultSiteSetting.bufferDay;
            }

            return this;
        }

        public boolean useDefault (String value) {
            return String.isNotBlank(value) && value.containsIgnoreCase('default');
        }

        public void addQuestions(List<sked_Question__c> questions) {
            screeningQuestions  = new List<Question>();
            bookingQuestions    = new List<Question>();
            verificationQuestions    = new List<Question>();

            survey  = new Survey();
            survey.questions = new List<Question>();
            Set<String> dataTypesWithDefaultValue = new Set<String>{'Text', ''};
            for (sked_Question__c q : questions) {
                Question que = new Question().init(q);
                if (q.RecordType.Name == 'Screening') {
                    screeningQuestions.add( que );
                } else if (q.RecordType.Name == 'Booking') {
                    bookingQuestions.add( que );
                } else if (q.RecordType.Name == 'Verification') {
                    verificationQuestions.add( que );
                } else {
                    survey.questions.add( que );
                }
            }
        }
    }

    public class Survey extends BaseModel {
        @AuraEnabled
        public List<Question> questions {get;set;}
    }

    public class Question extends BaseModel {
        @AuraEnabled
        public String question {get;set;}

        @AuraEnabled
        public String dataType {get;set;}

        @AuraEnabled
        public List<String> options {get;set;}

        @AuraEnabled
        public String answer {get;set;}

        @AuraEnabled
        public List<Map<String, String>> optionFormats {get;set;}

        @AuraEnabled
        public String shortQuestion {get;set;}

        @AuraEnabled
        public String showIf {get;set;}

        @AuraEnabled
        public Question questionGroup {get;set;}

        @AuraEnabled
        public boolean required {get;set;}

        @AuraEnabled
        public Integer order {get;set;}

        @AuraEnabled
        public String fieldApiName {get;set;}

        @AuraEnabled
        public String defaultValue {get;set;}

        //Setters
        public Question init (sked_Question__c param) {
            id          = param.Id;
            name        = param.Name;
            shortQuestion     = param.Short_Question__c;
            showIf      = param.Show_If__c;
            question    = param.Question__c;
            dataType    = param.Data_Type__c;
            order       = param.Order__c == null? 100 : Integer.valueOf(param.Order__c);
            required    = param.Required__c;
            fieldApiName = param.Field_Api_Name__c;
            answer      = param.Default_Value__c;
            if (param.Answers__c != null && dataType != null && dataType.containsIgnoreCase('picklist')) {
                options     = split(param.Answers__c);
            }
            if (param.Group__c != null) {
                questionGroup = new Question();
                questionGroup.question = param.Group__r.Question__c;
            }
            //build question format
            if (String.isNotBlank( param.Option_Format__c )) {
                optionFormats = new List<Map<String, String>>();
                for (String format : param.Option_Format__c.split('---') ) {
                    if (String.isEmpty( format ) || format.trim() == '\r\n') continue;
                    Map<String, String> mapItems = new Map<String, String>();
                    for (String fi : split(format)) {
                        if (String.isBlank(fi) || !fi.containsIgnoreCase(':')) continue;
                        mapItems.put( fi.subStringBefore(':').trim(), fi.subStringAfter(':').trim() );
                    }
                    optionFormats.add(mapItems);
                }
            }
            return this;
        }

        public List<String> split (String str) {
            if (str.contains('\r\n')) return str.split('\r\n');
            return str.split('\n');
        }
    }

    global class Config {
        @AuraEnabled
        public SiteSetting siteSetting {get; set;}
        public String defaultSite;
    }

    global class JobCreationRequest {
        public JobModel job;
        public List<SurveyModel> surveys;
        public List<ResourceModel> availableResources;
        public Subscription subscription;
    }

    
}