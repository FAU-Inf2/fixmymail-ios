//
//  EmailViewController.swift
//  SMile
//
//  Created by Jan Weiß on 17.08.15.
//  Copyright (c) 2015 SMile. All rights reserved.
//

import UIKit
import CoreData

class EmailViewController: UIViewController, EmailViewDelegate, UIActionSheetDelegate {

    var mcoimapmessage: MCOIMAPMessage!
    var message: Email!
    var session: MCOIMAPSession!
    var emailView: EmailView!
    var containerView: UIView!
    
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
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setToolbarHidden(false, animated: false)
        var buttonDelete = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Trash, target: self, action: "delete")
        var buttonReply = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Reply, target: self, action: "replyButtonPressed")
        var buttonCompose = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Compose, target: self, action: "compose")
        var items = [buttonDelete, UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil), buttonReply,UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil), buttonCompose]
        self.navigationController?.visibleViewController.setToolbarItems(items, animated: false)
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.navigationController?.setToolbarHidden(true, animated: false)
        super.viewWillDisappear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - UIBarButtonActions
    
    func delete() {
        //get trashFolderName
        let fetchFoldersOp = session.fetchAllFoldersOperation()
        var folders = [MCOIMAPFolder]()
        fetchFoldersOp.start({ (error, folders) -> Void in
            var trashFolderName: String?
            for folder in folders {
                if ((folder as! MCOIMAPFolder).flags & MCOIMAPFolderFlag.Trash) == MCOIMAPFolderFlag.Trash {
                    trashFolderName = (folder as! MCOIMAPFolder).path
                    //NSLog("found it" + self.trashFolderName!)
                    break
                }
            }
            if trashFolderName != nil {
                //copy email to trash folder
                let localCopyMessageOperation = self.session.copyMessagesOperationWithFolder("INBOX", uids: MCOIndexSet(index: UInt64((self.message.mcomessage as! MCOIMAPMessage).uid)), destFolder: trashFolderName)
                
                localCopyMessageOperation.start {(error, uidMapping) -> Void in
                    if let error = error {
                        NSLog("error in deleting email : \(error.userInfo!)")
                    }
                }
                
                //set deleteFlag
                let setDeleteFlagOP = self.session.storeFlagsOperationWithFolder("INBOX", uids: MCOIndexSet(index: UInt64((self.message.mcomessage as! MCOIMAPMessage).uid)), kind: MCOIMAPStoreFlagsRequestKind.Add, flags: MCOMessageFlag.Deleted)
                
                setDeleteFlagOP.start({ (error) -> Void in
                    if let error = error {
                        NSLog("error in deleting email (flags) : \(error.userInfo)")
                    } else {
                        NSLog("email deleted")
                        
                        let expangeFolder = self.session.expungeOperation("INBOX")
                        expangeFolder.start({ (error) -> Void in })
                    }
                })
                
                var managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext as NSManagedObjectContext!
                managedObjectContext.deleteObject(self.message)
                
                var error: NSError? = nil
                managedObjectContext.save(&error)
                if error != nil {
                    NSLog("%@", error!.description)
                }
            } else {
                NSLog("error: trashFolderName == nil")
            }
        })
        
        for var i = 0; i < self.navigationController?.viewControllers.count; i++ {
            if self.navigationController?.viewControllers[i] is MailTableViewController {
                var mailTableVC: MailTableViewController = self.navigationController?.viewControllers[i] as! MailTableViewController
                mailTableVC.emailToDelete = self.message
            }
        }
        self.navigationController?.popViewControllerAnimated(true)
    }

    func actionSheet(actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) {
        var replyAll: Bool = !((self.message.mcomessage as! MCOIMAPMessage).header.cc == nil &&
            (self.message.mcomessage as! MCOIMAPMessage).header.bcc == nil)
        switch buttonIndex {
        case 1:
            self.reply(false)
        case 2:
            if replyAll {
                self.reply(true)
            } else {
                self.forward()
            }
        case 3:
            if replyAll {
                self.forward()
            }
        default:
            return
        }
    }
    
    func replyButtonPressed() {
        if (self.message.mcomessage as! MCOIMAPMessage).header.cc == nil &&
            (self.message.mcomessage as! MCOIMAPMessage).header.bcc == nil {
                var replyActionSheet = UIActionSheet(title: nil, delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil, otherButtonTitles: "Reply", "Forward")
                replyActionSheet.showInView(self.view)
        } else {
            var replyActionSheet = UIActionSheet(title: nil, delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil, otherButtonTitles: "Reply", "Reply all", "Forward")
            replyActionSheet.showInView(self.view)
        }
    }
    
    func reply(replyAll: Bool) {
        var sendView = MailSendViewController(nibName: "MailSendViewController", bundle: nil)
        if replyAll {
            sendView.tableViewIsExpanded = true
            var array: [MCOAddress] = [MCOAddress]()
            var recipients = (self.message.mcomessage as! MCOIMAPMessage).header.to
            for recipient in recipients {
                if (recipient as! MCOAddress).mailbox != self.message.toAccount.emailAddress {
                    array.append(recipient as! MCOAddress)
                }
            }
            var ccRecipients = (self.message.mcomessage as! MCOIMAPMessage).header.cc
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
        var date = (self.message.mcomessage as! MCOIMAPMessage).header.date
        sendView.textBody = "\n\n\n\n\nOn \(date.day()) \(date.month()) \(date.year()), at \(date.hour()):\(date.minute()), " + (self.message.mcomessage as! MCOIMAPMessage).header.from.displayName + " wrote:\n\n" + msgContent
        self.navigationController?.pushViewController(sendView, animated: true)
    }
    
    func forward() {
        var sendView = MailSendViewController(nibName: "MailSendViewController", bundle: nil)
        sendView.account = self.message.toAccount
        sendView.subject = "Fwd: " + (self.message.mcomessage as! MCOIMAPMessage).header.subject
        var parser = MCOMessageParser(data: self.message.data)
        let msgContent: String = (self.emailView.plainHTMLContent as NSString).mco_flattenHTML().stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) as String
        sendView.textBody = "\n\n\n\n\nBegin forwarded message:\n\n" + msgContent
        self.navigationController?.pushViewController(sendView, animated: true)
    }
    
    func compose() {
        var sendView = MailSendViewController(nibName: "MailSendViewController", bundle: nil)
        sendView.account = self.message.toAccount
        self.navigationController?.pushViewController(sendView, animated: true)
    }
    
    //MARK: - EmailViewDelegate
    
    func handleMailtoWithRecipients(recipients: [String], andSubject subject: String, andHTMLString html: String) {
        let mailSendVC: MailSendViewController = MailSendViewController(nibName: "MailSendViewController", bundle: NSBundle.mainBundle())
        var recipientAddressArr = NSMutableArray()
        for recipient in recipients {
            recipientAddressArr.addObject(MCOAddress(mailbox: recipient))
        }
        mailSendVC.recipients = recipientAddressArr
        mailSendVC.account = self.message.toAccount
        
        let parser = MCOMessageParser(data: self.message.data)
        var error: NSError?
        //For Reply with only plain text
        let msgContent: String = (self.emailView.plainHTMLContent as NSString).mco_flattenHTML().stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) as String
        mailSendVC.textBody = msgContent
