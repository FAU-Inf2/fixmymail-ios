import UIKit
import CoreData
import AddressBook
import Foundation
import AddressBookUI

class MailSendViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ABPeoplePickerNavigationControllerDelegate, UITextViewDelegate, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate, UIActionSheetDelegate {
    
    //MARK: - Variables
    @IBOutlet weak var sendTableView: UITableView!
    var emailAddressPicker: UIPickerView!
    
    var origintableViewInsets: UIEdgeInsets?
    
    var tableViewIsExpanded: Bool = false
    
    var recipients: NSMutableArray = NSMutableArray()
    var ccRecipients: NSMutableArray = NSMutableArray()
    var bccRecipients: NSMutableArray = NSMutableArray()
    var subject: String = ""
    var textBody: String = ""
    
    var account: EmailAccount!
    var allAccounts: [EmailAccount]!
    
    var isResponder: AnyObject? = nil
    
    //MARK: - Initialisation
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initPickerView()
        if self.subject == "" {
            self.title = "New Message"
        } else {
            self.title = subject
        }
        self.sendTableView.registerNib(UINib(nibName: "SendViewCellWithLabelAndTextField", bundle: nil), forCellReuseIdentifier: "SendViewCellWithLabelAndTextField")
        self.sendTableView.registerNib(UINib(nibName: "SendViewCellWithTextView", bundle: nil), forCellReuseIdentifier: "SendViewCellWithTextView")
        var buttonSend: UIBarButtonItem = UIBarButtonItem(title: "Send", style: .Plain, target: self, action: "sendEmailWithSender:")
        self.navigationItem.rightBarButtonItem = buttonSend
        var buttonCancel: UIBarButtonItem = UIBarButtonItem(title: "Cancel", style: .Plain, target: self, action: "performCancelWithSender:")
        self.navigationItem.leftBarButtonItem = buttonCancel
        
