//
//  EmailViewController.swift
//  SMile
//
//  Created by Jan Weiß on 17.08.15.
//  Copyright (c) 2015 SMile. All rights reserved.
//

import UIKit
import CoreData
import Locksmith

class EmailViewController: UIViewController, EmailViewDelegate {

    var mcoimapmessage: MCOIMAPMessage!
    var message: Email!
    var session: MCOIMAPSession!
    var emailView: EmailView!
    var containerView: UIView!
    private let smileCrypto = SMileCrypto()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.whiteColor()
        var containerFrame = self.view.frame
        containerFrame.origin.y = self.navigationController!.navigationBar.frame.height + UIApplication.sharedApplication().statusBarFrame.height
        containerFrame.size.height = containerFrame.size.height - (self.navigationController!.navigationBar.frame.height + UIApplication.sharedApplication().statusBarFrame.height) - self.navigationController!.toolbar.frame.height
        self.containerView = UIView(frame: containerFrame)
        self.view.addSubview(self.containerView)
        self.view.bringSubviewToFront(self.containerView)
        
        self.emailView = EmailView(frame: CGRectMake(0, 0, self.containerView.frame.size.width, self.containerView.frame.size.height), message: self.mcoimapmessage, email: self.message)
        self.emailView.emailViewDelegate = self
        self.containerView.addSubview(self.emailView)
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setToolbarHidden(false, animated: false)
        let buttonDelete = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Trash, target: self, action: "delete")
        let buttonReply = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Reply, target: self, action: "replyButtonPressed")
        let buttonCompose = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Compose, target: self, action: "compose")
        let items = [buttonDelete, UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil), buttonReply,UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil), buttonCompose]
        self.navigationController?.visibleViewController!.setToolbarItems(items, animated: false)
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.navigationController?.setToolbarHidden(true, animated: false)
        super.viewWillDisappear(animated)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if let fileName = (UIApplication.sharedApplication().delegate as! AppDelegate).fileName {
            if let data = (UIApplication.sharedApplication().delegate as! AppDelegate).fileData {
                let sendView = MailSendViewController(nibName: "MailSendViewController", bundle: nil)
                var sendAccount: EmailAccount? = nil
                
                let accountName = NSUserDefaults.standardUserDefaults().stringForKey("standardAccount")
                let fetchRequest: NSFetchRequest = NSFetchRequest(entityName: "EmailAccount")
                var error: NSError?
                var result: [AnyObject]?
                do {
                    result = try managedObjectContext.executeFetchRequest(fetchRequest)
                } catch let error1 as NSError {
                    error = error1
                    result = nil
                }
                if error != nil {
                    NSLog("%@", error!.description)
                    return
                } else {
                    if let emailAccounts = result {
                        for account in emailAccounts {
                            if (account as! EmailAccount).accountName == accountName {
                                sendAccount = account as? EmailAccount
                                break
                            }
                        }
                        if sendAccount == nil {
                            sendAccount = emailAccounts.first as? EmailAccount
                        }
                    }
                }
                
                if let account = sendAccount {
                    sendView.account = account
                    sendView.attachFile(fileName, data: data, mimetype: getPathExtensionFromString(fileName)!)
                    
                    (UIApplication.sharedApplication().delegate as! AppDelegate).fileName = nil
                    (UIApplication.sharedApplication().delegate as! AppDelegate).fileData = nil
                    
                    self.navigationController?.pushViewController(sendView, animated: true)
                }
            }
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - UIBarButtonActions
    
    func delete() {
        for var i = 0; i < self.navigationController?.viewControllers.count; i++ {
            if self.navigationController?.viewControllers[i] is MailTableViewController {
                let mailTableVC: MailTableViewController = self.navigationController?.viewControllers[i] as! MailTableViewController
                mailTableVC.deleteEmail(self.message)
            }
        }
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func replyButtonPressed() {
        let replyActionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        let replyAction = UIAlertAction(title: "Reply", style: .Default) { (action) -> Void in
            self.reply(false)
        }
        replyActionSheet.addAction(replyAction)
        
        if (self.message.mcomessage as! MCOIMAPMessage).header.cc != nil &&
            (self.message.mcomessage as! MCOIMAPMessage).header.bcc != nil {
                let replyAllAction = UIAlertAction(title: "Reply all", style: .Default, handler: { (action) -> Void in
                    self.reply(true)
                })
                replyActionSheet.addAction(replyAllAction)
        }
        
        let forwardAction = UIAlertAction(title: "Forward", style: .Default) { (action) -> Void in
            self.forward()
        }
        replyActionSheet.addAction(forwardAction)
        self.presentViewController(replyActionSheet, animated: true, completion: nil)
    }
    
    func reply(replyAll: Bool) {
        let sendView = MailSendViewController(nibName: "MailSendViewController", bundle: nil)
        if replyAll {
            sendView.tableViewIsExpanded = true
            var array: [MCOAddress] = [MCOAddress]()
            let recipients = (self.message.mcomessage as! MCOIMAPMessage).header.to
            for recipient in recipients {
                if (recipient as! MCOAddress).mailbox != self.message.toAccount.emailAddress {
                    array.append(recipient as! MCOAddress)
                }
            }
            let ccRecipients = (self.message.mcomessage as! MCOIMAPMessage).header.cc
            if ccRecipients != nil {
                for ccRecipient in ccRecipients {
                    array.append(ccRecipient as! MCOAddress)
                }
            }
            if array.count == 0 {
                sendView.tableViewIsExpanded = false
            } else {
                sendView.ccRecipients.addObjectsFromArray(array)
            }
        }
        sendView.recipients.addObject((self.message.mcomessage as! MCOIMAPMessage).header.from)
        sendView.account = self.message.toAccount
        sendView.subject = "Re: " + (self.message.mcomessage as! MCOIMAPMessage).header.subject
        
        let msgContent: String = (self.emailView.plainHTMLContent as NSString).mco_flattenHTML().stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) as String
        let date = (self.message.mcomessage as! MCOIMAPMessage).header.date
        sendView.textBody = "\n\n\n\n\nOn \(date.day()) \(date.month()) \(date.year()), at \(date.hour()):\(date.minute()), " + (self.message.mcomessage as! MCOIMAPMessage).header.from.displayName + " wrote:\n\n" + msgContent
        self.navigationController?.pushViewController(sendView, animated: true)
    }
    
    func forward() {
        let sendView = MailSendViewController(nibName: "MailSendViewController", bundle: nil)
        sendView.account = self.message.toAccount
        sendView.subject = "Fwd: " + (self.message.mcomessage as! MCOIMAPMessage).header.subject
        let msgContent: String = (self.emailView.plainHTMLContent as NSString).mco_flattenHTML().stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) as String
        sendView.textBody = "\n\n\n\n\nBegin forwarded message:\n\n" + msgContent
        self.navigationController?.pushViewController(sendView, animated: true)
    }
    
    func compose() {
        let sendView = MailSendViewController(nibName: "MailSendViewController", bundle: nil)
        sendView.account = self.message.toAccount
        self.navigationController?.pushViewController(sendView, animated: true)
    }
    
    //MARK: - EmailViewDelegate
    
    func presentAttachmentVC(attachmentVC: AttachmentsViewController) {
        self.navigationController?.pushViewController(attachmentVC, animated: true)
    }
    
    func handleMailtoWithRecipients(recipients: [String], andSubject subject: String, andHTMLString html: String) {
        let mailSendVC: MailSendViewController = MailSendViewController(nibName: "MailSendViewController", bundle: NSBundle.mainBundle())
        let recipientAddressArr = NSMutableArray()
        for recipient in recipients {
            recipientAddressArr.addObject(MCOAddress(mailbox: recipient))
        }
        mailSendVC.recipients = recipientAddressArr
        mailSendVC.account = self.message.toAccount
        
        //For Reply with only plain text
        let msgContent: String = (self.emailView.plainHTMLContent as NSString).mco_flattenHTML().stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) as String
        mailSendVC.textBody = msgContent
        
        self.navigationController?.pushViewController(mailSendVC, animated: true)
    }
    
    func askPassphraseForKey(key: Key) -> String? {
        var passphrase: String?
        var inputTextField: UITextField?
        let passphrasePrompt = UIAlertController(title: "Enter Passphrase", message: "Please enter the passphrase for key: \(key.keyID)", preferredStyle: .Alert)
        
        passphrasePrompt.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        passphrasePrompt.addAction(UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
            if inputTextField!.text != nil {
                passphrase = inputTextField!.text
            }
        }))
        
        passphrasePrompt.addAction(UIAlertAction(title: "OK and Save Passphrase", style: .Default, handler: {(action) -> Void in
            if inputTextField!.text != nil {
                passphrase = inputTextField!.text
            }
            do {
                try Locksmith.deleteDataForUserAccount(key.keyID)
            } catch _ {}
            do {
                try Locksmith.saveData(["PassPhrase": passphrase!], forUserAccount: key.keyID)
            } catch let error as NSError {
                NSLog("Locksmith: \(error.localizedDescription)")
            }
        }))
        
        passphrasePrompt.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
            textField.placeholder = "Passphrase"
            textField.secureTextEntry = true
            inputTextField = textField
        })
        presentViewController(passphrasePrompt, animated: true, completion: nil)
        
        return passphrase
    }
    
    func getUImageFromFilename(filename: String) -> UIImage? {
        var fileimage: UIImage?
        switch filename {
        case let s where s.rangeOfString(".asc") != nil:
            fileimage = UIImage(named: "keyicon.png")
            // add more cases for different document types
        case let s where s.rangeOfString(".gpg") != nil:
            fileimage = UIImage(named: "fileicon_lock.png")
        default:
            fileimage = UIImage(named: "fileicon_standard.png")
        }
        return fileimage
        
    }
    
    func presentInformationAlertController(alertController: UIAlertController) {
        self.presentViewController(alertController, animated: true, completion: nil)
    }

}
