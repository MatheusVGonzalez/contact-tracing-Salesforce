public with sharing class CTLocationTriggerHandler {

    public static void beforeInsert(List<Location__c> newRecords){
        for(Location__c location : newRecords){
            location.Status__c = 'Green'; //set initial status to Green

        }
    }

    public static void beforeUpdate(List<Location__c> newRecords, Map<Id, Location__c> oldRecordsMap){
        for(Location__c location : newRecords){
            if(location.Status__c != oldRecordsMap.get(location.Id).Status__c) { //check if status has changed
                location.Status_Update_Date__c = Date.Today(); //update status update date if Red Score has changed
            }
        }
    }

    public static void afterUpdate(List<Location__c> newRecords, Map<Id, Location__c> oldRecordsMap){
        Set<Id> statusChange = new Set<Id>();
        for(Location__c location : newRecords){
            if(location.Status__c == 'Red' && oldRecordsMap.get(location.Id).Status__c != 'Red'){
            statusChange.add(location.Id); //collect all new location IDs
            }
        }
        List<Location_Tracing__c> locationTraces = CTLocationTracingController.getLocationsByLocationIds(statusChange); //get all location traces for the new locations
        Set<Id> personIds = new Set<Id>();
        for(Location_Tracing__c trace : locationTraces){
            personIds.add(trace.Person__c); //collect all person IDs from the traces
        }

        List<Person__c> peopleToUpdate = new List<Person__c>(); 
        for(Id pid : personIds){
            peopleToUpdate.add(new Person__c(Id=pid, Health_Status__c='Yellow')); //update health status of all people to Yellow
        }

        if(peopleToUpdate.size() > 0){
            update peopleToUpdate; //update all people with new health status
        }
    }
}