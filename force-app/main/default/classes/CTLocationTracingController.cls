public class CTLocationTracingController {

    /* 
         Get last 30 days visitors 
        @param locationId
        @return List<Location_Tracing__c>
    */
    
    public static List<Location_Tracing__c> getVisitors(String locationId){
        return [SELECT Id, Person__c, Location__c, Visit_Date__c, Person__r.Token__c, Person__r.Health_Status__c 
                FROM Location_Tracing__c
                WHERE Id =: locationId 
                ORDER BY Visit_Date__c DESC];
    }

    /* 
        Get all location ids for visitors
        @param Set<Id> personIds
        @return List<Location_Tracing__c>
    
    */
    public static List<Location_Tracing__c> getLocationsByPersonIds(Set<Id> personIds){
        return [SELECT Id, Person__c, Location__c
                FROM Location_Tracing__c
                WHERE Person__c IN :personIds 
                AND Visit_Date__c = LAST_N_DAYS:10];
    }
    /*
        Get all visitor ids for locations
        @param locationIds
        @return List<Location_Tracing__c>
    */
    public static List<Location_Tracing__c> getLocationsByLocationIds(Set<Id> locationIds){
        return [SELECT Id, Name, Person__c, Location__c, Visit_Date__c, Person__r.Token__c, Person__r.Health_Status__c 
                FROM Location_Tracing__c
                WHERE Location__c IN :locationIds
                AND Person__r.Health_Status__c = 'Green'
                AND Visit_Date__c > LAST_N_DAYS:10];        
    }

    public static List<Location_Tracing__c> checkDuplicates(List<Location_Tracing__c> newlocationTraces){ //will check before put inside the SOQL
       Set<Id> locationIds = new Set<Id>();
       Set<Id> personIds = new Set<Id>();

       for(Location_Tracing__c trace : newlocationTraces){
            locationIds.add(trace.Location__c); //add the value of the location inside the variable locationIds
            personIds.add(trace.Person__c);  //add the value of person inside the variable personIds
       }
       Map<Id, Set<Id>> mapOfExistingRecords = new Map<Id, Set<Id>>(); //creating a map. Id = location and the Set = person
       List<Location_Tracing__c> Duplicates = new List<Location_Tracing__c>(); //creating a list to put the duplicates inside
       List<Location_Tracing__c> existingRecord = [SELECT Id, Person__c, Location__c //just query
                                                    FROM Location_Tracing__c
                                                    WHERE Location__c IN :locationIds
                                                    AND Person__c IN :personIds];
       if(existingRecord != null && existingRecord.size() > 0){ //See if have something in the query
            for(Location_Tracing__c trace : existingRecord){ //create a loop and pass the values to the variable
                if(!mapOfExistingRecords.containsKey(trace.Location__c)){ // for example A => {1, 2} , B {3}... This see if its something different, if was diferent, he create for example a C
                    mapOfExistingRecords.put(trace.Location__c, new Set<Id>()); 
                }
                mapOfExistingRecords.get(trace.Location__c).add(trace.Person__c); //take the location that's there and put the person inside this Map
            }
            for(Location_Tracing__c trace : newlocationTraces){ //just loop to see put inside the variable
                if(mapOfExistingRecords.containsKey(trace.Location__c) && mapOfExistingRecords.get(trace.Location__c).contains(trace.Person__c)){
                 //see if the already have this location and for this location if already have the Person inside the SOQL, Ex: 
                 //SOQL: Location/Person (A/1, B/2)
                 //You want to put this values: (A/1, A/2, B/1, B/2)
                 //So A/1 and B/2 already have, so this is a variable who is duplicate and we don't want duplicates inside the SOQL                                                                                                                                 
                    duplicates.add(trace); //just add this inside the list
                }
            }
        }
    return Duplicates;
    }
}

