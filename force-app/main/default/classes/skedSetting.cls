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
public without sharing class skedSetting {
    private static Integer DEFAULT_LIMIT_RECORDS = 1000;
    private static skedSetting mInstance = null;

    public static skedSetting instance {
        get {
            if (mInstance == null) {
                mInstance = new skedSetting();
            }
            return mInstance;
        }
    }

    public BookingGridSetting bookingGrid {
        get {
            if (bookingGrid == null) {
                bookingGrid = new BookingGridSetting();
            }
            return bookingGrid;
        }
        set;
    }

    public skedAdminSetting adminSetting {
        get {
            if(adminSetting == null){
                adminSetting = new skedAdminSetting();
            }

            return adminSetting;
        }
        set;
    }

    public FieldToTagSetting fieldTagSetting {
        get {
            if(fieldTagSetting == null){
                fieldTagSetting = new FieldToTagSetting();
            }

            return fieldTagSetting;
        }
        set;
    }

    public ResourceGroupTagMapping resourceGroupMapping {
        get {
            if(resourceGroupMapping == null){
                resourceGroupMapping = new ResourceGroupTagMapping();
            }

            return resourceGroupMapping;
        }
        set;
    }



    public skedModels.SiteSetting defaultSiteSetting{
        get {
            if (defaultSiteSetting == null) {
                skedObjectSelector selector = skedObjectSelector.newInstance(Site_Setting__c.sObjectType);
                selector.filter('Default_Setting__c = true');
                selector.subQuery('Questions__r')
                    .filter('Is_Active__c = true')
                    .sort('Order__c', 'ASC')
                    .parentQuery('Group__c');
                selector.size(1);
                List<Site_Setting__c> siteSettings = Database.query( selector.getQuery() );
                for (Site_Setting__c setting : siteSettings) {
                    defaultSiteSetting = new skedModels.SiteSetting().init( setting );
                    defaultSiteSetting.addQuestions(setting.Questions__r);
                }
                defaultSiteSetting.calendarTemplate = siteSettings[0].Calendar_Template__c;
            }

            return defaultSiteSetting;
        }
        set;
    }

    public class BookingGridSetting {
        private Map<String, sked_Delivery_Method_Setting__mdt> skedConfigsInstance = null;
        private Map<String, Set<String>> map_ProductType_DeliveryMethod = new Map<String, Set<String>> ();
        public BookingGridSetting() {
            this.skedConfigsInstance = new Map<string, sked_Delivery_Method_Setting__mdt>();

            for ( sked_Delivery_Method_Setting__mdt config : [SELECT Id, DeveloperName, sked_Buffer__c, sked_Credit__c, sked_Delivery_Method__c,sked_Require_Location__c,
                                                            sked_Earliest_Date__c, sked_Earliest_Time_Start__c,sked_Except_first_of_day__c,sked_Latest_Date__c,Tags__c,
                                                            sked_Latest_Time_End__c, sked_Length__c, sked_Maximum_Jobs_Per_Day__c, sked_Start_Date_Buffer__c, sked_Type__c, sked_Interval_Slot__c
                                                            FROM sked_Delivery_Method_Setting__mdt
                                                            WHERE sked_Active__c = TRUE])
            {
                String key = config.sked_Type__c + ':' + config.sked_Delivery_Method__c;
                skedConfigsInstance.put(key, config);
                if ( !map_ProductType_DeliveryMethod.containsKey(config.sked_Type__c) )
                    map_ProductType_DeliveryMethod.put(config.sked_Type__c, new Set<String>());
                map_ProductType_DeliveryMethod.get(config.sked_Type__c).add(config.sked_Delivery_Method__c);
            }

        }

        public sked_Delivery_Method_Setting__mdt getConfig(String configKey) {
            if ( skedConfigsInstance.containsKey(configKey) ) {
                return skedConfigsInstance.get(configKey);
            }
            return NULL;
        }

        public Set<String> getDeliveryMethods(String productType) {
            System.debug('map_ProductType_DeliveryMethod@' + map_ProductType_DeliveryMethod);
            if ( map_ProductType_DeliveryMethod.containsKey(productType) ) {
                return map_ProductType_DeliveryMethod.get(productType);
            }
            return NULL;
        }
    }

    public class FieldToTagSetting {
        private Map<String, Set<String>> mapObjectToApiFieldNames;
        public FieldToTagSetting() {
            mapObjectToApiFieldNames = new Map<String, Set<String>>();
            for ( Fields_To_Tags_Setting__mdt setting : [SELECT Id, Object_Name__c, API_Field_Name__c FROM Fields_To_Tags_Setting__mdt WHERE Object_Name__c != NULL] ) {
                if ( setting.API_Field_Name__c != null) {
                    if ( !mapObjectToApiFieldNames.containsKey(setting.Object_Name__c) ) {
                        mapObjectToApiFieldNames.put(setting.Object_Name__c, new Set<String>());
                    }
                    mapObjectToApiFieldNames.get(setting.Object_Name__c).add(setting.API_Field_Name__c);
                }
            }
        }
        public Set<String> getFieldAPINames(String objectName) {
            return mapObjectToApiFieldNames.get(objectName);
        }
    }

    public class skedAdminSetting {
        public String Skedulo_API_Server;
        public String Skedulo_API_Token_Jti;
        public String Skedulo_API_Token;
        public string jobURL;
        public string countryCode;
        public string bookingGridPeriod;
        public string sessionDeliveredQuestionId;

        public skedAdminSetting(){
            Skedulo_API_Server = getSettingValue(mapName2Setting, 'Skedulo_API_Server');
            Skedulo_API_Token_Jti = getSettingValue(mapName2Setting, 'Skedulo_API_Token_Jti');
            Skedulo_API_Token = getSettingValue(mapName2Setting, 'Skedulo_API_Token');
            countryCode = getSettingValue(mapName2Setting, 'Country_Code');
            bookingGridPeriod = getSettingValue(mapName2Setting, 'BG_Duration');
            sessionDeliveredQuestionId = getSettingValue(mapName2Setting, 'Session_Delivered_Question');
        }

        private String getSettingValue(Map<String, sked__Admin_Setting__mdt> settings, string key){
            sked__Admin_Setting__mdt setting = settings.get(key);
            return setting != null ? setting.sked__Value__c : null;
        }

        private Map<String, sked__Admin_Setting__mdt> mapName2Setting{
            get{
                if(mapName2Setting==null){
                    mapName2Setting = new Map<String, sked__Admin_Setting__mdt>();
                    for(sked__Admin_Setting__mdt setting : [
                        SELECT DeveloperName, sked__Description__c, sked__Value__c
                        FROM sked__Admin_Setting__mdt
                        LIMIT :DEFAULT_LIMIT_RECORDS
                    ]){
                        if(String.isNotBlank(setting.sked__Value__c)) mapName2Setting.put( setting.DeveloperName, setting );
                    }
                }
                return mapName2Setting;
            }
            set;
        }
    }

    public class ResourceGroupTagMapping {
        private Map<String, String> map_Key_resourceGroup = new Map<String, String> ();
        public ResourceGroupTagMapping() {
            for ( sked_Resource_Group_Mapping__mdt config : [SELECT Id, DeveloperName, sked_Product_and_Delivery__c, sked_Resource_Group__c, sked_Tier__c
                                                            FROM sked_Resource_Group_Mapping__mdt
                                                            WHERE sked_Product_and_Delivery__c != NULL AND sked_Resource_Group__c != NULL AND sked_Tier__c != NULL])
            {
                List<String> tagNames = new List<String>();
                for ( String tgName : config.sked_Product_and_Delivery__c.split(';') ) {
                    tagNames.add(tgName.trim());
                }
                tagNames.sort();
                String key = config.sked_Tier__c + ':';
                for ( String tgName : tagNames ) {
                    key += tgName + ';';
                }
                map_Key_resourceGroup.put(key, config.sked_Resource_Group__c);
            }
            System.debug('map_Key_resourceGroup==>' + map_Key_resourceGroup);
        }

        public string getResourceGroup(String key) {
            if ( map_Key_resourceGroup.containsKey(key) ) {
                return map_Key_resourceGroup.get(key);
            }
            return NULL;
        }
    }
}