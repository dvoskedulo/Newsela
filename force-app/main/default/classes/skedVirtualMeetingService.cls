/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-09-2021
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   01-25-2021   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
public class skedVirtualMeetingService {
    private static final string STR_ZOOM = 'zoom';
    private static final string STR_AGENDA = 'agenda';
    private static final string STR_TOPIC = 'topic';
    private static final string STR_HOST_RESOURCE_ID = 'hostResourceId';
    private static final string STR_START_TIME = 'startTime';
    private static final string STR_DURATION = 'duration';
    private static final string STR_PASSWORD = 'password';

    /********************************************* PUBLIC METHODS *********************************************/
    public static skedSkeduloApiData.virtualMeeting getMeetingDetails(String meetingId) {
        Map<String, skedSkeduloApiData.virtualMeeting> result = getMeetingDetails(new Set<String>{ meetingId });
        return result.isEmpty() ? null : result.values().get(0);
    }

    // get the detail of a list of zoom meetings
    public static Map<String, skedSkeduloApiData.virtualMeeting> getMeetingDetails(Set<String> meetingIds) {
        Map<String, skedSkeduloApiData.virtualMeeting> result = new Map<String, skedSkeduloApiData.virtualMeeting>();

        skedSkeduloApiManager apiManager = new skedSkeduloApiManager();
        for (String meetingId : meetingIds) {
            skedSkeduloApiData.virtualMeetingResult calloutResult = apiManager.getMeetingDetails(meetingId);
            
            if (calloutResult.result != null) {
                result.put(meetingId, calloutResult.result);
            }
        }

        return result;
    }

    // create zoom meeting for a job
    public static skedSkeduloApiData.virtualMeetingResult createMeeting(string jobId) {
        List<string> jobIds = new List<string>{jobId};
        return createMeeting(jobIds);
    }

