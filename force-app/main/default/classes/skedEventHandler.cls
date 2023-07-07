/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-09-2021
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   02-04-2021   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
public class skedEventHandler {
    public static void onBeforeInsert(List<Event> newRecords) {
        populateData(newRecords);
    }

    private static void populateData(List<Event> newRecords) {
        List<Id> jaIds = new List<Id>();

        for (Event ev : newRecords) {
            if (ev.sked__Job_Allocation__c != NULL) {
                jaIds.add(ev.sked__Job_Allocation__c);
            }
        }

        if (!jaIds.isEmpty()) {
            Map<Id, string> mapDescription = buildMapDescription(jaIds);
            for (Event ev : newRecords) {
                if (ev.sked__Job_Allocation__c != NULL) {
                    ev.Description = mapDescription.get(ev.sked__Job_Allocation__c);
                }
            }
        }
    }

    public static Map<Id, string> buildMapDescription(List<Id> jaIds) {
        Map<Id, string> result = new Map<Id, string>();

        for (sked__Job_Allocation__c ja : [SELECT Id, Name, sked__Job__r.sked__Contact__c, sked__Job__r.sked__Contact__r.Phone,sked__Job__r.sked__Account__c, 
                                                sked__Resource__r.sked__User__c, sked__Job__r.sked__Address__c, sked__Job__r.sked__Account__r.Name, 
                                                sked__Job__r.sked__Contact__r.Name, sked__Job__r.Name, sked__Job__r.sked__Start__c, sked__Job__r.sked__Finish__c,
                                                sked__Job__r.sked__Timezone__c, sked__Job__r.sked__Notes_Comments__c , sked__Job__r.sked__Type__c, 
                                                sked__Job__r.sked__Location__r.Name, sked__job__r.Event_Subject__c, sked__Job__r.Subscription_Number__c,
                                                sked__Job__r.sked_Additional_Details__c, sked__Job__r.sked__Virtual_Meeting_URL__c, sked__Job__r.sked_Appointment_Type__c, 
                                                sked__Resource__r.Name, sked__Resource__r.sked__Primary_Phone__c, sked__Resource__r.sked__Mobile_Phone__c,
                                                sked__Resource__r.sked__Email__c
                                            FROM sked__Job_Allocation__c 
                                            WHERE Id IN :jaIds]) {
            result.put(ja.Id, buildEventDescription(ja));
        }
        return result;
    }

    public static void updateEventLocation(List<sked__Job_Allocation__c> skedJAs) {
        Map<Id, sked__Job_Allocation__c> mapJAs = 
                new Map<Id, sked__Job_Allocation__c>([SELECT Id, sked__Job__r.sked__Virtual_Meeting_URL__c 
                                                      FROM sked__Job_Allocation__c 
                                                      WHERE Id IN :skedJAs]);
        List<Event> events = [SELECT Id, sked__Job_Allocation__c, Location FROM Event WHERE sked__Job_Allocation__c IN :mapJAs.keySet()];
        for (Event ev : events) {
            sked__Job_Allocation__c ja = mapJAs.get(ev.sked__Job_Allocation__c);
            if (ja.sked__Job__r.sked__Virtual_Meeting_URL__c != null) {
                ev.Location = ja.sked__Job__r.sked__Virtual_Meeting_URL__c;
            }
        }
        update events;
    }

    static string buildEventDescription(sked__Job_Allocation__c jobAllocation) {
        string description = jobAllocation.sked__Job__r.sked_Appointment_Type__c.contains(skedConstants.APPOINTMENT_TYPE_VIRTUAL) 
                                ? System.Label.Skedulo_Virtual_Calendar_Template 
                                : (jobAllocation.sked__Job__r.sked_Appointment_Type__c.contains(skedConstants.APPOINTMENT_TYPE_IN_PERSON) ? System.Label.Skedulo_In_Person_Calendar_Template : System.Label.Skedulo_Call_Calendar_Template);
        
        description = description.replace('[SESSION TYPE]', jobAllocation.sked__Job__r.sked__Type__c);
        description = description.replace('[DATE]', jobAllocation.sked__Job__r.sked__Start__c.format(skedDateTimeUtils.DATE_FORMAT, jobAllocation.sked__Job__r.sked__Timezone__c));
        description = description.replace('[TIME DURATION]', jobAllocation.sked__Job__r.sked__Start__c.format(skedDateTimeUtils.TIME_FORMAT, jobAllocation.sked__Job__r.sked__Timezone__c));
        description = description.replace('[RESOURCE NAME]', jobAllocation.sked__Resource__r.Name);
        description = description.replace('[QUESTIONS AND ANSWERS]', nullToBlank(jobAllocation.sked__Job__r.sked_Additional_Details__c));
        description = description.replace('[ZOOM LINK]', nullToBlank(jobAllocation.sked__Job__r.sked__Virtual_Meeting_URL__c));
        description = description.replace('[LOCATION]', nullToBlank(jobAllocation.sked__Job__r.sked__Address__c));
        description = description.replace('[PHONE NUMBER]', nullToBlank(string.isNotBlank(jobAllocation.sked__Resource__r.sked__Primary_Phone__c) ?
                                                jobAllocation.sked__Resource__r.sked__Primary_Phone__c :
                                                jobAllocation.sked__Resource__r.sked__Mobile_Phone__c));
        description = description.replace('[RESOURCE EMAIL]', nullToBlank(jobAllocation.sked__Resource__r.sked__Email__c));
        description = description.replace('<br/>', '');
        description = description.replace('<p>', '');
        description = description.replace('</p>', '');

        return description;
    }

    static String nullToBlank(String value) {
        return (String.isBlank(value) ? '' : value);
    }
}