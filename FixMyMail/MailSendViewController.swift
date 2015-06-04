import UIKit
import CoreData
import AddressBook
import Foundation
import AddressBookUI


class MailSendViewController: UIViewController, ABPeoplePickerNavigationControllerDelegate{
    @IBOutlet weak var txtTo: UITextField!
    @IBOutlet weak var txtSubject: UITextField!
    @IBOutlet weak var tvText: UITextView!
    @IBOutlet weak var Suggestion: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var sendBut: UIBarButtonItem = UIBarButtonItem(title: "Senden", style: .Plain, target: self, action: "butSend:")
        self.navigationItem.rightBarButtonItem = sendBut
        LoadAddresses()
    }
    
    
    @IBAction func butSend(sender: AnyObject) {
        var managedObjectContext: NSManagedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!
        let fetchRequest: NSFetchRequest = NSFetchRequest(entityName: "EmailAccount")
        var error: NSError?
        var result = managedObjectContext.executeFetchRequest(fetchRequest, error: &error)
        if error != nil {
            NSLog("%@", error!.description)
        } else {
            if let emailAccounts = result {
                let acc: EmailAccount = emailAccounts[0] as! EmailAccount
                
                var session = MCOSMTPSession()
                session.hostname = acc.smtpHostname
                session.port = acc.smtpPort
                session.username = acc.username
                session.password = acc.password
                session.connectionType = MCOConnectionType.TLS;
                session.authType = MCOAuthType.SASLPlain;
                
                var builder = MCOMessageBuilder()
                var from = MCOAddress()
                from.displayName = "Fix Me"
                from.mailbox = acc.emailAddress
                var sender = MCOAddress()
                sender.displayName = "Fix Me"
                sender.mailbox = acc.emailAddress
                builder.header.from = from
                builder.header.sender = sender
                var to = MCOAddress()
                //to.displayName = "Fix Me"
                to.mailbox = txtTo.text
                var tos : NSMutableArray = [to]
                builder.header.to = tos as [AnyObject]
                builder.header.subject = txtSubject.text
                builder.textBody = tvText.text
                
                let op = session.sendOperationWithData(builder.data())
                
                op.start({(NSError error) in
                    if (error != nil) {
                        NSLog("can't send message: %@", error)
                    } else {
                        self.txtSubject.text = ""
                        self.txtTo.text = ""
                        self.tvText.text = ""
                        NSLog("sent")
                    }
                })
            }
        }
        
    }
    
    //
    //Collect Contacts from Addressbook and order Emails Ascending
    //
    
    var allEmail: NSMutableArray = []
    var sortedEmails: NSArray = []
    func addRecord(Entry: Record){
        allEmail.addObject(Entry)
    }
    
    func orderEmails(){
        var allEmailIDs:NSArray = allEmail
        println("ordering")
        let descriptor = NSSortDescriptor(key: "email", ascending: true, selector: "localizedStandardCompare:")
        var sortedResults: NSArray = allEmail.sortedArrayUsingDescriptors([descriptor])
        for results in sortedResults {
            println ("contactEmail : \(results.email as String)")
        }
        
        sortedEmails = sortedResults
    }
    
    func LoadAddresses() {
        var source: ABRecord = ABAddressBookCopyDefaultSource(addressBook).takeRetainedValue()
        var contactList: NSArray = ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering(addressBook, source, ABPersonSortOrdering(kABPersonEmailProperty )).takeRetainedValue()
        println("records in the array \(contactList.count)")
        for record:ABRecordRef in contactList{
            if !record.isEqual(nil){
                var contactPerson: ABRecordRef = record
                let emailProperty: ABMultiValueRef = ABRecordCopyValue(record, kABPersonEmailProperty).takeRetainedValue() as ABMultiValueRef
                if ABMultiValueGetCount(emailProperty) > 0 {
                    let allEmailIDs : NSArray = ABMultiValueCopyArrayOfAllValues(emailProperty).takeUnretainedValue() as NSArray
                    for email in allEmailIDs {
                        let emailID = email as! String
                        let contactFirstName: String = ABRecordCopyValue(contactPerson, kABPersonFirstNameProperty)?.takeRetainedValue() as? String ?? ""
                        let contactLastName: String = ABRecordCopyValue(contactPerson, kABPersonLastNameProperty)?.takeRetainedValue() as? String ?? ""
                        addRecord(Record(firstname:contactFirstName, lastname: contactLastName, email:emailID as String))
                        println ("contactEmail : \(emailID) :=>")
                    }
                }
            }
        }
        orderEmails()
    }
    
    //
    //Check if similar Email exists in Addressbook
    //
    
    @IBAction func EmailAddressEntered(sender: AnyObject) {
        var email:String=txtTo.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        var i: Int = count(email)
        println("Toaddress: \(txtTo.text)")
        if(email==""){
            Suggestion.text=""
        }
        else if(email==Suggestion.text){}
        else if(email.rangeOfString(",") != nil){
            var add:NSArray = email.componentsSeparatedByString(",")
            i=count(add.lastObject!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) as String)
            if(i != 0){
                checkforsimilarEmail(i, email:add.lastObject!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) as String)
            }
        }
        else{
            checkforsimilarEmail(i, email:email as String)
        }
    }
    
    func checkforsimilarEmail(i:Int,email:String){
        println("Toaddress: \(email)")
        for results in sortedEmails{
            if(i>count(results.email)){
                continue
            }
            let index: String.Index = advance(results.email.startIndex, i)
            var substring: String = results.email.substringToIndex(index)
            if(substring==email){
                Suggestion.text = results.email
                break
            }
            Suggestion.text = ""
        }
    }
    
    //
    //Confirm suggested Emailaddress
    //
    
    @IBAction func ConfirmEmail(sender: AnyObject) {
        var txtAddresses:String=""
        var add:Array=txtTo.text.componentsSeparatedByString(",")
        if(add.count > 1){
            add.removeAtIndex(add.count-1)
            for var index = 0; index < add.count; ++index{
                txtAddresses += add[index] as String
                txtAddresses += ", "
            }
            txtAddresses += Suggestion.text
            txtTo.text=txtAddresses
            Suggestion.text=""
        }
        else if(!(Suggestion.text==nil)){
            txtTo.text=Suggestion.text
            Suggestion.text=""
        }
    }
    
    //
    //   öffnet das Telefonbuch in App
    //
    @IBAction func doPeoplePicker (sender:AnyObject!) {
        let picker = ABPeoplePickerNavigationController()
        picker.peoplePickerDelegate = self
        picker.displayedProperties = [Int(kABPersonEmailProperty)]
        picker.predicateForSelectionOfPerson = NSPredicate(value:false)
        picker.predicateForSelectionOfProperty = NSPredicate(value:true)
        self.presentViewController(picker, animated:true, completion:nil)
    }
    
    func peoplePickerNavigationController(peoplePicker: ABPeoplePickerNavigationController!, didSelectPerson person: ABRecord!) {
        println("person")
        println(person)
    }
    
    func peoplePickerNavigationController(peoplePicker: ABPeoplePickerNavigationController!, didSelectPerson person: ABRecordRef!, property: ABPropertyID, identifier: ABMultiValueIdentifier) {
            println("person and property")
            let emails:ABMultiValue = ABRecordCopyValue(person, property).takeRetainedValue()
            let ix = ABMultiValueGetIndexForIdentifier(emails, identifier)
            let email = ABMultiValueCopyValueAtIndex(emails, ix).takeRetainedValue() as! String
            println(email)
            txtTo.text=email
            
    }
}

class Record: NSObject{
    let email: String
    let lastname: String
    let firstname: String
    
    init ( firstname: String, lastname: String, email: String){
        self.email = email
        self.lastname = lastname
        self.firstname = firstname
    }
    
}