    // create zoom meeting for a list of jobs
    public static skedSkeduloApiData.virtualMeetingResult createMeeting(List<string> jobIds) {
        List<sked__Job_Allocation__c> skedJobAllocs = [SELECT Id, sked__Job__r.sked__Type__c, sked__Job__r.sked__Start__c, sked__Job__r.sked__Description__c,sked__Job__r.Activity_Medium__c,
                                                            sked__Job__r.sked__Duration__c, sked__Resource__c, sked__Resource__r.sked__Email__c, sked__Job__r.sked__Timezone__c, sked__Job__r.sked__Account__c,
                                                            sked__Job__r.sked__Account__r.Name, sked__Resource__r.sked__Primary_Region__c, sked__Resource__r.sked__Primary_Region__r.sked__Timezone__c
                                                       FROM sked__Job_Allocation__c
                                                       WHERE sked__Job__c IN :jobIds];
        skedCommonServices cmService = new skedCommonServices();
        skedSkeduloApiData.zoomSettings settings = new skedSkeduloApiData.zoomSettings();
        settings.waiting_room = true;
        
        skedSkeduloApiData.zoom zoom = new skedSkeduloApiData.zoom();
        zoom.timezone =  skedJobAllocs[0].sked__Job__r.sked__Timezone__c;
        zoom.type = jobIds.size() > 1 ? 3 : 2;
        zoom.settings = settings;
        
        Map<String, Object> mapRequest = new Map<String, Object>();
        mapRequest.put(STR_ZOOM, zoom);
        mapRequest.put(STR_AGENDA, 'Appointment');
        mapRequest.put(STR_PASSWORD, generatePassword());

        Set<string> hostEmails = new Set<string>();
        
        for (sked__Job_Allocation__c skedAlloc : skedJobAllocs) {               
            String startTime = skedAlloc.sked__Job__r.sked__Start__c.format(skedDateTimeUtils.DATE_TIME_ISO_FORMAT_NEW, zoom.timezone);         
            mapRequest.put(STR_TOPIC, cmService.getEventSubject(skedAlloc.sked__Job__r));
            mapRequest.put(STR_START_TIME, startTime); // skedSetting.instance.Admin.timezoneSidId));
            mapRequest.put(STR_DURATION, Integer.valueOf(skedAlloc.sked__Job__r.sked__Duration__c));
            mapRequest.put(STR_HOST_RESOURCE_ID, skedAlloc.sked__Resource__c);
            //hostEmails.add(skedAlloc.sked__Resource__r.sked__Email__c);
        }
        zoom.topic = String.valueOf(mapRequest.get(STR_TOPIC));
        zoom.agenda = String.valueOf(mapRequest.get(STR_AGENDA));
        settings.alternative_hosts = String.join(new List<string>(hostEmails), ',');
        System.debug('mapRequest##' + mapRequest);
        skedSkeduloApiManager apiManager = new skedSkeduloApiManager();
        skedSkeduloApiData.virtualMeetingResult calloutResult = apiManager.createMeeting(mapRequest);
        system.debug('#calloutResult '+calloutResult);
        List<sked__Job__c> skedJobsToUpdate = new List<sked__Job__c>();
        if ( calloutResult.success != false ) {
            if (calloutResult.error == NULL && calloutResult.result != null) {
                skedSkeduloApiData.virtualMeeting result = calloutResult.result;                
                if (result != NULL) {
                    for (string jobId : jobIds) {
                        sked__Job__c skedJob = new sked__Job__c(
                            Id = (Id)jobId,
                            sked__Virtual_Meeting_Id__c = result.id != NULL ? result.id.remove('Zoom:') : '',
                            sked__Virtual_Meeting_URL__c = result.inviteeUrl,
                            sked__Virtual_Meeting_Info__c = zoom.topic,
                            sked_Virtual_Meeting_Password__c = result.password,
                            sked_Virtual_Meeting_Recurring__c = zoom.type == 3 ? true : false
                        );
                        skedJobsToUpdate.add(skedJob);
                    }
                    update skedJobsToUpdate;
                    skedEmailUtil.sendEmailCustomer(jobIds);
                    skedEventHandler.updateEventLocation(skedJobAllocs);
                }
            }
        }        
        else {
            for (string jobId : jobIds) {
                sked__Job__c skedJob = new sked__Job__c(
                        Id = (Id)jobId,
                        Sked_API_Error__c = true,
                        Sked_API_Error_Message__c = calloutResult.message
                );
                skedJobsToUpdate.add(skedJob);
            }
            update skedJobsToUpdate;
        }
        return calloutResult;
    }

