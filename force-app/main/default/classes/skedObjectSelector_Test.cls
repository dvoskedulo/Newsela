@isTest
private class skedObjectSelector_Test {
    @TestSetup
    static void makeData(){
        sked__Region__c region = skedDataFactory.createRegion('Tri-State Region', 'Eastern');        
        insert region;

        sked__Location__c location = skedDataFactory.createLocation('Test Location', region.Id);
        insert location;
    }
    @isTest
    static void test_filterWithParentQuery() {
        skedObjectSelector resSelector = skedObjectSelector.newInstance(
        sked__Location__c.sObjectType
        );
        resSelector.parentQuery('Name');
        resSelector.field('Name');
        resSelector.filters(new List<String>{ 'Name = \'New\'' })
        .size(10)
        .offset(0);
        // .sort('Name');

        List<SObject> result = resSelector.toSObjects();

        System.assert(result != null);
    }

    @isTest
    static void test_filterWithChildQuery() {
        skedObjectSelector resSelector = skedObjectSelector.newInstance(
        sked__Region__c.sObjectType
        );
        resSelector.fields(new List<String>{ 'Name' });
        resSelector.subQueries(new List<String>{ 'sked__Locations__r' });

        List<SObject> result = resSelector.toSObjects();

        System.assert(result != null);
    }
}