public class CTPersonController {
    public static String getToken(String mobileNo){
        Blob mobileCrypto = Blob.valueOf(mobileNo); //generating a crpto value using mobile no that user provided
        Blob hash = Crypto.generateDigest('MD5', mobileCrypto); //method that takes a string and returns a hash using generateDigest
        String token = EncodingUtil.base64Encode(hash); // transforming the hash value into String value
        return token; //return this value
    }

    /* Get 100 contacts with recent health status
     And returning the list */
    public static List<Person__c> getRecentHealthChanges(){
        return [Select Id, Name, Health_Status__c, Mobile__c, Status_Update_Date__c, Token__c FROM Person__c order by Status_Update_Date__c desc Nulls Last limit 100 ]; 
    }
    
    /* Search People with Name, token or mobile
    And returning the list */

    public static List<Person__c> searchPeople(String searchTerm){
        searchTerm = searchTerm + '%'; 
        return [Select Id, Name, Health_Status__c, Mobile__c, Status_Update_Date__c, Token__c 
                                FROM Person__c 
                                Where Name Like :searchTerm 
                                    OR Token__c Like :searchTerm 
                                    OR Mobile__c Like :searchTerm 
                                order by Status_Update_Date__c desc];
    }

    /* Get person for ID and doing a if to run */

    public static Person__c getPersonById(String personId){
        List<Person__c> people = [Select Id, Name, Health_Status__c, Mobile__c, Status_Update_Date__c, Token__c 
                FROM Person__c 
                WHERE Id = :personId];
        if(people != null && people.size()>0){
             return people[0];
        }else{
            return null;
        }
    }
    
    public static Map<String, Integer> getHealthStatusCount(){ //something like (Green, 2)  or (Orange, 1)...
        AggregateResult[] healthStatusCount = [SELECT COUNT(Id) total, Health_Status__c status  //created a query to use the aggregrate function and storing it in a variable
                                                FROM Person__c 
                                                GROUP BY Health_Status__c];
        
        Map<String, Integer> healthCountMap = new Map<String, Integer>(); //use a map to put like Map(Green, 3)
        
        for(AggregateResult results : healthStatusCount){ //make a for loop to pass in all lines for the query
            String healthStatus = String.valueOf(results.get('status')); //storage the values inside of the map
            Integer healthCount = Integer.valueOf(results.get('total')); //storage the values inside of the map
            healthCountMap.put(healthStatus, healthCount); //pass this values inside the map
        }
        return healthCountMap;//just return 
        } 

    public static Set<Id> getCohabitants(Set<Id> personIds, Set<Id> alreadyProcessed){ //pass a id to see who are the cohabitants with this person
        List<String> healthStatuse = new List<String>{'Green', 'Yellow'}; //list of health status to filter cohabitants
        
         List<People_Tracing__c> peopleTraces = [SELECT Id, Person_1__c, Person_2__c 
                                                FROM People_Tracing__c 
                                                WHERE (Person_1__c IN :personIds OR Person_2__c IN :personIds) //query to get all cohabitants of the person
                                                AND Contact_Type__c = 'Cohabitant'
                                                AND (Person_1__r.Health_Status__c IN :healthStatuse 
                                                OR Person_2__r.Health_Status__c IN :healthStatuse)]; //query just to get the cohabitants with Green or Yellow health status
        
        Set<Id> cohabitants = new Set<Id>(); //create a set to store the cohabitants
        for(People_Tracing__c pt : peopleTraces){ //loop through the people traces
            if(!alreadyProcessed.contains(pt.Person_1__c)){ //if the person is not in the personIds
                cohabitants.add(pt.Person_1__c); //add the person to the cohabitants set, because the person live with the person that we are looking for
                alreadyProcessed.add(pt.Person_1__c);
            }
            if(!personIds.contains(pt.Person_2__c)){ //if the person is not in the personIds
                cohabitants.add(pt.Person_2__c); //add the person to the cohabitants set, because the person live with the person that we are looking for
                alreadyProcessed.add(pt.Person_2__c);
            }
        }
        return cohabitants; //return the cohabitants set
    }
    
