import { LightningElement,track,wire } from 'lwc';
import getLayout from '@salesforce/apex/PageLayoutController.getObjectLayout';
import getObject from '@salesforce/apex/PageLayoutController.getObjects';
import getLayoutFields from '@salesforce/apex/PageLayoutController.getLayoutFields';

const columnList = [
    { label: 'Field Name', fieldName: 'value' }
];

export default class PageLayout extends LightningElement {
    @track objectList= [];
    @track layoutList=[];
    @track fields=[];
    @track fieldRows=[];
    @track columns = columnList;
    layoutName;

    error;
    objName;
    @wire(getObject, { shouldGetStandard: true })
    wiredObject({ error, data }) {
        if (data) {
            for(var i=0; i<data.length; i++)  {
                this.objectList = [...this.objectList ,{value: data[i] , label: data[i]} ];                                   
            }                
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.contacts = undefined;
        }
    }
    handleObjectList(event)
    {   
        this.layoutList=[];
        const selectedOption = event.detail.value;  
        this.objName=selectedOption;
        getLayout({ objectName: selectedOption})
        .then(data => {
            if (data) {
                for(var i=0; i<data.length; i++)  {
                    this.layoutList = [...this.layoutList ,{value: data[i] , label: data[i]} ];                                   
                }                
                this.error = undefined;
            } else if (error) {
                this.error = error;
            }
        })
        .catch(error => {
            this.error = error;
            console.log(error);
        });

    }

    handleLayoutList(event)
    {   
        this.fields=[];
        const selectedOption = event.detail.value;  
        this.layoutName=selectedOption;
        getLayoutFields({ objectName: this.objName,layout:selectedOption})
        .then(data => {
            if (data) {
                 for(var i=0; i<data.length; i++)  {
                    this.fields = [...this.fields ,{value: data[i] , label: data[i]} ];                                   
                }             
                this.error = undefined;
            } else if (error) {
                this.error = error;
            }
        })
        .catch(error => {
            this.error = error;
            console.log(error);
        });

    }

    handleFileDownload(event)
    {
        if(this.fields!==undefined)
        {
            let csvContent = "data:text/csv;charset=utf-8,";
            csvContent +="Fields,\r\n"; //header
            this.fields.forEach(function(rowArray) {
                let row = rowArray.value+",";
                csvContent += row + "\r\n";
            });
            var encodedUri = encodeURI(csvContent);
            var link = document.createElement("a");
            link.setAttribute("href", encodedUri);
            link.setAttribute("download", this.layoutName+".csv");
            document.body.appendChild(link); 
            link.click();
        }
    }
}