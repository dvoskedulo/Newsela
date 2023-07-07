public class skedAvailator {
    private skedResourceAvailability resourceAvailability {
        get {
            if (resourceAvailability == NULL) {
                resourceAvailability = new skedResourceAvailability();
            }
            return resourceAvailability;
        }
        set;
    }
    private Map<Datetime, Datetime> mapTimePeriod;
    private List<jobModel> inputJobs;
    private Map<Id, skedResourceAvailabilityBase.resourceModel> mapResource;
    private Set<Id> excludedEventIds;
    private Boolean calculateTravelTime;
    private String timezoneSidId;
    private Boolean exceptFirstOfDay = false;
    private Integer buffer = 0;
    private Integer firstTimeslot;

    public List<jobAllocation> unavailableAllocations;
    public List<jobAllocation> possibleAllocations;

    /*********************************************************Constructor***************************************************/
    public skedAvailator setResourceAvailability(skedResourceAvailability resourceAvailability) {
        this.resourceAvailability = resourceAvailability;
        return this;
    }

    public skedAvailator setJobToValidate(List<jobModel> inputJobs) {
        this.inputJobs = inputJobs;
        return this;
    }

    public skedAvailator excludeEventIds(Set<Id> excludedEventIds) {
        this.excludedEventIds = excludedEventIds;
        return this;
    }

    public skedAvailator calculateTravelTime(Boolean calculateTravelTime, Boolean exceptFirstOfDay, Integer buffer, Integer firstTimeslot) {
        this.calculateTravelTime = calculateTravelTime;
        this.exceptFirstOfDay = exceptFirstOfDay;
        this.buffer = buffer != null ? buffer : 0;
        this.firstTimeslot = firstTimeslot != null ? firstTimeslot : null;
        return this;
    }

    public skedAvailator setTimezone(String timezoneSidId) {
        this.timezoneSidId = timezoneSidId;
        return this;
    }

    /*********************************************************for availability validation***************************************************/
    public skedAvailator  initialize() {
        buidMapTimePeriod();
        this.resourceAvailability.setTimePeriod(this.mapTimePeriod);
        this.resourceAvailability.setTimezone(this.timezoneSidId);

        this.mapResource = this.resourceAvailability.initializeResourceList();
        System.debug('mapResource@@' + mapResource);
        return this;
    }

    /*********************************************************Validate allocation stuffs***************************************************/
    public void validateJobs() {
        this.unavailableAllocations = new List<jobAllocation>();
        this.possibleAllocations = getPossibleAllocations(this.mapResource.values(), this.inputJobs);
        validateAvailability(possibleAllocations, this.excludedEventIds);
    }

    private void validateAvailability(List<jobAllocation> inputAllocations, Set<Id> excludedEventIds) {
        if (inputAllocations == NULL || inputAllocations.isEmpty()) {
            return;
        }
        for (jobAllocation allocation : inputAllocations) {
            skedResourceAvailabilityBase.resourceModel resource = this.mapResource.get(allocation.resource.id);
            allocation.resource = resource;
            validateAllocation(allocation, resource, excludedEventIds);
        }
        if ( this.calculateTravelTime != null && this.calculateTravelTime ) {
            calculateDistanceBySkeduloAPI(inputAllocations);
        }
    }

    private void buidMapTimePeriod() {
        this.mapTimePeriod = new Map<Datetime, Datetime>();
        for ( jobModel job : this.inputJobs ) {
            mapTimePeriod.put(job.start, job.finish);
        }
    }

    public void validateAllocation(jobAllocation allocation, skedResourceAvailabilityBase.resourceModel resource, Set<Id> excludedEventIds) {
        System.debug('##### allocation 1 : ' + JSON.serialize(allocation));
        System.debug('##### resource : ' + JSON.serialize(resource));
        System.debug('##### excludedEventIds : ' + excludedEventIds);
        if ( !resource.allEvents.isEmpty() ) {
            Datetime startOfDate = skedDateTimeUtils.getStartOfDate(allocation.job.start, this.timezoneSidId);
            Datetime endOfDate = startOfDate.addDays(1);
            for (skedResourceAvailabilityBase.eventModel event : resource.allEvents) {
                if (event.id != NULL && excludedEventIds != NULL && !excludedEventIds.isEmpty()) {
                    if (excludedEventIds.contains(event.id)) {
                        continue;
                    }
                }

                System.debug('##### event : ' + event.start + ' => ' + event.finish);
                System.debug('##### allocation.job : ' + allocation.job.start + ' => ' + allocation.job.finish);

                if (event.start < allocation.job.finish && event.finish > allocation.job.start) {
                    System.debug('##### case 1 #####');
                    allocation.isAvailable = false;
                    handleConflict(allocation, event);
                }

                if ( event.start < endOfDate && event.finish > startOfDate ) {
                    if ( event.geometry != NULL ) {
                        if ( event.start >= allocation.job.finish ) {
                            allocation.nextEvent = event;
                            //break;
                        }
                        if ( event.finish <= allocation.job.start ) {
                            allocation.previousEvent = event;
                        }
                    }
                }
            }
            System.debug('##### allocation 2 : ' + JSON.serialize(allocation));
            if ( allocation.isAvailable ) {
                if (allocation.previousEvent != NULL) {
                    if ( this.exceptFirstOfDay && this.firstTimeslot != null && this.firstTimeslot == allocation.job.startTime) {
                        if (allocation.previousEvent.finish > allocation.job.start) {
                            System.debug('##### case 2 #####');
                            allocation.isAvailable = false;
                        }
                    }
                    else {
                        if (allocation.previousEvent.finish > allocation.job.start.addMinutes(-this.buffer)) {
                            System.debug('##### case 3 #####');
                            allocation.isAvailable = false;
                        }
                    }
                }
                if (allocation.nextEvent != NULL ) {
                    if (allocation.job.finish > allocation.nextEvent.start.addMinutes(-this.buffer)) {
                        System.debug('##### case 4 #####');
                        allocation.isAvailable = false;
                    }
                }
            }
        }
    }


    public void handleConflict(jobAllocation allocation, skedResourceAvailabilityBase.eventModel event) {
        ConflictEvent conflictEvent =  new ConflictEvent(event, this.resourceAvailability.getTimezone());
        allocation.conflictEvents.add(conflictEvent);
    }

    public virtual List<jobAllocation> getPossibleAllocations(List<skedResourceAvailabilityBase.resourceModel> resources, List<jobModel> inputJobs) {
        List<jobAllocation> result = new List<jobAllocation>();

        System.debug('##### resources : ' + resources);
        System.debug('##### inputJobs : ' + inputJobs);

        for (jobModel job : inputJobs) {
            for (skedResourceAvailabilityBase.resourceModel resource : resources) {
                jobAllocation allocation = new jobAllocation();
                allocation.resource = resource;
                allocation.job = job;
                allocation.start = job.start;
                allocation.finish = job.finish;
                allocation.isAvailable = true;
                result.add(allocation);
            }
        }

        return result;
    }

    public void calculateDistanceBySkeduloAPI(List<jobAllocation> allocations) {
        Map<String, skedSkeduloApiData.geometry> homeLocations = new Map<String, skedSkeduloApiData.geometry>();
        Map<String, skedSkeduloApiData.geometry> previousLocations = new Map<String, skedSkeduloApiData.geometry>();
        Map<String, skedSkeduloApiData.geometry> currentLocations = new Map<String, skedSkeduloApiData.geometry>();
        Map<String, skedSkeduloApiData.geometry> nextLocations = new Map<String, skedSkeduloApiData.geometry>();
        //calculate travel distance from previous event to current location
        for ( jobAllocation allocation : allocations ) {
            if ( !allocation.isAvailable ) {
                continue;
            }
            if ( allocation.job.geometry == null ) continue;
            if ( allocation.resource.geometry == null ) continue;
            String homeGeoKey = allocation.resource.geometry.lat + '|' + allocation.resource.geometry.lng;
            if ( !homeLocations.containsKey(homeGeoKey) ) {
                homeLocations.put(homeGeoKey, new skedSkeduloApiData.geometry(allocation.resource.geometry.lat, allocation.resource.geometry.lng) );
            }
            String currentGeoKey = allocation.job.geometry.lat + '|' + allocation.job.geometry.lng;
            if ( !currentLocations.containsKey(currentGeoKey) ) {
                currentLocations.put(currentGeoKey, new skedSkeduloApiData.geometry(allocation.job.geometry.lat, allocation.job.geometry.lng) );
            }
            if (allocation.previousEvent != NULL && allocation.previousEvent.geometry != NULL) {
                String previousGeoKey = allocation.previousEvent.geometry.lat + '|' + allocation.previousEvent.geometry.lng;
                if ( !previousLocations.containsKey(previousGeoKey) ) {
                    previousLocations.put(previousGeoKey, new skedSkeduloApiData.geometry(allocation.previousEvent.geometry.lat, allocation.previousEvent.geometry.lng) );
                }
            }
            if (allocation.nextEvent != NULL && allocation.nextEvent.geometry != NULL) {
                String nextGeoKey = allocation.nextEvent.geometry.lat + '|' + allocation.nextEvent.geometry.lng;
                if ( !nextLocations.containsKey(nextGeoKey) ) {
                    nextLocations.put(nextGeoKey, new skedSkeduloApiData.geometry(allocation.nextEvent.geometry.lat, allocation.nextEvent.geometry.lng) );
                }
            }
        }


        skedTravelTimeServiceBase travelTimeService = new skedTravelTimeServiceBase();

        travelTimeService.execute(homeLocations.values(), currentLocations.values());
        travelTimeService.execute(previousLocations.values(), currentLocations.values());
        travelTimeService.execute(currentLocations.values(), nextLocations.values());

        for ( jobAllocation allocation : allocations ) {
            if ( !allocation.isAvailable ) {
                continue;
            }
            if ( allocation.job.geometry != NULL ) {
                if (allocation.resource.geometry != NULL) {
                    skedSkeduloApiData.Route journey = travelTimeService.getJourney(allocation.resource.geometry,
                                                                                  allocation.job.geometry);
                    if (journey != null && journey.result != null && journey.result.status == 'OK') {
                        allocation.travelTimeFromHome = journey.result.duration.durationInSeconds/60;
                        allocation.distanceFromHome = journey.result.distance.distanceInMeters;
                    }
                }
                if (allocation.previousEvent != NULL && allocation.previousEvent.geometry != NULL) {
                    skedSkeduloApiData.Route journey = travelTimeService.getJourney(allocation.previousEvent.geometry,
                                                                                allocation.job.geometry);

                    if (journey != null && journey.result != null && journey.result.status == 'OK') {
                        // System.debug('get the result');
                        allocation.travelTimeFrom = journey.result.duration.durationInSeconds/60;
                        allocation.distanceFrom = journey.result.distance.distanceInMeters;

                        if ( this.exceptFirstOfDay && this.firstTimeslot != null && this.firstTimeslot == allocation.job.startTime) {
                            if (allocation.previousEvent.finish.addMinutes(allocation.travelTimeFrom) > allocation.job.start) {
                                allocation.isAvailable = false;
                            }
                        }
                        else {
                            if (allocation.previousEvent.finish.addMinutes(allocation.travelTimeFrom) > allocation.job.start.addMinutes(-this.buffer)) {
                                allocation.isAvailable = false;
                            }
                        }
                    }
                }
                if (allocation.nextEvent != NULL && allocation.nextEvent.geometry != NULL) {
                    skedSkeduloApiData.Route journey = travelTimeService.getJourney(allocation.job.geometry,
                                                                        allocation.nextEvent.geometry);
                    if (journey != null && journey.result != null && journey.result.status == 'OK') {
                        allocation.travelTimeTo = journey.result.duration.durationInSeconds/60;
                        allocation.distanceTo = journey.result.distance.distanceInMeters;

                        if (allocation.job.finish.addMinutes(allocation.travelTimeTo) > allocation.nextEvent.start.addMinutes(-this.buffer)) {
                            allocation.isAvailable = false;
                        }
                    }
                }
            }
        }
    }

    //=================Nested Class==================
    public class jobModel {
        public String id;
        public String name;
        public Datetime start;
        public Datetime finish;
        public Integer startTime;
        public skedResourceAvailabilityBase.geometry geometry;
    }

    public class jobAllocation {
        public skedResourceAvailabilityBase.resourceModel resource;
        public jobModel job;
        public Datetime start;
        public Datetime finish;
        public String eventType;
        public String subType;
        public Boolean isAvailable;
        public integer travelTimeFrom;
        public integer travelTimeTo;
        public Integer travelTimeFromHome;
        public Integer distanceFromHome;
        public Integer distanceFrom;
        public Integer distanceTo;
        public List<ConflictEvent>  conflictEvents;
        public transient skedResourceAvailabilityBase.eventModel previousEvent;
        public transient skedResourceAvailabilityBase.eventModel nextEvent;
        public jobAllocation() {
            this.conflictEvents = new List<ConflictEvent>();
        }
    }

    public class ConflictEvent {
        public Id id;
        public String name;
        public String strDate;
        public String intStart;
        public String intFinish;
        public String eventType;
        public ConflictEvent (skedResourceAvailabilityBase.eventModel event, String timzoneSidId) {
            this.id = event.id;
            this.eventType = event.eventType;
            if ( event.eventType.equalsIgnoreCase(skedConstant.EVENT_TYPE_ALLOCATION) ) {
                this.id = event.parentId;
                this.eventType = skedConstant.EVENT_TYPE_JOB;
            }
            this.name = event.name;
            this.intStart = event.start.format(skedDateTimeUtils.INT_TIME_FORMAT, timzoneSidId);
            this.intFinish = event.finish.format(skedDateTimeUtils.INT_TIME_FORMAT, timzoneSidId);
            this.strDate = event.start.format(skedDateTimeUtils.DATE_ISO_FORMAT, timzoneSidId);
        }
    }
}