    // update zoom meeting when a job is rescheduled
    public static List<skedSkeduloApiData.virtualMeetingResult> updateMeeting(List<string> jobIds) {
        Map<string, sked__Job__c> mapMeetingId_skedJob = new Map<string, sked__Job__c>();
        Map<string, List<string>> mapMeetingId_resourceEmails = new Map<string, List<string>>();

        List<sked__Job__c> skedJobs = [SELECT sked__Virtual_Meeting_Id__c, sked_Virtual_Meeting_Password__c, sked__Start__c, sked__Duration__c, sked__Timezone__c, 
                                            (SELECT sked__Resource__r.sked__Email__c 
                                             FROM sked__Job_Allocations__r
                                             WHERE sked__Status__c != :skedConstant.JOB_ALLOCATION_STATUS_DECLINED
                                                AND sked__Status__c != :skedConstant.JOB_ALLOCATION_STATUS_DELETED)
                                       FROM sked__Job__c 
                                       WHERE Id IN :jobIds];

        for (sked__Job__c skedJob : skedJobs) {
            string meetingId = skedJob.sked__Virtual_Meeting_Id__c;
            mapMeetingId_skedJob.put(meetingId, skedJob);

            for (sked__Job_Allocation__c skedAlloc : skedJob.sked__Job_Allocations__r) {
                List<string> emails = mapMeetingId_resourceEmails.containsKey(meetingId) ? mapMeetingId_resourceEmails.get(meetingId) : new List<string>();
                emails.add(skedAlloc.sked__Resource__r.sked__Email__c);
                mapMeetingId_resourceEmails.put(meetingId, emails);
            }
        }

        Map<String, skedSkeduloApiData.virtualMeeting> mapMeeting = getMeetingDetails(mapMeetingId_skedJob.keySet());

        skedSkeduloApiManager apiManager = new skedSkeduloApiManager();

        List<skedSkeduloApiData.virtualMeetingResult> calloutResults = new List<skedSkeduloApiData.virtualMeetingResult>();
        for (string meetingId : mapMeeting.keySet()) {
            skedSkeduloApiData.virtualMeeting meeting = mapMeeting.get(meetingId);
            sked__Job__c skedJob = mapMeetingId_skedJob.get(meetingId);

            skedSkeduloApiData.zoomSettings settings = new skedSkeduloApiData.zoomSettings();
            settings.waiting_room = true;

            skedSkeduloApiData.zoom zoom = new skedSkeduloApiData.zoom();
            if (meeting.zoom != NULL) {
                zoom.timezone = skedJob.sked__Timezone__c;
                zoom.type = meeting.zoom.type;
                zoom.settings = settings;
                zoom.topic = meeting.zoom.topic;
                zoom.agenda = meeting.zoom.agenda;
            }

            if (mapMeetingId_resourceEmails.containsKey(meetingId)) {
                List<string> emails = mapMeetingId_resourceEmails.get(meetingId);
                settings.alternative_hosts = String.join(emails, ',');
            }

            Map<String, Object> mapRequest = new Map<String, Object>();
            mapRequest.put(STR_ZOOM, zoom);
            mapRequest.put(STR_AGENDA, zoom.agenda);
            mapRequest.put(STR_TOPIC, zoom.topic);
            mapRequest.put(STR_PASSWORD, skedJob.sked_Virtual_Meeting_Password__c);
            mapRequest.put(STR_START_TIME, skedJob.sked__Start__c.format(skedDateTimeUtils.DATE_TIME_ISO_FORMAT, skedJob.sked__Timezone__c)); //skedSetting.instance.App.timezoneSidId));
            mapRequest.put(STR_DURATION, Integer.valueOf(skedJob.sked__Duration__c));

            skedSkeduloApiData.virtualMeetingResult calloutResult = apiManager.updateMeeting(meetingId, mapRequest);
            calloutResults.add(calloutResult);
        }
        return calloutResults;
    }

    // delete zoom meeting of a job
    public static List<skedSkeduloApiData.virtualMeetingResult> deleteMeeting(List<string> jobIds) {
        Set<String> meetingIds = new Set<String>();
        for (sked__Job__c skedJob : [SELECT sked__Virtual_Meeting_Id__c FROM sked__Job__c WHERE Id IN :jobIds]) {
            if (skedJob.sked__Virtual_Meeting_Id__c != NULL) {
                meetingIds.add(skedJob.sked__Virtual_Meeting_Id__c);
            }
        }
        return deleteMeetingByMeetingIds(meetingIds);
    }

    // delete a list of zoom meetings
    public static List<skedSkeduloApiData.virtualMeetingResult> deleteMeetingByMeetingIds(Set<string> meetingIds) {
        skedSkeduloApiManager apiManager = new skedSkeduloApiManager();
        List<skedSkeduloApiData.virtualMeetingResult> calloutResults = new List<skedSkeduloApiData.virtualMeetingResult>();
        for (string meetingId : meetingIds) {
            skedSkeduloApiData.virtualMeetingResult calloutResult = apiManager.deleteMeeting(meetingId);
            calloutResults.add(calloutResult);
        }
        return calloutResults;
    }

    /********************************************* PRIVATE METHODS *********************************************/
    private static String generatePassword() {
        return String.valueOf(Math.round((Math.random() * (900000) + 100000)));
    }
}