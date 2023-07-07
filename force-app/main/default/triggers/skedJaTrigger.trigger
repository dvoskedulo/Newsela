trigger skedJaTrigger on sked__Job_Allocation__c (after insert, after update) {
    if (trigger.isAfter) {
        if (trigger.isInsert) {
            skedJobAllocationHandler.onAfterInsert(trigger.new);
        }
        else if (trigger.isUpdate) {
            skedJobAllocationHandler.onAfterUpdate(trigger.new, trigger.oldMap);
        }
    }
}