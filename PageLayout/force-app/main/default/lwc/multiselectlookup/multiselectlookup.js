import { LightningElement,track,api,wire } from 'lwc';

// import getQuantity from '@salesforce/apex/MyController.getQuantity';
import getTable from '@salesforce/apex/MyController.getTable';
import createRecord from '@salesforce/apex/MyController.createRecordMethod';
import getResults from '@salesforce/apex/lwcMultiLookupController.getResults';

export default class Multiselectlookup extends LightningElement {
    // selectedId;
    // quantity = [];
    selectedNo;
    Table = [];
    @api objectName = 'Menu_Detail__c';
    @api fieldName = 'Name';
    @api Label;
    @track searchRecords = [];
    @track selectedRecords = [];
    @api required = false;
    @api iconName = 'action:new_account'
    @api LoadingText = false;
    @track txtclassname = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    @track messageFlag = false;
    @track res = false;
    @track item = '';
    @track selectedNo = '';

    menu;
    quantity;
    table;


    @wire(getTable)
    wiredTable({ error, data }) {
        if (data) {
            this.Table = data.map(tableDetail => ({
                label: String(tableDetail.Name), // Convert to string
                value: tableDetail.Id
            }));
        } else if (error) {
            console.error(error);
        }
    }

    handleChange(event) {
        // this.selectedId = event.detail.value;
        this.selectedNo = event.target.value;
    }
    handleItemChange(event){
        this.quantity = event.target.value;
    }
 
    searchField(event) {

        var currentText = event.target.value;
        var selectRecId = [];
        for(let i = 0; i < this.selectedRecords.length; i++){
            selectRecId.push(this.selectedRecords[i].recId);
        }
        this.LoadingText = true;
        getResults({ ObjectName: this.objectName, fieldName: this.fieldName, value: currentText, selectedRecId : selectRecId })
        .then(result => {
            this.searchRecords= result;
            this.LoadingText = false;
            
            this.txtclassname =  result.length > 0 ? 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open' : 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
            if(currentText.length > 0 && result.length == 0) {
                this.messageFlag = true;
            }
            else {
                this.messageFlag = false;
            }

            if(this.selectRecordId != null && this.selectRecordId.length > 0) {
                this.iconFlag = false;
                this.clearIconFlag = true;
            }
            else {
                this.iconFlag = true;
                this.clearIconFlag = false;
            }
        })
        .catch(error => {
            console.log('-------error-------------'+error);
            console.log(error);
        });
        
    }
    
   setSelectedRecord(event) {
        var recId = event.currentTarget.dataset.id;
        var selectName = event.currentTarget.dataset.name;
        let newsObject = { 'recId' : recId ,'recName' : selectName };
        this.selectedRecords.push(newsObject);
        this.txtclassname =  'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
        let selRecords = this.selectedRecords;
		this.template.querySelectorAll('lightning-input').forEach(each => {
            each.value = '';
        });
        const selectedEvent = new CustomEvent('selected', { detail: {selRecords}, });
        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
        console.log('selected items' + serecord.recName);
    }

    removeRecord (event){
        let selectRecId = [];
        for(let i = 0; i < this.selectedRecords.length; i++){
            if(event.detail.name !== this.selectedRecords[i].recId)
                selectRecId.push(this.selectedRecords[i]);
        }
        this.selectedRecords = [...selectRecId];
        let selRecords = this.selectedRecords;
        const selectedEvent = new CustomEvent('selected', { detail: {selRecords}, });
        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
        console.log('selected items' + serecord.recName);
    }

    handleItemChange(event) {
        this.item = parseInt(event.target.value);
    }
    handleClick() {
        console.log('save button clicked');
        this.res = true;
        const selectedItems = [];

        for (let i = 0; i < this.selectedRecords.length; i++) {
            console.log('selected item: ' + this.selectedRecords[i].recName);
            selectedItems.push(this.selectedRecords[i].recId);
        }
        // const selectedItemsString = selectedItems.join(', '); 
        createRecord({ item: this.item , selectedNo: this.selectedNo ,itemNames: this.selectedItems.join(', ') })
            .then(result => {
                console.log("result" + JSON.stringify(result))
            })
            .catch(error => {
                console.log("error" + JSON.stringify(error))
            })
    }
    
    // @wire(getQuantity)
    // wiredQuantity({ error, data }) {
    //     if (data) {
    //         this.quantity = data.map(orderDetail => ({
    //             label: String(orderDetail.Quantity__c), // Convert to string
    //             value: orderDetail.Id
    //         }));
    //     } else if (error) {
    //         console.error(error);
    //     }
    // }
}