public class PageLayoutController {
    
    //Retrieve All Objects in org
    @Auraenabled(cacheable=true)
    public static List<string> getObjects(boolean shouldGetStandard)
    {
        List<string> sObjectList = new List<string>();
        
        system.debug('shouldGetStandard:'+shouldGetStandard);
        for(Schema.SObjectType objTyp : Schema.getGlobalDescribe().Values()){
            String name = objTyp.getDescribe().getName();
            if(shouldGetStandard)
            {
                sObjectList.add(name); 
            }
            if((!name.containsignorecase('history') && !name.containsignorecase('tag')&&
                !name.containsignorecase('share') && !name.containsignorecase('feed')) && 
               name.toLowerCase().right(3) ==  '__c'){      
                   sObjectList.add(name);
               }
        }
        system.debug('sObjectList:'+sObjectList);
        return sObjectList;
    }
    
    @Auraenabled(cacheable=true)
    public static List<string> getObjectLayout(string objectName)
    {
        return getLayoutNameForObject(objectName);
    }
    
    @Auraenabled(cacheable=true)
    public static List<string> getLayoutFields(string objectName,string layout)
    {
        return getFields(objectName,layout);
    }
    
    
    static String toolingAPISOQL(string query) {
        //String baseURL = URL.getSalesforceBaseUrl().toExternalForm();
        String baseURL='callout:ToolingRest?';
        //return HttpCallout.restGet( baseURL +'/services/data/v41.0/tooling/query?q='+ (query.replace(' ', '+')),'GET', UserInfo.getSessionId());
        return HttpCallout.restGet( baseURL +'q='+ (query.replace(' ', '+')),'GET', UserInfo.getSessionId());
    } 
    
    static List<string> getLayoutNameForObject( string objectName ) {
        string sql='select Layout.Name from ProfileLayout where TableEnumOrId=\'objectName\'';
        System.debug('SOQL Query: ' + sql);
        String body = toolingAPISOQL(sql.replace('objectName', objectName));
        if(string.isNotBlank(body))
        {
            LayoutRecord data=LayoutRecord.parse(body);
            
            //get only layput name
            List<string> layouts=new List<string>();
            for(LayoutRecord.Record record:data.records)
            {
                if(!layouts.contains(record.Layout.Name))
                {
                    layouts.add(string.valueOf(record.Layout.Name));
                }
            }
            return layouts;
        }
        return null;
    }
    
    static List<string> getFields( string objectName,string layout ) {
        string layoutName=String.format('{0}-{1}', new String[]{objectName, layout}); 
        List<Metadata.Metadata> layouts = Metadata.Operations.retrieve(Metadata.MetadataType.Layout, new List<String> {layoutName});
        //get only layput name
        List<string> fields=new List<string>();
        Metadata.Layout layoutMd = (Metadata.Layout)layouts.get(0);
        for (Metadata.LayoutSection section : layoutMd.layoutSections) {
            for (Metadata.LayoutColumn column : section.layoutColumns) {
                if (column.layoutItems != null) {
                    for (Metadata.LayoutItem item : column.layoutItems) {
                        fields.add(item.field);
                    }
                }
            }
        }
        return fields;
    }
}