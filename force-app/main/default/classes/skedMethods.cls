/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-09-2021
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   03-11-2021   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
public with sharing class skedMethods {

    //Moved Sked Methods from their skedeventhandler as we have our own.  These get called from EventTriggerHandler
     public void updateInforFromJob (List<Event> newEvents) {
        Map<id, Event> map_jaID_event = new Map<id, Event>();

        for (Event evt : newEvents) {
            if (String.isNotBlank(evt.sked__Job_Allocation__c)) {
                map_jaID_event.put(evt.sked__Job_Allocation__c, evt);
            }
        }

        if (!map_jaID_event.isEmpty()) {
            for (sked__Job_Allocation__c ja : [select id, sked__job__c,sked__Job__r.Subscription_Number__c, sked__Job__r.name, sked__Job__r.Provisioning_Number__c, sked__job__r.sked_Event_Record_Type__c,
                                                sked__Job__r.sked__Job_Status__c, sked__Job__r.sked__Description__c, sked__Job__r.Activity_Medium__c,
                                                sked__job__r.Event_Subject__c, sked__job__r.Session_Delivered__c, sked__Job__r.sked__Address__c,
                                                sked__Job__r.sked__Start__c, sked__Job__r.sked__Finish__c, sked__Job__r.sked__Timezone__c,
                                                sked__Job__r.sked__Account__c, sked__Job__r.sked__Account__r.Name, sked__Job__r.sked__Virtual_Meeting_URL__c,
                                                sked__Job__r.sked__Abort_Reason__c
                                                from sked__Job_Allocation__c
                                                where id in :  map_jaID_event.keySet()
                                                ]) {
                if (map_jaID_event.containsKey(ja.id)) {
                    string subject = 'Newsela Professional Learning';
                    if (ja.sked__Job__r.Activity_Medium__c != null) {
                        subject += ' - ' + ja.sked__Job__r.Activity_Medium__c;
                    }
                    if (ja.sked__Job__r.sked__Account__c != null) {
                        subject += ' - ' + ja.sked__Job__r.sked__Account__r.Name;
                    }
                    subject += ' - ' + ja.sked__Job__r.sked__Start__c.format(skedDateTimeUtils.DATE_FORMAT, ja.sked__Job__r.sked__Timezone__c);

                    Event evt = map_jaID_event.get(ja.id);
                    system.debug('before Update event '+evt);
                    evt.Activity_Status__c = getEventStatusFromJobStatus(ja.sked__Job__r.sked__Job_Status__c);
                    evt.Subject = subject;
                    //evt.WhatId = ja.sked__Job__r.Provisioning_Number__c;
                      evt.WhatId = ja.sked__Job__r.Subscription_Number__c;
                    
                    if (String.isNotBlank(ja.sked__job__r.sked_Event_Record_Type__c)) {
                        evt.RecordTypeId = getEventRecordTypeIdFromName(ja.sked__job__r.sked_Event_Record_Type__c);
                    }
                    
                    if (ja.sked__Job__r.sked__Abort_Reason__c != null) {
                        evt.Activity_Result__c = ja.sked__Job__r.sked__Abort_Reason__c;
                    }
                    
                    evt.Description = ja.sked__Job__r.sked__Description__c;
                    evt.Activity_Medium__c = ja.sked__Job__r.Activity_Medium__c;
                    evt.Session_Delivered__c = ja.sked__job__r.Session_Delivered__c;
                    evt.Location = ja.sked__Job__r.sked__Virtual_Meeting_URL__c != null ? ja.sked__Job__r.sked__Virtual_Meeting_URL__c : ja.sked__Job__r.sked__Address__c;
                    evt.StartDateTime = ja.sked__job__r.sked__Start__c;
                    evt.EndDateTime = ja.sked__job__r.sked__finish__c;
                    evt.ActivityDateTime = ja.sked__job__r.sked__start__c;
                    system.debug('Update event '+evt);
                }                                    
            }
        }
    }

    private static string getEventStatusFromJobStatus(string jobStatus) {
        if (jobStatus.equalsIgnoreCase(skedConstants.JOB_STATUS_COMPLETE)) {
            return skedConstants.EVENT_STATUS_CLOSED_COMPLETE;
        }
        else if (jobStatus.equalsIgnoreCase(skedConstants.JOB_STATUS_CANCELLED)) {
            return skedConstants.EVENT_STATUS_CLOSED_NOT_COMPLETED;
        }

        return skedConstants.EVENT_STATUS_OPEN;
    }

    private static string getEventRecordTypeIdFromName(string evtRecordTypeName) {
        return Schema.SObjectType.Event.getRecordTypeInfosByName().get(evtRecordTypeName).getRecordTypeId();
    }

    public void syncEventsToActivities(List<Event> newEvents, boolean isUpdate) {
        system.debug('1 Im in the afterupdate');
        if(newEvents==null || newEvents.isEMpty()) return;
        //Get source activities (i.e Activities that are not referencing to other events)
        list<Event> sourceList = new list<Event>();
        for(Event a : newEvents){
            if(!String.isBlank(a.sked__Activity__c)) continue;
            if(a.IsRecurrence) continue;//Do not sync Calendar Series
            if(String.isNotBlank(a.sked__Job_Allocation__c)) continue; 
            sourceList.add( a );
        }
        if(sourceList.isEmpty()) return;

        list<id> lstWhoIDs = new list<id>();
        list<String> eventIDs   = new list<String> ();

        for(Event e: sourceList){
            lstWhoIDs.add(e.OwnerId);
            eventIDs.add( e.Id );
        }
    
        list<sked__Resource__c> lstRes = [select id,sked__Home_Address__c , sked__User__c from sked__Resource__c where sked__User__c in:lstWhoIDS];
        map<id,sked__Resource__c> map_User_Res = new map<id,sked__Resource__c>();

        for(sked__Resource__c res: lstRes){
            map_User_Res.put(res.sked__User__c,res);
        }
        //Search for related activities
        list<sked__Activity__c> relatedActivities = [Select Id, sked__Event_Id__c from sked__Activity__c where sked__Event_Id__c IN :eventIDs order by Name asc];
        Map<Id,Id> mapEventIdToActivityId = new Map<Id,Id>();
        for( sked__Activity__c a : relatedActivities ){
            mapEventIdToActivityId.put( Id.valueOf(a.sked__Event_Id__c), a.Id );
        }

        list<sked__Activity__c> activitiesToUpsert = new list<sked__Activity__c>();
        Set<Id> activitiesToDelete = new Set<Id>();

        for(Event e: sourceList){
            Id aId = mapEventIdToActivityId.containsKey( e.Id )? mapEventIdToActivityId.get( e.Id ) : null;
            if(isUpdate && aId==null) continue;
            if(e.ShowAs == 'Free'){
                activitiesToDelete.add(aId);
                continue;
            }else if(map_User_Res.containskey(e.OwnerId)){
                activitiesToUpsert.add( syncEventToActivity(e, map_User_Res.get(e.OwnerId), aId) );
            }
        }

        if(activitiesToUpsert.size() > 0){
            Schema.SObjectField eventID = sked__Activity__c.sked__Event_Id__c.getDescribe().getSObjectField();
            skedActivityHandler.isFromEvent = true;
            Database.upsert(activitiesToUpsert, eventID, false)  ;
        }
        if(!activitiesToDelete.isEmpty()) Database.delete([select Id from sked__Activity__c where Id IN :activitiesToDelete]);
    
    }

    /*
    * Sync an Event to an Activity
    */
    public static sked__Activity__c syncEventToActivity(Event e, sked__Resource__c resource, Id activityId){
        System.debug(e.StartDateTime);
        System.debug(e.EndDateTime);
        sked__Activity__c a = new sked__Activity__c(
            sked__Type__C       = e.Subject,
            //sked__Notes__c      = e.Description,
            sked__Start__c      = e.StartDateTime,
            sked__End__c        = e.EndDateTime,
            sked__Address__c    = e.Location, 
            sked__Event_Id__c         = e.Id,
            sked__Resource__c   = resource.id
        );
        
        if(activityId != null){//Update an existing activity
            a.Id    = activityId;
        }

        System.debug('a activity before insert ' + a);
        return a;
    }

    /*
    * Delete Activities related to deleted events
    */
    public void deleteActivities(list<Event> events){
        Set<Id> eventIDs = new Set<Id>();
        Set<String> activityIDs = new Set<String>();
        for( Event e : events ){
            eventIDs.add( e.Id );
            if(!String.isBlank(e.sked__Activity__c)) activityIDs.add(e.sked__Activity__c);
        }
        list<sked__Activity__c> aList = [Select Id from sked__Activity__c where sked__Event_Id__c IN :eventIDs or Id IN :activityIDs];
        if( !aList.isEmpty() ) Database.delete( aList );
    }

    /*
    * Delete related events when an event series is deleted
    */
    public void deleteEventSeries(list<Event> events){
        Set<Id> eventSeriesID = new Set<Id>();
        for(Event e : events){
            if(e.IsRecurrence == true && e.Id == e.RecurrenceActivityId){
                eventSeriesID.add( e.Id );
            }
        }
        if(!eventSeriesID.isEmpty()) Database.delete([Select Id from Event where RecurrenceActivityId IN :eventSeriesID and (NOT ID IN :events)]);
    }
}