    public static Set<Id> getNeighbours(Set<Id> personIds, Set<Id> alreadyProcessed){ //pass a id to see who are the neighbours with this person        
         List<People_Tracing__c> peopleTraces = [SELECT Id, Person_1__c, Person_2__c 
                                                FROM People_Tracing__c 
                                                WHERE (Person_1__c IN :personIds OR Person_2__c IN :personIds) //query to get all neighbours of the person
                                                AND Contact_Type__c = 'Neighbour'
                                                AND (Person_1__r.Health_Status__c = 'Green'
                                                OR Person_2__r.Health_Status__c = 'Green')]; //query just to get the neighbours with Green or Yellow health status
        
        Set<Id> neighbours = new Set<Id>(); //create a set to store the neighbours
        for(People_Tracing__c pt : peopleTraces){ //loop through the people traces
            if(!alreadyProcessed.contains(pt.Person_1__c)){ //if the person is not in the personIds
                neighbours.add(pt.Person_1__c); //add the person to the neighbours set, because the person live with the person that we are looking for
                alreadyProcessed.add(pt.Person_1__c);
            }
            if(!personIds.contains(pt.Person_2__c)){ //if the person is not in the personIds
                neighbours.add(pt.Person_2__c); //add the person to the neighbours set, because the person live with the person that we are looking for
                alreadyProcessed.add(pt.Person_2__c);
            }
        }
        return neighbours; //return the neighbours set
    }
    
    public static Set<Id> getPrimaryContact(Set<Id> personIds, Set<Id> alreadyProcessed){ //Take the primary, who meet in person face to face   
        List<String> healthStatuse = new List<String>{'Green', 'Yellow'}; //list of health status to filter cohabitants     
         List<People_Tracing__c> peopleTraces = [SELECT Id, Person_1__c, Person_2__c 
                                                FROM People_Tracing__c 
                                                WHERE (Person_1__c IN :personIds OR Person_2__c IN :personIds) //query to get all cohabitants of the person
                                                AND Contact_Type__c = 'Other' 
                                                AND Contact_Date__c = LAST_N_DAYS:10 //query to get the last 30 days contacts
                                                AND (Person_1__r.Health_Status__c IN :healthStatuse
                                                OR Person_2__r.Health_Status__c IN :healthStatuse)]; //query just to get the cohabitants with Green or Yellow health status
        
        Set<Id> primaryContacts = new Set<Id>(); //create a set to store the primaryContacts
        for(People_Tracing__c pt : peopleTraces){ //loop through the people traces
            if(!alreadyProcessed.contains(pt.Person_1__c)){ //if the person is not in the personIds
                primaryContacts.add(pt.Person_1__c); //add the person to the primaryContacts set, because the person live with the person that we are looking for
                alreadyProcessed.add(pt.Person_1__c);
            }
            if(!personIds.contains(pt.Person_2__c)){ //if the person is not in the personIds
                primaryContacts.add(pt.Person_2__c); //add the person to the primaryContacts set, because the person live with the person that we are looking for
                alreadyProcessed.add(pt.Person_2__c);
            }
        }
        return primaryContacts; //return the cohabitants set
    }
    
    public static Set<Id> getSecondaryContact(Set<Id> primaryContactsIds, Set<Id> alreadyProcessed){ //Take the second, who stay in contact with someone who meet the primary face a face
         List<People_Tracing__c> peopleTraces = [SELECT Id, Person_1__c, Person_2__c 
                                                FROM People_Tracing__c 
                                                WHERE (Person_1__c IN :primaryContactsIds OR Person_2__c IN :primaryContactsIds) //query to get all cohabitants of the person
                                                AND Contact_Type__c = 'Other' 
                                                AND Contact_Date__c = LAST_N_DAYS:10 //query to get the last 30 days contacts
                                                AND (Person_1__r.Health_Status__c = 'Green'
                                                OR Person_2__r.Health_Status__c = 'Green')]; //query just to get the cohabitants with Green or Yellow health status
        
        Set<Id> secondaryContacts = new Set<Id>(); //create a set to store the primaryContacts
        for(People_Tracing__c pt : peopleTraces){ //loop through the people traces
            if(!alreadyProcessed.contains(pt.Person_1__c)){ //if the person is not in the personIds
                secondaryContacts.add(pt.Person_1__c); //add the person to the primaryContacts set, because the person live with the person that we are looking for
                alreadyProcessed.add(pt.Person_1__c);
            }
            if(!primaryContactsIds.contains(pt.Person_2__c)){ //if the person is not in the personIds
                secondaryContacts.add(pt.Person_2__c); //add the person to the primaryContacts set, because the person live with the person that we are looking for
                alreadyProcessed.add(pt.Person_2__c);
            }
        }
        return secondaryContacts; //return the cohabitants set
    }
}
    