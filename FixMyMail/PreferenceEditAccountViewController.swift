//
//  PreferenceEditAccountViewController.swift
//  FixMyMail
//
//  Created by Sebastian Thürauf on 31.05.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit

class PreferenceEditAccountViewController: UIViewController {
	
	var emailAcc: EmailAccount?
	var actionItem: ActionItem?

	@IBOutlet weak var textfieldEmailAddress: TextfieldWithPadding!
	@IBOutlet weak var textfieldUsername: TextfieldWithPadding!
	@IBOutlet weak var textfieldPassword: TextfieldWithPadding!
	@IBOutlet weak var textfieldImapHostname: TextfieldWithPadding!
	@IBOutlet weak var textfieldImapPort: TextfieldWithPadding!
	@IBOutlet weak var testfieldSmtpHostname: TextfieldWithPadding!
	@IBOutlet weak var textfieldSmtpPort: TextfieldWithPadding!
	
	@IBAction func buttonDone(sender: UIButton) {
	}
	
	@IBAction func buttonDeleteAccount(sender: UIButton) {
	}
	
	
	
    override func viewDidLoad() {
        super.viewDidLoad()

		self.navigationItem.title = actionItem?.mailAdress
		
        // Do any additional setup after loading the view.
		if emailAcc != nil {
			self.textfieldEmailAddress.text = emailAcc!.emailAddress
			self.textfieldUsername.text = emailAcc!.username
			self.textfieldPassword.text = emailAcc!.password
			self.textfieldImapHostname.text = emailAcc!.imapHostname
			self.textfieldImapPort.text = String(Int(emailAcc!.imapPort))
			self.testfieldSmtpHostname.text = emailAcc!.smtpHostname
			self.textfieldSmtpPort.text = String(Int(emailAcc!.smtpPort))
		}
		
		
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
