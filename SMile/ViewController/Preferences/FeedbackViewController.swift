//
//  FeedbackViewController.swift
//  FixMyMail
//
//  Created by Sebastian Thürauf on 16.06.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit
import CoreData

class FeedbackViewController: UIViewController, NSFetchedResultsControllerDelegate{

	@IBOutlet weak var textView: UITextView!
	@IBOutlet weak var buttonFeedback: UIButton!
	
	var accounts: [EmailAccount]?

	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		if let html = NSBundle.mainBundle().URLForResource("Feedback", withExtension: "html") {
			let attributedString = try? NSAttributedString(fileURL: html, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil)
			self.textView.attributedText = attributedString
		}
		
		self.accounts = self.getAccount()
		

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
	@IBAction func buttonFeedbackTapped(sender: UIButton) {
		var standardAccount: EmailAccount?
		let recipient = MCOAddress(mailbox: "fixmymail@i2.cs.fau.de")
		let subject = "Feedback for SMile on iOS"
		let sendView = MailSendViewController(nibName: "MailSendViewController", bundle: nil)
		sendView.recipients.addObject(recipient)
		sendView.subject = subject
		
		if self.accounts!.count != 0 {
				if NSUserDefaults.standardUserDefaults().stringForKey("standardAccount") != "" {
					for account in self.accounts! {
						if account.accountName == NSUserDefaults.standardUserDefaults().stringForKey("standardAccount") {
							standardAccount = account
						}
					}
					
					// user has declared a standard account -> use it
					if standardAccount != nil {
						sendView.account = standardAccount!
						self.navigationController?.pushViewController(sendView, animated: true)
					}
					
					
				} else {
					// user has NOT declared a standard account
					sendView.account = self.accounts?.first
					self.navigationController?.pushViewController(sendView, animated: true)
				}
			
		} else {
			// user has no accounts declared
			let alert = UIAlertController(title: "Sorry", message: "It seems you have not declared an Email account, please use the provided link or add a new account in Preferences > Accounts > \"Add New Account\".", preferredStyle: UIAlertControllerStyle.Alert)
			alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { action in }))
			self.presentViewController(alert, animated: true, completion: nil)
			
		}
	}
    
	
	func getAccount() -> [EmailAccount]? {
		let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext as NSManagedObjectContext!
		var retaccount = [EmailAccount]()
		let fetchRequest: NSFetchRequest = NSFetchRequest(entityName: "EmailAccount")
		var error: NSError?
		var result: [AnyObject]?
		do {
			result = try managedObjectContext!.executeFetchRequest(fetchRequest)
		} catch let error1 as NSError {
			error = error1
			result = nil
		}
		if error != nil {
			NSLog("%@", error!.description)
		} else {
			if let emailAccounts = result {
				for account in emailAccounts {
					
					retaccount.append(account as! EmailAccount)
					
				}
			}
		}
		
		return retaccount
	}
	
}
