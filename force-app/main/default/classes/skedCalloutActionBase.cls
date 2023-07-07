public abstract class skedCalloutActionBase {

    public skedCalloutResultBase execute(string endPoint, string httpMethod, Map<string, string> mapHeader, string body) {
        beforeExecute();
        skedCalloutResultBase result = doExecute(endPoint, httpMethod, mapHeader, body);
        afterExecute();

        return result;
    }

    protected virtual void beforeExecute() {

    }

    protected virtual void afterExecute() {

    }

    protected virtual skedCalloutResultBase initializeResult() {
        return new skedCalloutResultBase();
    }

    protected virtual skedCalloutResultBase doExecute(string endPoint, string httpMethod, Map<string, string> mapHeader, string body) {
        skedCalloutResultBase result = initializeResult();
        System.debug('execute@');
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endPoint);
        if (!string.isBlank(body)) {
            req.setBody(body);
        }
        else {
            req.setHeader('Content-length', '0');
        }

        if (httpMethod == 'PATCH') {
            req.setHeader('X-HTTP-Method-Override', 'PATCH');
        }
        for (string headerKey : mapHeader.keySet()) {
            string headerValue = mapHeader.get(headerKey);
            req.setHeader(headerKey, headerValue);
        }

        httpMethod = httpMethod == 'PATCH' ? 'POST' : httpMethod;
        req.setMethod(httpMethod);
        req.setTimeout(60000);

        Http h = new Http();
        HttpResponse res;
        if (!Test.isRunningTest()) {
            res = h.send(req);
        } else {
            res = new HttpResponse();
            if ( endPoint.containsIgnoreCase(skedSkeduloApiManager.AVAILABILITY_SIMPLE_ENDPOINT) ) {
                res.setBody(populateTestTemplatePatternJSON());
            }
            else if ( endPoint.containsIgnoreCase(skedSkeduloApiManager.VIRTUAL_MEETING_ENDPOINT) ) {
                skedDataFactory.skedMockDataFactory mockFactory = new skedDataFactory.skedMockDataFactory();
                if ( httpMethod == 'GET' ) {
                    res = mockFactory.getGetMeetingDetailsResponse(req, false);
                }
                else if ( httpMethod == 'POST' ) {
                    res = mockFactory.getCreateMeetingResponse(req, false);
                }
                else if ( httpMethod == 'PUT' ) {
                    res = mockFactory.getUpdateMeetingResponse(req, false);
                }
                else if ( httpMethod == 'DELETE' ) {
                    res = mockFactory.getDeleteMeetingResponse(req, false);
                }
            }
            
        }

        string response = res.getBody();
        string status = res.getStatus();
        integer statusCode = res.getStatusCode();
        System.debug('response@' + response);

        if (statusCode >= 400) {
            result.success = false;
            throw new skedExceptionHandler.CustomException(statusCode, status, response);
        }
        else {
            result = processResponse(response);
        }

        result.status = status;
        result.statusCode = statusCode;
        return result;
    }

    protected virtual skedCalloutResultBase processResponse(string response) {
        skedCalloutResultBase result = new skedCalloutResultBase();
        result.response = response;
        return result;
    }

    public String replaceReservedJSON(String data, Boolean isRequest) {
        //String regexFormat = '(?m)^\\s*"{0}"\\s*:';
        //String replacementFormat = '"{0}" :';
        Map<String, String> replacements = getReplacements(isRequest);
        // String formattedJSON = JSON.serializePretty(JSON.deserializeUntyped(data));
        
        for (String key : replacements.keySet()) {
            //String regex = String.format(regexFormat, new List<String> {key});
            //String replacement = String.format(replacementFormat, new List<String> {replacements.get(key)});
            data = data.replace(key, replacements.get(key));
        }
        
        return data;
    }
    
    private Map<String, String> getReplacements(Boolean isRequest) {
        if (isRequest) {
            return new Map<String, String> {
                'end_x' => 'end',
                'time_x' => 'time'
            };
        } else {
            return new Map<String, String> {
                'end' => 'end_x'
                // 'time' => 'time_x',
                // 'type'  => 'type_x'
            };
        }
    }

    public String populateTestTemplatePatternJSON() {
        List<skedSkeduloApiData.simplifiedAvailability> mergedAvailabilities = new List<skedSkeduloApiData.simplifiedAvailability>();
        Datetime startOfDate = Datetime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));        
        Integer i = -5;
        while ( i < 20 ) {
            Datetime start = startOfDate.addDays(i);
            Datetime finish = startOfDate.addDays(i+1);
            skedSkeduloApiData.simplifiedAvailability availability = new skedSkeduloApiData.simplifiedAvailability();
            availability.start = start;
            availability.end_x = finish;
            mergedAvailabilities.add(availability);
            i++;
        }        

        skedSkeduloApiData.simplifiedResourceAvailability simplifyAvailability = new skedSkeduloApiData.simplifiedResourceAvailability();
        simplifyAvailability.mergedAvailabilities = mergedAvailabilities;
        simplifyAvailability.resourceId = '{0}';
        skedSkeduloApiData.simplifiedResourceAvailabilityResult result = new skedSkeduloApiData.simplifiedResourceAvailabilityResult();
        result.result = new List<skedSkeduloApiData.simplifiedResourceAvailability>();  
        result.result.add(simplifyAvailability);
        String jsonResponse = JSON.serialize(result);      
        sked__Resource__c resource = [SELECT Id FROM sked__Resource__c LIMIT 1];
        system.debug('#resource#' + resource.Id);
        jsonResponse = jsonResponse.replace('{0}', resource.Id);
        return jsonResponse;
    }

}