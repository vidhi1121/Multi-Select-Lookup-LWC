public with sharing class ServiceTerritoryMemberTriggerHandler{
    
    public static final String INSTITUTIONAL_SR_NAME = 'Institutional';
    public static final Id INST_SR_RECORDTYPEID = Schema.SObjectType.ServiceResource.getRecordTypeInfosByName().get(INSTITUTIONAL_SR_NAME).getRecordTypeId(); //allows filtering of Service Resources by Institutional record type
    
    public static void updateSTALignments(List<ServiceTerritoryMember> stMembers){
        try{
            Map <ID, ServiceTerritoryMember> stMemberMap = new Map<ID, ServiceTerritoryMember>([SELECT ID, ServiceResourceId,TerritoryType, ServiceResource.RelatedRecordID, ServiceTerritory.Id, ServiceTerritory.Ecolab_Territory__c
                                                                                                FROM ServiceTerritoryMember Where ID IN :stMembers]);
            
            Set<ID> userIds = new Set<ID>();
            for(ServiceTerritoryMember stm:stMemberMap.values()){
                userIds.add(stm.ServiceResource.RelatedRecordID);
            }
            
            //Finds accounts where the KAR FA or caretaker / primary FA are among the service territory members that were inserted.
            List<Account> accountList = new List<Account>([SELECT ID, KAR_FA__c,Caretaker_Primary_FA__c, KAR_Service_Territory__c,Service_Territory__c,Current_Dual_Alignment__c,Territory__c,Caretaker__c 
                                                           FROM Account WHERE KAR_FA__c IN: userIds OR Caretaker_Primary_FA__c in: userIds]);
            
            Map<Id,Account> accsToUpdate = new Map <Id, Account>(); //Map holding each account that has its Service Territory updated. Used to update owner of WOs and Sas at the end of the function
            
            Map<Id,ServiceTerritoryMember> stmServiceResMap = new Map<Id, ServiceTerritoryMember>();
            
            for(ServiceTerritoryMember stm:stMemberMap.values()){
                stmServiceResMap.put(stm.ServiceResource.RelatedRecordID,stm);
            }
            System.debug('=====stmServiceResMap=======' + stmServiceResMap);
            
            //for each user, get accounts from account map/list and then check alignment logic
            //TODO the loop here seems inefficient. Could probably have its performance improved. 
            
            
            for(Account acc:accountList){ //find accounts with this user
                System.debug('=====acc=======' + acc);
      
                    ServiceTerritoryMember stmForKAR_FA = stmServiceResMap.containsKey(acc.KAR_FA__c) ? stmServiceResMap.get(acc.KAR_FA__c) : null ;
                        if(stmForKAR_FA != null && stmForKAR_FA.ServiceResource.RelatedRecordID == acc.KAR_FA__c){
                            System.debug('=====stmForKAR_FA=======' + stmForKAR_FA);
                            //perform KAR logic
                            if(stmForKAR_FA.ServiceTerritoryID != acc.KAR_Service_Territory__c && stmForKAR_FA.ServiceTerritory.Ecolab_Territory__c == acc.Current_Dual_Alignment__c ){ //no logic needed if it is already aligned and check if acc is in alignment with KAR
                                System.debug('=====Test2=======');
                                //set the KAR ST of the account
                                if(!accsToUpdate.containsKey(acc.Id)){
                                    acc.KAR_Service_Territory__c = stmForKAR_FA.ServiceTerritoryID;
                                    accsToUpdate.put(acc.Id, acc);
                                }else{
                                    Account account = accsToUpdate.get(acc.Id);
                                    account.KAR_Service_Territory__c = stmForKAR_FA.ServiceTerritoryId;
                                    accsToUpdate.put(account.Id,account);
                                }
                            }
                        }
                    ServiceTerritoryMember stmForCaretakerPrimaryFA = stmServiceResMap.containsKey(acc.Caretaker_Primary_FA__c) ? stmServiceResMap.get(acc.Caretaker_Primary_FA__c) : null ;
                           System.debug('=====stmForCaretakerPrimaryFA=======' + stmForCaretakerPrimaryFA);
                           if(stmForCaretakerPrimaryFA !=null && acc.Caretaker_Primary_FA__c == stmForCaretakerPrimaryFA.ServiceResource.RelatedRecordID){
                                System.debug('=====Test2=======');
                                if(acc.Service_Territory__c != stmForCaretakerPrimaryFA.ServiceTerritoryId && ((acc.Territory__c == stmForCaretakerPrimaryFA.ServiceTerritory.Ecolab_Territory__c)
                                                                                          || (acc.Caretaker__c == stmForCaretakerPrimaryFA.ServiceResource.RelatedRecordID && stmForCaretakerPrimaryFA.TerritoryType == 'P'))){
                                  if(!accsToUpdate.containsKey(acc.Id)){
                                     acc.Service_Territory__c = stmForCaretakerPrimaryFA.ServiceTerritoryId; //set to caretakers ST
                                     accsToUpdate.put(acc.id, acc); //updates to FA's service territory
                                  }else{
                                    Account account = accsToUpdate.get(acc.Id);
                                    account.Service_Territory__c = stmForCaretakerPrimaryFA.ServiceTerritoryId;
                                    accsToUpdate.put(account.Id,account);
                                    }
                                }
                            }
                
            } 
            
            if(!accsToUpdate.isEmpty()){
                List<Account> accsToUpdateList = accsToUpdate.values(); //convert set to list for database update operation
                Database.update(accsToUpdateList);
                Set<Account> accountSet = new Set<Account>(accsToUpdateList); //changes list to a set for the STChangeAsync function
                FSL_AccountSTChangeAsync.updateOwnerOfWOAndSAs(accountSet);
            } 
            
        }
        catch(exception ex){
            ApexException.LogException(ex);
        } 
    }
}