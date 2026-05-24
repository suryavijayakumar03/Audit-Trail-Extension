String[] ns='Metadata_Diff__c,Metadata_Component_Snapshot__c,Metadata_Audit_Event__c,Metadata_Risk_Assessment__c,Audit_Run__c,Task,Event,Case,Opportunity,Lead,Contact,Account,CampaignMember,Campaign,Product2,PricebookEntry,Contract,Order,Asset'.split(',');
Integer n=0;
for(String s:ns){
 try{
  List<SObject> r=Database.query('SELECT Id FROM '+s+' WHERE IsDeleted=true ALL ROWS LIMIT 200');
  if(!r.isEmpty()){
   Database.EmptyRecycleBinResult[] er=Database.emptyRecycleBin(r);
   for(Database.EmptyRecycleBinResult x:er)if(x.isSuccess())n++;
  }
 }catch(Exception e){}
}
System.debug('EMPTY_RECYCLE_BIN_PASS_PURGED='+n);
