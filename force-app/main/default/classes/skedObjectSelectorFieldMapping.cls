/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 03-11-2021
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   03-11-2021   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
public class skedObjectSelectorFieldMapping {
    public Map<Schema.sObjectType,Set<String>> mapObjectType2Fields = new Map<Schema.sObjectType, Set<String>>{
        Account.sObjectType => new Set<String> {
            'id', 'Name', 'Timezone_c__c', 'Regions__c'
        },
        sked_Subscription__c.sObjectType => new Set<String> {
            'id', 'Name', 'sked_Account__c', 'sked_Custom_URL__c', 'sked_Product_Type__c', 'sked_Total_available_credits__c'
        },
        sked__Location__c.sObjectType => new Set<String> {
            'id', 'Name', 'sked__GeoLocation__c', 'sked__Address__c', 'sked__Region__c', 'sked__Region__r.Id', 'sked__Region__r.Name', 'sked__Region__r.sked__Timezone__c'
        },
        sked__Region__c.sObjectType => new Set<String> {
            'id', 'Name', 'sked__Timezone__c'
        },
        sked__Resource__c.sObjectType => new Set<String> {
            'Id','Name','sked__User__r.SmallPhotoUrl','sked__User__c','sked__Category__c','sked__Home_Address__c','sked__Primary_Region__r.Name','sked__Primary_Region__c','sked__Primary_Region__r.sked__Timezone__c',
            'sked__GeoLocation__c','sked__GeoLocation__Latitude__s','sked__GeoLocation__Longitude__s','sked__Resource_Type__c', 'sked_Resource_Group__c'
        },
        sked__Job_Allocation__c.sObjectType => new Set<String> {
            'Id','Name','sked__Job__c','sked__Job__r.Name','sked__Job__r.sked__Type__c','sked__Job__r.sked__Start__c','sked__Job__r.sked__Finish__c','sked__Job__r.sked__Timezone__c',
            'sked__Job__r.sked__GeoLocation__Latitude__s','sked__Resource__c','sked__Job__r.sked__GeoLocation__Longitude__s','sked__Job__r.sked__GeoLocation__c','sked__Job__r.sked__Account__c',
            'sked__Job__r.sked__Account__r.Name','sked__Job__r.sked__Address__c'
        },
        sked__Activity__c.sObjectType => new Set<String> {
            'Id','Name','sked__Start__c','sked__End__c','sked__Address__c','sked__GeoLocation__c','sked__Timezone__c', 'sked__Type__c','sked__GeoLocation__Longitude__s','sked__GeoLocation__Latitude__s'
        },
        sked__Availability__c.sObjectType => new Set<String> {
            'Id','Name','sked__Start__c','sked__Finish__c','sked__Is_Available__c','sked__Status__c','sked__Timezone__c','sked__Type__c'
        },
        SBQQ__Subscription__c.sObjectType => new Set<String> {
            'Id','Name','SBQQ__Product__c', 'SBQQ__Product__r.Id', 'SBQQ__Product__r.Name', 'SBQQ__Product__r.Family', 'SBQQ__Product__r.Product_Sub__c', 'Total_number_of_sessions__c','Account_Provisioned__c', 'Account_Provisioned__r.Id', 
            'Account_Provisioned__r.Name', 'Account_Provisioned__r.Timezone_c__c', 'PD_Events_Scheduled__c', 'SBQQ__StartDate__c','SBQQ__EndDate__c', 'Account_Provisioned__r.Skedulo_Territory__c'
        },
        Product2.sObjectType => new Set<String> {
            'Id','Name','Family','Product_Sub__c'
        },
        Site_Setting__c.sObjectType => new Set<String>{
            'Id',
            'Name',
            'Logo_Url__c',
            'Site_Description__c',
            'Test_Code__c',
            'Default_Ordering_Provider__c',
            'Landing_Page__c',
            'Confirmation_Page__c',
            'Email_Template__c',
            'Ineligible_Page__c',
            'Maintenance_Page__c',
            'Screening_Question__c',
            'SMS_Template__c',
            'Default_Setting__c',
            'Email_Subject__c',
            'Email_Body__c',
            'SendGrid_Email__c',
            'Survey_Page__c',
            'Domain__c',
            'Email_Subject_Cancellation__c',
            'Email_Body_Cancellation__c',
            'SMS_Template_Cancellation__c',
            'Search_Distance__c',
            'Email_Subject_Reminder__c',
            'Email_Body_Reminder__c',
            'SMS_Template_Reminder__c',
            'Reminder_Options__c',
            'Calendar_Template__c',
            'Default_Site__c',
            'Enable_Booking_Questions__c',
            'Service_Filter_On_Off__c',
            'Clear_Patient_Info_After__c',
            'Suppressed_Date_of_Service__c',
            'Verification_Page__c',
            'Buffer_Day__c',
            'MP_Test_Code__c',
            'Verification_Error__c',
            'Showing_Virtual_Successfully_Message__c'
        },
        sked_Question__c.sObjectType => new Set<String>{
            'Id',
            'Name',
            'Question__c',
            'Site_Setting__c',
            'Is_Active__c',
            'RecordTypeId',
            'RecordType.Name',
            'Short_Question__c',
            'Answers__c',
            'Data_Type__c',
            'Required__c',
            'Group__c',
            'Show_If__c',
            'Group__r.Id',
            'Group__r.Name',
            'Group__r.Question__c',
            'Order__c',
            'Option_Format__c',
            'Field_Api_Name__c',
            'AOE__c',
            'Default_Value__c'
        }

    };
}