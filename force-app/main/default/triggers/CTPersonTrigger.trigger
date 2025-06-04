trigger CTPersonTrigger on Person__c (before insert, before update, after insert, after update, before delete, after delete, after undelete) {
    Set<Id> personIds = new Set<Id>();
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            CTPersonTriggerHandler.beforeInsert(Trigger.new);

        }

        when BEFORE_UPDATE {
            CTPersonTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
        }

        when AFTER_UPDATE{
            CTPersonTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
        }

    }
}