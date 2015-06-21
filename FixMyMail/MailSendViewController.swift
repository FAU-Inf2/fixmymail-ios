import UIKit
import CoreData
import AddressBook
import Foundation
import AddressBookUI

class MailSendViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ABPeoplePickerNavigationControllerDelegate, UITextViewDelegate, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
    @IBOutlet weak var sendTableView: UITableView!
    var emailAddressPicker: UIPickerView!
    var origintableViewInsets: UIEdgeInsets?
    
    var tableViewIsExpanded: Bool = false
    var recipients: NSMutableArray = NSMutableArray()
    var ccRecipients: NSMutableArray = NSMutableArray()
    var bccRecipients: NSMutableArray = NSMutableArray()
    var account: EmailAccount!
    var subject: String = ""
    var textBody: String = ""
    var allAccounts: [EmailAccount]!
    
    var isResponder: AnyObject? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.emailAddressPicker = UIPickerView()
        self.emailAddressPicker.delegate = self
        self.emailAddressPicker.dataSource = self
        self.emailAddressPicker.backgroundColor = UIColor.whiteColor()
        self.emailAddressPicker.layer.borderColor = UIColor.grayColor().CGColor
        self.emailAddressPicker.layer.borderWidth = 0.5
        self.allAccounts = [EmailAccount]()
        self.allAccounts.append(self.account)
        let fetchRequest: NSFetchRequest = NSFetchRequest(entityName: "EmailAccount")
        var error: NSError?
        var result = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!.executeFetchRequest(fetchRequest, error: &error)
        if error != nil {
            NSLog("%@", error!.description)
        } else {
            if let emailAccounts = result {
                for account in emailAccounts {
                    if (!account.isEqual(self.account)) {
                        self.allAccounts.append(account as! EmailAccount)
                    }
                }
            }
        }
        if self.subject == "" {
            self.title = "New Message"
        } else {
            self.title = subject
        }
        self.sendTableView.registerNib(UINib(nibName: "SendViewCellWithLabelAndTextField", bundle: nil), forCellReuseIdentifier: "SendViewCellWithLabelAndTextField")
        self.sendTableView.registerNib(UINib(nibName: "SendViewCellWithTextView", bundle: nil), forCellReuseIdentifier: "SendViewCellWithTextView")
        self.sendTableView.rowHeight = UITableViewAutomaticDimension
        self.sendTableView.estimatedRowHeight = self.view.bounds.height
        var buttonSend: UIBarButtonItem = UIBarButtonItem(title: "Send", style: .Plain, target: self, action: "sendEmail:")
        self.navigationItem.rightBarButtonItem = buttonSend
        
        LoadAddresses()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        // Register notification when the keyboard will appear
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "keyboardWillShow:",
            name: UIKeyboardWillShowNotification,
            object: nil)
        
        // Register notification when the keyboard will be hide
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "keyboardWillHide:",
            name: UIKeyboardWillHideNotification,
            object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.tableViewIsExpanded {
            return 6
        }
        return 4
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            var cell = tableView.dequeueReusableCellWithIdentifier("SendViewCellWithLabelAndTextField", forIndexPath: indexPath) as! SendViewCellWithLabelAndTextField
            cell.label.textColor = UIColor.grayColor()
            cell.label.text = "To:"
            cell.textField.textColor = UIColor.blackColor()
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
            cell.textField.enabled = false
            
            var buttonOpenContacts: UIButton = UIButton.buttonWithType(UIButtonType.ContactAdd) as! UIButton
            buttonOpenContacts.frame = CGRectMake(0, 0, 20, 20)
            buttonOpenContacts.addTarget(self, action: "openPeoplePickerWithSender:", forControlEvents: UIControlEvents.TouchUpInside)
            cell.accessoryView = buttonOpenContacts
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            return cell
        case 1:
            if self.tableViewIsExpanded {
                var cell = tableView.dequeueReusableCellWithIdentifier("SendViewCellWithLabelAndTextField", forIndexPath: indexPath) as! SendViewCellWithLabelAndTextField
                cell.label.textColor = UIColor.grayColor()
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
                cell.textField.enabled = false
                
                var buttonOpenContacts: UIButton = UIButton.buttonWithType(UIButtonType.ContactAdd) as! UIButton
                buttonOpenContacts.frame = CGRectMake(0, 0, 20, 20)
                buttonOpenContacts.addTarget(self, action: "openPeoplePickerWithSender:", forControlEvents: UIControlEvents.TouchUpInside)
                cell.accessoryView = buttonOpenContacts
                cell.selectionStyle = UITableViewCellSelectionStyle.None
                return cell
            } else {
                var cell = tableView.dequeueReusableCellWithIdentifier("SendViewCellWithLabelAndTextField", forIndexPath: indexPath) as! SendViewCellWithLabelAndTextField
                cell.label.textColor = UIColor.grayColor()
                cell.label.text = "Cc/Bcc, From:"
                cell.textField.textColor = UIColor.grayColor()
                cell.textField.text = self.account.emailAddress
                cell.textField.tag = 5
                cell.textField.delegate = self
                cell.accessoryView = nil
                cell.selectionStyle = UITableViewCellSelectionStyle.None
                cell.textField.enabled = false
                return cell
            }
        case 2:
            if self.tableViewIsExpanded {
                var cell = tableView.dequeueReusableCellWithIdentifier("SendViewCellWithLabelAndTextField", forIndexPath: indexPath) as! SendViewCellWithLabelAndTextField
                cell.label.textColor = UIColor.grayColor()
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
                cell.textField.enabled = false
                
                var buttonOpenContacts: UIButton = UIButton.buttonWithType(UIButtonType.ContactAdd) as! UIButton
                buttonOpenContacts.frame = CGRectMake(0, 0, 20, 20)
                buttonOpenContacts.addTarget(self, action: "openPeoplePickerWithSender:", forControlEvents: UIControlEvents.TouchUpInside)
                cell.accessoryView = buttonOpenContacts
                cell.selectionStyle = UITableViewCellSelectionStyle.None
                return cell
            } else {
                var cell = tableView.dequeueReusableCellWithIdentifier("SendViewCellWithLabelAndTextField", forIndexPath: indexPath) as! SendViewCellWithLabelAndTextField
                cell.label.textColor = UIColor.grayColor()
                cell.label.text = "Subject:"
                cell.textField.text = self.subject
                cell.textField.tag = 6
                cell.textField.delegate = self
                cell.textField.addTarget(self, action: "updateSubjectAndTitleWithSender:", forControlEvents: UIControlEvents.EditingChanged)
                cell.textField.enabled = false
                cell.selectionStyle = UITableViewCellSelectionStyle.None
                return cell
            }
        case 3:
            if self.tableViewIsExpanded {
                var cell = tableView.dequeueReusableCellWithIdentifier("SendViewCellWithLabelAndTextField", forIndexPath: indexPath) as! SendViewCellWithLabelAndTextField
                cell.label.textColor = UIColor.grayColor()
                cell.label.text = "From:"
                cell.textField.text = self.account.emailAddress
                cell.textField.tag = 3
                cell.textField.delegate = self
                cell.textField.tintColor = UIColor.whiteColor()
                cell.textField.inputView = self.emailAddressPicker
                cell.textField.enabled = false
                return cell
            } else {
                var cell = tableView.dequeueReusableCellWithIdentifier("SendViewCellWithTextView", forIndexPath: indexPath) as! SendViewCellWithTextView
                cell.textViewMailBody.addConstraint(NSLayoutConstraint(item: cell.textViewMailBody, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 0, constant: tableView.frame.height - (3 * 44 + self.navigationController!.navigationBar.frame.size.height + UIApplication.sharedApplication().statusBarFrame.size.height)))
                cell.textViewMailBody.delegate = self
                cell.textViewMailBody.text = self.textBody
                cell.selectionStyle = UITableViewCellSelectionStyle.None
                return cell
            }
        case 4:
            var cell = tableView.dequeueReusableCellWithIdentifier("SendViewCellWithLabelAndTextField", forIndexPath: indexPath) as! SendViewCellWithLabelAndTextField
            cell.label.textColor = UIColor.grayColor()
            cell.label.text = "Subject:"
            cell.textField.text = self.subject
            cell.textField.tag = 4
            cell.textField.delegate = self
            cell.textField.addTarget(self, action: "updateSubjectAndTitleWithSender:", forControlEvents: UIControlEvents.EditingChanged)
            cell.textField.enabled = false
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            return cell
        case 5:
            var cell = tableView.dequeueReusableCellWithIdentifier("SendViewCellWithTextView", forIndexPath: indexPath) as! SendViewCellWithTextView
            cell.textViewMailBody.addConstraint(NSLayoutConstraint(item: cell.textViewMailBody, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 0, constant: tableView.frame.height - (5 * 44 + self.navigationController!.navigationBar.frame.size.height + UIApplication.sharedApplication().statusBarFrame.size.height)))
            cell.textViewMailBody.delegate = self
            cell.textViewMailBody.text = self.textBody
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var selectIndexPath: NSIndexPath? = nil
        switch indexPath.row {
        case 0:
            if tableViewIsExpanded && self.shouldContractTableView() {
                tableViewIsExpanded = false
                tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
            }
            selectIndexPath = indexPath
        case 1:
            if !tableViewIsExpanded {
                tableViewIsExpanded = true
                tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
            }
            selectIndexPath = indexPath
        case 2:
            selectIndexPath = indexPath
        case 3:
            if tableViewIsExpanded {
                selectIndexPath = indexPath
            } else {
                if let responder: AnyObject = self.isResponder {
                    responder.resignFirstResponder()
                }
                var textView = (tableView.cellForRowAtIndexPath(indexPath) as! SendViewCellWithTextView).textViewMailBody
                textView.becomeFirstResponder()
            }
        case 4:
            if self.shouldContractTableView() {
                tableViewIsExpanded = false
                tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
                selectIndexPath = NSIndexPath(forRow: 2, inSection: 0)
            } else {
                selectIndexPath = indexPath
            }
        case 5:
            if self.shouldContractTableView() {
                tableViewIsExpanded = false
                tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
                var textView = (tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 3, inSection: 0)) as! SendViewCellWithTextView).textViewMailBody
                textView.becomeFirstResponder()
            } else {
                var textView = (tableView.cellForRowAtIndexPath(indexPath) as! SendViewCellWithTextView).textViewMailBody
                textView.becomeFirstResponder()
            }
        default:
            break
        }
        if let newIndexPath = selectIndexPath {
            var textField = (tableView.cellForRowAtIndexPath(newIndexPath) as! SendViewCellWithLabelAndTextField).textField
            if let responder: AnyObject = self.isResponder {
                if textField.isEqual(responder) {
                    return
                } else {
                    responder.resignFirstResponder()
                }
            }
            textField.enabled = true
            textField.becomeFirstResponder()
        }
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.allAccounts.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        return self.allAccounts[row].emailAddress
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.account = self.allAccounts[row]
        (self.isResponder as! UITextField).text = self.account.emailAddress
    }
    
    func shouldContractTableView() -> Bool {
        var cell = self.sendTableView.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 0)) as! SendViewCellWithLabelAndTextField
        if cell.textField.text != "" {
            return false
        }
        cell = self.sendTableView.cellForRowAtIndexPath(NSIndexPath(forRow: 2, inSection: 0)) as! SendViewCellWithLabelAndTextField
        if cell.textField.text != "" {
            return false
        }
        return true
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        self.textBody = textView.text
        self.isResponder = nil
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        self.isResponder = textView
        if self.tableViewIsExpanded {
            tableView(sendTableView, didSelectRowAtIndexPath: NSIndexPath(forRow: 5, inSection: 0))
        }
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        self.isResponder = nil
        textField.enabled = false
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
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        self.isResponder = textField
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
        (sender as! UIBarButtonItem).enabled = false
        if let responder: AnyObject = self.isResponder {
            responder.resignFirstResponder()
        }
        var session = MCOSMTPSession()
        session.hostname = self.account.smtpHostname
        session.port = UInt32(self.account.smtpPort.unsignedIntegerValue)
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
        if self.tableViewIsExpanded {
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
    
    // add keyboard size to tableView size
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue().size {
            var contentInsets = UIEdgeInsetsMake(self.navigationController!.navigationBar.frame.size.height + UIApplication.sharedApplication().statusBarFrame.size.height, 0.0, keyboardSize.height, 0.0)
            
            if self.origintableViewInsets == nil {
                self.origintableViewInsets = self.sendTableView.contentInset
            }
            
            self.sendTableView.contentInset = contentInsets
            self.sendTableView.scrollIndicatorInsets = contentInsets
            if self.isResponder != nil {
                var cellView = self.isResponder!.superview!
                var cell = cellView!.superview as! UITableViewCell
                var indexPath = self.sendTableView.indexPathForCell(cell)
                self.sendTableView.scrollToRowAtIndexPath(indexPath!, atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
            }
        }
    }
    // bring tableview size back to origin
    func keyboardWillHide(notification: NSNotification) {
        if let animationDuration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double) {
            if self.origintableViewInsets != nil {
                UIView.animateWithDuration(animationDuration, animations: { () -> Void in
                    self.sendTableView.contentInset = self.origintableViewInsets!
                    self.sendTableView.scrollIndicatorInsets = self.origintableViewInsets!
                })
            }
        }
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
    }
    
}
