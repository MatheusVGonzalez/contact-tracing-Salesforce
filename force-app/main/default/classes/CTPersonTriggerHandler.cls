public with sharing class CTPersonTriggerHandler {

    public static void beforeInsert(List<Person__c> newRecords){
        for(Person__c person : newRecords) {
            person.Health_Status__c = 'Green'; //update health status to Green
            person.Token__c = CTPersonController.getToken(person.Mobile__c); //generate token based on mobile number
        }
    }

    public static void beforeUpdate(List<Person__c> newRecords, Map<Id, Person__c> oldRecordsMap){
        for(Person__c person : newRecords) {
            if(person.Health_Status__c != oldRecordsMap.get(person.Id).Health_Status__c) {
                person.Status_Update_Date__c = Date.Today();
            }
        }

    }
    public static void afterUpdate(List<Person__c> newRecords, Map<Id, Person__c> oldRecordsMap){
        Set<Id> statusChanges = new Set<Id>(); //any changes in health status
        Set<Id> redStatus = new Set<Id>(); //chances to Red status        
        for(Person__c person : newRecords) {
            if(person.Health_Status__c != oldRecordsMap.get(person.Id).Health_Status__c) { // if the status has changed 
                statusChanges.add(person.Id); //add the person ID to the set of status changes
            }

            if(person.Health_Status__c == 'Red' && oldRecordsMap.get(person.Id).Health_Status__c != 'Red') { // if the status has changed to Red
                redStatus.add(person.Id); // add the person ID to the set of red status changes
            }
        }

        Set<Id> alreadyProcessed = new Set<Id>(); //to avoid processing the same person multiple times
        alreadyProcessed.addAll(redStatus);

        Set<Id> orangeStatus = new Set<Id>();
        Set<Id> yellowStatus = new Set<Id>();

        List<Person__c> personsToUpdate = new List<Person__c>();

        //lets add cohabitants
        orangeStatus.addAll(CTPersonController.getCohabitants(redStatus, alreadyProcessed)); //take the ID of the red status people and update the cohabitants to orange status because its cohabitants of the red status people
        //lets add primaryContact
        Set<Id> primaryContacts = CTPersonController.getPrimaryContact(redStatus, alreadyProcessed); //take the ID of the red status people and update the primary contacts to orange status because its primary contacts of the red status people
        orangeStatus.addAll(primaryContacts); //add here the primary contacts to the orange status set
        //lets add neighbours
        yellowStatus.addAll(CTPersonController.getNeighbours(redStatus, alreadyProcessed)); //take the ID of the red status people and update the neighbours to yellow status because its neighbours of the red status people
        //lets add secondaryContact
        yellowStatus.addAll(CTPersonController.getSecondaryContact(primaryContacts, alreadyProcessed)); //take the ID of the primary contacts and update the secondary contacts to yellow status because its secondary contacts of the primary contacts
        //example to understand the logic:
        /* Imagine the following:
            John becomes "Red"
            Mary lives with John → goes to Orange
            Peter is John’s neighbor → goes to Yellow
            Anna is John’s caregiver → goes to Orange
            Bruno is close to Anna → goes to Yellow
        */

        Map<Id, Person__c> personMapToUpdate = new Map<Id, Person__c>();

        for (Id pid : orangeStatus) {
            personMapToUpdate.put(pid, new Person__c(Id = pid, Health_Status__c = 'Orange'));
        }

        for (Id pid : yellowStatus) {
            //Just update the person if it is not already in the map to avoid duplicates
            if (!personMapToUpdate.containsKey(pid)) {
                personMapToUpdate.put(pid, new Person__c(Id = pid, Health_Status__c = 'Yellow'));
            }
        }

        // Update the persons with the new health status
        if (!personMapToUpdate.isEmpty()) {
            update personMapToUpdate.values();
        }

        List<Location_Tracing__c> locationTraces = CTLocationTracingController.getLocationsByPersonIds(statusChanges); //get the location traces for the persons with status changes
        if(locationTraces.size() > 0 && locationTraces != null) {
            Set<Id> locationIds = new Set<Id>();
            for(Location_Tracing__c trace : locationTraces){
                locationIds.add(trace.Location__c); //add the location ID to the set of location IDs
            }
            CTLocationController.updateRedScore(locationIds); //update the red score for the locations based on the location traces
        }
    }
}