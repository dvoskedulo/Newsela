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
public abstract class skedSkeduloApiData {
   
    public static String DISTANCE_MATRIX_MOCK_DATA   = '{"result":{"matrix":[[{"duration":{"durationInSeconds":8},"distance":{"distanceInMeters":133},"status":"OK"}]],"vendor":"GRAPHHOPPER"}}';
    public static String GEOCODE_MOCK_DATA           = '{"result":[{"GeocodeSuccess":{"address":"79 McLachlan St, Fortitude Valley QLD 4006, Australia","latlng":{"lat":-27.4578649,"lng":153.037271}}}]}';
    public static String NOTIFY_MOCK_DATA            = '{"result":{"results":[{"resourceId":"{resourceId}","protocol":"push","error":{"message":"No device found for resource a0B7X000002FTjvUAG","errorType":"recipient_error"}}],"jobId":"{jobId}"}}';
    // API Error Message class
    public class SkeduloApiError {
        public string errorType;
        public string message;
        public string errorKey;
        
        public SkeduloApiError(Exception ex) {
            this.message = ex.getMessage();
        }
    }

    // distance matrix success result 
    public virtual class genericResult {
        public boolean success;
        public String message;
        public String status;
        public Integer statusCode;
        public String response;
        
        public genericResult() {
            success = true;
        }

        public genericResult init(sked.ApiResult.Generic gr) {
            this.success        = gr.success;
            this.message        = gr.message;
            this.status         = gr.status;
            this.statusCode     = gr.statusCode;
            this.response       = gr.response;
            

            if (Test.isRunningTest()) setMockResponse();
            if (success == true) {
                System.debug('#response: ' + response);
                if (response.containsIgnoreCase('"result"')) {
                    Map<String, Object> deserializedResponse = (Map<String, Object>)Json.deserializeUntyped(response);
                    Object resultNode = (Object)deserializedResponse.get('result');
                    toResultObject(Json.serialize(resultNode));
                } else {
                    toResultObject(response);
                }
                
            }
            return this;
        }
        // Convert a string result to the result object
        // to be overwritten by subclasses
        public virtual void toResultObject(String jsonResult){
            System.debug(jsonResult);
        }

        public virtual void setMockResponse(){
            this.success    = true;
			if (this instanceOf distanceMatrixResult) {
                response        = DISTANCE_MATRIX_MOCK_DATA;
            } 
            // if ( this instanceOf notifyResponseResult ) {
            //     response = NOTIFY_MOCK_DATA;
            // }
        }
    }

    // distanceMatrix request body model
    public class distanceMatrixRequestBody {
        public List<geometry> origins;
        public List<geometry> destinations;
        public distanceMatrixRequestBody(List<geometry> origins, List<geometry> destinations) {
            this.origins = new List<geometry>(origins);
            this.destinations = new List<geometry>(destinations);
        }
    }

    // geolocation data model
    public class geometry {
        public decimal lat;
        public decimal lng;

        public geometry(Location geoLocation) {
            if (geoLocation != null) {
                this.lat = geoLocation.getLatitude();
                this.lng = geoLocation.getLongitude();   
            }
            removeTrailingZeros();
        }
        
        public geometry(decimal lat, decimal lng) {
            this.lat = lat;
            this.lng = lng;
            removeTrailingZeros();
        }

        public geometry(skedModels.geometry baseModel) {
            this.lat = baseModel.lat;
            this.lng = baseModel.lng;
            removeTrailingZeros();
        }

        void removeTrailingZeros() {
            if ( lat != null && lng != null ) {
                this.lat  = this.lat.stripTrailingZeros();
                this.lng = this.lng.stripTrailingZeros();
            }
        }
    }
    /**
    * distance matrix success result 
    */
    public class distanceMatrixResult extends genericResult{
        public Matrix result;

        public override void toResultObject(String jsonResult){
            result = (Matrix)JSON.deserialize(jsonResult, Matrix.class);
        }
        
        // Parse the matrix and put the result in a map of <origin,desination> -> route info
        public Map<String, Route> toRouteMap (List<geometry> originList, List<geometry> destinationList) {
            if (this.success == false) {
                if ( String.isBlank(this.message) ) {
                    this.message = 'We are experiencing a high usage volume at present. Please try again in a few seconds.';
                }
                throw new ApiException(this.message);
            }            

            Map<String, Route> routeMap = new Map<String, Route>();

            for (integer i = 0; i < this.result.matrix.size(); i++) {
                List<Element> row = this.result.matrix.get(i);
                for (integer j = 0; j < row.size(); j++) {
                    Element element = row.get(j);
                    
                    geometry originGeometry = originList.get(i);
                    string originKey = originGeometry.lat + ',' + originGeometry.lng;
                    
                    geometry destinationGeometry = destinationList.get(j);
                    string destinationKey = destinationGeometry.lat + ',' + destinationGeometry.lng;
                    
                    Route r         = new Route();
                    r.origin        = originGeometry;
                    r.destination   = destinationGeometry;
                    r.result        = element;
                    
                    routeMap.put(originKey + '|' + destinationKey, r);
                }
            }
            System.debug('routeMap@@' + routeMap);
            return routeMap;
        }
    }

    //distance matrix element data
    public class Matrix {
        public List<List<Element>> matrix;
    }
    
    //distance matrix element data
    public class Distance {
        public integer distanceInMeters;
    }
    
    //distance matrix element data
    public class Duration {
        public integer durationInSeconds;
    }
    
    //distance matrix element data
    public class Element {
        public Distance distance;
        public Duration duration;
        public string status;
    }
    
    // Status: OK if successful
    public class Route {
        public geometry origin;
        public geometry destination;
        public Element result;
    }

    public class ApiException extends Exception{}

