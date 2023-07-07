public class skedActivityHandler {
    public static boolean isFromEvent = false;
    public static void onAfterInsert(List<sked__Activity__c> newActs) {
        syncActivitiesToEvents(newActs);
    }

    public static void onAfterUpdate(List<sked__Activity__c> newActs, Map<id, sked__Activity__c> map_id_oldAct) {
        syncActivitiesToEvents(newActs);
    }

    //==============================================================Private functions===============================================//
    /*
    * Sync Activities to Event when Activities are upserted
    */
    static void syncActivitiesToEvents(list<sked__Activity__c> activityList){
        if( activityList==null || activityList.isEMpty() || isFromEvent) return;
        //Get source activities (i.e Activities that are not referencing to other events)
        list<sked__Activity__c> sourceList = new list<sked__Activity__c>();
        for(sked__Activity__c a : activityList){
            System.debug('a activity after insert ' + a);
            if( String.isBlank(a.sked__Event_Id__c)) sourceList.add( a );
        }
        if(sourceList.isEmpty()) return;
        System.debug('sourceList ' + sourceList);
        list<Event> eventsToUpsert = new list<Event>();
        list<ID> resourceIDs    = new list<ID> ();
        list<String> activityIDs    = new list<String> ();

        for(sked__Activity__c act: sourceList){
            if(act.sked__Resource__c != null){
                resourceIDs.add(act.sked__Resource__c);
                activityIDs.add( act.Id );
            }
        }
        //Map Resource ID to Resource to get User's Id 
        map<id,sked__Resource__c> map_Id_Res = new map<id,sked__Resource__c>([select id , sked__User__c from sked__Resource__c where id in:resourceIDs and sked__User__c != null]);
        //Search for related Events
        list<Event> relatedEvents = [Select Id, sked__Activity__c from Event where sked__Activity__c IN :activityIDs];
        Map<Id,Id> mapActivityIdToEventId = new Map<Id,Id>();
        for( Event e : relatedEvents ){
            mapActivityIdToEventId.put( Id.valueOf(e.sked__Activity__c), e.Id );
        }

        for(sked__Activity__c act: sourceList){
            if(act.sked__Resource__c != null && map_Id_Res.containskey(act.sked__Resource__c)){
                Id eventId = mapActivityIdToEventId.containsKey( act.Id )? mapActivityIdToEventId.get( act.Id ) : null;
                eventsToUpsert.add( 
                    syncActivityToEvent(act, map_Id_Res.get(act.sked__Resource__c).sked__User__c, eventId)
                );
            }
        }

        if(eventsToUpsert.size() > 0){
            upsert eventsToUpsert;
        }   
    }

    /*
    * Sync an Activity to an Event
    */
    static Event syncActivityToEvent(sked__Activity__c activity, Id userId, Id eventId){
        Event event = new Event(
            Subject         = activity.sked__Type__C,
            OwnerId         = userId,
            Location        = activity.sked__Address__c,
            StartDateTime   = activity.sked__Start__c,
            EndDateTime     = activity.sked__End__c,
            Description     = activity.sked__Notes__c,
            sked__Activity__c  = activity.Id
        );
        if(eventId != null){//Update an existing event
            event.Id    = eventId;
        }
        return event;
    }
}