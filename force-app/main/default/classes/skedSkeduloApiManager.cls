/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-25-2021
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   01-25-2021   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
public without sharing class skedSkeduloApiManager {

    public static final String BASE_END_POINT_WITH_OAUTH2 = 'callout:Skedulo_API/';
    public static final String BASE_END_POINT_WITH_TOKEN = 'https://api.skedulo.com/';
    public static final String OPTIMIZATION_END_POINT = 'https://api.skedulo.com/planr/optimize/schedule';
    public static String DISTANCE_MATRIX_ENDPOINT   = '/geoservices/distanceMatrix';
    public static final string AVAILABILITY_PATTERN_ENDPOINT = 'https://api.skedulo.com/availability/patterns';
    public static final string AVAILABILITY_SIMPLE_ENDPOINT = 'https://api.skedulo.com/availability/simple';
    public static final String NOTIFICATION_ENDPOINT               = '/notifications/notify';
    public static String GEOCODE_ENDPOINT           = '/geoservices/geocode';
    public static final string VIRTUAL_MEETING_ENDPOINT = 'https://api.skedulo.com/virtualmeeting/meetings';

    /**
    * @description: calculate distance matrix
    */
    public static skedSkeduloApiData.distanceMatrixResult calculateDistanceMatrix(List<skedSkeduloApiData.geometry> origins, List<skedSkeduloApiData.geometry> destinations) {
        skedSkeduloApiData.distanceMatrixRequestBody request = new skedSkeduloApiData.distanceMatrixRequestBody(origins, destinations);
        system.debug('request in JSON format: ' + JSON.serialize(request));
        sked.ApiInput.Generic data = new sked.ApiInput.Generic('POST', DISTANCE_MATRIX_ENDPOINT, new Map<String, String>(), JSON.serialize(request));

        skedSkeduloApiData.distanceMatrixResult result = new skedSkeduloApiData.distanceMatrixResult();
        result.init(sked.SkeduloAPI.callAPI(data));

        return result;
    }

    /**
    * @description: Send SMS to any phone number
    */
    // public static skedSkeduloApiData.notifyResponseResult notify(string resourceId, String jobId) {
    //     NotificationRequest request = new NotificationRequest(resourceId, jobId);        
    //     sked.ApiInput.Generic data = new sked.ApiInput.Generic('POST', NOTIFICATION_ENDPOINT, new Map<String, String>(), JSON.serialize(request));
    //     skedSkeduloApiData.notifyResponseResult result = new skedSkeduloApiData.notifyResponseResult();
    //     result.init(sked.SkeduloAPI.callAPI(data));

    //     return result;
    // }

     /**
    * @description: get geo code of list of addresses
    */
    public static skedSkeduloApiData.GeocodeResult geocode(List<String> addresses) {
        skedSkeduloApiData.GeocodeResult result = new skedSkeduloApiData.GeocodeResult();

        skedSkeduloApiData.GeoCodeRequest request = new skedSkeduloApiData.GeoCodeRequest(addresses);
        String dataJson = JSON.serialize(request);
        sked.ApiInput.Generic data = new sked.ApiInput.Generic('POST', GEOCODE_ENDPOINT, new Map<String, String>(), dataJson);
        sked.ApiResult.Generic apiResult = sked.SkeduloAPI.callAPI(data);
        System.debug(apiResult.response);
        result.init(apiResult);
        return result;
    }

    public static List<skedSkeduloApiData.Prediction> autocomplete (String searchAddress, String countryCode, String sessionId) {
        List<skedSkeduloApiData.Prediction> predictions = new List<skedSkeduloApiData.Prediction>();        
        sked.ApiResult.AutoComplete result = sked.SkeduloAPI.autocomplete(searchAddress, countryCode, sessionId);
        System.debug('== result: ' + result);
        if (result.isSuccess()) {
            Map<String,String> resultMap = result.getResultMap();
            // System.debug('== sessionId: ' + result.getSessionId());
            for (String placeId : resultMap.keySet()) {
                System.debug('=== placeId: ' + placeId + ' == address: ' + resultMap.get(placeId));
                skedSkeduloApiData.Prediction prediction = new skedSkeduloApiData.Prediction(resultMap.get(placeId), placeId );
                predictions.add(prediction);
                // NOTES: if the place API is called here then it should use the same sessionId                
            }            
        } else {
            System.debug('Error: ' + result.message);
        }
        return predictions;
    }

    // private static String getBaseEndpointAndHeader(Map<string, string> mapHeader) {
    //     String skeduloLongLivedToken = skedSetting.instance.adminSetting.Skedulo_API_Token;
    //     String endPoint;
    //     if (String.isBlank(skeduloLongLivedToken)) {
    //         endPoint = BASE_END_POINT_WITH_OAUTH2;
    //     } else {
    //         endPoint = BASE_END_POINT_WITH_TOKEN;
    //         mapHeader.put('Authorization', 'Bearer ' + skeduloLongLivedToken);
    //     }
    //     return endPoint;
    // }
    
    public skedSkeduloApiData.virtualMeetingResult getMeetingDetails(String meetingId) {  
        string url = VIRTUAL_MEETING_ENDPOINT + '/Zoom:' + meetingId;
        virtualMeetingAction action = new virtualMeetingAction();
        return (skedSkeduloApiData.virtualMeetingResult)action.execute(url, 'GET', getDefaultHeader(), '');
    }

    public skedSkeduloApiData.virtualMeetingResult createMeeting(Map<String, Object> request) {
        string jsonBody = Json.serialize(request);
        system.debug('#json '+jsonBody);
        virtualMeetingAction action = new virtualMeetingAction();
        return (skedSkeduloApiData.virtualMeetingResult)action.execute(VIRTUAL_MEETING_ENDPOINT, 'POST', getDefaultHeader(), jsonBody);
    }

    public skedSkeduloApiData.virtualMeetingResult updateMeeting(String meetingId, Map<String, Object> request) {
        string url = VIRTUAL_MEETING_ENDPOINT + '/Zoom:' + meetingId;
        string jsonBody = Json.serialize(request);
        virtualMeetingAction action = new virtualMeetingAction();
        return (skedSkeduloApiData.virtualMeetingResult)action.execute(url, 'PUT', getDefaultHeader(), jsonBody);
    }

    public skedSkeduloApiData.virtualMeetingResult deleteMeeting(String meetingId) {
        string url = VIRTUAL_MEETING_ENDPOINT + '/Zoom:' + meetingId;
        virtualMeetingAction action = new virtualMeetingAction();
        return (skedSkeduloApiData.virtualMeetingResult)action.execute(url, 'DELETE', getDefaultHeader(), '');
    }

    /******************************************* Skedulo Availability Pattern *******************************************/        

    public skedSkeduloApiData.simplifiedResourceAvailabilityResult getSimplifiedResourceAvailability(skedSkeduloApiData.simplifiedResourceAvailabilityPayload payload) {
        simplifiedResourceAvailabilityAction action = new simplifiedResourceAvailabilityAction();
        string url = AVAILABILITY_SIMPLE_ENDPOINT + '?resource_ids={{resourceIds}}&start={{start}}&end={{end}}&mergedAvailabilities={{mergedAvailabilities}}';
        url = url.replace('{{resourceIds}}', payload.resource_ids);
        url = url.replace('{{start}}', payload.start);
        url = url.replace('{{end}}', payload.end_x);
        url = url.replace('{{mergedAvailabilities}}', 'true');
        Map<string, string> mapHeader = getDefaultHeader();
        return (skedSkeduloApiData.simplifiedResourceAvailabilityResult)action.execute(url, 'GET', mapHeader, '');
    }

    // public skedCalloutResultBase scheduleJobs(
    //     List<String> jobIds, List<String> resourceIds, String timezoneSidId,
    //     DateTime scheduleStart, DateTime scheduleEnd
    // ) {
    //     Map<string, string> mapHeader = getDefaultHeader();

    //     OptimizationRequest request = new OptimizationRequest();
    //     request.jobIds = jobIds;
    //     request.resourceIds = resourceIds;
    //     request.timezone = timezoneSidId;
    //     request.scheduleStart = JSON.serialize(scheduleStart).replace('"', '');
    //     request.scheduleEnd = JSON.serialize(scheduleEnd).replace('"', '');
    //     request.schedulingOptions = new OptimizationScheduleOption();

    //     String jsonBody = JSON.serialize(request);

    //     System.debug('#jsonBody: ' + jsonBody);
    //     System.debug('#header: ' + System.JSON.serialize(mapHeader));

    //     actionBase action = new actionBase();
    //     skedCalloutResultBase result = action.execute(OPTIMIZATION_END_POINT, 'POST', mapHeader, jsonBody);
    //     return result;
    // }

    /*************************************************Nested classes*******************************************************/
    public class simplifiedResourceAvailabilityAction extends actionBase {
        protected override skedCalloutResultBase initializeResult() {
            return new skedSkeduloApiData.simplifiedResourceAvailabilityResult();
        }
        protected override skedCalloutResultBase processResponse(string response) {
            
            response = replaceReservedJSON(response, false);
            system.debug('#response#' + response);
            // if ( Test.isRunningTest() ) {
            //     response = populateTestTemplatePatternJSON();
            //     system.debug('#response#' + response);
            //     sked__Resource__c resource = [SELECT Id FROM sked__Resource__c LIMIT 1];
            //     system.debug('#resource#' + resource.Id);
            //     response = response.replace('{0}', resource.Id);
            //     system.debug('#response#' + response);
            // }

            skedSkeduloApiData.simplifiedResourceAvailabilityResult result = (skedSkeduloApiData.simplifiedResourceAvailabilityResult)JSON.deserialize(response, skedSkeduloApiData.simplifiedResourceAvailabilityResult.class);                                
            return result;
        }
    }

    public class virtualMeetingAction extends actionBase {
        protected override skedCalloutResultBase initializeResult() {
            return new skedSkeduloApiData.virtualMeetingResult();
        }
    
        protected override skedCalloutResultBase processResponse(string response) {
            if ( Test.isRunningTest() ) {

            }
            skedSkeduloApiData.virtualMeetingResult result = new skedSkeduloApiData.virtualMeetingResult();
            result = (skedSkeduloApiData.virtualMeetingResult)Json.deserialize(response, skedSkeduloApiData.virtualMeetingResult.class);
            return result;
        }
    }

    public virtual class actionBase extends skedCalloutActionBase {
        protected override skedCalloutResultBase doExecute(string endPoint, string httpMethod, Map<string, string> mapHeader, string body) {
            skedCalloutResultBase result;
            try {
                result = super.doExecute(endPoint, httpMethod, mapHeader, body);
            }
            catch (skedExceptionHandler.CustomException ex) {
                result = initializeResult();
                result.success = false;
                result.message = ex.response;
            }
            catch (Exception ex) {
                result = initializeResult();
                result.success = false;
                result.message = ex.getMessage() + ' - ' + ex.getStackTraceString();
            }
            return result;
        }
    }

    private Map<string, string> getDefaultHeader() {
        Map<string, string> mapHeader = new Map<string, string>();
        mapHeader.put('Content-Type', 'application/json');
        String longLiveToken = skedSetting.instance.adminSetting.Skedulo_API_Token;        
        mapHeader.put('Authorization', 'Bearer ' + longLiveToken);    
 
        return mapHeader;
    }    

    public class OptimizationRequest {
        public List<String> jobIds;
        public List<String> resourceIds;
        public String timeZone;
        public String scheduleStart;
        public String scheduleEnd;
        public OptimizationScheduleOption schedulingOptions;
    }

    public class OptimizationScheduleOption {
        public Boolean ignoreTravelTimes;
        public Boolean ignoreTravelTimeFirstJob;
        public Boolean ignoreTravelTimeLastJob;
        public Boolean respectSchedule;
        public Boolean balanceWorkload;
        public Integer padding;

        // Default option
        public OptimizationScheduleOption() {
            ignoreTravelTimes = false;
            ignoreTravelTimeFirstJob = true;
            ignoreTravelTimeLastJob = true;
            respectSchedule = true;
            balanceWorkload = false;
            padding = 0;
        }
    }

    // skedulo sms request model
    public class NotificationRequest {
        public List<string> resourceIds;
        public string resourceId;
        public string jobId;

        public NotificationRequest(string resourceId, string jobId) {
            this.resourceId = resourceId;
            this.jobId = jobId;
        }
    }
}