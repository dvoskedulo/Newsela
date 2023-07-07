public without sharing class skedCommonServices {
    public list<skedModels.BaseModel> getPicklistValues(string objName, String fld){
        list<skedModels.BaseModel> options = new list<skedModels.BaseModel>();
        Schema.DescribeSObjectResult objDescribe = Schema.getGlobalDescribe().get(objName).getDescribe();
        // Get a map of fields for the SObject
        map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
        // Get the list of picklist values for this field.
        list<Schema.PicklistEntry> values =fieldMap.get(fld).getDescribe().getPickListValues();
        // Add these values to the selectoption list.
        for (Schema.PicklistEntry a : values)
        {
            if ( a.isActive() ) {
                options.add(new skedModels.BaseModel(a.getValue(), a.getLabel() ));
            }            
        }
        return options;
    }   

    /*
    * operator: start with or like or not like
    */
    public List<skedModels.BaseModel> searchByName(String term, string objectName, string operator, String filters, Integer limitNumber) {
        list<skedModels.BaseModel> result = new list<skedModels.BaseModel>();
        if ( term == null ) term = '';                
        SObjectType objectType = ((SObject)(Type.forName('Schema.'+objectName).newInstance())).getSObjectType();
        skedObjectSelector objectSelector = skedObjectSelector.newInstance(objectType);     
        String filter;                   
        if ( operator == null ) {
            filter = ' Name Like \'' + '%' + term + '%' + '\'';
        }
        else {            
            if ('start with'.equalsIgnoreCase(operator)) {
                term = term + '%';
                filter = ' Name LIKE \'' + term + '\'';
            } else {
                term = '%' + term + '%';
                if ('NOT LIKE'.equalsIgnoreCase(operator)) {
                    filter = '(NOT Name LIKE \'' + term + '\'' + ')';
                } else {
                    filter = ' Name ' + operator + ' \'' + term + '\'';
                }
            }            
        }
        objectSelector.filter(filter);
        
        if ( !String.isEmpty(filters) ) {
            objectSelector.filter(filters);
        }
        if ( limitNumber != null ) {
            objectSelector.size(limitNumber);
        }
        System.debug('query@' + objectSelector.getQuery());
        
        for(sObject obj : Database.query(objectSelector.getQuery()) ) {
            if ( objectName.equalsIgnoreCase(skedConstant.LOCATION_API_NAME) ) {                
                result.add(new skedModels.LocationModel((sked__Location__c)obj) );
            }            
            else {
                result.add(new skedModels.BaseModel(obj));
            }            
        }
        return result;
    }  

    public string getEventSubject(sked__Job__c skedJob) {
        string subject = 'Newsela Professional Learning';
        if (skedJob.Activity_Medium__c != null) {
            subject += ' - ' + skedJob.Activity_Medium__c;
        }
        if (skedJob.sked__Account__c != null) {
            subject += ' - ' + skedJob.sked__Account__r.Name;
        }
        subject += ' - ' + skedJob.sked__Start__c.format(skedDateTimeUtils.DATE_FORMAT, skedJob.sked__Timezone__c);
        return subject;
    }
}