/**
 * @description       :
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             :
 * @last modified on  : 01-26-2021
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log
 * Ver   Date         Author                               Modification
 * 1.0   01-26-2021   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
trigger skedJobTrigger on sked__Job__c (before insert, after insert, after update) {
    if (trigger.isAfter) {
        if (trigger.isInsert) {
            skedJobHandler.onAfterInsert(trigger.new);
        }

        if (trigger.isUpdate) {
            skedJobHandler.onAfterUpdate(trigger.new, trigger.oldMap);
        }
    }

    if (trigger.isBefore) {
        if (trigger.isInsert) {
            skedJobHandler.onBeforeInsert(trigger.new);
        }
    }
}