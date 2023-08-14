public with sharing class MyController {
    // @AuraEnabled(cacheable=true)
    // public static List<Order_Detail__c> getQuantity() {
    //     return [SELECT Quantity__c FROM Order_Detail__c];
    // }
    @AuraEnabled(cacheable=true)
    public static List<Table_Detail__c> getTable() {
        return [SELECT Name FROM Table_Detail__c];
    }
    @AuraEnabled
    public static void createRecordMethod(Integer item ,String selectedNo, List<Id> selectedItems ) {
        Order_Detail__c newRecord = new Order_Detail__c();
        newRecord.Quantity__c = item; // Update with your field's API name
        // Set other fields as needed
        newRecord.Table_Detail__c = selectedNo;
        // newRecord.Item_Name__c = itemNames;
        // System.debug('Received itemNames: ' + itemNames);
        
        try {
            insert newRecord;

            // Create Junction Object Records
        List<Order_Menu_Junction__c> junctionRecords = new List<Order_Menu_Junction__c>();
        for (Id menuItemId : selectedItems) {
            Order_Menu_Junction__c junction = new Order_Menu_Junction__c();
            junction.Order_Detail__c = newRecord.Id;
            junction.Menu_Detail__c = menuItemId;
            junctionRecords.add(junction);
        }
        insert junctionRecords;
         // Return the ID of the created record
        } catch (Exception e) {
            throw new AuraHandledException('Error creating record: ' + e.getMessage());
        }
    }
    


}