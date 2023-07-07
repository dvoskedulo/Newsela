/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 02-04-2021
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   02-04-2021   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
trigger skedEventTrigger on Event (before insert) {
    if (trigger.isBefore) {
        if (trigger.isInsert) {
            skedEventHandler.onBeforeInsert(trigger.new);
        }
    }
}