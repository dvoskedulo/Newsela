public virtual class skedResourceAvailabilityBase {
    protected Boolean useAvailabilityTemplate;
    protected Set<Id> resourceIds;
    protected Map<Datetime, Datetime> mapTimePeriods;
    protected String timezoneSidId;
    public skedResourceAvailabilityBase( ) {
    }

    private void loadResourceEvents(sked__Resource__c skedResource, resourceModel resource) {
        System.debug('skedResource allocation@' + skedResource.sked__Job_Allocations__r);
        // for (sked__Availability__c availableBlock : skedResource.sked__Availabilities1__r) {
        //     if (availableBlock.sked__Is_Available__c != TRUE) {
        //         continue;
        //     }
        //     resource.addAvailableBlock(availableBlock.sked__Start__c, availableBlock.sked__Finish__c);
        // }

        // for (sked__Availability__c unavailableBlock : skedResource.sked__Availabilities1__r) {
        //     if (unavailableBlock.sked__Is_Available__c = TRUE) {
        //         continue;
        //     }
        //     eventModel availability = new eventModel();
        //     availability.id = unavailableBlock.Id;
        //     availability.name = unavailableBlock.Name;
        //     availability.start = unavailableBlock.sked__Start__c;
        //     availability.finish = unavailableBlock.sked__Finish__c;
        //     availability.eventType = skedConstant.EVENT_TYPE_AVAILABILITY;
        //     availability.subType = unavailableBlock.sked__Type__c;
        //     resource.allEvents.add(availability);
        // }

        for (sked__Job_Allocation__c skedAllocation : skedResource.sked__Job_Allocations__r) {
            eventModel jobAllocation = new eventModel();
            jobAllocation.id = skedAllocation.Id;
            jobAllocation.name = skedAllocation.Name;
            jobAllocation.start = skedAllocation.sked__Job__r.sked__Start__c;
            jobAllocation.finish = skedAllocation.sked__Job__r.sked__Finish__c;
            jobAllocation.eventType = skedConstant.EVENT_TYPE_ALLOCATION;
            jobAllocation.parentId = skedAllocation.sked__Job__c;
            if ( skedAllocation.sked__Job__r.sked__GeoLocation__c != null ) {
                jobAllocation.geometry = new Geometry(skedAllocation.sked__Job__r.sked__GeoLocation__c);
            }

            resource.allEvents.add(jobAllocation);
        }

        for (sked__Activity__c skedActivity : skedResource.sked__Activities__r) {
            eventModel activity = new eventModel();
            activity.id = skedActivity.Id;
            activity.name = skedActivity.Name;
            activity.start = skedActivity.sked__Start__c;
            activity.finish = skedActivity.sked__End__c;
            activity.eventType = skedConstant.EVENT_TYPE_ACTIVITY;
            if ( skedActivity.sked__GeoLocation__c != null ) {
                activity.geometry = new Geometry(skedActivity.sked__GeoLocation__c);
            }

            resource.allEvents.add(activity);
        }
        resource.allEvents.sort();
    }

    public Map<Id, resourceModel> initializeResourceList() {
        Datetime startTime, endTime;
        for ( Datetime start : mapTimePeriods.keySet() ) {
            Datetime finish = mapTimePeriods.get(start);
            if ( startTime == null || startTime > start ) {
                startTime = start;
            }
            if ( endTime == null || endTime < finish ) {
                endTime = finish;
            }
        }
        System.debug('##### this.mapTimePeriods 1 : ' + this.mapTimePeriods);
        this.mapTimePeriods = new Map<Datetime,Datetime>();
        this.mapTimePeriods.put(startTime, endTime);
        System.debug('##### this.mapTimePeriods 2 : ' + this.mapTimePeriods);

        Map<Id, List<eventModel>> mapResourceToAvailabilities = getSimplifiedResourceAvailability(this.resourceIds, startTime, endTime, this.timezoneSidId);
        System.debug('##### mapResourceToAvailabilities ' + mapResourceToAvailabilities);
        Set<String> allocationIgnoreStatus = new Set<String>{skedConstant.JOB_ALLOCATION_STATUS_DELETED};
        Set<String> jobIgnoreStatus = new Set<String>{skedConstant.JOB_STATUS_CANCELLED};
        Map<Id, resourceModel> mapResource = new Map<Id, resourceModel>();
        for (sked__Resource__c skedResource : Database.query(getResourceQuery(this.resourceIds, this.mapTimePeriods)) )  {
            resourceModel resource = new resourceModel();
            resource.id = skedResource.Id;
            resource.name = skedResource.Name;
            resource.regionId = skedResource.sked__Primary_Region__c;
            if ( skedResource.sked__GeoLocation__c != null) {
                resource.geometry = new Geometry(skedResource.sked__GeoLocation__c);
            }

            if ( skedResource.sked__Resource_Type__c  == skedConstant.RESOURCE_TYPE_PERSON ) {
                eventModel nonWorkingEvent = new eventModel();
                nonWorkingEvent.start = startTime;
                nonWorkingEvent.finish = endTime;
                nonWorkingEvent.eventType = skedConstant.EVENT_TYPE_NON_WORKING;
                resource.allEvents.add( nonWorkingEvent );
            }

            if ( mapResourceToAvailabilities.containsKey(skedResource.Id) ) {
                List<eventModel> availabilities = mapResourceToAvailabilities.get(skedResource.Id);
                for ( eventModel availability : availabilities ) {
                    resource.addAvailableBlock(availability.start, availability.finish);
                }
            }

            loadResourceEvents(skedResource, resource);
            mapResource.put(resource.Id, resource);
        }

        return mapResource;
    }

    private static Map<Id, List<eventModel>>  getSimplifiedResourceAvailability(Set<Id> resourceIds, DateTime startTime, DateTime endTime, string timezoneSidId) {
        System.debug('startTime@' + startTime);
        System.debug('endTime@' + endTime);
        Map<Id, List<eventModel>> mapResourceToEvents = new Map<Id, List<eventModel>>();
        skedAvailabilityTemplateService templateService = new skedAvailabilityTemplateService(new List<Id>(resourceIds), startTime, endTime, timezoneSidId, true);
        templateService.initialize();
        for ( skedSkeduloApiData.simplifiedResourceAvailabilityResult result : templateService.results ) {
            for (skedSkeduloApiData.simplifiedResourceAvailability resourceAvailability : result.result) {
                mapResourceToEvents.put(resourceAvailability.resourceId, new List<eventModel>());
                List<eventModel> events = new List<eventModel>();
                for (skedSkeduloApiData.simplifiedAvailability simplifiedAvailability : resourceAvailability.mergedAvailabilities) {

                    eventModel event = new eventModel();
                    event.start = simplifiedAvailability.start;
                    event.finish = simplifiedAvailability.end_x;
                    events.add(event);
                }
                mapResourceToEvents.get(resourceAvailability.resourceId).addAll(events);
            }
        }

        return     mapResourceToEvents;
    }

    String getResourceQuery(Set<Id> resourceIds, Map<DateTime, Datetime> mapTimePeriod) {
        String jobTimeFilter = buildTimeFilterQuery('sked__Job__r.sked__Start__c', 'sked__Job__r.sked__Finish__c', mapTimePeriod);
        String activityFilter = buildTimeFilterQuery('sked__Start__c', 'sked__End__c', mapTimePeriod);
        String availabliityFilter = buildTimeFilterQuery('sked__Start__c', 'sked__Finish__c', mapTimePeriod);

        skedObjectSelector resourceSelector = skedObjectSelector.newInstance(sked__Resource__c.SObjectType);
        resourceSelector.filter('Id In :resourceIds');

        resourceSelector.subQuery('sked__Job_Allocations__r')
                        .filter('sked__Status__c NOT IN :allocationIgnoreStatus' )
                        .filter('sked__Job__r.sked__Job_Status__c NOT IN :jobIgnoreStatus')
                        .filter('(' + jobTimeFilter + ')' )
                        .sort('sked__Job__r.sked__Start__c', 'ASC');

        resourceSelector.subQuery('sked__Activities__r')
                        .filter('(' + activityFilter + ')' )
                        .sort('sked__Start__c', 'ASC');

        resourceSelector.subQuery('sked__Availabilities1__r')
                        .filter('(' + availabliityFilter + ')' )
                        .sort('sked__Start__c', 'ASC');

        return resourceSelector.getQuery();
    }

    private String buildTimeFilterQuery(String startApiName, String endApiName, Map<DateTime, Datetime> mapTimePeriod) {
        String query = '';
        for ( Datetime start : mapTimePeriod.keySet() ) {
            Datetime finish = mapTimePeriod.get(start);
            query += ' ( ' + startApiName + ' < ' + JSON.serialize(finish).replace('"','');
            query += ' AND ' + endApiName + ' > ' + JSON.serialize(start).replace('"','');
            query += ' ) OR ';
        }
        query = query.substringBeforeLast('OR');
        return query;
    }

    public class resourceModel {
        public string id;
        public string name;
        public string regionId;
        public List<eventModel> allEvents;
        public Geometry geometry;

        public resourceModel(){
            this.allEvents = new List<eventModel>();
        }

        // public eventModel addEvent(DateTime startTime, DateTime endTime, string eventType, boolean isAvailable) {
        //     return addEvent(startTime, endTime, eventType, isAvailable, null);
        // }

        // public eventModel addEvent(DateTime startTime, DateTime endTime, string eventType, boolean isAvailable, string relatedId) {
        //     if (isAvailable == true) {
        //         addAvailableBlock(startTime, endTime);
        //     }
        //     else {
        //         eventModel newEvent = new eventModel();
        //         newEvent.start = startTime;
        //         newEvent.finish = endTime;
        //         newEvent.eventType = eventType;
        //         this.allEvents.add(newEvent);
        //         return newEvent;
        //     }
        //     return null;
        // }

        public void addAvailableBlock(DateTime startTime, DateTime endTime) {
            List<eventModel> newEvents = new List<eventModel>();
            Set<DateTime> removedEvents = new Set<DateTime>();

            for (eventModel eventItem : this.allEvents) {
                if (eventItem.start < startTime && startTime < eventItem.finish) {
                    if (endTime < eventItem.finish) {
                        eventModel newEvent = new eventModel();
                        newEvent.start = endTime;
                        newEvent.finish = eventItem.finish;
                        newEvent.eventType = eventItem.eventType;
                        newEvents.add(newEvent);
                    }
                    eventItem.finish = startTime;
                }
                else if (startTime <= eventItem.start) {
                    if (endTime >= eventItem.finish) {
                        removedEvents.add(eventItem.start);
                    }
                    else if (eventItem.start < endTime && endTime < eventItem.finish) {
                        eventItem.start = endTime;
                    }
                }
            }

            for (integer i = this.allEvents.size() - 1; i >= 0; i--) {
                eventModel eventItem = this.allEvents.get(i);
                if (removedEvents.contains(eventItem.start)) {
                    this.allEvents.remove(i);
                }
            }

            this.allEvents.addAll(newEvents);
        }
    }

    public class eventModel implements Comparable{
        public Id id;
        public String name;
        public Datetime start;
        public Datetime finish;
        public String eventType;
        public String subType;
        public Id parentId;
        public String inspectionName;
        public String timezoneSidId;
        public Geometry geometry;

        public virtual Integer compareTo(Object compareTo) {
            eventModel compareToRecord = (eventModel)compareTo;
            Integer returnValue = 0;

            if (start > compareToRecord.start) {
                returnValue = 1;
            } else if (start < compareToRecord.start) {
                returnValue = -1;
            }
            return returnValue;
        }
    }

    public class TemplateEntryModel {
        public String weekday;
        public List<Integer> timeIndexes;
        public TemplateEntryModel() {
            this.timeIndexes = new List<Integer>{0,2400};
        }
    }

    public class Geometry {
        public string address;
        public decimal lat;
        public decimal lng;

        public Geometry(){}

        public Geometry(string address, decimal lat, decimal lng) {
            this.address = address;
            this.lat = lat;
            this.lng = lng;
        }

        public Geometry(Location geoLocation) {
            this.lat = geoLocation.getLatitude();
            this.lng = geoLocation.getLongitude();
        }
    }

}