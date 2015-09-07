import UIKit
import CoreData
import AddressBook
import Foundation
import AddressBookUI

class MailSendViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate, ABPeoplePickerNavigationControllerDelegate, UITextViewDelegate, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate, UIActionSheetDelegate {
    
    //MARK: - Variables
    @IBOutlet weak var sendTableView: UITableView!
    @IBOutlet weak var textViewTextBody: UITextView!
    @IBOutlet weak var scrollView: UIScrollView!
    var emailAddressPicker: UIPickerView!
    var attachmentView: AttachmentsViewController! = AttachmentsViewController(nibName: "AttachmentsViewController", bundle: nil)
    
    var initialTextViewHeight: CGFloat = 0
    var initialTableViewHeight: CGFloat = 0
    
    var tableViewIsExpanded: Bool = false
    var backspacePressed: Bool = false
    
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
        
        attachmentView.isSendAttachment = true
        
        self.textViewTextBody.delegate = self
        self.textViewTextBody.scrollEnabled = false
        self.textViewTextBody.text = self.textBody
        self.initialTextViewHeight = self.textViewTextBody.frame.size.height
        
        self.sendTableView.registerNib(UINib(nibName: "SendViewCellWithLabelAndTextField", bundle: nil), forCellReuseIdentifier: "SendViewCellWithLabelAndTextField")
        self.sendTableView.registerNib(UINib(nibName: "AttachmentViewCell", bundle: nil), forCellReuseIdentifier: "AttachmentViewCell")
        self.sendTableView.scrollEnabled = false
        for constraint in self.sendTableView.constraints() {
            let cons = constraint as! NSLayoutConstraint
            if cons.firstAttribute == NSLayoutAttribute.Height {
                self.initialTableViewHeight = cons.constant
                if !tableViewIsExpanded {
                    cons.constant = 180
                }
                break
            }
        }
        
        var buttonSend: UIBarButtonItem = UIBarButtonItem(title: "Send", style: .Plain, target: self, action: "sendEmailWithSender:")
        self.navigationItem.rightBarButtonItem = buttonSend
        var buttonCancel: UIBarButtonItem = UIBarButtonItem(title: "Cancel", style: .Plain, target: self, action: "performCancelWithSender:")
        self.navigationItem.leftBarButtonItem = buttonCancel
        
