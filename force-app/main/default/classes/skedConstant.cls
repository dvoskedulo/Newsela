/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 02-03-2021
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   02-03-2021   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
public class skedConstant {
    
    public static final list<string> DAY_OF_WEEK = new list<string>{'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'};

    public static final string JOB_ALLOCATION_STATUS_DELETED = 'Deleted';
    public static final string JOB_ALLOCATION_STATUS_CANCELLED = 'Cancelled';
    public static final string JOB_ALLOCATION_STATUS_DISPATCHED = 'Dispatched';
    public static final string JOB_ALLOCATION_STATUS_COMPLETE = 'Complete';
    public static final string JOB_ALLOCATION_STATUS_DECLINED = 'Declined';
    public static final string JOB_ALLOCATION_STATUS_PENDING_DISPATCH = 'Pending Dispatch';
    public static final string JOB_ALLOCATION_STATUS_CONFIRMED = 'Confirmed';
    
    public static final string JOB_STATUS_QUEUED = 'Queued';
    public static final string JOB_STATUS_PENDING_ALLOCATION = 'Pending Allocation';
    public static final string JOB_STATUS_PENDING_DISPATCH = 'Pending Dispatch';
    public static final string JOB_STATUS_DISPATCHED = 'Dispatched';
    public static final string JOB_STATUS_READY = 'Ready';
    public static final string JOB_STATUS_EN_ROUTE = 'En Route';
    public static final string JOB_STATUS_ON_SITE = 'On Site';
    public static final string JOB_STATUS_IN_PROGRESS = 'In Progress';
    public static final string JOB_STATUS_COMPLETE = 'Complete';
    public static final string JOB_STATUS_DELETED = 'Deleted';
    public static final string JOB_STATUS_CANCELLED = 'Cancelled';

    //====================================================================================

    public static final string HOLIDAY_GLOBAL = 'global';
    public static final string RESOURCE_TYPE_PERSON = 'Person';
    public static final string RESOURCE_TYPE_ASSET = 'Asset';  
    
    //====================================================================================

    public static final String EVENT_TYPE_JOB = 'Job';
    public static final string EVENT_TYPE_ALLOCATION = 'Job Allocation';
    public static final string EVENT_TYPE_ACTIVITY = 'Activity';
    public static final string EVENT_TYPE_AVAILABILITY = 'Availability';
    public static final string EVENT_TYPE_NON_WORKING = 'non-working';

    //====================================================================================
    public static final string LOCATION_API_NAME = 'sked__Location__c';
    public static final string SUBSCRIPTION_API_NAME = 'sked_Subscription';
    public static final string RESOURCE_API_NAME = 'sked__Resource__c';
    public static final string REGION_API_NAME = 'sked__Region__c';
    public static final string ACCOUNT_API_NAME = 'Account';
    public static final string ACCOUNT_TIER_API_NAME = 'Account_Tier__c';

    //Job types
    public static final string JOB_TYPE_VIRTUAL = 'Virtual';
    public static final string JOB_TYPE_IN_PERSON = 'In-Person';
    public static final string JOB_TYPE_CALL = 'Call';
    public static final string JOB_TYPE_WEBINAR = 'Webinar';

}