        self.addSignature()
    }
    
    func initPickerView() {
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
    
    //MARK: - TableViewDelegate
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.tableViewIsExpanded {
            return 6
        }
        return 4
    }
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        var offset = 0
        if self.tableViewIsExpanded {
            offset = 2
        }
        if indexPath.row == 3 + offset {
            return tableView.frame.height - (3 * 44 + self.navigationController!.navigationBar.frame.size.height + UIApplication.sharedApplication().statusBarFrame.size.height)
        }
        return 44
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0: // Cell for To
            var cell = tableView.dequeueReusableCellWithIdentifier("SendViewCellWithLabelAndTextField", forIndexPath: indexPath) as! SendViewCellWithLabelAndTextField
            cell.label.textColor = UIColor.grayColor()
            cell.label.text = "To:"
            cell.textField.textColor = UIColor.blackColor()
            cell.textField.tintColor = self.view.tintColor
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
            cell.textField.inputView = nil
            cell.textField.enabled = false
            
            var buttonOpenContacts: UIButton = UIButton.buttonWithType(UIButtonType.ContactAdd) as! UIButton
            buttonOpenContacts.frame = CGRectMake(0, 0, 20, 20)
			buttonOpenContacts.tag = 0
            buttonOpenContacts.addTarget(self, action: "openPeoplePickerWithSender:", forControlEvents: UIControlEvents.TouchUpInside)
            cell.accessoryView = buttonOpenContacts
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            return cell
        case 1:
            if self.tableViewIsExpanded { // Cell for CC
                var cell = tableView.dequeueReusableCellWithIdentifier("SendViewCellWithLabelAndTextField", forIndexPath: indexPath) as! SendViewCellWithLabelAndTextField
                cell.label.textColor = UIColor.grayColor()
                cell.label.text = "Cc:"
                cell.textField.textColor = UIColor.blackColor()
                cell.textField.tintColor = self.view.tintColor
                var ccRecipientsAsString: String = ""
                var count = 1
                for ccRecipient in self.ccRecipients {
                    ccRecipientsAsString = ccRecipientsAsString + (ccRecipient as! MCOAddress).mailbox
                    if count++ < self.ccRecipients.count {
                        ccRecipientsAsString = ccRecipientsAsString + ", "
                    }
                }
                cell.textField.textColor = UIColor.blackColor()
                cell.textField.text = ccRecipientsAsString
                cell.textField.tag = 1
                cell.textField.delegate = self
                cell.textField.inputView = nil
                cell.textField.enabled = false
                
                var buttonOpenContacts: UIButton = UIButton.buttonWithType(UIButtonType.ContactAdd) as! UIButton
                buttonOpenContacts.frame = CGRectMake(0, 0, 20, 20)
				buttonOpenContacts.tag = 1
                buttonOpenContacts.addTarget(self, action: "openPeoplePickerWithSender:", forControlEvents: UIControlEvents.TouchUpInside)
                cell.accessoryView = buttonOpenContacts
                cell.selectionStyle = UITableViewCellSelectionStyle.None
                return cell
            } else { // Cell for closed CC/BCC/From
                var cell = tableView.dequeueReusableCellWithIdentifier("SendViewCellWithLabelAndTextField", forIndexPath: indexPath) as! SendViewCellWithLabelAndTextField
                cell.label.textColor = UIColor.grayColor()
                cell.label.text = "Cc/Bcc, From:"
                cell.textField.textColor = UIColor.grayColor()
                cell.textField.tintColor = self.view.tintColor
                cell.textField.text = self.account.emailAddress
                cell.textField.tag = 5
                cell.textField.delegate = self
                cell.textField.enabled = false
                cell.accessoryView = nil
                cell.selectionStyle = UITableViewCellSelectionStyle.None
                return cell
            }
        case 2:
            if self.tableViewIsExpanded { // Cell for BCC
                var cell = tableView.dequeueReusableCellWithIdentifier("SendViewCellWithLabelAndTextField", forIndexPath: indexPath) as! SendViewCellWithLabelAndTextField
                cell.label.textColor = UIColor.grayColor()
                cell.label.text = "Bcc:"
                cell.textField.textColor = UIColor.blackColor()
                cell.textField.tintColor = self.view.tintColor
                var bccRecipientsAsString: String = ""
                var count = 1
                for bccRecipient in self.bccRecipients {
                    bccRecipientsAsString = bccRecipientsAsString + (bccRecipient as! MCOAddress).mailbox
                    if count++ < self.bccRecipients.count {
                        bccRecipientsAsString = bccRecipientsAsString + ", "
                    }
                }
                cell.textField.textColor = UIColor.blackColor()
                cell.textField.text = bccRecipientsAsString
                cell.textField.tag = 2
                cell.textField.delegate = self
                cell.textField.inputView = nil
                cell.textField.enabled = false
                
                var buttonOpenContacts: UIButton = UIButton.buttonWithType(UIButtonType.ContactAdd) as! UIButton
                buttonOpenContacts.frame = CGRectMake(0, 0, 20, 20)
				buttonOpenContacts.tag = 2
                buttonOpenContacts.addTarget(self, action: "openPeoplePickerWithSender:", forControlEvents: UIControlEvents.TouchUpInside)
                cell.accessoryView = buttonOpenContacts
                cell.selectionStyle = UITableViewCellSelectionStyle.None
                return cell
            } else { // Cell for Subject
                var cell = tableView.dequeueReusableCellWithIdentifier("SendViewCellWithLabelAndTextField", forIndexPath: indexPath) as! SendViewCellWithLabelAndTextField
                cell.label.textColor = UIColor.grayColor()
                cell.label.text = "Subject:"
                cell.textField.textColor = UIColor.blackColor()
                cell.textField.tintColor = self.view.tintColor
                cell.textField.text = self.subject
                cell.textField.tag = 6
                cell.textField.delegate = self
                cell.textField.inputView = nil
                cell.textField.addTarget(self, action: "updateSubjectAndTitleWithSender:", forControlEvents: UIControlEvents.EditingChanged)
                cell.textField.enabled = false
                cell.accessoryView = nil
                cell.selectionStyle = UITableViewCellSelectionStyle.None
                return cell
            }
        case 3:
            if self.tableViewIsExpanded { // Cell for From
                var cell = tableView.dequeueReusableCellWithIdentifier("SendViewCellWithLabelAndTextField", forIndexPath: indexPath) as! SendViewCellWithLabelAndTextField
                cell.label.textColor = UIColor.grayColor()
                cell.label.text = "From:"
                cell.textField.textColor = UIColor.blackColor()
                cell.textField.text = self.account.emailAddress
                cell.textField.tag = 3
                cell.textField.delegate = self
                cell.textField.tintColor = UIColor.whiteColor()
                cell.textField.inputView = self.emailAddressPicker
                cell.textField.addTarget(self, action: "togglePickerViewWithSender:", forControlEvents: UIControlEvents.TouchDown)
                cell.textField.enabled = false
                cell.accessoryView = nil
                cell.selectionStyle = UITableViewCellSelectionStyle.None
                return cell
            } else { // Cell for TextBody
                var cell = tableView.dequeueReusableCellWithIdentifier("SendViewCellWithTextView", forIndexPath: indexPath) as! SendViewCellWithTextView
                cell.textViewMailBody.textColor = UIColor.blackColor()
                cell.textViewMailBody.tintColor = self.view.tintColor
                cell.textViewMailBody.delegate = self
                cell.textViewMailBody.inputView = nil
                cell.textViewMailBody.tag = 8
                cell.textViewMailBody.userInteractionEnabled = false
                cell.textViewMailBody.text = self.textBody
                cell.selectionStyle = UITableViewCellSelectionStyle.None
                return cell
            }
        case 4: // Cell for Subject
            var cell = tableView.dequeueReusableCellWithIdentifier("SendViewCellWithLabelAndTextField", forIndexPath: indexPath) as! SendViewCellWithLabelAndTextField
            cell.label.textColor = UIColor.grayColor()
            cell.label.text = "Subject:"
            cell.textField.textColor = UIColor.blackColor()
            cell.textField.tintColor = self.view.tintColor
            cell.textField.text = self.subject
            cell.textField.tag = 4
            cell.textField.delegate = self
            cell.textField.inputView = nil
            cell.textField.addTarget(self, action: "updateSubjectAndTitleWithSender:", forControlEvents: UIControlEvents.EditingChanged)
            cell.textField.enabled = false
            cell.accessoryView = nil
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            return cell
        case 5: // Cell for TextBody
            var cell = tableView.dequeueReusableCellWithIdentifier("SendViewCellWithTextView", forIndexPath: indexPath) as! SendViewCellWithTextView
            cell.textViewMailBody.textColor = UIColor.blackColor()
            cell.textViewMailBody.tintColor = self.view.tintColor
            cell.textViewMailBody.delegate = self
            cell.textViewMailBody.inputView = nil
            cell.textViewMailBody.tag = 7
            cell.textViewMailBody.userInteractionEnabled = false
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
        case 0: // Cell for To
            if tableViewIsExpanded && self.shouldContractTableView() {
                tableViewIsExpanded = false
                tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
            }
            selectIndexPath = indexPath
        case 1: // Cell for CC
            if !tableViewIsExpanded {
                tableViewIsExpanded = true
                tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
            }
            selectIndexPath = indexPath
        case 2: // Cell for BCC or Subject
            selectIndexPath = indexPath
        case 3: // Cell for From or TextBody
            if tableViewIsExpanded {
                selectIndexPath = indexPath
            } else {
                if let responder: AnyObject = self.isResponder {
                    responder.resignFirstResponder()
                }
                var textView = (tableView.cellForRowAtIndexPath(indexPath) as! SendViewCellWithTextView).textViewMailBody
                textView.becomeFirstResponder()
            }
        case 4: // Cell for Subject
            if self.shouldContractTableView() {
                tableViewIsExpanded = false
                tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
                selectIndexPath = NSIndexPath(forRow: 2, inSection: 0)
            } else {
                selectIndexPath = indexPath
            }
        case 5: // Cell for TextBody
            if self.shouldContractTableView() {
                tableViewIsExpanded = false
                tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
                var textView = (tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 3, inSection: 0)) as! SendViewCellWithTextView).textViewMailBody
                if let responder: AnyObject = self.isResponder {
                    responder.resignFirstResponder()
                }
                textView.becomeFirstResponder()
            } else {
                var textView = (tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 5, inSection: 0)) as! SendViewCellWithTextView).textViewMailBody
                if let responder: AnyObject = self.isResponder {
                    responder.resignFirstResponder()
                }
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
    
    //MARK: - PickerViewDelegate
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
		var oldAccount = self.account
        self.account = self.allAccounts[row]
        (self.isResponder as! UITextField).text = self.account.emailAddress
		self.textBody = self.replaceSignatureWithText(self.textBody, toDelete: oldAccount.signature, toInsert: self.account.signature)
		(self.sendTableView.cellForRowAtIndexPath(NSIndexPath(forRow: 5, inSection: 0)) as! SendViewCellWithTextView).textViewMailBody.text = self.textBody
    }
    
    //MARK: - TextViewDelegate
    func textViewDidBeginEditing(textView: UITextView) {
        textView.userInteractionEnabled = true
        self.isResponder = textView
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        self.textBody = textView.text
        self.isResponder = nil
        textView.userInteractionEnabled = false
    }
    
    //MARK: - TextFieldDelegate
    func textFieldDidBeginEditing(textField: UITextField) {
        self.isResponder = textField
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
                if recipient != "" {
                    self.recipients.addObject(MCOAddress(mailbox: recipient))
                }
            }
            for recipient in self.recipients {
                NSLog("recipient: %@", recipient.mailbox)
            }
        case 1:
            self.ccRecipients.removeAllObjects()
            var ccRecipientsAsString = textField.text
            ccRecipientsAsString = ccRecipientsAsString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            for recipient in ccRecipientsAsString.componentsSeparatedByString(", ") {
                if recipient != "" {
                    self.ccRecipients.addObject(MCOAddress(mailbox: recipient))
                }
            }
        case 2:
            self.bccRecipients.removeAllObjects()
            var bccRecipientsAsString = textField.text
            bccRecipientsAsString = bccRecipientsAsString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            for recipient in bccRecipientsAsString.componentsSeparatedByString(", ") {
                if recipient != "" {
                    self.bccRecipients.addObject(MCOAddress(mailbox: recipient))
                }
            }
        default:
            break
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
   
    //MARK: - ActionSheetDelegate
    func actionSheet(actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) {
        switch buttonIndex {
        case 0:
            self.navigationController?.popViewControllerAnimated(true)
        case 2:
            //Move Email to drafts Folder
            let imapSession = MCOIMAPSession()
            imapSession.hostname = self.account.imapHostname
            imapSession.port = UInt32(self.account.imapPort.unsignedIntegerValue)
            imapSession.username = self.account.username
            
            let (dictionary, error) = Locksmith.loadDataForUserAccount(self.account.emailAddress)
            if error == nil {
                imapSession.password = dictionary?.valueForKey("Password:") as! String
            }
            
            imapSession.authType = StringToAuthType(self.account.authTypeImap)
            imapSession.connectionType = StringToConnectionType(self.account.connectionTypeImap)
            
            //get draftsFolderName
            let fetchFoldersOp = imapSession.fetchAllFoldersOperation()
            fetchFoldersOp.start({ (error, folders) -> Void in
                for folder in folders {
                    if ((folder as! MCOIMAPFolder).flags & MCOIMAPFolderFlag.Drafts) == MCOIMAPFolderFlag.Drafts {
                        var appendMsgOp = imapSession.appendMessageOperationWithFolder((folder as! MCOIMAPFolder).path, messageData: self.buildEmail(), flags: MCOMessageFlag.Seen|MCOMessageFlag.Draft)
                        appendMsgOp.start({ (error, uid) -> Void in
                            if error != nil {
                                NSLog("error in appenMsgOp")
                            } else {
                                NSLog("Draft saved")
                            }
                        })
                        break
                    }
                }
            })
            
            self.navigationController?.popViewControllerAnimated(true)
        default:
            break
        }
    }
    
    //MARK: - Supportive methods
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
    
    func updateSubjectAndTitleWithSender(sender: AnyObject) {
        var subject = (sender as! UITextField).text
        self.subject = subject
        if subject == "" {
            self.title = "New Message"
        } else {
            self.title = subject
        }
    }
    
    func togglePickerViewWithSender(sender: AnyObject) {
        if sender.isFirstResponder() {
            sender.resignFirstResponder()
        } else {
            sender.becomeFirstResponder()
        }
    }
    
    func performCancelWithSender(sender: AnyObject) {
        if let responder: AnyObject = self.isResponder {
            responder.resignFirstResponder()
        }
        var text = self.textBody
        text = self.replaceSignatureWithText(text, toDelete: self.account.signature, toInsert: "")
        if self.recipients.count != 0 || self.ccRecipients.count != 0 || self.bccRecipients.count != 0 || self.subject != "" || text != "\n" {
            var cancelActionSheet = UIActionSheet(title: nil, delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: "Delete Draft", otherButtonTitles: "Save Draft")
            cancelActionSheet.showInView(self.view)
        } else {
            self.navigationController?.popViewControllerAnimated(true)
        }
    }
    
    func addSignature() {
        if self.account.signature != "" {
            self.textBody = self.textBody + "\n" + self.account.signature
        }
        
    }
    
    func replaceSignatureWithText(text: String, toDelete: String, toInsert: String) -> String {
        if let range = text.rangeOfString(toDelete) {
            var newtext = text.substringToIndex(range.startIndex) + toInsert + text.substringFromIndex(range.endIndex)
            return newtext
        } else {
            return text + "\n" + toInsert
        }
    }
    
    //MARK: - Build and send E-Mail
    func buildEmail() -> NSData {
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
        
        return builder.data()
    }
    
    func sendEmailWithSender(sender: AnyObject) {
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
        
        var data = self.buildEmail()
        
        let sendOp = session.sendOperationWithData(data)
        sendOp.start({(error) in
            if error != nil {
                NSLog("%@", error.description)
            } else {
                NSLog("sent")
                
                //Move Email to sent Folder
                let imapSession = MCOIMAPSession()
                imapSession.hostname = self.account.imapHostname
                imapSession.port = UInt32(self.account.imapPort.unsignedIntegerValue)
                imapSession.username = self.account.username
                
                let (dictionary, error) = Locksmith.loadDataForUserAccount(self.account.emailAddress)
                if error == nil {
                    imapSession.password = dictionary?.valueForKey("Password:") as! String
                }
                
                imapSession.authType = StringToAuthType(self.account.authTypeImap)
                imapSession.connectionType = StringToConnectionType(self.account.connectionTypeImap)
                
                //get sentFolderName
                let fetchFoldersOp = imapSession.fetchAllFoldersOperation()
                fetchFoldersOp.start({ (error, folders) -> Void in
                    for folder in folders {
                        if ((folder as! MCOIMAPFolder).flags & MCOIMAPFolderFlag.SentMail) == MCOIMAPFolderFlag.SentMail {
                            //append Email to sent Folder
                            var appendMsgOp = imapSession.appendMessageOperationWithFolder((folder as! MCOIMAPFolder).path, messageData: data, flags: MCOMessageFlag.Seen)
                            appendMsgOp.start({ (error, uid) -> Void in
                                if error != nil {
                                    NSLog("error in appenMsgOp")
                                }
                            })
                            break
                        }
                    }
                })

                self.navigationController?.popViewControllerAnimated(true)
            }
        })
    }
    
    //MARK: - Methods to show/hide keyboard
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
    
    //MARK: - Methods to show Addressbook
    func openPeoplePickerWithSender(sender:AnyObject!) {
        let picker = ABPeoplePickerNavigationController()
        picker.peoplePickerDelegate = self
        picker.displayedProperties = [Int(kABPersonEmailProperty)]
        picker.predicateForSelectionOfPerson = NSPredicate(value:false)
        picker.predicateForSelectionOfProperty = NSPredicate(value:true)
		switch sender.tag {
		case 0: picker.title = "To:"
		case 1: picker.title = "Cc:"
		case 2: picker.title = "Bcc:"
		default: picker.title = ""
		}
        self.presentViewController(picker, animated:true, completion:nil)
    }

	func peoplePickerNavigationController(peoplePicker: ABPeoplePickerNavigationController!, didSelectPerson person: ABRecordRef!, property: ABPropertyID, identifier: ABMultiValueIdentifier) {
		println("person and property")
		let emails:ABMultiValue = ABRecordCopyValue(person, property).takeRetainedValue()
		let ix = ABMultiValueGetIndexForIdentifier(emails, identifier)
		let email = ABMultiValueCopyValueAtIndex(emails, ix).takeRetainedValue() as! String
		println(email)
		var address = MCOAddress(mailbox: email)
		
		switch peoplePicker.title! {
		case "To:": self.recipients.addObject(address)
		case "Cc:": self.ccRecipients.addObject(address)
		case "Bcc:": self.bccRecipients.addObject(address)
		default: break
		}
		
		self.sendTableView.reloadData()
	}
	
}