        self.addSignature()
    }
    
    override func viewDidAppear(animated: Bool) {
        if let fileName = (UIApplication.sharedApplication().delegate as! AppDelegate).fileName {
            if let data = (UIApplication.sharedApplication().delegate as! AppDelegate).fileData {
                self.attachFile(fileName, data: data, mimetype: fileName.pathExtension)
                (UIApplication.sharedApplication().delegate as! AppDelegate).fileName = nil
                (UIApplication.sharedApplication().delegate as! AppDelegate).fileData = nil
            }
        }
        self.sendTableView.reloadData()
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
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0: // Cell for To
            var cell = tableView.dequeueReusableCellWithIdentifier("SendViewCellWithLabelAndTextField", forIndexPath: indexPath) as! SendViewCellWithLabelAndTextField
            
            var recipientsAsString: String = ""
            var count = 1
            for recipient in self.recipients {
                NSLog("%@", (recipient as! MCOAddress).mailbox)
                recipientsAsString = recipientsAsString + (recipient as! MCOAddress).mailbox
                if count++ < self.recipients.count {
                    recipientsAsString = recipientsAsString + ", "
                }
            }
            
            var buttonOpenContacts: UIButton = UIButton.buttonWithType(UIButtonType.ContactAdd) as! UIButton
            buttonOpenContacts.frame = CGRectMake(0, 0, 20, 20)
            buttonOpenContacts.tag = 0
            buttonOpenContacts.addTarget(self, action: "openPeoplePickerWithSender:", forControlEvents: UIControlEvents.TouchUpInside)
            
            self.initSendViewCellWithLabelAndTextFieldWithCell(cell, labelColor: UIColor.grayColor(), labelText: "To:", textFieldTextColor: UIColor.blackColor(), textFieldTintColor: self.view.tintColor, textFieldText: recipientsAsString, textFieldTag: 0, textFieldDelegate: self, textFieldInputView: nil, cellAccessoryView: buttonOpenContacts)
            
            return cell
        case 1:
            if self.tableViewIsExpanded { // Cell for CC
                var cell = tableView.dequeueReusableCellWithIdentifier("SendViewCellWithLabelAndTextField", forIndexPath: indexPath) as! SendViewCellWithLabelAndTextField
                
                var ccRecipientsAsString: String = ""
                var count = 1
                for ccRecipient in self.ccRecipients {
                    ccRecipientsAsString = ccRecipientsAsString + (ccRecipient as! MCOAddress).mailbox
                    if count++ < self.ccRecipients.count {
                        ccRecipientsAsString = ccRecipientsAsString + ", "
                    }
                }
                
                var buttonOpenContacts: UIButton = UIButton.buttonWithType(UIButtonType.ContactAdd) as! UIButton
                buttonOpenContacts.frame = CGRectMake(0, 0, 20, 20)
                buttonOpenContacts.tag = 1
                buttonOpenContacts.addTarget(self, action: "openPeoplePickerWithSender:", forControlEvents: UIControlEvents.TouchUpInside)
                
                self.initSendViewCellWithLabelAndTextFieldWithCell(cell, labelColor: UIColor.grayColor(), labelText: "Cc:", textFieldTextColor: UIColor.blackColor(), textFieldTintColor: self.view.tintColor, textFieldText: ccRecipientsAsString, textFieldTag: 1, textFieldDelegate: self, textFieldInputView: nil, cellAccessoryView: buttonOpenContacts)
                
                return cell
            } else { // Cell for closed CC/BCC/From
                var cell = tableView.dequeueReusableCellWithIdentifier("SendViewCellWithLabelAndTextField", forIndexPath: indexPath) as! SendViewCellWithLabelAndTextField
                
                self.initSendViewCellWithLabelAndTextFieldWithCell(cell, labelColor: UIColor.grayColor(), labelText: "Cc/Bcc, From:", textFieldTextColor: UIColor.grayColor(), textFieldTintColor: self.view.tintColor, textFieldText: self.account.emailAddress, textFieldTag: 4, textFieldDelegate: self, textFieldInputView: nil, cellAccessoryView: nil)
                
                return cell
            }
        case 2:
            if self.tableViewIsExpanded { // Cell for BCC
                var cell = tableView.dequeueReusableCellWithIdentifier("SendViewCellWithLabelAndTextField", forIndexPath: indexPath) as! SendViewCellWithLabelAndTextField
                
                var bccRecipientsAsString: String = ""
                var count = 1
                for bccRecipient in self.bccRecipients {
                    bccRecipientsAsString = bccRecipientsAsString + (bccRecipient as! MCOAddress).mailbox
                    if count++ < self.bccRecipients.count {
                        bccRecipientsAsString = bccRecipientsAsString + ", "
                    }
                }
                
                var buttonOpenContacts: UIButton = UIButton.buttonWithType(UIButtonType.ContactAdd) as! UIButton
                buttonOpenContacts.frame = CGRectMake(0, 0, 20, 20)
                buttonOpenContacts.tag = 2
                buttonOpenContacts.addTarget(self, action: "openPeoplePickerWithSender:", forControlEvents: UIControlEvents.TouchUpInside)
                
                self.initSendViewCellWithLabelAndTextFieldWithCell(cell, labelColor: UIColor.grayColor(), labelText: "Bcc:", textFieldTextColor: UIColor.blackColor(), textFieldTintColor: self.view.tintColor, textFieldText: bccRecipientsAsString, textFieldTag: 2, textFieldDelegate: self, textFieldInputView: nil, cellAccessoryView: buttonOpenContacts)
                
                return cell
            } else { // Cell for Subject
                var cell = tableView.dequeueReusableCellWithIdentifier("SendViewCellWithLabelAndTextField", forIndexPath: indexPath) as! SendViewCellWithLabelAndTextField
                
                self.initSendViewCellWithLabelAndTextFieldWithCell(cell, labelColor: UIColor.grayColor(), labelText: "Subject:", textFieldTextColor: UIColor.blackColor(), textFieldTintColor: self.view.tintColor, textFieldText: self.subject, textFieldTag: 5, textFieldDelegate: self, textFieldInputView: nil, cellAccessoryView: nil)
                
                cell.textField.addTarget(self, action: "updateSubjectAndTitleWithSender:", forControlEvents: UIControlEvents.EditingChanged)
                
                return cell
            }
        case 3:
            if self.tableViewIsExpanded { // Cell for From
                var cell = tableView.dequeueReusableCellWithIdentifier("SendViewCellWithLabelAndTextField", forIndexPath: indexPath) as! SendViewCellWithLabelAndTextField
                
                self.initSendViewCellWithLabelAndTextFieldWithCell(cell, labelColor: UIColor.grayColor(), labelText: "From:", textFieldTextColor: UIColor.blackColor(), textFieldTintColor: UIColor.clearColor(), textFieldText: self.account.emailAddress, textFieldTag: 3, textFieldDelegate: self, textFieldInputView: self.emailAddressPicker, cellAccessoryView: nil)
                
                return cell
            } else { // Cell for attachments
                var cell = tableView.dequeueReusableCellWithIdentifier("AttachmentViewCell", forIndexPath: indexPath) as! AttachmentViewCell
                
                cell.imageViewPreview.image = UIImage(named: "attachment_icon@2x.png")!
                cell.imageViewPreview.image = UIImage(CGImage: cell.imageViewPreview.image!.CGImage, scale: 1, orientation: UIImageOrientation.Up)!
                cell.labelFilesAttached.text = "\t\(self.attachmentView.keys.count) files attached"
                cell.labelFilesAttached.textColor = UIColor.grayColor()
                
                cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
                cell.selectionStyle = UITableViewCellSelectionStyle.Default
                
                return cell
            }
            
        case 4: // Cell for Subject
            var cell = tableView.dequeueReusableCellWithIdentifier("SendViewCellWithLabelAndTextField", forIndexPath: indexPath) as! SendViewCellWithLabelAndTextField
            
            self.initSendViewCellWithLabelAndTextFieldWithCell(cell, labelColor: UIColor.grayColor(), labelText: "Subject:", textFieldTextColor: UIColor.blackColor(), textFieldTintColor: self.view.tintColor, textFieldText: self.subject, textFieldTag: 5, textFieldDelegate: self, textFieldInputView: nil, cellAccessoryView: nil)
            
            cell.textField.addTarget(self, action: "updateSubjectAndTitleWithSender:", forControlEvents: UIControlEvents.EditingChanged)
            
            return cell
        case 5: // Cell for attachments
            var cell = tableView.dequeueReusableCellWithIdentifier("AttachmentViewCell", forIndexPath: indexPath) as! AttachmentViewCell
            
            cell.imageViewPreview.image = UIImage(named: "attachedFile.png")!
            cell.imageViewPreview.image = UIImage(CGImage: cell.imageViewPreview.image!.CGImage, scale: 1, orientation: UIImageOrientation.Up)!
            cell.labelFilesAttached.text = "\t\(self.attachmentView.keys.count) files attached"
            cell.labelFilesAttached.textColor = UIColor.grayColor()
            
            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            cell.selectionStyle = UITableViewCellSelectionStyle.Default
            
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
                for constraint in tableView.constraints() {
                    let cons = constraint as! NSLayoutConstraint
                    if cons.firstAttribute == NSLayoutAttribute.Height {
                        cons.constant = 180
                        break
                    }
                }
                tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
            }
            selectIndexPath = indexPath
        case 1: // Cell for CC
            if !tableViewIsExpanded {
                tableViewIsExpanded = true
                for constraint in tableView.constraints() {
                    let cons = constraint as! NSLayoutConstraint
                    if cons.firstAttribute == NSLayoutAttribute.Height {
                        cons.constant = self.initialTableViewHeight
                        break
                    }
                }
                tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
            }
            selectIndexPath = indexPath
        case 2: // Cell for BCC or Subject
            selectIndexPath = indexPath
        case 3: // Cell for From or Attachments
            if self.tableViewIsExpanded {
                self.togglePickerViewWithSender((tableView.cellForRowAtIndexPath(indexPath) as! SendViewCellWithLabelAndTextField).textField)
            } else {
                tableView.deselectRowAtIndexPath(indexPath, animated: true)
                self.navigationController?.pushViewController(self.attachmentView, animated: true)
            }
        case 4: // Cell for Subject
            if self.shouldContractTableView() {
                tableViewIsExpanded = false
                for constraint in tableView.constraints() {
                    let cons = constraint as! NSLayoutConstraint
                    if cons.firstAttribute == NSLayoutAttribute.Height {
                        cons.constant = 180
                        break
                    }
                }
                tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
                selectIndexPath = NSIndexPath(forRow: 2, inSection: 0)
            } else {
                selectIndexPath = indexPath
            }
        case 5: // Cell for Attachments
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            self.navigationController?.pushViewController(self.attachmentView, animated: true)
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
        self.textViewTextBody.text = self.textBody
    }
    
    //MARK: - TextViewDelegate
    func textViewDidBeginEditing(textView: UITextView) {
        self.isResponder = textView
        if tableViewIsExpanded && self.shouldContractTableView() {
            tableViewIsExpanded = false
            for constraint in self.sendTableView.constraints() {
                let cons = constraint as! NSLayoutConstraint
                if cons.firstAttribute == NSLayoutAttribute.Height {
                    cons.constant = 180
                    break
                }
            }
            self.sendTableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
        }
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        self.textBody = textView.text
        self.isResponder = nil
    }
    
    func textViewDidChange(textView: UITextView) {
        // Resize the textView if needed
        let newSize = textView.sizeThatFits(CGSize(width: textView.frame.size.width, height: CGFloat.max))
        for constraint in textView.constraints() {
            let cons = constraint as! NSLayoutConstraint
            if cons.firstAttribute == NSLayoutAttribute.Height && newSize.height > cons.constant {
                cons.constant = newSize.height
                for scrollConstraint in self.scrollView.constraints() {
                    let scrollCons = scrollConstraint as! NSLayoutConstraint
                    if scrollCons.firstAttribute == NSLayoutAttribute.Height {
                        scrollCons.constant = self.sendTableView.frame.height + newSize.height + textView.font.lineHeight
                        break
                    }
                }
                break
            }
        }
    }
    
    //MARK: - TextFieldDelegate
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        if textField.tag == 3 {
            textField.userInteractionEnabled = false
        }
        return true
    }
    
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
        case 3:
            textField.userInteractionEnabled = true
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
            if actionSheet.tag == 1 {
                self.navigationController?.popViewControllerAnimated(true)
            }
        case 2:
            if actionSheet.tag == 1 {
                //Move Email to drafts Folder
                let imapSession = getSession(self.account)
                
                //get draftsFolderName
                if let folder = getFolderPathWithMCOIMAPFolderFlag(self.account, MCOIMAPFolderFlag.Drafts) {
                    var appendMsgOp = imapSession.appendMessageOperationWithFolder(folder, messageData: self.buildEmail(), flags: MCOMessageFlag.Seen|MCOMessageFlag.Draft)
                    appendMsgOp.start({ (error, uid) -> Void in
                        if error != nil {
                            NSLog("%@", error.description)
                        } else {
                            NSLog("Draft saved")
                        }
                    })
                }
                
                self.navigationController?.popViewControllerAnimated(true)
            }
        default:
            break
        }
    }
    
    //MARK: - Supportive methods
    func initSendViewCellWithLabelAndTextFieldWithCell(cell: SendViewCellWithLabelAndTextField, labelColor: UIColor, labelText: String, textFieldTextColor: UIColor, textFieldTintColor: UIColor, textFieldText: String, textFieldTag: Int, textFieldDelegate: UITextFieldDelegate, textFieldInputView: UIView?, cellAccessoryView: UIView?) {
        cell.label.textColor = labelColor
        cell.label.text = labelText
        cell.textField.textColor = textFieldTextColor
        cell.textField.tintColor = textFieldTintColor
        cell.textField.text = textFieldText
        cell.textField.tag = textFieldTag
        cell.textField.delegate = textFieldDelegate
        cell.textField.inputView = textFieldInputView
        cell.textField.enabled = false
        cell.accessoryView = cellAccessoryView
        cell.selectionStyle = UITableViewCellSelectionStyle.None
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
            (sender as! UITextField).enabled = true
            if let responder: AnyObject = self.isResponder {
                responder.resignFirstResponder()
            }
            sender.becomeFirstResponder()
        }
    }
    
    func performCancelWithSender(sender: AnyObject) {
        if let responder: AnyObject = self.isResponder {
            responder.resignFirstResponder()
        }
        var text = self.textBody
        text = self.replaceSignatureWithText(text, toDelete: self.account.signature, toInsert: "")
        if self.recipients.count != 0 || self.ccRecipients.count != 0 || self.bccRecipients.count != 0 || self.subject != "" || text != "\n" || self.attachmentView.keys.count > 0 {
            var cancelActionSheet = UIActionSheet(title: nil, delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: "Delete Draft", otherButtonTitles: "Save Draft")
            cancelActionSheet.tag = 1
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
    func attachFile(filename: String, data: NSData, mimetype: String) {
        self.attachmentView.attachFile(filename, data: data, mimetype: mimetype)
    }
    
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
        self.textBody = self.textBody.stringByReplacingOccurrencesOfString(String(Character(UnicodeScalar(NSAttachmentCharacter))), withString: " ", options: NSStringCompareOptions.LiteralSearch, range: nil)
        builder.textBody = self.textBody
        for (fileName, attachment) in self.attachmentView.attachments {
            NSLog("%@\n\n", fileName as! String)
            builder.addAttachment(MCOAttachment(data: attachment as! NSData, filename: fileName as! String))
        }
        
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
        
        let imapSession = getSession(self.account)
        let sendOp = session.sendOperationWithData(data)
        sendOp.start({(error) in
            if error != nil {
                NSLog("%@", error.description)
                var alert = UIAlertView(title: "Error", message: "Could not sent your message.", delegate: nil, cancelButtonTitle: "OK")
                alert.show()
                (sender as! UIBarButtonItem).enabled = true
            } else {
                NSLog("sent")
                
                //Move Email to sent Folder
                if let folder = getFolderPathWithMCOIMAPFolderFlag(self.account, MCOIMAPFolderFlag.SentMail) {
                    var appendMsgOp = imapSession.appendMessageOperationWithFolder(folder, messageData: data, flags: MCOMessageFlag.Seen)
                    appendMsgOp.start({ (error, uid) -> Void in
                        if error != nil {
                            NSLog("%@", error.description)
                        }
                    })
                }
                
                self.navigationController?.popViewControllerAnimated(true)
            }
        })
    }
    
    //MARK: - Methods to show/hide keyboard
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue().size {
            var contentInsets = UIEdgeInsetsMake(self.navigationController!.navigationBar.frame.size.height + UIApplication.sharedApplication().statusBarFrame.size.height, 0.0, keyboardSize.height, 0.0)
            
            self.scrollView.contentInset = contentInsets
            self.scrollView.contentInset.bottom = self.scrollView.contentInset.bottom + self.textViewTextBody.font.lineHeight
            self.scrollView.scrollIndicatorInsets = contentInsets
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue().size {
            var contentInsets = UIEdgeInsetsMake(self.navigationController!.navigationBar.frame.size.height + UIApplication.sharedApplication().statusBarFrame.size.height, 0.0, 0.0, 0.0)
            
            self.scrollView.contentInset = contentInsets
            self.scrollView.scrollIndicatorInsets = contentInsets
        }
    }
    
    //MARK: - Methods to show Addressbook
    func openPeoplePickerWithSender(sender:AnyObject!) {
        let picker = ABPeoplePickerNavigationController()
        picker.peoplePickerDelegate = self
        picker.displayedProperties = [Int(kABPersonEmailProperty)]
        picker.predicateForEnablingPerson = NSPredicate(format: "emailAddresses.@count > 0")
        picker.predicateForSelectionOfPerson = NSPredicate(value:false)
        picker.predicateForSelectionOfProperty = NSPredicate(value:true)
        switch (sender as! UIButton).tag {
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
