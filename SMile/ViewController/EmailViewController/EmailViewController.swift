//
//  EmailViewController.swift
//  SMile
//
//  Created by Jan Weiß on 17.08.15.
//  Copyright (c) 2015 SMile. All rights reserved.
//

import UIKit

class EmailViewController: UIViewController, EmailViewDelegate {

    var mcoimapmessage: MCOIMAPMessage!
    var message: Email!
    var session: MCOIMAPSession!
    var emailView: EmailView!
    var containerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var containerFrame = self.view.frame
        containerFrame.origin.y = 64.0
        containerFrame.size.height = containerFrame.size.height - 64.0
        self.containerView = UIView(frame: containerFrame)
        self.view.addSubview(self.containerView)
        self.view.bringSubviewToFront(self.containerView)
        
        self.emailView = EmailView(frame: CGRectMake(0, 0, self.containerView.frame.size.width, self.containerView.frame.size.height), message: self.mcoimapmessage, email: self.message)
        self.emailView.emailViewDelegate = self
        self.containerView.addSubview(self.emailView)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func handleMailtoWithRecipients(recipients: [String], andSubject subject: String, andHTMLString html: String) {
        let mailSendVC: MailSendViewController = MailSendViewController(nibName: "MailSendViewController", bundle: NSBundle.mainBundle())
        var recipientAddressArr = NSMutableArray()
        for recipient in recipients {
            recipientAddressArr.addObject(MCOAddress(mailbox: recipient))
        }
        mailSendVC.recipients = recipientAddressArr
        mailSendVC.account = self.message.toAccount
        self.navigationController?.pushViewController(mailSendVC, animated: true)
    }

}
