public virtual class skedAvailabilityTemplateService {
    protected integer maxOrigins = 100;
    protected Datetime startTime;
    protected Datetime endTime;
    protected List<Id> resourceIds;
    protected String timezoneSidId;
    protected Boolean mergedAvailabilities;
    public List<skedSkeduloApiData.simplifiedResourceAvailabilityResult> results;
    public skedAvailabilityTemplateService(List<Id> resourceIds, Datetime startTIme, Datetime endTime, String timezoneSidId, Boolean mergedAvailabilities) {
        this.resourceIds = resourceIds;
        this.startTime = startTime;
        this.endTime = endTime;
        this.timezoneSidId = timezoneSidId;
        this.mergedAvailabilities = mergedAvailabilities;
        this.results = new List<skedSkeduloApiData.simplifiedResourceAvailabilityResult> ();
    }

    public void initialize() {
        skedSkeduloApiManager apiManager = new skedSkeduloApiManager();
        List<skedSkeduloApiData.simplifiedResourceAvailabilityPayload> requests = getRequestList();
        for ( skedSkeduloApiData.simplifiedResourceAvailabilityPayload request :  requests) {
            System.debug('CPU time in callout 1@' + Limits.getCpuTime()); 
            skedSkeduloApiData.simplifiedResourceAvailabilityResult result = apiManager.getSimplifiedResourceAvailability(request);
            System.debug('CPU time in callout 2@' + Limits.getCpuTime()); 
            this.results.add(result);
        }
    }

    protected List<skedSkeduloApiData.simplifiedResourceAvailabilityPayload> getRequestList() {
        List<skedSkeduloApiData.simplifiedResourceAvailabilityPayload> requests = new List<skedSkeduloApiData.simplifiedResourceAvailabilityPayload>();        
        List<Id> lstTemp;
        Integer size = this.resourceIds.size();
        for ( Integer i = 0; i <= (size/maxOrigins)+1 ; i++ ) {
            lstTemp = new List<Id>();
            for ( Integer j=(i*maxOrigins); (j < (i*maxOrigins + maxOrigins)) && (j < size) ; j++) {
                lstTemp.add(this.resourceIds[j]);
            }
            if ( !lstTemp.isEmpty() ) {
                System.debug('lstTemp@@' + lstTemp.size());
                skedSkeduloApiData.simplifiedResourceAvailabilityPayload payload = new skedSkeduloApiData.simplifiedResourceAvailabilityPayload();
                payload.resource_ids = string.join(lstTemp, ',');
                payload.start = startTime.format(skedDateTimeUtils.DATE_TIME_ISO_FORMAT, this.timezoneSidId);
                payload.end_x = endTime.addDays(1).format(skedDateTimeUtils.DATE_TIME_ISO_FORMAT, this.timezoneSidId);
                system.debug('payload: ' + payload.start + '-' + payload.end_x);
                payload.mergedAvailabilities = this.mergedAvailabilities;
                requests.add(payload);
            }            
        }
        return requests;
    }
}