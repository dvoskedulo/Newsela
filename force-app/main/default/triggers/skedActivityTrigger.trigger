trigger skedActivityTrigger on sked__Activity__c (after insert, after update) {
    if (trigger.isAfter) {
        if (trigger.isInsert) {
            skedActivityHandler.onAfterInsert(trigger.new);
        }
        else if (trigger.isUpdate) {
            skedActivityHandler.onAfterUpdate(trigger.new, trigger.oldMap);
        }
    }
}