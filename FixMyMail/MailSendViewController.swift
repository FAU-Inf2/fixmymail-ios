import UIKit
import CoreData
import AddressBook
import Foundation
import AddressBookUI

class MailSendViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ABPeoplePickerNavigationControllerDelegate, UITextViewDelegate, UITextFieldDelegate {
    @IBOutlet weak var sendTableView: UITableView!
    var tokenView: KSTokenView = KSTokenView(frame: .zeroRect)
    
    var expendTableView: Bool = false
    var recipients: NSMutableArray = NSMutableArray()
    var ccRecipients: NSMutableArray = NSMutableArray()
    var bccRecipients: NSMutableArray = NSMutableArray()
    var account: EmailAccount!
    var subject: String = ""
    var textBody: String = ""
    
    var isResponder: AnyObject? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.subject == "" {
            self.title = "New Message"
        } else {
            self.title = subject
        }
        self.sendTableView.registerNib(UINib(nibName: "SendViewCellSubject", bundle: nil), forCellReuseIdentifier: "SendViewCellSubject")
        self.sendTableView.registerNib(UINib(nibName: "SendViewCellTo", bundle: nil), forCellReuseIdentifier: "SendViewCellTo")
        self.sendTableView.registerNib(UINib(nibName: "SendViewCellText", bundle: nil), forCellReuseIdentifier: "SendViewCellText")
        self.sendTableView.rowHeight = UITableViewAutomaticDimension
        self.sendTableView.estimatedRowHeight = self.view.bounds.height
        var buttonSend: UIBarButtonItem = UIBarButtonItem(title: "Send", style: .Plain, target: self, action: "sendEmail:")
        self.navigationItem.rightBarButtonItem = buttonSend
        
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
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.expendTableView {
            return 6
        }
        return 4
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            var cell = tableView.dequeueReusableCellWithIdentifier("SendViewCellWithLabelAndTextField", forIndexPath: indexPath) as! SendViewCellWithLabelAndTextField
            cell.label.text = "To:"
            var recipientsAsString: String = ""
            var count = 1
            for recipient in self.recipients {
                NSLog("%@", (recipient as! MCOAddress).mailbox)
                recipientsAsString = recipientsAsString + (recipient as! MCOAddress).mailbox
                if count++ < self.recipients.count {
                    recipientsAsString = recipientsAsString + ", "
                }
            }
            cell.textField.text = recipientsAsString
            cell.textField.tag = 0
            cell.textField.delegate = self
            var buttonOpenContacts: UIButton = UIButton.buttonWithType(UIButtonType.ContactAdd) as! UIButton
            buttonOpenContacts.frame = CGRectMake(0, 0, 20, 20)
            buttonOpenContacts.addTarget(self, action: "openPeoplePickerWithSender:", forControlEvents: UIControlEvents.TouchUpInside)
            cell.accessoryView = buttonOpenContacts
            return cell
        case 1:
            if self.expendTableView {
                var cell = tableView.dequeueReusableCellWithIdentifier("SendViewCellWithLabelAndTextField", forIndexPath: indexPath) as! SendViewCellWithLabelAndTextField
                cell.label.text = "Cc:"
                var ccRecipientsAsString: String = ""
                var count = 1
                for ccRecipient in self.ccRecipients {
                    ccRecipientsAsString = ccRecipientsAsString + (ccRecipient as! MCOAddress).mailbox
                    if count++ < self.ccRecipients.count {
                        ccRecipientsAsString = ccRecipientsAsString + ", "
                    }
                }
                cell.textField.text = ccRecipientsAsString
                cell.textField.tag = 1
                cell.textField.delegate = self
                var buttonOpenContacts: UIButton = UIButton.buttonWithType(UIButtonType.ContactAdd) as! UIButton
                buttonOpenContacts.frame = CGRectMake(0, 0, 20, 20)
                buttonOpenContacts.addTarget(self, action: "openPeoplePickerWithSender:", forControlEvents: UIControlEvents.TouchUpInside)
                cell.accessoryView = buttonOpenContacts
                return cell
            } else {
                var cell = tableView.dequeueReusableCellWithIdentifier("SendViewCellWithLabelAndTextField", forIndexPath: indexPath) as! SendViewCellWithLabelAndTextField
                cell.label.text = "Cc/Bcc, From:"
                cell.textField.text = self.account.emailAddress
                cell.textField.tag = 5
                cell.textField.delegate = self
                cell.accessoryView = nil
                return cell
            }
        case 2:
            if self.expendTableView {
                var cell = tableView.dequeueReusableCellWithIdentifier("SendViewCellWithLabelAndTextField", forIndexPath: indexPath) as! SendViewCellWithLabelAndTextField
                cell.label.text = "Bcc:"
                var bccRecipientsAsString: String = ""
                var count = 1
                for bccRecipient in self.bccRecipients {
                    bccRecipientsAsString = bccRecipientsAsString + (bccRecipient as! MCOAddress).mailbox
                    if count++ < self.bccRecipients.count {
                        bccRecipientsAsString = bccRecipientsAsString + ", "
                    }
                }
                cell.textField.text = bccRecipientsAsString
                cell.textField.tag = 2
                cell.textField.delegate = self
                var buttonOpenContacts: UIButton = UIButton.buttonWithType(UIButtonType.ContactAdd) as! UIButton
                buttonOpenContacts.frame = CGRectMake(0, 0, 20, 20)
                buttonOpenContacts.addTarget(self, action: "openPeoplePickerWithSender:", forControlEvents: UIControlEvents.TouchUpInside)
                cell.accessoryView = buttonOpenContacts
                return cell
            } else {
                var cell = tableView.dequeueReusableCellWithIdentifier("SendViewCellWithLabelAndTextField", forIndexPath: indexPath) as! SendViewCellWithLabelAndTextField
                cell.label.text = "Subject:"
                cell.textField.text = self.subject
                cell.textField.tag = 6
                cell.textField.delegate = self
                cell.textField.addTarget(self, action: "updateSubjectAndTitleWithSender:", forControlEvents: UIControlEvents.EditingChanged)
                return cell
            }
        case 3:
            if self.expendTableView {
                var cell = tableView.dequeueReusableCellWithIdentifier("SendViewCellWithLabelAndTextField", forIndexPath: indexPath) as! SendViewCellWithLabelAndTextField
                cell.label.text = "From:"
                cell.textField.text = self.account.emailAddress
                cell.textField.tag = 3
                cell.textField.delegate = self
                return cell
            } else {
                var cell = tableView.dequeueReusableCellWithIdentifier("SendViewCellWithTextView", forIndexPath: indexPath) as! SendViewCellWithTextView
                cell.textViewMailBody.addConstraint(NSLayoutConstraint(item: cell.textViewMailBody, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 0, constant: tableView.frame.height - 3 * 44))
                cell.textViewMailBody.delegate = self
                cell.textViewMailBody.text = self.textBody
                return cell
            }
        case 4:
            var cell = tableView.dequeueReusableCellWithIdentifier("SendViewCellWithLabelAndTextField", forIndexPath: indexPath) as! SendViewCellWithLabelAndTextField
            cell.label.text = "Subject:"
            cell.textField.text = self.subject
            cell.textField.tag = 4
            cell.textField.delegate = self
            cell.textField.addTarget(self, action: "updateSubjectAndTitleWithSender:", forControlEvents: UIControlEvents.EditingChanged)
            return cell
        case 5:
            var cell = tableView.dequeueReusableCellWithIdentifier("SendViewCellWithTextView", forIndexPath: indexPath) as! SendViewCellWithTextView
            cell.textViewMailBody.addConstraint(NSLayoutConstraint(item: cell.textViewMailBody, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 0, constant: tableView.frame.height - 5 * 44))
            cell.textViewMailBody.delegate = self
            cell.textViewMailBody.text = self.textBody
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if self.expendTableView {
            if indexPath.row != 1 && indexPath.row != 2 && indexPath.row != 3 {
                var cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 0)) as! SendViewCellWithLabelAndTextField
                if cell.textField.text != "" {
                    return
                }
                cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 2, inSection: 0)) as! SendViewCellWithLabelAndTextField
                if cell.textField.text != "" {
                    return
                }
                self.expendTableView = false
                tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
            }
        } else {
            if indexPath.row == 1 {
                self.expendTableView = true
                tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
            }
        }
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        self.textBody = textView.text
        self.isResponder = nil
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        self.isResponder = textView
        if self.expendTableView {
            tableView(sendTableView, didSelectRowAtIndexPath: NSIndexPath(forRow: 5, inSection: 0))
        }
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        switch textField.tag {
        case 0:
            self.recipients.removeAllObjects()
            var recipientsAsString = textField.text
            recipientsAsString = recipientsAsString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            for recipient in recipientsAsString.componentsSeparatedByString(", ") {
                self.recipients.addObject(MCOAddress(mailbox: recipient))
            }
        case 1:
            self.ccRecipients.removeAllObjects()
            var ccRecipientsAsString = textField.text
            ccRecipientsAsString = ccRecipientsAsString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            for recipient in ccRecipientsAsString.componentsSeparatedByString(", ") {
                self.ccRecipients.addObject(MCOAddress(mailbox: recipient))
            }
        case 2:
            self.bccRecipients.removeAllObjects()
            var bccRecipientsAsString = textField.text
            bccRecipientsAsString = bccRecipientsAsString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            for recipient in bccRecipientsAsString.componentsSeparatedByString(", ") {
                self.bccRecipients.addObject(MCOAddress(mailbox: recipient))
            }
        default:
            break
        }
        self.isResponder = nil
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        self.isResponder = textField
        switch textField.tag {
        case 0:
            if self.expendTableView {
                tableView(sendTableView, didSelectRowAtIndexPath: NSIndexPath(forRow: 0, inSection: 0))
            }
        case 3, 5:
            if !self.expendTableView {
                tableView(sendTableView, didSelectRowAtIndexPath: NSIndexPath(forRow: 1, inSection: 0))
            }
        case 4, 6:
            if self.expendTableView {
                tableView(sendTableView, didSelectRowAtIndexPath: NSIndexPath(forRow: 4, inSection: 0))
            }
        default:
            break
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func updateSubjectAndTitleWithSender(sender: AnyObject) {
        var subject = (sender as! UITextField).text
        self.subject = subject
        if subject == "" {
            self.title = "New Message"
        } else {
            self.title = subject
        }
    }
    
    func sendEmail(sender: AnyObject) {
        if let responder: AnyObject = self.isResponder {
            responder.resignFirstResponder()
        }
        var session = MCOSMTPSession()
        session.hostname = self.account.smtpHostname
        session.port = self.account.smtpPort
        session.username = self.account.username
        let (dictionary, error) = Locksmith.loadDataForUserAccount(self.account.emailAddress)
        if error == nil {
            session.password = dictionary?.valueForKey("Password:") as! String
        } else {
            NSLog("%@", error!.description)
            return
        }
        session.connectionType = StringToConnectionType(self.account.connectionTypeSmtp)
        session.authType = StringToAuthType(self.account.authTypeSmtp)
        
        var builder = MCOMessageBuilder()
        
        builder.header.from = MCOAddress(displayName: self.account.realName, mailbox: self.account.emailAddress)
        builder.header.sender = MCOAddress(displayName: self.account.realName, mailbox: self.account.emailAddress)
        builder.header.to = self.recipients as [AnyObject]
        var offset = 0
        if self.expendTableView {
            offset = 2
            builder.header.cc = self.ccRecipients as [AnyObject]
            builder.header.bcc = self.bccRecipients as [AnyObject]
        }
        builder.header.subject = self.subject
        builder.textBody = self.textBody
        
        let sendOp = session.sendOperationWithData(builder.data())
        sendOp.start({(error) in
            if error != nil {
                NSLog("%@", error.description)
            } else {
                NSLog("sent")
                self.navigationController?.popViewControllerAnimated(true)
            }
        })
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
    func openPeoplePickerWithSender(sender:AnyObject!) {
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