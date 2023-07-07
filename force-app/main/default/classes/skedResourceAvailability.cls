public class skedResourceAvailability extends skedResourceAvailabilityBase {
    public skedResourceAvailability() {

    }

    public skedResourceAvailability setResources(Set<Id> resourceIds) {
        this.resourceIds = resourceIds;
        return this;
    }

    public skedResourceAvailability setTimePeriod(Map<Datetime, Datetime> mapTimePeriods) {
        this.mapTimePeriods = mapTimePeriods;
        return this;
    }

    public skedResourceAvailability setTimezone(String timezoneSidId) {
        this.timezoneSidId = timezoneSidId;
        return this;
    }

    public String getTimezone() {
        return this.timezoneSidId;
    }
}