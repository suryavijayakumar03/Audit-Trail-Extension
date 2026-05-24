String[] ns='Metadata_Diff__c,Metadata_Component_Snapshot__c,Metadata_Audit_Event__c,Metadata_Risk_Assessment__c,Audit_Run__c,Task,Event,Case,Opportunity,Lead,Contact,Account,CampaignMember,Campaign,Product2,PricebookEntry,Contract,Order,Asset,ContentDocument'.split(',');
Integer n=0;
for(String s:ns){
 try{
  Schema.DescribeSObjectResult d=Schema.getGlobalDescribe().get(s).getDescribe();
  if(!d.isQueryable()||!d.isDeletable())continue;
  List<SObject> r=Database.query('SELECT Id FROM '+s+' LIMIT 200');
  Database.DeleteResult[] dr=Database.delete(r,false);
  for(Database.DeleteResult x:dr)if(x.isSuccess())n++;
 }catch(Exception e){}
}
System.debug('FULL_CLEAN_SLATE_PASS_DELETED='+n);
