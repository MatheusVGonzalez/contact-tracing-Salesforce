public class CTPeopleTracingController {
    public static List<People_Tracing__c> getTraces (String recordId){
        return [SELECT Id, Contact_Date__c, Person_1__c, Person_1__r.Token__c, Person_1__r.Health_Status__c, Person_2__c, Person_2__r.Token__c, Person_2__r.Health_Status__c
        FROM People_Tracing__c 
        WHERE Person_1__c  =:recordId
           OR Person_2__c =:recordId
        ORDER BY Contact_Date__c DESC];
    }

    public static List<People_Tracing__c> checkDuplicates(List<People_Tracing__c> newPeopleTraces){
        set<Id> personIds = new Set<Id>();

        for(People_Tracing__c trace : newPeopleTraces){ //passing the people to the variable trace
            personIds.add(trace.Person_1__c); //adding this people to the List person Ids
            personIds.add(trace.Person_2__c);
        }
        List<People_Tracing__c> duplicates = new List<People_Tracing__c>(); //list to storage the duplicates
        Map<Id, Set<Id>> mapOfExistingRecord = new Map<Id, Set<Id>>();//insert all the people that one person meet ex: Cindy(ID) meet John, Nick, Srini (Set)  
        
        List<People_Tracing__c> existingRecords = [SELECT Id, Person_1__c, Person_2__c //Create a list to storage the values that already there
                                                    FROM People_Tracing__c
                                                    WHERE Person_1__c IN :personIds
                                                        OR Person_2__c IN :personIds];
        if(existingRecords != null && existingRecords.size() > 0){ //make sure that have something to run
            for(People_Tracing__c trace : existingRecords){
                if(! mapOfExistingRecord.containsKey(trace.Person_1__c)){//if the map already have the person 1, i don't want put again
                    mapOfExistingRecord.put(trace.Person_1__c, new Set<Id>()); //if the map doesn't have no one in person 1, that will be adding here
                }
                mapOfExistingRecord.get(trace.Person_1__c).add(trace.Person_2__c); //adding the person 2 in the set
                
                //map for person 2
                if(! mapOfExistingRecord.containsKey(trace.Person_2__c)){ 
                    mapOfExistingRecord.put(trace.Person_2__c, new Set<Id>());
                }
                mapOfExistingRecord.get(trace.Person_2__c).add(trace.Person_1__c);
            }

            for(People_Tracing__c trace : newPeopleTraces){ //for loop
                if((mapOfExistingRecord.containsKey(trace.Person_1__c) && mapOfExistingRecord.get(trace.Person_1__c).contains(trace.Person_2__c))
                || (mapOfExistingRecord.containsKey(trace.Person_2__c) && mapOfExistingRecord.get(trace.Person_2__c).contains(trace.Person_1__c))) 
                { //see if the map contains the ID(person1), and see if the Set(Person2) also have something. 
                    //Same thing for condition 2
                    duplicates.add(trace);
                }
            }
        }
        return duplicates;
    }
}