//        var attString = self.convertText(self.emailView.plainHTMLContent)
//        var attributedString = NSMutableAttributedString(data: self.emailView.plainHTMLContent.dataUsingEncoding(NSUTF8StringEncoding)!, options: [NSDocumentTypeDocumentAttribute : NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: NSNumber(unsignedLong: NSUTF8StringEncoding)], documentAttributes: nil, error: &error)
//        if error != nil {
//            println("Error: \(error!), UserInfo: \(error!.userInfo)")
//        } else {
//            mailSendVC.textViewTextBody.attributedText = attributedString
//        }
        
        self.navigationController?.pushViewController(mailSendVC, animated: true)
    }
    
//    private func convertText(inputText: String) -> NSAttributedString? {
//        
//        var html = inputText
//        
//        // Replace newline character by HTML line break
//        while let range = html.rangeOfString("\n") {
//            html.replaceRange(range, with: "")
//        }
//        
//        while let range = html.rangeOfString("\"") {
//            html.replaceRange(range, with: "'")
//        }
//        
//        html = "" +
//        "<html lang=\"en\" xml:lang='en' xmlns='http://www.w3.org/1999/xhtml'>"  +
//        "<head>" +
//        "<title>Your Comodo FREE Personal Email Certificate</title>" +
//        "<meta http-equiv='Content-Type' content=" +
//        "'text/html; charset=utf-8' />" +
//        "<style type='text/css'>" +
//        "/*<![CDATA[*/" +
//        "html, body{background: #73899F;color: #000000;font-family: freewayroman, arial, sans-serif;}" +
//        "td, th{color: #000000;}" +
//        ".main p{padding: 0px;margin: 0px; font-size: 12px;}" +
//        ".main ul li{padding: 0px;margin: 0px; font-size: 11px;}" +
//        ".main a{text-decoration: underline; color:#000000;}" +
//        ".main a:hover{ color:#ff0000; text-decoration:none;}" +
//        ".phone {color:#FFFFFF; font-size:11px; line-height:18px; text-align:right;}" +
//        ".footer p{color:#FFFFFF; font-size: 11px;}" +
//        "a{color: #ffffff;}" +
//        "a:hover{text-decoration:none;}" +
//        "a.link{color: #ffffff;}" +
//        "a.link:hover{text-decoration:none;}" +
//        "p a:hover{text-decoration:none;}" +
//        "p a.link{color: #000000;}" +
//        "p a.link:hover{text-decoration:none;}" +
//        "h1{margin:0px;}" +
//        "h2{color:#FFFFFF; font-weight:normal;}" +
//        ".thankyou p{font-family: freewayroman, arial, sans-serif; font-weight:normal; padding-top:5px; font-size: 12px;}" +
//        ".thankyou h1{font-family: freewayroman, arial, sans-serif; font-weight:bold; color:red;padding-top:5px; font-size: 14px;}" +
//        ".thankyou strong{color:red;}" +
//        ".thankyou a{text-decoration:underline;}" +
//        ".thankyou a:hover{text-decoration:underline;}" +
//        ".thankyou {border:1px solid #cccccc;padding:10px;margin-bottom:20px;margin-top:20px;" +
//        "width:425px;" +
//        "}" +
//        "/*]]>*/" +
//        "</style>" +
//        "</head>" +
//        "<body style=" +
//        "'background:#73899F;color: #424242;font-family: freewayroman, arial, sans-serif;'>" +
//        "<div style=" +
//        "'background:#73899F;color: #424242; text-align:center;font-family: freewayroman, arial, sans-serif;font-size: 11px;'>" +
//        "<table border='0' cellpadding='0' cellspacing='0' bgcolor='#FFFFFF'" +
//        "style=" +
//        "'width: 680px; text-align:left; margin-left: auto; margin-right: auto; margin-top:10px; margin-bottom:10px; font-size:11px;'>" +
//        "<tbody>" +
//        "<tr>" +
//        "<th width='680' height='30' colspan='3' valign='top'>" +
//        "<table width='100%' border='0' cellspacing='0' cellpadding='0'>" +
//        "<tr>" +
//        "<td><img src='cid:hgtrialtopleft.gif@comodo.com' width='10' height=" +
//        "'10' /></td>" +
//        "<td width='99%' align='right'><img src=" +
//        "'cid:hgtrialtoprght.gif@comodo.com' width='10' height='10' /></td>" +
//        "</tr>" +
//        "</table>" +
//        "</th>" +
//        "</tr>" +
//        "<tr>" +
//        "<th colspan='3' valign='top'>" +
//        "<table width='94%' border='0' align='center' cellpadding='0'" +
//        "cellspacing='0'>" +
//        "<tr>" +
//        "<td width='73%' align='left' valign='top'><a href=" +
//        "'http://www.comodogroup.com'><img src=" +
//        "'cid:grayClogo.jpg@comodo.com' alt='COMODO' border='0' longdesc=" +
//        "'http://www.comodogroup.com' /></a></td>" +
//        "<td width='27%' align='right' valign='top'>" +
//        "<p style='font-size:12px; line-height:18px; text-align:right;'>" +
//        "<font color='#999999'>Tel Sales :</font> <strong>+1 888 266" +
//        "6361</strong><br />" +
//        "<font color='#999999'>Fax Sales :</font>" +
//        "<strong>+1.201.963.9003</strong></p>" +
//        "</td>" +
//        "</tr>" +
//        "<tr>" +
//        "<td height='40' colspan='2' align='left' valign='bottom'></td>" +
//        "</tr>" +
//        "</table>" +
//        "</th>" +
//        "</tr>" +
//        "<tr>" +
//        "<th colspan='3' align='center' valign='top' class='footer'>" +
//        "<table width='94%' border='0' align='center' cellpadding='0'" +
//        "cellspacing='0'>" +
//        "<tr>"
//        "<td width='73%' align='left' valign='middle'>" +
//        "<h2 style=" +
//        "' font-family: freewayroman, arial, sans-serif; color:#FF0000;font-size: 32px;margin:0px; font-weight:normal;'>" +
//        "Your Comodo FREE<br />" +
//        "Personal Email Certificate<br />" +
//        "is now ready for collection!</h2>" +
//        "    </td>" +
//        "    <td width='27%' align='right' valign='top'><a href=" +
//        "    'http://www.comodogroup.com'><img src=" +
//        "    'cid:FreeCrt-img01.jpg@comodo.com' alt=" +
//        "    'COMODO | Free eMail Certificate' border='0' /></a></td>" +
//        "    </tr>" +
//        "    </table>" +
//        "    </th>" +
//        "    </tr>" +
//        "    <tr>" +
//        "    <th colspan='3' bgcolor='#FFFFFF'>" +
//        "    <table width='100%' border='0' cellpadding='20'>" +
//        "    <tr>" +
//        "    <td align='left' valign='top'>" +
//        "    <table width='100%' border='0' cellpadding='0' cellspacing='0'" +
//        "    class='main'>" +
//        "    <tr>" +
//        "    <td align='left' valign='top'>" +
//        "    <p style=" +
//        "    'font-family: freewayroman, arial, sans-serif; font-weight:normal; font-size: 12px;line-height:18px;'>" +
//        "    Dear Richard Mayhew,<br />" +
//        "    <br />" +
//        "    <font style=" +
//        "    'font-weight:bold; font-size:13px;'>Congratulations</font> - your" +
//        "    Comodo FREE Personal Secure Email Certificate is now ready for" +
//        "        collection! You are almost able to send secure email!</p>" +
//        "        <p style=" +
//        "        'font-family: freewayroman, arial, sans-serif; font-weight:normal; padding-top:15px; font-size: 12px;line-height:18px;'>" +
//        "        Simply click on the button below to collect your certificate.</p>" +
//        "        <a href=" +
//        "        'https://secure.comodo.com/products/!SecureEmailCertificate_Collec2?apID=1&amp;emailAddress=fixmymail@t-online.de&amp;collectionPassword=9j34Tedq4TPWEfOt'><img src='cid:FreeCrt-clickbtn.jpg@comodo.com'" +
//        "        alt='Click to Install Comodo Email Certificate' vspace='10' border=" +
//        "        '0' /></a>" +
//        "        <p style=" +
//        "        'font-family: freewayroman, arial, sans-serif; font-weight:normal; padding-top:5px; font-size: 12px;color: #000000;'>" +
//        "        <strong>Note:-</strong> If the above button does not work, please" +
//        "        navigate to <a href=" +
//        "        'https://secure.comodo.com/products/!SecureEmailCertificate_Collec2'>" +
//        "        https://secure.comodo.com/products/!SecureEmailCertificate_Collec2</a>" +
//        "        Enter your email address and the Collection Password which is:" +
//        "        9j34Tedq4TPWEfOt</p>" +
//        "        <p style=" +
//        "        'font-family: freewayroman, arial, sans-serif; font-weight:normal; padding-top:15px; font-size: 12px;line-height:18px;'>" +
//        "        Your Comodo FREE Personal Secure Email Certificate will then be" +
//        "        automatically placed into the Certificate store on your" +
//        "        computer.</p>" +
//        "        <p style=" +
//        "        'font-family: freewayroman, arial, sans-serif; font-weight:normal; color:#003399; padding-top:15px; font-size: 12px;line-height:18px;'>" +
//        "        Click ''Yes'' if you see a 'Potential Scripting Violation' window" +
//        "            asking 'Do you want this Program to add Certificates now?'</p>" +
//        "            <p style=" +
//        "            'font-family: freewayroman, arial, sans-serif; font-weight:normal; padding-top:15px; font-size: 12px;line-height:18px;color: #000000;'>" +
//        "            Please visit <a href=" +
//        "            'http://www.comodogroup.com/support/products/email_certs/index.html'>" +
//        "            http://www.comodogroup.com/support/products/email_certs/index.html</a>" +
//        "            for guidance on configuring your email client to use your" +
//        "                certificate to secure email.</p>" +
//        "                <p style=" +
//        "                'font-family: freewayroman, arial, sans-serif; font-weight:normal; padding-top:15px; font-size: 12px;color: #000000;'>" +
//        "                <strong>Note:-</strong> We strongly recommend that you export your" +
//        "                certificate to a safe place in case you need to reload it later." +
//        "                For details, please see <a href=" +
//        "                'http://www.instantssl.com/ssl-certificate-support/server_faq/ssl-email-certificate-faq.html'" +
//        "                target=" +
//        "                '_blank'>http://www.instantssl.com/ssl-certificate-support/server_faq/ssl-email-certificate-faq.html</a>.</p>" +
//        "                <p style=" +
//        "                'font-family: freewayroman, arial, sans-serif; font-weight:normal; padding-top:15px; font-size: 12px;line-height:18px;'>" +
//        "                You can revoke your certificate by clicking on the button" +
//        "                below.</p>" +
//        "                <a href=" +
//        "                'https://secure.comodo.com/products/!SecureEmailCertificate_Revoke'><img src='cid:Revoke.gif@comodo.com'" +
//        "                alt='Click to Revoke Comodo Email Certificate' vspace='10' border=" +
//        "                '0' /></a>" +
//        "                <div class='thankyou' style='display: none'>" +
//        "                <p align='center'><strong>And as a special thank" +
//        "                you,</strong><span lang='EN-GB' xml:lang='EN-GB'></span></p>" +
//        "                <p align='center'><strong>We are pleased to offer our <a title=" +
//        "                'http://www.secure-email.comodo.com/?utm_source=free%2Bcert%2Bemail&amp;utm_medium=free%2Bcert%2Bemail&amp;utm_campaign=free%2Bcert%2Bemail'" +
//        "                href=" +
//        "                'http://www.secure-email.comodo.com/?utm_source=free+cert+email&amp;utm_medium=free+cert+email&amp;utm_campaign=free+cert+email'>" +
//        "                <span title=" +
//        "                'http://www.secure-email.comodo.com/?utm_source=free%2Bcert%2Bemail&amp;utm_medium=free%2Bcert%2Bemail&amp;utm_campaign=free%2Bcert%2Bemail'>" +
//        "                install and forget solution for securing your e-mails</span></a>" +
//        "                    for your use for</strong> <a title=" +
//        "                        'http://www.secure-email.comodo.com/?utm_source=free+cert+email&amp;utm_medium=free+cert+email&amp;utm_campaign=free+cert+email/'" +
//        "                        href=" +
//        "                        'http://www.secure-email.comodo.com/?utm_source=free+cert+email&amp;utm_medium=free+cert+email&amp;utm_campaign=free+cert+email'>" +
//        "                        <strong title=" +
//        "                        'http://www.secure-email.comodo.com/?utm_source=free+cert+email&amp;utm_medium=free+cert+email&amp;utm_campaign=free+cert+email'>" +
//        "                        </strong><span title=" +
//        "                        'http://www.secure-email.comodo.com/?utm_source=free+cert+email&amp;utm_medium=free+cert+email&amp;utm_campaign=free+cert+email/'>FREE</span></a>.<span lang='EN-GB'" +
//        "                        xml:lang='EN-GB'></span></p>" +
//        "                        <p><strong><a title=" +
//        "                        'http://www.secure-email.comodo.com/?utm_source=free+cert+email&amp;utm_medium=free+cert+email&amp;utm_campaign=free+cert+email/'" +
//        "                        href=" +
//        "                        'http://www.secure-email.comodo.com/?utm_source=free+cert+email&amp;utm_medium=free+cert+email&amp;utm_campaign=free+cert+email'>" +
//        "                        <span title=" +
//        "                        'http://www.secure-email.comodo.com/?utm_source=free+cert+email&amp;utm_medium=free+cert+email&amp;utm_campaign=free+cert+email/'>" +
//        "                        So what are you getting?</span></a></strong><span lang='EN-GB'" +
//        "                        xml:lang='EN-GB'></span></p>" +
//        "                        <ul>" +
//        "                        <li>Encrypt to anyone, anytime – without having their certificate" +
//        "                        installed – using patent-pending one-time certificate issuance –" +
//        "                        <a href=" +
//        "                        'http://www.secure-email.comodo.com/?utm_source=free+cert+email&amp;utm_medium=free+cert+email&amp;utm_campaign=free+cert+email'>" +
//        "                        <span title=" +
//        "                        'http://www.secure-email.comodo.com/?utm_source=free%2Bcert%2Bemail&amp;utm_medium=free%2Bcert%2Bemail&amp;utm_campaign=free%2Bcert%2Bemail'>" +
//        "                        <strong>Download it now</strong></span> <strong>for" +
//        "                            FREE</strong></a><span class='style1'><a href=" +
//        "                            'http://www.secure-email.comodo.com/?utm_source=free%2Bcert%2Bemail&amp;utm_medium=free%2Bcert%2Bemail&amp;utm_campaign=free%2Bcert%2Bemail'></a></span></li>" +
//        "                            <li>Skip the hassle of dealing with management of certificates –" +
//        "                            <a href=" +
//        "                            'http://www.secure-email.comodo.com/?utm_source=free+cert+email&amp;utm_medium=free+cert+email&amp;utm_campaign=free+cert+email'>" +
//        "                            <span title=" +
//        "                            'http://www.secure-email.comodo.com/?utm_source=free%2Bcert%2Bemail&amp;utm_medium=free%2Bcert%2Bemail&amp;utm_campaign=free%2Bcert%2Bemail'>" +
//        "                            <strong>Download it now</strong></span> <strong>for" +
//        "                                FREE</strong></a></li>" +
//        "                                <li>Automatic certificate update and renewal – <a href=" +
//        "                                'http://www.secure-email.comodo.com/?utm_source=free+cert+email&amp;utm_medium=free+cert+email&amp;utm_campaign=free+cert+email'>" +
//        "                                <span title=" +
//        "                                'http://www.secure-email.comodo.com/?utm_source=free%2Bcert%2Bemail&amp;utm_medium=free%2Bcert%2Bemail&amp;utm_campaign=free%2Bcert%2Bemail'>" +
//        "                                <strong>Download it now</strong></span> <strong>for" +
//        "                                    FREE</strong></a><a title=" +
//        "                                    'http://www.secure-email.comodo.com/?utm_source=free%2Bcert%2Bemail&amp;utm_medium=free%2Bcert%2Bemail&amp;utm_campaign=free%2Bcert%2Bemail'" +
//        "                                    href=" +
//        "                                    'http://www.secure-email.comodo.com/?utm_source=free+cert+email&amp;utm_medium=free+cert+email&amp;utm_campaign=free+cert+email'></a></li>" +
//        "                                    <li>Send encrypted e-mails within minutes! – <a href=" +
//        "                                    'http://www.secure-email.comodo.com/?utm_source=free+cert+email&amp;utm_medium=free+cert+email&amp;utm_campaign=free+cert+email'>" +
//        "                                    <span title=" +
//        "                                    'http://www.secure-email.comodo.com/?utm_source=free%2Bcert%2Bemail&amp;utm_medium=free%2Bcert%2Bemail&amp;utm_campaign=free%2Bcert%2Bemail'>" +
//        "                                    <strong>Download it now</strong></span> <strong>for" +
//        "                                        FREE</strong></a></li>" +
//        "                                        </ul>" +
//        "                                        <p>Thanks for doing your part to help make the online world more" +
//        "                                            trusted and verified.<span lang='EN-GB' xml:lang=" +
//        "                                            'EN-GB'></span></p>" +
//        "                                            <h1 style='TEXT-ALIGN: center'>&nbsp;</h1>" +
//        "</div>" +
//        "<p style=" +
//        "'font-family: freewayroman, arial, sans-serif; font-weight:normal; padding-top:0px; font-size: 12px;'>" +
//        "If you need to revoke your Comodo FREE Personal Secure Email" +
//        "Certificate then please navigate to <a href=" +
//        "'https://secure.comodo.com/products/!SecureEmailCertificate_Revoke'>" +
//        "https://secure.comodo.com/products/!SecureEmailCertificate_Revoke</a>" +
//        "    You will need to enter your email address and revocation code.</p>" +
//        "    <p style=" +
//        "    'font-family: freewayroman, arial, sans-serif; font-weight:normal; padding-top:0px; font-size: 12px;'>" +
//        "    Thank you for your interest in Comodo.<br />" +
//        "        <br />" +
//        "        Comodo Certificate Services Team<br />" +
//        "        <a href=" +
//        "        'mailto:secureemail@comodogroup.com'>secureemail@comodogroup.com</a></p>" +
//        "        </td>" +
//        "        <td width='166' align='right' valign='top'>" +
//        "        <table width='166' border='0' cellpadding='0' cellspacing='0'>" +
//        "        <tr>" +
//        "        <td colspan='3'><img src=" +
//        "        'cid:FreeCrt-rtbnrtop.gif@comodo.com' /></td>" +
//        "        </tr>" +
//        "        <tr>" +
//        "        <td width='1' bgcolor='#999999'></td>" +
//        "        <td width='164' align='center' valign='top' bgcolor='#F5F5F5'>" +
//        "        <table width='144' border='0' align='center' cellpadding='0'" +
//        "        cellspacing='0'>" +
//        "        <tr>" +
//        "        <td><font style='font-weight:bold; font-size:13px;'>How to encrypt" +
//        "        mail</font></td>" +
//        "        </tr>" +
//        "        <tr>" +
//        "        <td height='25' valign='bottom'><font style=" +
//        "        'font-weight:bold; color:#FF6600; font-size:13px; padding: 25px 0px 5px 0px;'>" +
//        "        Step 1</font></td>" +
//        "        </tr>" +
//        "        <tr>" +
//        "        <td height='1' bgcolor='#CCCCCC'></td>" +
//        "        </tr>" +
//        "        <tr>" +
//        "        <td>" +
//        "        <p style=" +
//        "        'font-family: freewayroman, arial, sans-serif; font-weight:normal; font-size: 11px;line-height:18px; padding-top:5px;'>" +
//        "        Create a new Mail</p>" +
//        "        <img src='cid:FreeCrt-stp01.jpg@comodo.com' alt=" +
//        "        'How to encrypt mail - Step1' /></td>" +
//        "        </tr>" +
//        "        <tr>" +
//        "        <td height='25' valign='bottom'><font style=" +
//        "        'font-weight:bold; color:#FF6600; font-size:13px; padding: 25px 0px 5px 0px;'>" +
//        "        Step 2</font></td>" +
//        "        </tr>" +
//        "        <tr>" +
//        "        <td height='1' bgcolor='#CCCCCC'></td>" +
//        "        </tr>" +
//        "        <tr>" +
//        "        <td>" +
//        "        <p style=" +
//        "        'font-family: freewayroman, arial, sans-serif; font-weight:normal; font-size: 11px;line-height:18px; padding-top:5px;'>" +
//        "        Chose the Options button</p>" +
//        "        <img src='cid:FreeCrt-stp02.jpg@comodo.com' alt=" +
//        "        'How to encrypt mail - Step2' /></td>" +
//        "        </tr>" +
//        "        <tr>" +
//        "        <td height='25' valign='bottom'><font style=" +
//        "        'font-weight:bold; color:#FF6600; font-size:13px; padding: 25px 0px 5px 0px;'>" +
//        "        Step 3</font></td>" +
//        "        </tr>" +
//        "        <tr>" +
//        "        <td height='1' bgcolor='#CCCCCC'></td>" +
//        "        </tr>" +
//        "        <tr>" +
//        "        <td>" +
//        "        <p style=" +
//        "        'font-family: freewayroman, arial, sans-serif; font-weight:normal; font-size: 11px;line-height:12px; padding-top:5px;'>" +
//        "        Choose 'Security Settings...' and click 'Add digital" +
//        "        signatures'</p>" +
//        "        <img src='cid:FreeCrt-stp03.jpg@comodo.com' alt=" +
//        "        'How to encrypt mail - Step3' /></td>" +
//        "        </tr>" +
//        "        <tr>" +
//        "        <td height='25' valign='bottom'><font style=" +
//        "        'font-weight:bold; color:#FF6600; font-size:13px; padding: 25px 0px 5px 0px;'>" +
//        "        Step 4</font></td>" +
//        "        </tr>" +
//        "        <tr>" +
//        "        <td height='1' bgcolor='#CCCCCC'></td>" +
//        "        </tr>" +
//        "        <tr>" +
//        "        <td>" +
//        "        <p style=" +
//        "        'font-family: freewayroman, arial, sans-serif; font-weight:normal; font-size: 11px;line-height:12px; padding-top:5px;'>" +
//        "        You can digitally sign 'all' your e-mails by enabling it in the" +
//        "        main 'options' setting in outlook</p>" +
//        "        <img src='cid:FreeCrt-stp04.jpg@comodo.com' alt=" +
//        "        'How to encrypt mail - Step4' />" +
//        "        <p style=" +
//        "        'font-family: freewayroman, arial, sans-serif; font-weight:normal; font-size: 11px;line-height:12px; padding-top:5px;'>" +
//        "        <strong><font color='#FF0000'>Tip :-</font></strong>'Encrypt" +
//        "        contents' will only work if you have added a digitally signed email" +
//        "        to your address book from the person you want to encrypt the email" +
//        "        with!on the RHS screenshot.</p>" +
//        "        </td>" +
//        "        </tr>" +
//        "        </table>" +
//        "        </td>" +
//        "        <td width='1' bgcolor='#999999'></td>" +
//        "        </tr>" +
//        "        <tr>" +
//        "        <td colspan='3'><img src=" +
//        "        'cid:FreeCrt-rtbnrbtm.gif@comodo.com' /></td>" +
//        "        </tr>" +
//        "        </table>" +
//        "        </td>" +
//        "        </tr>" +
//        "        </table>" +
//        "        </td>" +
//        "        </tr>" +
//        "        </table>" +
//        "        </th>" +
//        "        </tr>" +
//        "        <tr>" +
//        "        <th height='10' colspan='3'>" +
//        "        <table width='100%' border='0' cellspacing='0' cellpadding='0'>" +
//        "        <tr>" +
//        "        <td><img src='cid:hgtrialbtmleft.gif@comodo.com' width='10' height=" +
//        "        '10' /></td>" +
//        "        <td width='99%' align='right'><img src=" +
//        "        'cid:hgtrialbtmrght.gif@comodo.com' width='10' height='10' /></td>" +
//        "        </tr>" +
//        "        </table>" +
//        "        </th>" +
//        "        </tr>" +
//        "        </tbody>" +
//        "        </table>" +
//        "        </div>" +
//        "        </body>" +
//        "        </html>"
//        
//        println(html.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()))
//        let attStr = HTMLContentToAttributedStringHelper.getAttributedStringWithHTML(html)
//        
//        // Embed in a <span> for font attributes:
////        html = "<span style=\"font-family: Helvetica; font-size:14pt;\">" + html + "</span>"
//        
//        let data = html.dataUsingEncoding(NSUnicodeStringEncoding, allowLossyConversion: true)!
//        var error: NSError?
//        let attrStr = NSAttributedString(
//            data: data,
//            options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType],
//            documentAttributes: nil,
//            error: &error)
//        if error != nil {
//            print(error)
//            print(error!.userInfo)
//        }
//        return attrStr
//    }

}
