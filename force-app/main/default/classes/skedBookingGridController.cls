/**
 * @description       :
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             :
 * @last modified on  : 08-10-2021
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log
 * Ver   Date         Author                               Modification
 * 1.0   01-25-2021   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
global class skedBookingGridController {
    @remoteAction
    global static skedResponse getSubscriptionInfo(skedModels.SubscriptionInfoRequest request) {
        skedResponse result = new skedResponse();
        try {
            String subId = request.subId;
            if ( subId != null ) {
                skedObjectSelector subscriptionSelector =  skedObjectSelector.newInstance(SBQQ__Subscription__c.sObjectType);
                subscriptionSelector.filter('Id = :subId');
                subscriptionSelector.parentQuery('Account_Provisioned__c');
                subscriptionSelector.parentQuery('SBQQ__Product__c');
                List<SBQQ__Subscription__c> subscriptions = (List<SBQQ__Subscription__c>)Database.query(subscriptionSelector.getQuery());
                SBQQ__Subscription__c viewingSub;
                if ( !subscriptions.isEmpty() )
                    viewingSub = subscriptions.get(0);
                if ( viewingSub == null ) {
                    throw new skedExceptionHandler.CustomException('getSubscriptionInfo', 'No subscription found!');
                }
                if ( viewingSub.SBQQ__Product__c == null || String.isEmpty(viewingSub.SBQQ__Product__r.Family) || viewingSub.SBQQ__Product__r.Family != 'Professional Learning')
                {
                    throw new skedExceptionHandler.CustomException('getSubscriptionInfo', 'Subscription is not valid for Professional Learning!');
                }
                Integer totalAvailableCredits = Integer.valueOf(viewingSub.Total_number_of_sessions__c - viewingSub.PD_Events_Scheduled__c);
                if ( totalAvailableCredits <= 0 )
                {
                    ////System.debug('go here');
                    throw new skedExceptionHandler.CustomException('getSubscriptionInfo', 'Buy More Credits!');
                }

                if ( viewingSub.Account_Provisioned__c == null ) {
                    throw new skedExceptionHandler.CustomException('getSubscriptionInfo', 'No Account Provisioned for selected Subscription!');
                }

                skedModels.SubscriptionInfoResponse configData = new skedModels.SubscriptionInfoResponse();
                configData.account = new skedModels.AccountModel(viewingSub.Account_Provisioned__r);
                configData.productType = new skedModels.ProductTypeModel(viewingSub.SBQQ__Product__r.Product_Sub__c, viewingSub.SBQQ__Product__r.Product_Sub__c);
                configData.productType.locationRequired = configData.productType.id == 'In-Person' ? true : false;
                Set<String> deliveryMethods = skedSetting.instance.bookingGrid.getDeliveryMethods(viewingSub.SBQQ__Product__r.Product_Sub__c);
                if ( deliveryMethods != null ) {
                    for ( String deliveryMethod : deliveryMethods ) {
                        skedModels.OptionModel option = new skedModels.OptionModel(deliveryMethod, deliveryMethod);
                        String key = viewingSub.SBQQ__Product__r.Product_Sub__c + ':' + deliveryMethod;
                        sked_Delivery_Method_Setting__mdt dmSetting = skedSetting.instance.bookingGrid.getConfig(key);
                        if ( totalAvailableCredits >= dmSetting.sked_Credit__c ) {
                            option.seletable = true;
                        }
                        else {
                            option.seletable = false;
                        }
                        configData.deliveryMethods.add(option);
                    }
                }

                String regionName = viewingSub.Account_Provisioned__r.Skedulo_Territory__c;
                skedObjectSelector regionSelector =  skedObjectSelector.newInstance(sked__Region__c.sObjectType);
                regionSelector.filter('Name = :regionName');
                List<sked__Region__c> regions = (List<sked__Region__c>)Database.query(regionSelector.getQuery());

                if ( regions.isEmpty() ) {
                    throw new skedExceptionHandler.CustomException('getSubscriptionInfo', 'No Region found for selected Subscription!');
                }

                sked__Region__c region = regions.get(0);
                configData.region = new skedModels.RegionModel(region);
                result.data = configData;
            }
        }
        catch(skedExceptionHandler.CustomException cex) {
            result.message = cex.message;
            result.success = false;
        }
        catch (Exception ex) {
            result.getErrorMessage(ex);
        }
        return result;
    }

    @remoteAction
    global static skedResponse getTrainingLocations(skedModels.InputRequest request) {
        skedResponse result = new skedResponse();
        try {
            request.objectName = skedConstant.LOCATION_API_NAME;
            result.data = searchData(request);
         }
        catch (Exception ex) {
            result.getErrorMessage(ex);
        }
        return result;
    }

    //will rename getConfigData to getDeliveryMethodSetting
    @remoteAction
    global static skedResponse getConfigData(skedModels.ConfigurationRequest request) {
        skedResponse result = new skedResponse();
        try {
            skedModels.ConfigurationResponse data = new skedModels.ConfigurationResponse();
            String configKey = request.productType + ':' + request.deliveryMethod;
            String subId = request.subscription.id;
            skedObjectSelector subscriptionSelector =  skedObjectSelector.newInstance(SBQQ__Subscription__c.sObjectType);
            subscriptionSelector.filter('Id = :subId');
            List<SBQQ__Subscription__c> subscriptions = (List<SBQQ__Subscription__c>)Database.query(subscriptionSelector.getQuery());
            SBQQ__Subscription__c sub = subscriptions.get(0);
            sked_Delivery_Method_Setting__mdt setting = skedSetting.instance.bookingGrid.getConfig(configKey);
            if ( sub.SBQQ__StartDate__c == null || sub.SBQQ__EndDate__c == null ) {
                throw new skedExceptionHandler.CustomException('getConfigData', 'Subscription does not have start and end date');
            }
            if ( setting == null ) {
                throw new skedExceptionHandler.CustomException('getConfigData', 'There is no delivery setting for selected delivery method');
            }
            Date startDate;
            Integer startDateBuffer = Integer.valueOf(setting.sked_Start_Date_Buffer__c);

            Date today = date.today();
            if ( sub.SBQQ__StartDate__c > today.addDays(startDateBuffer) ) {
                startDate = sub.SBQQ__StartDate__c;
            }
            else {
                startDate = today.addDays(startDateBuffer);
            }

            data.defaultStartDate = JSON.serialize(startDate).replace('"', '');
            data.numberOfDays =  Integer.valueOf(skedSetting.instance.adminSetting.bookingGridPeriod);
            data.jobDuration = Integer.valueOf(setting.sked_Length__c);
            data.interval = Integer.valueOf(setting.sked_Interval_Slot__c);
            data.gridStart = Integer.valueOf(setting.sked_Earliest_Time_Start__c);
            data.gridEnd = Integer.valueOf(setting.sked_Latest_Time_End__c);
            result.data = data;
         }
         catch(skedExceptionHandler.CustomException cex) {
            result.message = cex.message;
            result.success = false;
        }
        catch (Exception ex) {
            result.getErrorMessage(ex);
        }
        return result;
    }

    @remoteAction
    global static skedResponse getBookingGrid(skedModels.bookingGridQueryModel queryModel) {
        skedResponse result = new skedResponse();
        try {
            queryModel.startDate = skedDateTimeUtils.getDateFromIsoString(queryModel.startDateISO);
            queryModel.endDate = skedDateTimeUtils.getDateFromIsoString(queryModel.endDateISO);
            String configKey = queryModel.productType + ':' + queryModel.deliveryMethod;
            sked_Delivery_Method_Setting__mdt setting = skedSetting.instance.bookingGrid.getConfig(configKey);
            Boolean requireLocation = queryModel.productType == 'In-Person' ? true : false;

            //System.debug('##### setting : ' + setting);
            //System.debug('##### requireLocation : ' + requireLocation);

            String subId = queryModel.subscription.id;
            skedObjectSelector subscriptionSelector =  skedObjectSelector.newInstance(SBQQ__Subscription__c.sObjectType);
            subscriptionSelector.filter('Id = :subId');
            subscriptionSelector.parentQuery('Account_Provisioned__c');
            List<SBQQ__Subscription__c> subscriptions = (List<SBQQ__Subscription__c>)Database.query(subscriptionSelector.getQuery());
            SBQQ__Subscription__c sub = subscriptions.get(0);
            // String accountTimezone = sub.Account_Provisioned__r.Timezone_c__c;

            //System.debug('##### sub : ' + sub);

            if ( sub.Account_Provisioned__c == null ) {
                throw new skedExceptionHandler.CustomException('getBookingGrid', 'No Account Provisioned for selected Subscription!');
            }
            String regionName = sub.Account_Provisioned__r.Skedulo_Territory__c;

            skedObjectSelector regionSelector =  skedObjectSelector.newInstance(sked__Region__c.sObjectType);
            regionSelector.filter('Name = :regionName');
            List<sked__Region__c> regions = (List<sked__Region__c>)Database.query(regionSelector.getQuery());

            if ( regions.isEmpty() ) {
                throw new skedExceptionHandler.CustomException('getBookingGrid', 'No Region found for selected Subscription!');
            }

            sked__Region__c region = regions.get(0);
            ////System.debug('region@@' + region);
            queryModel.region = new skedModels.RegionModel(region);

            //System.debug('##### region : ' + region);

            Date validStartDate;
            Integer startDateBuffer = Integer.valueOf(setting.sked_Start_Date_Buffer__c);

            Date today = date.today();
            if ( sub.SBQQ__StartDate__c > today.addDays(startDateBuffer) ) {
                validStartDate = sub.SBQQ__StartDate__c;
            }
            else {
                validStartDate = today.addDays(startDateBuffer);
            }

            Datetime validStart = skedDateTimeUtils.getStartOfDate(validStartDate, region.sked__Timezone__c);
            Datetime validEnd = skedDateTimeUtils.getEndOfDate(sub.SBQQ__EndDate__c, region.sked__Timezone__c);

            //System.debug('##### validStart : ' + validStart);
            //System.debug('##### validEnd : ' + validEnd);

            skedModels.bookingGridModel bookingGrid = initializeBookingGrid(queryModel);
            Map<string, skedModels.slotModel> mapSlot = bookingGrid.mapSlot;
            String timezone = queryModel.region.timezoneSidId;

            Set<Id> resourceIds = new Set<Id>();
            Map<Id, List<Datetime>> mapResourceToValidityPeriod = new Map<Id, List<Datetime>>();

            populateResourceIds(mapResourceToValidityPeriod, resourceIds, requireLocation, region.Id);
            Set<Id> qualifiedResourceIDs = filterResourceIds(setting, sub.Account_Provisioned__c, resourceIds);

            System.debug('##### qualifiedResourceIDs : ' + qualifiedResourceIDs);

            //remove resources which exceed maximum jobs in day
            Map<String, Set<Id>> map_Date_ResourceToRemove = new Map<String, Set<Id>>();

            if ( Test.isRunningTest() ) setting.sked_Maximum_Jobs_Per_Day__c = 100;
            if ( setting.sked_Maximum_Jobs_Per_Day__c != null ) {
                Map<String, Map<Id, Integer>> map_Date_Resource_NoOfJob = new Map<String, Map<Id, Integer>>();
                Set<String> allocationIgnoreStatus = new Set<String>{skedConstant.JOB_ALLOCATION_STATUS_DELETED};
                Set<String> jobIgnoreStatus = new Set<String>{skedConstant.JOB_STATUS_CANCELLED};
                for ( sked__Job_Allocation__c jobAlloc : [SELECT Id, sked__Job__r.sked__Start__c, sked__Resource__c FROM sked__Job_Allocation__c
                                                            WHERE sked__Resource__c IN :qualifiedResourceIDs
                                                            AND sked__Status__c NOT IN :allocationIgnoreStatus
                                                            AND sked__job__r.sked__Job_Status__c NOT IN :jobIgnoreStatus] )
                {
                    String strDate = jobAlloc.sked__Job__r.sked__Start__c.format(skedDateTimeUtils.DATE_ISO_FORMAT, timezone);
                    if ( !map_Date_Resource_NoOfJob.containsKey(strDate) ) {
                        map_Date_Resource_NoOfJob.put(strDate, new Map<Id, Integer>());
                    }
                    Map<Id, Integer> map_Resource_NoOfJob = map_Date_Resource_NoOfJob.get(strDate);

                    if ( !map_Resource_NoOfJob.containsKey(jobAlloc.sked__Resource__c) ) {
                        map_Resource_NoOfJob.put(jobAlloc.sked__Resource__c, 0);
                    }

                    Integer noOfJob = map_Resource_NoOfJob.get(jobAlloc.sked__Resource__c);

                    noOfJob +=1;
                    map_Resource_NoOfJob.put(jobAlloc.sked__Resource__c, noOfJob);

                }

                for ( String strDate : map_Date_Resource_NoOfJob.keySet() ) {
                    if (! map_Date_ResourceToRemove.containsKey(strDate) ) {
                        map_Date_ResourceToRemove.put(strDate, new Set<Id>());
                    }
                    Set<Id> resourceIdToRemove = map_Date_ResourceToRemove.get(strDate);
                    Map<Id, Integer> map_Resource_NoOfJob =   map_Date_Resource_NoOfJob.get(strDate);
                    for ( Id resourceId : map_Resource_NoOfJob.keySet() ) {
                        Integer noOfJob = map_Resource_NoOfJob.get(resourceId);
                        if ( noOfJob > setting.sked_Maximum_Jobs_Per_Day__c ) {
                            resourceIdToRemove.add(resourceId);
                        }
                    }
                }
            }

            DateTime bufferTime = system.now().addDays(-10);
            List<skedAvailator.jobModel> possibleJobs = new List<skedAvailator.jobModel>();
            for (skedModels.slotModel slot : mapSlot.values()) {
                if (slot.startTime < validStart || slot.startTime > validEnd ) {
                    continue;
                }
                skedAvailator.jobModel possibleJob = new skedAvailator.jobModel();
                possibleJob.start = slot.startTime;
                possibleJob.finish = skedDateTimeUtils.addMinutes(slot.startTime, queryModel.jobDuration, timezone);
                possibleJob.startTime = slot.slotTime;
                if ( queryModel.geometry != null ) {
                    possibleJob.geometry = new skedResourceAvailabilityBase.Geometry(queryModel.geometry.address, queryModel.geometry.lat, queryModel.geometry.lng);
                }

                possibleJobs.add(possibleJob);
            }

            System.debug('##### possibleJobs : ' + JSON.serialize(possibleJobs));

            if (possibleJobs.size() > 0) {
                skedResourceService rsService = new skedResourceService();
                Integer buffer = Integer.valueOf(setting.sked_Buffer__c);
                Integer earliestTimeSlot = queryModel.startTimeInt;
                Boolean exceptFirstSlot = setting.sked_Except_first_of_day__c;
                List<skedAvailator.jobAllocation> jobAllocations = rsService.validateResourceAvailability(qualifiedResourceIDs,  null, possibleJobs, timeZone, requireLocation, exceptFirstSlot, buffer, earliestTimeSlot);

                //System.debug('##### jobAllocations size : ' + jobAllocations.size());
                System.debug('##### jobAllocations : ' + JSON.serialize(jobAllocations));

                ////System.debug('jobAllocations==>' + JSON.serialize(jobAllocations));
                Map<String, Set<Id>> mapJobToAvailableResourceIds = new Map<String, Set<Id>>();
                for ( skedAvailator.jobAllocation jobAllocation : jobAllocations ) {
                    // String key = Json.serialize(jobAllocation.job.start);
                    String key = jobAllocation.job.start.format(skedDateTimeUtils.DATE_TIME_FORMAT, queryModel.region.timezoneSidId);
                    if ( !mapJobToAvailableResourceIds.containsKey(key) ) {
                        mapJobToAvailableResourceIds.put(key, new Set<Id>());
                    }

                    if ( jobAllocation.isAvailable ) {
                        if ( mapResourceToValidityPeriod.containsKey(jobAllocation.resource.id) ) { //this resource has secondary region with validity period
                            List<Datetime> validityPeriod = mapResourceToValidityPeriod.get(jobAllocation.resource.id);
                            if ( !(validityPeriod[0] <= jobAllocation.job.start && validityPeriod[1] >= jobAllocation.job.finish) ) {
                                continue; //resource is not in valid secondary region period
                            }
                        }
                        mapJobToAvailableResourceIds.get(key).add(jobAllocation.resource.id);
                    }
                }
                System.debug('##### mapJobToAvailableResourceIds : ' + JSON.serialize(mapJobToAvailableResourceIds));
                ////System.debug('mapJobToAvailableResourceIds==>' + JSON.serialize(mapJobToAvailableResourceIds));
                Map<Id, sked__Resource__c> mapResources = new Map<Id, sked__Resource__c>([SELECT Id, Name, sked__User__c, sked__User__r.smallPhotoUrl, sked__Mobile_Phone__c
                                                                                        FROM sked__Resource__c
                                                                                        WHERE Id IN :qualifiedResourceIDs]);
                for (String key : mapJobToAvailableResourceIds.keySet() ) {
                    skedModels.slotModel slot = mapSlot.get(key);
                    Set<Id> availableResourceIDs = mapJobToAvailableResourceIds.get(key);
                    if ( map_Date_ResourceToRemove.containsKey(slot.slotDate) ) {
                        Set<Id> resourceIdToRemove = map_Date_ResourceToRemove.get(slot.slotDate);
                        availableResourceIDs.removeAll(resourceIdToRemove);
                    }
                    slot.noOfAvailableResources = availableResourceIDs.size();
                    for ( Id resourceId : availableResourceIDs ) {
                        sked__Resource__c resource = mapResources.get(resourceId);
                        slot.availableResources.add( new skedModels.ResourceModel(resource) );
                    }
                    slot.availableResources.sort();
                }
            }
            System.debug('##### mapSlot : ' + JSON.serialize(mapSlot));
            result.data = bookingGrid;
        }
        catch (Exception ex) {
            result.getErrorMessage(ex);
        }
        return result;
    }

    @remoteAction
    global static skedResponse getAddressGeoLocation(skedModels.AddressGeolocationRequest request){
        skedResponse response = new skedResponse();
        try {
            skedModels.AddressModel addr = new skedModels.AddressModel();
            addr.placeId = request.placeId;
            if (String.isBlank(request.placeId)) {
                List<Location> locationList = skedSkeduloApiManager.geocode( new List<String> {request.address} ).toLocations();
                if ( !locationList.isEmpty() ) {
                    Location bookingLocation = locationList.get(0);
                    skedModels.Geometry geometry = new skedModels.Geometry(bookingLocation);
                    geometry.address = request.address;
                    addr.geometry = geometry;
                }
            }
            else {
                sked.ApiResult.Place place = sked.SkeduloApi.place(request.placeId, request.skedApiSession);
                if (place.success) {
                    String street = (String.isBlank(place.result.addressComponents.streetNumber) ? '' : place.result.addressComponents.streetNumber + ' ') + place.result.addressComponents.route;
                    skedModels.PlaceInfoModel placeInfo = new skedModels.PlaceInfoModel();
                    placeInfo.street = street;
                    placeInfo.State = place.result.addressComponents.area1;
                    placeInfo.PostalCode = place.result.addressComponents.postalCode;
                    placeInfo.country = place.result.addressComponents.country;

                    Location loc = Location.newInstance(place.result.geometry.lat, place.result.geometry.lng);
                    skedModels.Geometry geometry = new skedModels.Geometry(loc);
                    geometry.address = place.result.formattedAddress;
                    addr.geometry = geometry;
                    addr.placeInfo = placeInfo;
                }
            }

            response.data = addr;

        } catch ( Exception ex ) {
            response.getErrorMessage(ex);
        }
        return response;
    }

    @remoteAction
    global static skedResponse getAddresses(String searchingText) {
        skedResponse response = new skedResponse();
        try {
            searchingText = EncodingUtil.urlEncode(searchingText, 'UTF-8');
            String country = skedSetting.instance.adminSetting.countryCode;
            String sessionId = sked.SkeduloAPI.getSessionId();
            List<skedSkeduloApiData.Prediction> predictions =  skedSkeduloApiManager.autocomplete(searchingText, country, sessionId);
            skedModels.AutoCompleteResponse result = new skedModels.AutoCompleteResponse();
            result.skedApiSession = sessionId;
            result.predictions = predictions;
            response.data = result;
        } catch ( Exception ex ) {
            response.getErrorMessage(ex);
        }
        return response;
    }

    @remoteAction
    global static skedResponse getConfig(configRequest request) {
        skedResponse response = new skedResponse();
        try {
            skedModels.config c = new skedModels.config();
            c.siteSetting = skedSetting.instance.defaultSiteSetting;

            SBQQ__Subscription__c subscription = [SELECT SBQQ__Contract__c FROM SBQQ__Subscription__c WHERE Id = :request.subscriptionId];
            Contract contract = [SELECT Has_Custom_Collections__c,Has_Blended_Learning_District_Suite__c,Has_LGBTQIA__c, Has_ELA__c, Has_Essentials__c, Has_SEL__c, Has_Social_Studies__c, Has_Science__c
                                 FROM Contract
                                 WHERE Id = :subscription.SBQQ__Contract__c];

            for (skedModels.Question question : c.siteSetting.survey.questions) {
                system.debug('question--->'+question);
                if (question.question == 'Which session would you like to book?') {
                         if (contract.Has_Custom_Collections__c == true) {
                        question.options.add('Implementing Your Custom Collections');
                    }
                    if (contract.Has_Essentials__c == true||contract.Has_ELA__c == true) {
                        question.options.add('Discussing Complex Topics'); 
                        question.options.add('Building Background Knowledge');
                        question.options.add('Reinforcing Reading Skills');
                        question.options.add('Rethinking History');
                        question.options.add('Integrating Science and Literacy');
                     }
                    if (contract.Has_SEL__c == true) {
                        question.options.add('Social-Emotional Learning');
                    }
                    if (contract.Has_Social_Studies__c == true) {
                        question.options.add('Rethinking History');
                        question.options.add('Building Background Knowledge');
                        question.options.add('Discussing Complex Topics'); 
                        question.options.add('Social Justice in Your Classroom');
                    }
                    if (contract.Has_Science__c == true) {
                        question.options.add('Integrating Science and Literacy');
                    }
                    if (contract.Has_LGBTQIA__c == true) {
                        question.options.add('LGBTQIA+ Studies');
                    }
                    if (contract.Has_Blended_Learning_District_Suite__c == true) {
                        question.options.add('Discussing Complex Topics'); 
                        question.options.add('Building Background Knowledge');
                        question.options.add('Reinforcing Reading Skills');
                        question.options.add('Rethinking History');
                        question.options.add('Integrating Science and Literacy');
                        question.options.add('Social-Emotional Learning');
                    } 
   
                   break;
                }
            }

            response.data = c;
        } catch ( Exception ex ) {
            response.getErrorMessage(ex);
        }
        return response;
    }

    @remoteAction
    global static skedResponse scheduleJob(skedModels.JobCreationRequest request) {
        //System.debug('#request '+request);
        skedResponse response = new skedResponse();
        try {
            Id resourceId;
            sked__Resource__c skedResource;
            if ( !request.availableResources.isEmpty() ) {
                request.availableResources.sort();
                resourceId = (request.availableResources.get(0)).id;
                skedResource = [SELECT Id, sked__Home_Address__c, sked__GeoLocation__Latitude__s, sked__GeoLocation__Longitude__s
                                FROM sked__Resource__c
                                WHERE Id = :resourceId];
            }

            string addtionalDetails = '';
            string sessionDelivered = '';
            if (request.surveys != null && !request.surveys.isEmpty()) {
                addtionalDetails = 'Additional Details:<br/>' + '\n';
                for (skedModels.SurveyModel survey : request.surveys) {
                    addtionalDetails += '<p>' + survey.question + ' ((' + survey.answer + '))</p>' + '\n';
                    if ( survey.id == skedSetting.instance.adminSetting.sessionDeliveredQuestionId ) {
                        sessionDelivered = survey.answer;
                    }
                }
                addtionalDetails += '<p>Customer Name' + ' ((' + request.job.customerName + '))</p>' + '\n';
                addtionalDetails += '<p>Customer Email' + ' ((' + request.job.customerEmail + '))</p>' + '\n';
                addtionalDetails += '<p>Customer Phone' + ' ((' + request.job.customerPhoneNo + '))</p>' + '\n';
            }

            Contact con;
            Account acc;
            sked__Region__c skedRegion;
            if (request.subscription != null && request.subscription.account != null) {
                List<Contact> contacts = [SELECT Id, AccountId, Account.Skedulo_Territory__c FROM Contact WHERE AccountId = :request.subscription.account.id];
                if (!contacts.isEmpty()) {
                    con = contacts[0];
                }
                acc = [SELECT Id, Skedulo_Territory__c FROM Account WHERE Id = :request.subscription.account.id];

                string regionName = con != null ? con.Account.Skedulo_Territory__c : acc.Skedulo_Territory__c;
                ////System.debug('regionName@' + regionName);
                List<sked__Region__c> regions = [SELECT Id, sked__Timezone__c FROM sked__Region__c WHERE Name = :regionName];
                if (!regions.isEmpty()) {
                    skedRegion = regions[0];
                }
            }

            if (skedRegion != NULL) {
                string timezoneSidId = skedRegion.sked__Timezone__c;
                Date jobDate = skedDateTimeUtils.getDateFromIsoString(request.job.jobDate);
                Datetime startOfDate = skedDateTimeUtils.getStartOfDate(jobDate, timezoneSidId);
                Integer startTimeInMinutes = skedDateTimeUtils.convertTimeNumberToMinutes(request.job.startTime);
                Integer endTimeInMinutes = skedDateTimeUtils.convertTimeNumberToMinutes(request.job.endTime);
                Datetime start = skedDateTimeUtils.addMinutes(startOfDate, startTimeInMinutes, timezoneSidId);
                Datetime finish = skedDateTimeUtils.addMinutes(startOfDate, endTimeInMinutes, timezoneSidId);

                sked__Job__c jobToInsert = new sked__Job__c (
                    sked__Account__c = acc != null ? acc.Id : null,
                    sked__Contact__c = con != null ? con.Id : null,
                    sked__Region__c = skedRegion.Id,
                    sked__Type__c = request.job.jobType,
                    sked__Address__c = request.job.address == null ?
                                        ((skedResource != null && string.isNotBlank(skedResource.sked__Home_Address__c)) ? skedResource.sked__Home_Address__c : null) :
                                        request.job.address.geometry.address,
                    sked__GeoLocation__Latitude__s = request.job.address == null ?
                                                        ((skedResource != null && skedResource.sked__GeoLocation__Latitude__s != null) ? skedResource.sked__GeoLocation__Latitude__s : null) :
                                                        request.job.address.geometry.lat,
                    sked__GeoLocation__Longitude__s = request.job.address == null ?
                                                        ((skedResource != null && skedResource.sked__GeoLocation__Longitude__s != null) ? skedResource.sked__GeoLocation__Longitude__s : null) :
                                                        request.job.address.geometry.lng,
                    sked__Start__c = start,
                    sked__Finish__c = finish,
                    sked__Duration__c = request.job.duration,
                    //sked__Location__c = request.job.location == null ? null : request.job.location.id,
                    sked_Additional_Details__c = addtionalDetails,
                    Session_Delivered__c = sessionDelivered,
                    Subscription_Number__c = request.subscription != null ? request.subscription.id : null,
                    sked_Delivery_Method__c = request.job.deliveryMethod,
                    sked_Customer_Name__c = request.job.customerName,
                    sked_Customer_Email__c = request.job.customerEmail,
                    sked_Customer_Phone_Number__c = request.job.customerPhoneNo,
                    sked_Location__c = request.job.locationText
                );
                upsert jobToInsert;

                if ( resourceId != null ) {
                    sked__Job_Allocation__c allocation = new sked__Job_Allocation__c(
                        sked__Job__c = jobToInsert.Id,
                        sked__Resource__c = resourceId,
                        sked__Status__c = request.job.jobType.contains('Virtual') ? skedConstant.JOB_ALLOCATION_STATUS_DISPATCHED : skedConstant.JOB_ALLOCATION_STATUS_PENDING_DISPATCH
                    );
                    insert allocation;
                }

                if (request.job.jobType.contains('Virtual') && !request.job.deliveryMethod.contains('Asynchronous')) {
                    createVirtualMeeting(jobToInsert.Id);
                }

                response.data = jobToInsert.Id;
            }
            else {
                skedExceptionHandler.CustomException ex = new skedExceptionHandler.CustomException('scheduleJob', 'There is no valid Region!');
                response.message = ex.message;
                response.success = false;
            }
        } catch ( Exception ex ) {
            response.getErrorMessage(ex);
        }
        return response;
    }


    /*********************************private method*********** */
    static List<skedModels.BaseModel> searchData(skedModels.InputRequest request) {
        List<skedModels.BaseModel> response;
        skedCommonServices cmService = new skedCommonServices();
        if ( request.objectName == skedConstant.LOCATION_API_NAME ) {
            response = cmService.searchByName(request.searchingName, skedConstant.LOCATION_API_NAME, null, null, 10);
        }

        return response;
    }

    private static skedModels.bookingGridModel initializeBookingGrid(skedModels.bookingGridQueryModel queryModel) {
        skedModels.bookingGridModel bookingGrid = new skedModels.bookingGridModel();

        Date startDate = queryModel.startDate;
        Date endDate = queryModel.endDate;

        ////System.debug('startDate Init ' + JSON.serialize(startDate) );
        ////System.debug('startDate Init ' + JSON.serialize(endDate));
        ////System.debug('queryModel ++ ' + JSON.serialize(queryModel));

        queryModel.startTime = skedDateTimeUtils.getStartOfDate(startDate, queryModel.region.timezoneSidId);
        queryModel.endTime = skedDateTimeUtils.getEndOfDate(endDate, queryModel.region.timezoneSidId);


        ////System.debug('queryModel.startTime Init ' + JSON.serialize(queryModel.startTime));
        ////System.debug('queryModel.endTime Init ' + JSON.serialize(queryModel.endTime));
        // queryModel.startTimeInt = Integer.valueOf('800');
        // queryModel.endTimeInt = Integer.valueOf('1800');

        integer firstSlotStartInMinutes = skedDateTimeUtils.convertTimeNumberToMinutes(queryModel.startTimeInt);
        integer lastSlotEndInMinutes = skedDateTimeUtils.convertTimeNumberToMinutes(queryModel.endTimeInt);

        integer slotStartInMinutes = firstSlotStartInMinutes;
        while (slotStartInMinutes <= lastSlotEndInMinutes) {
            DateTime tempDt = queryModel.startTime;
            skedModels.bookingGridRowModel row = new skedModels.bookingGridRowModel();
            row.startTimeInt = (slotStartInMinutes / 60) * 100 + Math.mod(slotStartInMinutes, 60);

            while (tempDt < queryModel.endTime) {
                DateTime slotStart = skedDateTimeUtils.addMinutes(tempDt, slotStartInMinutes, queryModel.region.timezoneSidId);

                skedModels.slotModel slot = new skedModels.slotModel();
                slot.slotDate = slotStart.format(skedDateTimeUtils.DATE_ISO_FORMAT, queryModel.region.timezoneSidId);
                slot.slotTime = integer.valueOf(slotStart.format('Hmm', queryModel.region.timezoneSidId));
                slot.startTime = slotStart;
                slot.slotKey = slotStart.format(skedDateTimeUtils.DATE_TIME_FORMAT, queryModel.region.timezoneSidId);

                row.slots.add(slot);
                bookingGrid.mapSlot.put(slot.slotKey, slot);
                tempDt = skedDateTimeUtils.addDays(tempDt, 1, queryModel.region.timezoneSidId);

                if(row.slots.size() == 7) break;
            }

            bookingGrid.rows.add(row);
            slotStartInMinutes += queryModel.timeslotStep;
        }
        ////System.debug('bookingGrid  ' + JSON.serialize(bookingGrid) );
        return bookingGrid;
    }

    private static void populateResourceIds(Map<Id, List<Datetime>> mapResourceToValidityPeriod, Set<Id> resourceIds, Boolean requireLocation, Id regionId) {
        if ( requireLocation ) {
            for(sked__Resource__c res: [select id from sked__Resource__c where sked__Primary_Region__c =:regionId and sked__Is_Active__c = true]){
                resourceIds.add(res.id);
            }
            for (sked__Resource_Region__c rr : [SELECT sked__Resource__c, sked__Start__c,sked__End__c  FROM sked__Resource_Region__c
                                            WHERE sked__Region__c = :regionId
                                            AND sked__Resource__r.sked__Is_Active__c = true])
            {
                resourceIds.add(rr.sked__Resource__c);
                if ( rr.sked__Start__c != null && rr.sked__End__c != null ) {
                    mapResourceToValidityPeriod.put(rr.sked__Resource__c, new List<Datetime>{rr.sked__Start__c, rr.sked__End__c});
                }

            }
        }
        else {
            for(sked__Resource__c res: [select id from sked__Resource__c where sked__Is_Active__c = true ]){
                resourceIds.add(res.id);
            }
        }
        System.debug('##### mapResourceToValidityPeriod : ' + mapResourceToValidityPeriod);
        System.debug('##### resourceIds : ' + resourceIds);
    }


    private static Set<Id> filterResourceIds(sked_Delivery_Method_Setting__mdt setting, string accountId, Set<Id> resourceIds) {
        Set<Id> qualifiedResourceIDs = new Set<Id>();
        Set<Id> tagIds = new Set<Id>();
        Set<String> tagNames = new Set<String>();
        String key = ''; //key will be account tier + delivery tags

        //get Tag Name from Account API Fields - Tags setting
        Set<String> accountAPIFieldNames = skedSetting.instance.fieldTagSetting.getFieldAPINames(skedConstant.ACCOUNT_API_NAME);
        String accountQuery = 'select ' + String.join(new List<String>(accountAPIFieldNames), ',') + ' from Account where id = :accountId';
        //System.debug('accountQuery==>' + accountQuery);
        SObject acctProvisioned = (Database.query(accountQuery)).get(0);
        for ( String actAPIFieldName : accountAPIFieldNames ) {
            if ( acctProvisioned.get(actAPIFieldName) != null ) {
                String value = (String)acctProvisioned.get(actAPIFieldName);
                tagNames.add(value);
                if ( actAPIFieldName.equalsIgnoreCase(skedConstant.ACCOUNT_TIER_API_NAME) ) {
                    key = value + ':';
                }
            }
        }

        //get Tag Names from Delivery Method setting
        List<String> deliveryTags = new List<String>();
        if ( setting.Tags__c != null ) {
            for ( String tgName : setting.Tags__c.split(';') ) {
                tgName = tgName.trim();
                tagNames.add(tgName);
                deliveryTags.add(tgName);
            }
        }
        deliveryTags.sort();
        for ( String tgName : deliveryTags ) {
            key += tgName + ';';
        }

        //get resource group from custom metadata
        String resourceGroup = skedSetting.instance.resourceGroupMapping.getResourceGroup(key);
        //System.debug('resourceIds==>' + resourceIds);
        //System.debug('tagNames==>' + tagNames);
        //System.debug('key==>' + key);
        //System.debug('resourceGroup==>' + resourceGroup);
        String query = 'SELECT Id FROM sked__Resource__c WHERE ID IN :resourceIds AND sked__Is_Active__c = TRUE';
        if ( resourceGroup != null ) {
            query += ' AND sked_Resource_Group__c = :resourceGroup';
        }
        //System.debug('query==>' + query);
        Map<Id, SObject> mapResources = new Map<Id, SObject>( Database.query(query) );
        //System.debug('mapResources==>' + mapResources);
        //query tag IDS based on tag names
        for (sked__Tag__c tag : [SELECT Id FROM sked__Tag__c WHERE Name IN :tagNames]) {
            tagIds.add(tag.Id);
        }

        if ( !tagIds.isEmpty() ) {
            Map<Id, Set<Id>> mapResourceToRequiredTags = new Map<Id, Set<Id>>();
            for (sked__Resource_Tag__c skedResourceTag : [SELECT Id, sked__Tag__c,sked__Resource__c
                                                            FROM sked__Resource_Tag__c
                                                            WHERE sked__Tag__c IN :tagIds
                                                            AND sked__Resource__c IN :mapResources.keySet()
                                                            AND sked__Resource__r.sked__Is_Active__c = TRUE]) {
                //todo: filter resource tags
                if ( !mapResourceToRequiredTags.containsKey(skedResourceTag.sked__Resource__c) ) {
                    mapResourceToRequiredTags.put(skedResourceTag.sked__Resource__c, new Set<Id>());
                }
                mapResourceToRequiredTags.get(skedResourceTag.sked__Resource__c).add(skedResourceTag.sked__Tag__c);
            }

            for ( Id resourceId : mapResourceToRequiredTags.keySet() ) {
                Set<Id> resourceTagIds = mapResourceToRequiredTags.get(resourceId);
                if ( resourceTagIds.containsAll(tagIds)) {
                    qualifiedResourceIDs.add(resourceId);
                }
            }
        }
        else {
            qualifiedResourceIDs = mapResources.keySet();
        }
        //System.debug('qualifiedResourceIDs@==>' + qualifiedResourceIDs);
        return qualifiedResourceIDs;
    }

    @future(callout=true)
    private static void createVirtualMeeting(string jobId) {
        skedVirtualMeetingService.createMeeting(jobId);
    }
    /***************************************************** Nested classes *************************************************/
    global class configRequest {
        public string subscriptionId;
    }
}