    public virtual class ResultBase extends skedCalloutResultBase {
        public SkeduloApiError error;
        public List<SkeduloApiError> errors;
    }

    /* RESOUCE AVAILABILITY */
    public class simplifiedResourceAvailabilityResult extends resultBase {
        public List<simplifiedResourceAvailability> result;
    }

    public class simplifiedResourceAvailability {
        public string resourceId;
        public List<simplifiedAvailability> mergedAvailabilities;
        //public List<availabilityEntry> entries;
    }

    public class simplifiedAvailability {
        public DateTime start;
        public DateTime end_x;
    }

    public class availabilityEntry {
        public string templateId;
        public string templateEntryId;
        public string name;
        public string type;
        public DateTime start;
        public DateTime end_x;
        public boolean available;
    }

    public class simplifiedResourceAvailabilityPayload {
        public string resource_ids;
        public string start;
        public string end_x;
        public boolean mergedAvailabilities;
    }
    
    /* Availability Pattern Result */
    public class upsertAvailabilityPatternResult extends resultBase {
        public string result;
    }
    
    /* Availability Pattern Payload*/
    public class interval {
        public string startTime;
        public string endTime;
    }
    
    public class day {
        public integer day;
        public string weekday;
        public List<interval> intervals;
    }
    
    public class pattern2 {
        public integer lengthDays;
        public integer repeatWeeks;
        public List<day> days;
        public string type;
    }
    
    public class pattern {
        public string UID;
        public string name;
        public string description;
        public pattern2 pattern;
    }
    
    public class resource {
        public string UID;
        public string resourceId;
        public DateTime start;
        public DateTime end_x;
    }
    
    public class availabilityPatternPayload {
        public pattern pattern;
        public List<resource> resources;
    }

    public class OptimizationResult extends ResultBase {
        public OptimizationReturnedData result;
    }

    public class OptimizationReturnedData {
        public List<OptimizationRouteResult> routes;
        public List<OptimizationUnScheduledResult> unscheduled;
    }

    public class OptimizationRouteResult {
        public String resourceId;
        public String resourceName;
        public List<OptimizationRouteData> route;
    }

    public class OptimizationRouteData {
        public String jobId;
        public String jobName;
        public String start;
        public String type;
        public Integer duration;
        public Integer travelTime;
    }

    public class OptimizationUnScheduledResult {
        public String jobId;
        public String jobName;
    }    

    // public class notifyResponseResult extends genericResult {
    //     public notifyResult result;

    //     public notifyResponseResult() {
    //         super();
    //     }
    //     public override void toResultObject(String jsonResult){
    //         result = (notifyResult)JSON.deserialize(jsonResult, notifyResult.class);
    //     }
    // }

    public class notifyResult {
        public String jobId;
        public List<notifySuccess> results;
    }

    public class notifySuccess {
        public String resourceId;
        public String protocol;
        public notifyError error;
    }

    public class notifyError {
        public String errorType;
        public String message;
    }

    /**
    * geocode data model
    */
    public class GeocodeResult extends genericResult{
        public list<GeocodeResultItem> result;

        public override void toResultObject(String jsonResult){
            result = (List<GeocodeResultItem>)JSON.deserialize(jsonResult, List<GeocodeResultItem>.class);
        }

        public override void setMockResponse(){
            this.success        = true;
            response            =  GEOCODE_MOCK_DATA;
        }

        public List<Location> toLocations () {
            if (success == false){
                throw new  ApiException( message );
            }
            List<Location> locationList = new List<Location>();
            for (Integer index = 0; index < result.size(); index++) {
                GeocodeResultItem resultItem = result.get(index);
                if ( resultItem.isSuccess()) {
                    locationList.add( resultItem.getGeocode() );
                } else {
                    locationList.add( null );
                }
            }
            return locationList;
        }
    }

    public class GeocodeResultItem {
        public GeocodeSuccess geocodeSuccess;
        public GeocodeFailure geocodeFailure;

        public boolean isSuccess(){
            return geocodeSuccess != null && geocodeSuccess.latlng != null && geocodeSuccess.latlng.lat != null && geocodeSuccess.latlng.lng != null;
        }

        public Location GetGeocode(){
            if(!isSuccess()) return null;
            return Location.newInstance(geocodeSuccess.latlng.lat, geocodeSuccess.latlng.lng);
        }

        public String getErrorMsg(){
            if(isSuccess() || geocodeFailure == null || geocodeFailure.reason == null) return null;
            return geocodeFailure.reason.msg;
        }
    }

    //geocode data model
    public class GeocodeSuccess {
        public string address;
        public geometry latlng;
    }
    
    //geocode data model
    public class GeocodeFailure {
        public string address;
        public GeocodeFailureReason reason;
    }
    
    //geocode data model
    public class GeocodeFailureReason {
        public string msg;
    }

    /**
    * geocode request data model
    */
    public class GeoCodeRequest {
        public List<String> addresses;

        public GeoCodeRequest(List<String> addresses) {
            this.addresses = new List<String>(addresses);
        }
    }

    /**
    * predicted address
    */
    public class Prediction {
        public String description;
        public String placeId;
        public Prediction(String description, String placeId) {
            this.description = description;
            this.placeId = placeId;
        }
    }

    /* Zoom meeting */
    public class virtualMeetingResult extends resultBase {
        public virtualMeeting result;
    }

    public class virtualMeeting {
        public string hostUrl;
        public string inviteeUrl;
        public string id;
        public string password;
        public zoom zoom;
    }

    public class zoom {
        public string topic;
        public string agenda;
        public string timezone;
        public string schedule_for;
        public integer type;
        public zoomSettings settings;
    }

    public class zoomSettings {
        public boolean waiting_room;
        public string alternative_hosts;
    }

    public class message {
        public Integer code;
        public String message;
    }
}