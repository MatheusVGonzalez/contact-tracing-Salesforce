public class CTLocationController {
    /* Get 100 contacts with recent health status
    And returning the list */
    public static List<Location__c> getRecentStatusChanges(){
        return [SELECT Id, Name, Address__c, Pincode__c, Red_Score__c, Status_Update_Date__c, Status__c FROM Location__c order by Status_Update_Date__c DESC NULLS LAST LIMIT 100];
    }
    /* Search a location by name, zip code or address 
    And returning the List */
    public static List<Location__c> searchLocations(String searchTerm){
        searchTerm = searchTerm + '%';
        return [SELECT Id, Name, Address__c, Pincode__c, Red_Score__c, Status_Update_Date__c, Status__c FROM Location__c 
                WHERE Name LIKE : searchTerm 
                OR Pincode__c LIKE : searchTerm 
                OR Address__c LIKE : searchTerm 
                ORDER BY Status_Update_Date__c DESC NULLS LAST];
    }

    /*Searching the locations by ID and returning*/
        /* See if it's not empty to run this */
        //Use list because if the locations return 0, we don't take the exceptions
    public static Location__c getLocationById(String locationId){
        List<Location__c> locations =  [SELECT Id, Name, Address__c, Pincode__c, Red_Score__c, Status_Update_Date__c  , Status__c
                                        FROM Location__c 
                                        WHERE Id = :locationId]; 
        if(locations != null && locations.size()>0){
            return locations[0];
        }else{
            return null;
        }
    }

    public static Map<String, Integer> getStatusCount(){ //something like (Green, 2)  or (Orange, 1)...
        AggregateResult[] statusCount = [SELECT Status__c status, COUNT(Id) total  //created a query to use the aggregrate function and storing it in a variable
                                        FROM Location__c 
                                        GROUP BY Status__c];
        Map<String, Integer> healthCountMap = new Map<String, Integer>(); //use a map to put like Map(Green, 3)
        for(AggregateResult results : statusCount){ //make a for loop to pass in all lines for the query 
            String status = String.valueOf(results.get('status')); //storage the values inside of the map
            Integer count = Integer.valueOf(results.get('total')); //storage the values inside of the map
            healthCountMap.put(status, count); //pass this values inside the map
        }
        return healthCountMap; //just return
    }

    public static void updateRedScore(Set<Id> locationIds){
        List<Location__c> locationToUpdate = new List<Location__c>(); //create a list to update the locations
        AggregateResult[] redPeoplePerLocation = [SELECT Location__c, COUNT(Id) total FROM Location_Tracing__c //grouping location, tracing records by the location
                    WHERE Person__r.Health_Status__c = 'Red' // only the red status people
                    AND Visit_Date__c = LAST_N_DAYS:10 // only the last 10 days
                    AND Location__c IN :locationIds
                    GROUP BY Location__c];

                    for(AggregateResult result : redPeoplePerLocation) {
                        String locationId = String.ValueOf(result.get('Location__c')); 
                        Integer redScore = Integer.ValueOf(result.get('total'));
                        String status = getStatus(redScore); //get the status based on the red score
                        locationToUpdate.add(new Location__c(Id=locationId, Red_Score__c=redScore, Status__c=status)); 
                    }

                    if(locationToUpdate != null && locationToUpdate.size() > 0) {
                        update locationToUpdate; //update the locations with the new red score and status
                    }
    }

    public static String getStatus(Integer redScore){
        if(redScore == 0){
            return 'Green';
        }else if(redScore <= 5){
            return 'Yellow';
        }else if(redScore <= 10){
            return 'Orange';
        }else{
            return 'Red';
        }

    }
    
}