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
    var sendingAccount: EmailAccount!
    var subject: String = ""
    var textBody: String = ""
    
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
            var cell = tableView.dequeueReusableCellWithIdentifier("SendViewCellTo", forIndexPath: indexPath) as! SendViewCellTo
            cell.lblTo.text = "To:"
            var recipientsAsString: String = ""
            var count = 1
            for recipient in self.recipients {
                recipientsAsString = recipientsAsString + (recipient as! MCOAddress).mailbox
                if count++ < self.recipients.count {
                    recipientsAsString = recipientsAsString + ", "
                }
            }
            cell.txtTo.text = recipientsAsString
            cell.txtTo.tag = 0
            cell.txtTo.delegate = self
            var buttonOpenContacts: UIButton = UIButton.buttonWithType(UIButtonType.ContactAdd) as! UIButton
            buttonOpenContacts.frame = CGRectMake(0, 0, 20, 20)
            buttonOpenContacts.addTarget(self, action: "doPeoplePicker:", forControlEvents: UIControlEvents.TouchUpInside)
            cell.accessoryView = buttonOpenContacts
            cell.txtTo.addTarget(self, action: "updateRecipients:", forControlEvents: UIControlEvents.EditingDidEnd)
            return cell
        case 1:
            if self.expendTableView {
                var cell = tableView.dequeueReusableCellWithIdentifier("SendViewCellTo", forIndexPath: indexPath) as! SendViewCellTo
                cell.lblTo.text = "Cc:"
                var ccRecipientsAsString: String = ""
                var count = 1
                for ccRecipient in self.ccRecipients {
                    ccRecipientsAsString = ccRecipientsAsString + (ccRecipient as! MCOAddress).mailbox
                    if count++ < self.ccRecipients.count {
                        ccRecipientsAsString = ccRecipientsAsString + ", "
                    }
                }
                cell.txtTo.text = ccRecipientsAsString
                cell.txtTo.tag = 1
                cell.txtTo.delegate = self
                var buttonOpenContacts: UIButton = UIButton.buttonWithType(UIButtonType.ContactAdd) as! UIButton
                buttonOpenContacts.frame = CGRectMake(0, 0, 20, 20)
                buttonOpenContacts.addTarget(self, action: "doPeoplePicker:", forControlEvents: UIControlEvents.TouchUpInside)
                cell.accessoryView = buttonOpenContacts
                cell.txtTo.addTarget(self, action: "updateCcRecipients:", forControlEvents: UIControlEvents.EditingDidEnd)
                return cell
            } else {
                var cell = tableView.dequeueReusableCellWithIdentifier("SendViewCellTo", forIndexPath: indexPath) as! SendViewCellTo
                cell.lblTo.text = "Cc/Bcc, From:"
                cell.txtTo.text = self.sendingAccount.emailAddress
                cell.txtTo.tag = 3
                cell.txtTo.delegate = self
                return cell
            }
        case 2:
            if self.expendTableView {
                var cell = tableView.dequeueReusableCellWithIdentifier("SendViewCellTo", forIndexPath: indexPath) as! SendViewCellTo
                cell.lblTo.text = "Bcc:"
                var bccRecipientsAsString: String = ""
                var count = 1
                for bccRecipient in self.bccRecipients {
                    bccRecipientsAsString = bccRecipientsAsString + (bccRecipient as! MCOAddress).mailbox
                    if count++ < self.bccRecipients.count {
                        bccRecipientsAsString = bccRecipientsAsString + ", "
                    }
                }
                cell.txtTo.text = bccRecipientsAsString
                cell.txtTo.tag = 2
                cell.txtTo.delegate = self
                var buttonOpenContacts: UIButton = UIButton.buttonWithType(UIButtonType.ContactAdd) as! UIButton
                buttonOpenContacts.frame = CGRectMake(0, 0, 20, 20)
                buttonOpenContacts.addTarget(self, action: "doPeoplePicker:", forControlEvents: UIControlEvents.TouchUpInside)
                cell.accessoryView = buttonOpenContacts
                cell.txtTo.addTarget(self, action: "updateBccRecipients:", forControlEvents: UIControlEvents.EditingDidEnd)
                return cell
            } else {
                var cell = tableView.dequeueReusableCellWithIdentifier("SendViewCellSubject", forIndexPath: indexPath) as! SendViewCellSubject
                cell.txtText.text = self.subject
                cell.txtText.tag = 4
                cell.txtText.delegate = self
                cell.txtText.addTarget(self, action: "updateSubjectAndTitle:", forControlEvents: UIControlEvents.EditingChanged)
                return cell
            }
        case 3:
            if self.expendTableView {
                var cell = tableView.dequeueReusableCellWithIdentifier("SendViewCellTo", forIndexPath: indexPath) as! SendViewCellTo
                cell.lblTo.text = "From:"
                cell.txtTo.text = self.sendingAccount.emailAddress
                cell.txtTo.tag = 3
                cell.txtTo.delegate = self
                return cell
            } else {
                var cell = tableView.dequeueReusableCellWithIdentifier("SendViewCellText", forIndexPath: indexPath) as! SendViewCellText
                cell.textViewMailBody.addConstraint(NSLayoutConstraint(item: cell.textViewMailBody, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 0, constant: tableView.frame.height - 3 * 44))
                cell.textViewMailBody.delegate = self
                cell.textViewMailBody.text = self.textBody
                return cell
            }
        case 4:
            var cell = tableView.dequeueReusableCellWithIdentifier("SendViewCellSubject", forIndexPath: indexPath) as! SendViewCellSubject
            cell.txtText.text = self.subject
            cell.txtText.addTarget(self, action: "updateSubjectAndTitle:", forControlEvents: UIControlEvents.EditingChanged)
            cell.txtText.tag = 4
            cell.txtText.delegate = self
            return cell
        case 5:
            var cell = tableView.dequeueReusableCellWithIdentifier("SendViewCellText", forIndexPath: indexPath) as! SendViewCellText
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
                var cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 0)) as! SendViewCellTo
                if cell.txtTo.text != "" {
                    return
                }
                cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 2, inSection: 0)) as! SendViewCellTo
                if cell.txtTo.text != "" {
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
    }
    
    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        if self.expendTableView {
            tableView(sendTableView, didSelectRowAtIndexPath: NSIndexPath(forRow: 5, inSection: 0))
        }
        return true
    }
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        switch textField.tag {
        case 0:
            if self.expendTableView {
                tableView(sendTableView, didSelectRowAtIndexPath: NSIndexPath(forRow: 0, inSection: 0))
            }
        case 3:
            if !self.expendTableView {
                tableView(sendTableView, didSelectRowAtIndexPath: NSIndexPath(forRow: 1, inSection: 0))
            }
        case 4:
            if self.expendTableView {
                tableView(sendTableView, didSelectRowAtIndexPath: NSIndexPath(forRow: 4, inSection: 0))
            }
        default:
            NSLog("nothing to do here")
        }
        return true
    }
    
    func updateRecipients(sender: AnyObject) {
        self.recipients.removeAllObjects()
        var recipientsAsString = (sender as! UITextField).text
        recipientsAsString = recipientsAsString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        for recipient in recipientsAsString.componentsSeparatedByString(", ") {
            self.recipients.addObject(MCOAddress(mailbox: recipient))
        }
    }
    
    func updateCcRecipients(sender: AnyObject) {
        self.ccRecipients.removeAllObjects()
        var ccRecipientsAsString = (sender as! UITextField).text
        ccRecipientsAsString = ccRecipientsAsString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        for recipient in ccRecipientsAsString.componentsSeparatedByString(", ") {
            self.ccRecipients.addObject(MCOAddress(mailbox: recipient))
        }
    }
    
    func updateBccRecipients(sender: AnyObject) {
        self.bccRecipients.removeAllObjects()
        var bccRecipientsAsString = (sender as! UITextField).text
        bccRecipientsAsString = bccRecipientsAsString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        for recipient in bccRecipientsAsString.componentsSeparatedByString(", ") {
            self.bccRecipients.addObject(MCOAddress(mailbox: recipient))
        }
    }
    
    func updateSubjectAndTitle(sender: AnyObject) {
        var subject = (sender as! UITextField).text
        self.subject = subject
        if subject == "" {
            self.title = "New Message"
        } else {
            self.title = subject
        }
    }
    
    func sendEmail(sender: AnyObject) {
        var session = MCOSMTPSession()
        session.hostname = self.sendingAccount.smtpHostname
        session.port = UInt32(self.sendingAccount.smtpPort.unsignedIntegerValue)
        session.username = self.sendingAccount.username
        let (dictionary, error) = Locksmith.loadDataForUserAccount(self.sendingAccount.emailAddress)
        if error == nil {
            session.password = dictionary?.valueForKey("Password:") as! String
        } else {
            NSLog("%@", error!.description)
            return
        }
        session.connectionType = StringToConnectionType(self.sendingAccount.connectionTypeSmtp)
        session.authType = StringToAuthType(self.sendingAccount.authTypeSmtp)
        
        var builder = MCOMessageBuilder()
        
        builder.header.from = MCOAddress(displayName: self.sendingAccount.realName, mailbox: self.sendingAccount.emailAddress)
        builder.header.sender = MCOAddress(displayName: self.sendingAccount.realName, mailbox: self.sendingAccount.emailAddress)
        builder.header.to = self.recipients as [AnyObject]
        var offset = 0
        if self.expendTableView {
            offset = 2
            builder.header.cc = self.ccRecipients as [AnyObject]
            builder.header.bcc = self.bccRecipients as [AnyObject]
        }
        builder.header.subject = self.subject
        var textCell = sendTableView.cellForRowAtIndexPath(NSIndexPath(forRow: 3 + offset, inSection: 0)) as! SendViewCellText
        builder.textBody = textCell.textViewMailBody.text
        
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