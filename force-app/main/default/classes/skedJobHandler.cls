/**
 * @description       :
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             :
 * @last modified on  : 02-04-2021
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log
 * Ver   Date         Author                               Modification
 * 1.0   01-26-2021   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
public class skedJobHandler {

    public static void onBeforeInsert(List<sked__Job__c> newJobs) {
        populateActivityMedium(newJobs);
    }

    public static void onAfterInsert(List<sked__Job__c> newJobs) {

    }

    public static void onAfterUpdate(List<sked__Job__c> newJobs, Map<id, sked__Job__c> oldData) {
        updateRelatedEvent(newJobs, oldData);
    }

    //===========================================Private function==========================================//
    static void updateRelatedEvent(List<sked__Job__c> newJobs, Map<id, sked__Job__c> oldData) {
        Set<id> updatedJobIds = getJobIdsNeedToUpdateEvent(newJobs, oldData);

        if (!updatedJobIds.isEmpty()) {
            List<id> jaIds = getJaIdsNeedToUpdateEvent(updatedJobIds);

            if (!jaIds.isEmpty()) {
                updateRelatedEvent(jaIds);
            }
        }
    }

    static Set<id> getJobIdsNeedToUpdateEvent(List<sked__Job__c> newJobs, Map<id, sked__Job__c> oldData) {
        Set<id> updatedJobIds = new Set<id>();

        for (sked__Job__c newJob : newJobs) {
            sked__Job__c oldJob = oldData.get(newJob.id);
            if (newJob.Event_Subject__c != oldJob.Event_Subject__c || newJob.Provisioning_Number__c != oldJob.Provisioning_Number__c
                || newJob.sked_Event_Record_Type__c != oldJob.sked_Event_Record_Type__c || newJob.sked__Job_Status__c != oldJob.sked__Job_Status__c
                || newJob.sked__Description__c != oldJob.sked__Description__c
                || newJob.Activity_Medium__c != oldJob.Activity_Medium__c || newJob.sked__Address__c != oldJob.sked__Address__c
                || newJob.sked__Start__c != oldJob.sked__Start__c || newJob.sked__Finish__c != oldJob.sked__Finish__c
                || newJob.Session_Delivered__c != oldJob.Session_Delivered__c
                || newJob.sked__Abort_Reason__c != oldJob.sked__Abort_Reason__c
                || newJob.sked__Virtual_Meeting_URL__c != oldJob.sked__Virtual_Meeting_URL__c
                ) {
                    updatedJobIds.add(newJob.id);
            }
        }

        return updatedJobIds;
    }

    static List<id> getJaIdsNeedToUpdateEvent(Set<id> jobIds) {
        List<id> jaIds = new List<id>();
        List<String> ignoreJaStatus = new List<String>{skedConstants.JA_STATUS_COMPLETE, skedConstants.JA_STATUS_DECLINED, skedConstants.JA_STATUS_DELETED};

        for (sked__job_allocation__c ja : [select id
                                            from sked__job_allocation__c
                                            where sked__Job__c in : jobIds
                                            and sked__status__c not in :ignoreJaStatus]) {
            jaIds.add(ja.id);
        }

        return jaIds;
    }

    static void updateRelatedEvent(List<id> jaIds) {
        Map<Id, Event> map_id_event = new Map<Id, event>([SELECT Id, sked__Job_Allocation__c FROM Event WHERE sked__Job_Allocation__c in :jaIds]);
        Map<Id, string> mapDescription = skedEventHandler.buildMapDescription(jaIds);

        if (!map_id_event.isEmpty()) {
            for (Event ev : map_id_event.values()) {
                ev.Description = mapDescription.get(ev.sked__Job_Allocation__c);
            }
            update map_id_event.values();
        }
    }

    static void populateActivityMedium(List<sked__Job__c> newJobs) {
        String defActMedium = 'Webinar - PLC';
        Map<String, String> deliveryActMediumMap = new Map<String, STring>();

        for ( sked_Delivery_Method_Setting__mdt config : [
            SELECT sked_Delivery_Method__c, sked_Activity_Medium__c
            FROM sked_Delivery_Method_Setting__mdt
            WHERE sked_Active__c = TRUE
        ]) {
            deliveryActMediumMap.put(config.sked_Delivery_Method__c, config.sked_Activity_Medium__c);
        }

        for (sked__Job__c job : newJobs) {
            job.Activity_Medium__c = defActMedium;

            if (deliveryActMediumMap.containsKey(job.sked_Delivery_Method__c)) {
                job.Activity_Medium__c = deliveryActMediumMap.get(job.sked_Delivery_Method__c);
            }
        }
    }
}