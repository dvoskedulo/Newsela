/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-27-2021
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   01-27-2021   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
public class skedJobAllocationHandler {
    public static void onAfterInsert(List<sked__Job_Allocation__c> newJAs) {
        createAndUpdateEventFromJA(newJAs, null);
        sendEmailCustomer(newJAs);
    }

    public static void onAfterUpdate(List<sked__Job_Allocation__c> newJAs, Map<id, sked__Job_Allocation__c> map_id_oldJa) {
        createAndUpdateEventFromJA(newJAs, map_id_oldJa);
    }

    //===============================================private function=======================================//
    static void createAndUpdateEventFromJA(List<sked__Job_Allocation__c> newJAs, Map<id, sked__Job_Allocation__c> map_id_oldJa) {
        Set<id> jaIds = getJaIds(newJAs, map_id_oldJa);

        if (!jaIds.isEmpty()) {
            List<Event> events = generateEventFromJa(jaIds);
            if (!events.isEmpty()) {
                upsert events;
            }
        }
    }

    static Set<Id> getJaIds(List<sked__Job_Allocation__c> newJAs, Map<id, sked__Job_Allocation__c> map_id_oldJa) {
        Set<id> jaIds = new Set<id>();
        List<String> ignoreJaStatus = new List<String>{skedConstants.JA_STATUS_PENDING_DISPATCH, skedConstants.JA_STATUS_DECLINED, skedConstants.JA_STATUS_DELETED};

        for (sked__Job_Allocation__c ja : newJAs) {
            if (!ignoreJaStatus.contains(ja.sked__Status__c)) {
                if (map_id_oldJa != null) {
                    sked__Job_Allocation__c oldJA = map_id_oldJa.get(ja.id);
                    if (oldJA.sked__status__c != ja.sked__Status__c) {
                        jaIds.add(ja.id);
                    }
                }
                else {
                    jaIds.add(ja.id);
                }
                
            }
        }

        return jaIds;
    }

    static List<Event> generateEventFromJa(Set<id> jaIds) {
        Map<id, id> map_jaID_eventId = new Map<id, id>();
        List<Event> events = new List<Event>();

        for (Event evt : [select id, sked__Job_Allocation__c from Event where sked__Job_Allocation__c in :jaIds]) {
            map_jaID_eventId.put(evt.sked__Job_Allocation__c, evt.id);
        }

        for (sked__Job_Allocation__c ja : [SELECT Id, Name, sked__Job__r.sked__Contact__c, sked__Job__r.sked__Contact__r.Phone,sked__Job__r.sked__Account__c, 
                                                sked__Resource__r.sked__User__c, sked__Job__r.sked__Address__c, sked__Job__r.sked__Account__r.Name, 
                                                sked__Job__r.sked__Contact__r.Name, sked__Job__r.Name, sked__Job__r.sked__Start__c, sked__Job__r.sked__Finish__c,
                                                sked__Job__r.sked__Timezone__c, sked__Job__r.sked__Notes_Comments__c , sked__Job__r.sked__Type__c, 
                                                sked__Job__r.sked__Location__r.Name, sked__job__r.Event_Subject__c, sked__Job__r.Subscription_Number__c,
                                                sked__Job__r.sked_Additional_Details__c, sked__Job__r.sked__Virtual_Meeting_URL__c, sked__Job__r.sked_Appointment_Type__c, 
                                                sked__Job__r.sked_Event_Record_Type__c, sked__Job__r.Activity_Medium__c, sked__Job__r.Subscription_Number__r.TrainingContact__c, 
                                                sked__Job__r.Session_Delivered__c, sked__Resource__r.Name, sked__Resource__r.sked__Primary_Phone__c, sked__Resource__r.sked__Mobile_Phone__c,
                                                sked__Resource__r.sked__Email__c
                                            FROM sked__Job_Allocation__c 
                                            WHERE Id IN :jaIDs 
                                            and sked__Job__r.sked__Start__c != null 
                                            and sked__Job__r.sked__Finish__c != null 
                                            and sked__Resource__r.sked__User__c!=null]) {
            Event evt = syncDataFromJaToEvent(ja);
            
            if(ja.sked__Job__r.Subscription_Number__c != null && ja.sked__Job__r.Subscription_Number__r.TrainingContact__c != null){
                evt.WhoID     = ja.sked__Job__r.Subscription_Number__r.TrainingContact__c;
            } 

            evt.id =  map_jaID_eventId.get(ja.id);
            events.add(evt);
        }
		
        return events;
    }

    static Event syncDataFromJaToEvent(sked__Job_Allocation__c ja) {
        string subject = 'Newsela Professional Learning';
        if (ja.sked__Job__r.Activity_Medium__c != null) {
            subject += ' - ' + ja.sked__Job__r.Activity_Medium__c;
        }
        if (ja.sked__Job__r.sked__Account__c != null) {
            subject += ' - ' + ja.sked__Job__r.sked__Account__r.Name;
        }
        subject += ' - ' + ja.sked__Job__r.sked__Start__c.format(skedDateTimeUtils.DATE_FORMAT, ja.sked__Job__r.sked__Timezone__c);

        Id eventRecordType = Schema.SObjectType.Event.getRecordTypeInfosByName().get(ja.sked__Job__r.sked_Event_Record_Type__c).getRecordTypeId();
        Event e = new Event(
            OwnerId                     = ja.sked__Resource__r.sked__User__c,
            WhatId                      = ja.sked__Job__r.Subscription_Number__c,
            Location                    = ja.sked__Job__r.sked__Virtual_Meeting_URL__c != null ? ja.sked__Job__r.sked__Virtual_Meeting_URL__c : ja.sked__Job__r.sked__Address__c,
            StartDateTime               = ja.sked__Job__r.sked__Start__c,
            EndDateTime                 = ja.sked__Job__r.sked__Finish__c,
            sked__Job_Allocation__c     = ja.Id,
            Subject                     = subject,
            RecordTypeId                = eventRecordType,
            Activity_Medium__c          = ja.sked__Job__r.Activity_Medium__c,
            Session_Delivered__c        = ja.sked__job__r.Session_Delivered__c,
            Description                 = ja.sked__job__r.sked_Additional_Details__c
        );
		
        return e;
    }

    static void sendEmailCustomer(List<sked__Job_Allocation__c> newRecords) {
        List<string> jobIds = new List<string>();
        for (sked__Job_Allocation__c ja : [SELECT Id, sked__Job__c, sked__Job__r.sked__Type__c, sked__Job__r.sked_Delivery_Method__c
                                           FROM sked__Job_Allocation__c 
                                           WHERE Id IN :newRecords]) {
            if (!ja.sked__Job__r.sked__Type__c.contains(skedConstants.JOB_TYPE_VIRTUAL) 
                    || ja.sked__Job__r.sked_Delivery_Method__c.contains('Asynchronous')) {
                jobIds.add(ja.sked__Job__c);
            }
        }
        if (!jobIds.isEmpty()) {
            skedEmailUtil.sendEmailCustomer(jobIds);
        }
    }
}