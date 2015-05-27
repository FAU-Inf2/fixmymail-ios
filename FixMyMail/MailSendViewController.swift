import UIKit
import CoreData
import AddressBook

class MailSendViewController: UIViewController {
    @IBOutlet weak var txtTo: UITextField!
    @IBOutlet weak var txtSubject: UITextField!
    @IBOutlet weak var tvText: UITextView!
    @IBOutlet weak var Suggestion: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
                from.displayName = "Moritz Müller"
                from.mailbox = acc.emailAddress
                var sender = MCOAddress()
                sender.displayName = "Moritz Müller"
                sender.mailbox = acc.emailAddress
                builder.header.from = from
                builder.header.sender = sender
                var to = MCOAddress()
                //to.displayName = "Moritz Müller"
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
    
    @IBAction func EmailAddressEntered(sender: AnyObject) {
        var email:String=txtTo.text
        var i: Int = count(txtTo.text)
        println("Toaddress: \(txtTo.text)")
        if(email==""){
            Suggestion.text=""
        }
        else if(email==Suggestion.text){}
        else{
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
    }
    @IBAction func ConfirmEmail(sender: AnyObject) {
        txtTo.text=Suggestion.text
        Suggestion.text=""
    }
    
    func LoadAddresses() {
        
        //var contactList: NSArray = ABAddressBookCopyArrayOfAllPeople(addressBook).takeRetainedValue()
        var source: ABRecord = ABAddressBookCopyDefaultSource(addressBook).takeRetainedValue()
        var contactList: NSArray = ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering(addressBook, source, ABPersonSortOrdering(kABPersonEmailProperty )).takeRetainedValue()
        
        println("records in the array \(contactList.count)")
        
        for record:ABRecordRef in contactList{
            // if record != nil {
            if !record.isEqual(nil){
                var contactPerson: ABRecordRef = record
                
                let emailProperty: ABMultiValueRef = ABRecordCopyValue(record, kABPersonEmailProperty).takeRetainedValue() as ABMultiValueRef
                if ABMultiValueGetCount(emailProperty) > 0 {
                    let allEmailIDs : NSArray = ABMultiValueCopyArrayOfAllValues(emailProperty).takeUnretainedValue() as NSArray
                    for email in allEmailIDs {
                        let emailID = email as! String
                        let contactFirstName = ABRecordCopyValue(contactPerson, kABPersonFirstNameProperty).takeRetainedValue() as! NSString
                        let contactLastName = ABRecordCopyValue(contactPerson, kABPersonLastNameProperty).takeRetainedValue() as! NSString
                        addRecord(Record(firstname:contactFirstName as String, lastname: contactLastName as String, email:emailID as String))
                        println ("contactEmail : \(emailID) :=>")
                    }
                }
            }
        }
        orderEmails()
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