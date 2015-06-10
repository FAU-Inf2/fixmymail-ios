import UIKit
import CoreData
import AddressBook
import Foundation
import AddressBookUI

class MailSendViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ABPeoplePickerNavigationControllerDelegate {
    @IBOutlet weak var sendTableView: UITableView!
    var ccOpened: Bool = false
    var replyTo: NSMutableArray? = nil
    var subject: String = ""
    var replyText: String = ""
    var activeAccount: EmailAccount? = nil
    var tokenView: KSTokenView = KSTokenView(frame: .zeroRect)
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "New E-Mail"
        self.sendTableView.registerNib(UINib(nibName: "SendViewCellSubject", bundle: nil), forCellReuseIdentifier: "SendViewCellSubject")
        self.sendTableView.registerNib(UINib(nibName: "SendViewCellTo", bundle: nil), forCellReuseIdentifier: "SendViewCellTo")
        self.sendTableView.registerNib(UINib(nibName: "SendViewCellText", bundle: nil), forCellReuseIdentifier: "SendViewCellText")
        self.sendTableView.rowHeight = UITableViewAutomaticDimension
        self.sendTableView.estimatedRowHeight = self.view.bounds.height
        var sendBut: UIBarButtonItem = UIBarButtonItem(title: "Senden", style: .Plain, target: self, action: "sendEmail:")
        self.navigationItem.rightBarButtonItem = sendBut
        if self.activeAccount == nil {
            var managedObjectContext: NSManagedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!
            let fetchRequest: NSFetchRequest = NSFetchRequest(entityName: "EmailAccount")
            var error: NSError?
            var result = managedObjectContext.executeFetchRequest(fetchRequest, error: &error)
            if error != nil {
                NSLog("%@", error!.description)
            } else {
                if let emailAccounts = result {
                    for account in emailAccounts {
                        if (account as! EmailAccount).active {
                            activeAccount = account as? EmailAccount
                            break
                        }
                    }
                }
            }
        }
        LoadAddresses()
        /*let tokenView = KSTokenView(frame: CGRect(x: 76, y: 100, width: 250, height: 30))
        tokenView.delegate = self
        tokenView.placeholder = "Email"
        tokenView.descriptionText = "Emails"
        tokenView.maxTokenLimit = -1
        tokenView.searchResultBackgroundColor = UIColor.lightGrayColor()
        tokenView.removesTokensOnEndEditing = false
        view.addSubview(tokenView)*/

    }
    
    
    @IBAction func sendEmail(sender: AnyObject) {
        var session = MCOSMTPSession()
        session.hostname = activeAccount!.smtpHostname
        session.port = activeAccount!.smtpPort
        session.username = activeAccount!.username
        session.password = activeAccount!.password
        session.connectionType = StringToConnectionType(activeAccount!.connectionTypeSmtp);
        session.authType = StringToAuthType(activeAccount!.authTypeSmtp);
        
        var builder = MCOMessageBuilder()
        var from = MCOAddress()
        from.displayName = activeAccount!.realName
        from.mailbox = activeAccount!.emailAddress
        var sender = MCOAddress()
        sender.displayName = activeAccount!.realName
        sender.mailbox = activeAccount!.emailAddress
        builder.header.from = from
        builder.header.sender = sender
        var tos: NSMutableArray = NSMutableArray()
        var toCell = sendTableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as! SendViewCellTo
        // toCell.txtTo.text = tokenView.descriptionText
        var recipients: String = toCell.txtTo.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        for recipient in recipients.componentsSeparatedByString(", ") {
            var to = MCOAddress()
            to.mailbox = recipient
            NSLog("%@", recipient)
            tos.addObject(to)
        }
        builder.header.to = tos as [AnyObject]
        var ccCell: SendViewCellTo = SendViewCellTo()
        var bccCell: SendViewCellTo = SendViewCellTo()
        var offset = 0
        if ccOpened {
            offset = 2
            ccCell = sendTableView.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 0)) as! SendViewCellTo
            var ccs: NSMutableArray = NSMutableArray()
            var ccRecipients: String = ccCell.txtTo.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            for recipient in ccRecipients.componentsSeparatedByString(", ") {
                var to = MCOAddress()
                to.mailbox = recipient
                ccs.addObject(to)
            }
            builder.header.cc = ccs as [AnyObject]
            bccCell = sendTableView.cellForRowAtIndexPath(NSIndexPath(forRow: 2, inSection: 0)) as! SendViewCellTo
            var bccs: NSMutableArray = NSMutableArray()
            var bccRecipients: String = bccCell.txtTo.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            for recipient in bccRecipients.componentsSeparatedByString(", ") {
                var to = MCOAddress()
                to.mailbox = recipient
                bccs.addObject(to)
            }
            builder.header.bcc = bccs as [AnyObject]
        }
        var subCell = sendTableView.cellForRowAtIndexPath(NSIndexPath(forRow: 2 + offset, inSection: 0)) as! SendViewCellSubject
        builder.header.subject = subCell.txtText.text
        var textCell = sendTableView.cellForRowAtIndexPath(NSIndexPath(forRow: 3 + offset, inSection: 0)) as! SendViewCellText
        builder.textBody = textCell.textViewMailBody.text
                
        let op = session.sendOperationWithData(builder.data())
                
        op.start({(NSError error) in
            if (error != nil) {
                NSLog("can't send message: %@", error)
            } else {
                toCell.txtTo.text = ""
                subCell.txtText.text = ""
                textCell.textViewMailBody.text = ""
                if self.ccOpened {
                    ccCell.txtTo.text = ""
                    bccCell.txtTo.text = ""
                }
                NSLog("sent")
            }
        })
    }
    
    // TableView
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if ccOpened {
            return 6
        }
        return 4
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if ccOpened {
            switch indexPath.row {
            case 0:
                var sendCell = tableView.dequeueReusableCellWithIdentifier("SendViewCellTo", forIndexPath: indexPath) as! SendViewCellTo
                sendCell.lblTo.text = "To:"
                if sendCell.txtTo.text == "" {
                    if self.replyTo != nil {
                        for address in self.replyTo! {
                            sendCell.txtTo.text = sendCell.txtTo.text + (address as! MCOAddress).mailbox
                            if self.replyTo!.lastObject!.isEqual(address) == false {
                                sendCell.txtTo.text = sendCell.txtTo.text + ", "
                            }
                        }
                    }
                }
                sendCell.txtTo.addTarget(self, action: "closeCC", forControlEvents: UIControlEvents.AllEditingEvents)
                sendCell.emails = sortedEmails
                var addContacts: UIButton = UIButton.buttonWithType(UIButtonType.ContactAdd) as! UIButton
                addContacts.frame = CGRectMake(0, 0, 20, 20)
                addContacts.addTarget(self, action: "doPeoplePicker:", forControlEvents: UIControlEvents.TouchUpInside)
                sendCell.accessoryView = addContacts
                return sendCell
            case 1:
                var sendCell = tableView.dequeueReusableCellWithIdentifier("SendViewCellTo", forIndexPath: indexPath) as! SendViewCellTo
                sendCell.lblTo.text = "Cc:"
                sendCell.txtTo.text = ""
                var addContacts: UIButton = UIButton.buttonWithType(UIButtonType.ContactAdd) as! UIButton
                addContacts.frame = CGRectMake(0, 0, 20, 20)
                addContacts.addTarget(self, action: "doPeoplePicker:", forControlEvents: UIControlEvents.TouchUpInside)
                sendCell.accessoryView = addContacts
                return sendCell
            case 2:
                var sendCell = tableView.dequeueReusableCellWithIdentifier("SendViewCellTo", forIndexPath: indexPath) as! SendViewCellTo
                sendCell.lblTo.text = "Bcc:"
                sendCell.txtTo.text = ""
                var addContacts: UIButton = UIButton.buttonWithType(UIButtonType.ContactAdd) as! UIButton
                addContacts.frame = CGRectMake(0, 0, 20, 20)
                addContacts.addTarget(self, action: "doPeoplePicker:", forControlEvents: UIControlEvents.TouchUpInside)
                sendCell.accessoryView = addContacts
                return sendCell
            case 3:
                var sendCell = tableView.dequeueReusableCellWithIdentifier("SendViewCellTo", forIndexPath: indexPath) as! SendViewCellTo
                sendCell.lblTo.text = "From:"
                sendCell.txtTo.text = activeAccount!.emailAddress
                sendCell.accessoryView = nil
                return sendCell
            case 4:
                var sendCell = tableView.dequeueReusableCellWithIdentifier("SendViewCellSubject", forIndexPath: indexPath) as! SendViewCellSubject
                sendCell.txtText.text = self.subject
                sendCell.txtText.addTarget(self, action: "closeCC", forControlEvents: UIControlEvents.AllEditingEvents)
                return sendCell
            case 5:
                var sendCell = tableView.dequeueReusableCellWithIdentifier("SendViewCellText", forIndexPath: indexPath) as! SendViewCellText
                sendCell.textViewMailBody.addConstraint(NSLayoutConstraint(item: sendCell.textViewMailBody, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 0, constant: tableView.bounds.height + 132))
                if replyText != "" {
                    sendCell.textViewMailBody.text = replyText + "\n\n"
                }
                return sendCell
            default:
                var sendCell = UITableViewCell()
                return sendCell
            }
        } else {
            switch indexPath.row {
            case 0:
                var sendCell = tableView.dequeueReusableCellWithIdentifier("SendViewCellTo", forIndexPath: indexPath) as! SendViewCellTo
                sendCell.lblTo.text = "To:"
                if sendCell.txtTo.text == "" {
                    if self.replyTo != nil {
                        for address in self.replyTo! {
                            sendCell.txtTo.text = sendCell.txtTo.text + (address as! MCOAddress).mailbox
                            if self.replyTo!.lastObject!.isEqual(address) == false {
                                sendCell.txtTo.text = sendCell.txtTo.text + ", "
                            }
                        }
                    }
                }
                sendCell.emails = sortedEmails
                var addContacts: UIButton = UIButton.buttonWithType(UIButtonType.ContactAdd) as! UIButton
                addContacts.frame = CGRectMake(0, 0, 20, 20)
                addContacts.addTarget(self, action: "doPeoplePicker:", forControlEvents: UIControlEvents.TouchUpInside)
                sendCell.accessoryView = addContacts
                return sendCell
            case 1:
                var sendCell = tableView.dequeueReusableCellWithIdentifier("SendViewCellTo", forIndexPath: indexPath) as! SendViewCellTo
                sendCell.lblTo.text = "Cc/Bcc, From:"
                sendCell.txtTo.text = activeAccount!.emailAddress
                sendCell.accessoryView = nil
                sendCell.txtTo.addTarget(self, action: "openCC", forControlEvents: UIControlEvents.AllEditingEvents)
                return sendCell
            case 2:
                var sendCell = tableView.dequeueReusableCellWithIdentifier("SendViewCellSubject", forIndexPath: indexPath) as! SendViewCellSubject
                sendCell.txtText.text = self.subject
                return sendCell
            case 3:
                var sendCell = tableView.dequeueReusableCellWithIdentifier("SendViewCellText", forIndexPath: indexPath) as! SendViewCellText
                sendCell.textViewMailBody.addConstraint(NSLayoutConstraint(item: sendCell.textViewMailBody, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 0, constant: tableView.bounds.height + 132))
                if replyText != "" {
                    sendCell.textViewMailBody.text = replyText + "\n\n"
                }
                return sendCell
            default:
                var sendCell = UITableViewCell()
                return sendCell
            }
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if ccOpened {
            if indexPath.row != 1 && indexPath.row != 2 && indexPath.row != 3 {
                var cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 0)) as! SendViewCellTo
                if cell.txtTo.text != "" {
                    return
                }
                cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 2, inSection: 0)) as! SendViewCellTo
                if cell.txtTo.text != "" {
                    return
                }
                ccOpened = false
                tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
            }
        } else {
            if indexPath.row == 1 {
                ccOpened = true
                tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
            }
        }
    }
    
    func closeCC() {
        self.tableView(sendTableView, didSelectRowAtIndexPath: NSIndexPath(forRow: 0, inSection: 0))
    }
    
    func openCC() {
        self.tableView(sendTableView, didSelectRowAtIndexPath: NSIndexPath(forRow: 1, inSection: 0))
    }
    
    // Addressbook functionality
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
    //   öffnet das Telefonbuch in App
    //
    @IBAction func doPeoplePicker (sender:AnyObject!) {
        let picker = ABPeoplePickerNavigationController()
        picker.peoplePickerDelegate = self
        picker.displayedProperties = [Int(kABPersonEmailProperty)]
        picker.predicateForSelectionOfPerson = NSPredicate(value:false)
        picker.predicateForSelectionOfProperty = NSPredicate(value:true)
        self.presentViewController(picker, animated:true, completion:nil)
        var tok: Array<KSToken>= tokenView.tokens()!
        /*var emailaddr: NSMutableArray = []
        for var index = 0; index < tok.count-1; ++index {
            emailaddr.addObject(tokenView(tokenView, displayTitleForObject: ))
        }
        println ("contactEmail :\( emailaddr.firstObject as! String)")*/
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
        //TODO
        //Email in KSTokenView einbinden
     }
    
   
    
}
extension MailSendViewController: KSTokenViewDelegate {
    func tokenView(token: KSTokenView, performSearchWithString string: String, completion: ((results: Array<AnyObject>) -> Void)?) {
        token.searchResultBackgroundColor = UIColor.lightGrayColor()
        var data: Array<String> = []
        for value in sortedEmails {
            var emailaddress:String = value.email
            if emailaddress.lowercaseString.rangeOfString(string.lowercaseString) != nil {
                data.append(emailaddress as String)
            }
        }
        completion!(results: data)
    }
    
    func tokenView(token: KSTokenView, displayTitleForObject object: AnyObject) -> String {
        
        return object as! String
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