public without sharing class skedResourceService {
    public List<skedAvailator.jobAllocation> validateResourceAvailability(Set<Id> resourceIds,  Set<Id> excludedJobIds, List<skedAvailator.jobModel> inputJobs, String timeZone, Boolean calculateTravelTime,
                                                                            Boolean exceptFirstOfDay, Integer buffer, Integer firstTimeslot) {
        skedResourceAvailability resourceAvailability = new skedResourceAvailability()
                                                        .setResources(resourceIds);
        System.debug('##### resourceAvailability : ' + resourceAvailability);
        skedAvailator availator = new skedAvailator()
                                    .setResourceAvailability(resourceAvailability)
                                    .setJobToValidate(inputJobs)
                                    .excludeEventIds(excludedJobIds)
                                    .calculateTravelTime(calculateTravelTime, exceptFirstOfDay, buffer, firstTimeslot)
                                    .setTimezone(timeZone)
                                    .initialize();

        System.debug('##### availator : ' + availator);

        availator.validateJobs();
        List<skedAvailator.jobAllocation> jobAllocations = availator.possibleAllocations;
        return jobAllocations;
    }
}