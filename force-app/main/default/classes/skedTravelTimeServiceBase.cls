public class skedTravelTimeServiceBase {
    public Map<string, skedSkeduloApiData.Route> mapJourney;
    public integer maxOrigins = 25;
    public void initialize(List<skedSkeduloApiData.geometry> origins, List<skedSkeduloApiData.geometry> destinations) {
        List<distanceMatrixRequest> requests = getRequestList(origins, destinations);
        initialize(requests);
    }

    public skedTravelTimeServiceBase() {
        this.mapJourney = new Map<string, skedSkeduloApiData.Route>();
    }

    public void initialize(List<distanceMatrixRequest> requests) {
        //process matrix distance request        

        system.debug('#requests#' + requests.size());

        for (distanceMatrixRequest request : requests) {
            List<skedSkeduloApiData.geometry> originList = new List<skedSkeduloApiData.geometry>();          
            originList.addAll( request.mapOrigin.values() );

            List<skedSkeduloApiData.geometry> destinationList = new List<skedSkeduloApiData.geometry>();
            destinationList.addAll( request.mapDestination.values() );

            // mapJourney.putAll( skedSkeduloApiManager.calculateDistanceMatrix(originList, destinationList).toRouteMap(originList, destinationList) );                        
            Map<String, skedSkeduloApiData.Route> mapRoute = skedSkeduloApiManager.calculateDistanceMatrix(originList, destinationList).toRouteMap(originList, destinationList);
            for ( String key : mapRoute.keySet() ) {
                this.mapJourney.put(key, mapRoute.get(key));
            }
        }
    }
    public void execute(List<skedSkeduloApiData.geometry> origins, List<skedSkeduloApiData.geometry> destinations) {
        List<distanceMatrixRequest> requests = getRequestList(origins, destinations);
        System.debug('requests#' + JSON.serialize(requests));
        initialize(requests);
    }

    public List<distanceMatrixRequest> getRequestList(List<skedSkeduloApiData.geometry> origins, List<skedSkeduloApiData.geometry> destinations) {
        List<distanceMatrixRequest> result = new List<distanceMatrixRequest>();

        integer noOfOriginSets = integer.valueOf(Math.ceil(decimal.valueOf(origins.size()) / maxOrigins));
        integer noOfDestinationSets = integer.valueOf(Math.ceil(decimal.valueOf(destinations.size()) / maxOrigins));

        for (integer i = 0; i < noOfOriginSets; i++) {
            integer originFirstIdx = maxOrigins * i;
            integer originLastIdx = originFirstIdx + (maxOrigins - 1);
            originLastIdx = originLastIdx > (origins.size() - 1) ? origins.size() - 1 : originLastIdx;

            Map<string, skedSkeduloApiData.geometry> mapOrigin = new Map<string, skedSkeduloApiData.geometry>();
            for (integer j = originFirstIdx; j <= originLastIdx; j++) {
                skedSkeduloApiData.geometry originGeometry = origins.get(j);
                mapOrigin.put(originGeometry.lat + ',' + originGeometry.lng, originGeometry);
            }

            for (integer m = 0; m < noOfDestinationSets; m++) {
                integer destinationFirstIdx = maxOrigins * m;
                integer destinationLastIdx = destinationFirstIdx + (maxOrigins - 1);
                destinationLastIdx = destinationLastIdx > (destinations.size() - 1) ? destinations.size() - 1 : destinationLastIdx;

                Map<string, skedSkeduloApiData.geometry> mapDestination = new Map<string, skedSkeduloApiData.geometry>();
                for (integer n = destinationFirstIdx; n <= destinationLastIdx; n++) {
                    skedSkeduloApiData.geometry destinationGeometry = destinations.get(n);
                    mapDestination.put(destinationGeometry.lat + ',' + destinationGeometry.lng, destinationGeometry);
                }

                distanceMatrixRequest request = new distanceMatrixRequest();
                request.mapOrigin = mapOrigin;
                request.mapDestination = mapDestination;
                result.add(request);
            }
        }

        return result;
    }

    public class distanceMatrixRequest {
        public Map<string, skedSkeduloApiData.geometry> mapOrigin {get;set;}
        public Map<string, skedSkeduloApiData.geometry> mapDestination {get;set;}
    } 

    public skedSkeduloApiData.Route getJourney(Location fromLoc, Location toLoc) {
        string originkey = fromLoc.getLatitude() + ',' + fromLoc.getLongitude();
        string destinationkey = toLoc.getLatitude() + ',' + toLoc.getLongitude();
        string key = originkey + '|' + destinationkey;
        system.debug('### getJourney key: ' + key);
        return mapJourney.get(key);
    }

    public skedSkeduloApiData.Route getJourney(skedSkeduloApiData.geometry fromLoc, skedSkeduloApiData.geometry toLoc) {
        string originkey = fromLoc.lat + ',' + fromLoc.lng;
        string destinationkey = toLoc.lat + ',' + toLoc.lng;
        string key = originkey + '|' + destinationkey;
        system.debug('### getJourney key: ' + key);
        return mapJourney.get(key);
    }

    public skedSkeduloApiData.Route getJourney(skedResourceAvailabilityBase.geometry fromLoc, skedResourceAvailabilityBase.geometry toLoc) {
        string originkey = fromLoc.lat + ',' + fromLoc.lng;
        string destinationkey = toLoc.lat + ',' + toLoc.lng;
        string key = originkey + '|' + destinationkey;
        system.debug('### getJourney key: ' + key);
        return mapJourney.get(key);
    }
}