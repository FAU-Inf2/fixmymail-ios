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
	
	var preferences: Preferences?
	var accounts: [EmailAccount]?

	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		if let html = NSBundle.mainBundle().URLForResource("Feedback", withExtension: "html") {
			let attributedString = NSAttributedString(fileURL: html, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil, error: nil)
			self.textView.attributedText = attributedString
		}
		
		self.loadData()
		

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
	@IBAction func buttonFeedbackTapped(sender: UIButton) {
		var standardAccount: EmailAccount?
		var recipient = MCOAddress(mailbox: "fixmymail@i2.cs.fau.de")
		var subject = "Feedback for SMile on iOS"
		var sendView = MailSendViewController(nibName: "MailSendViewController", bundle: nil)
		sendView.recipients.addObject(recipient)
		sendView.subject = subject
		
		if self.accounts!.count != 0 {
			if self.preferences != nil {
				if self.preferences?.standardAccount != "" {
					for account in self.accounts! {
						if account.accountName == self.preferences?.standardAccount {
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
				// got accounts but no preferences
				
				sendView.account = self.accounts?.first
				self.navigationController?.pushViewController(sendView, animated: true)
			}
			
		} else {
			// user has no accounts declared
			var alert = UIAlertController(title: "Sorry", message: "It seems you have not declared an Email account, please use the provided link or add a new account in Preferences > Accounts > \"Add New Account\".", preferredStyle: UIAlertControllerStyle.Alert)
			alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { action in }))
			self.presentViewController(alert, animated: true, completion: nil)
			
		}
	}

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

	
	func loadData() {
		let appDel: AppDelegate? = UIApplication.sharedApplication().delegate as? AppDelegate
		if let appDelegate = appDel {
			var managedObjectContext = appDelegate.managedObjectContext
			var preferencesFetchRequest = NSFetchRequest(entityName: "Preferences")
			var error: NSError?
			let fetchedPreferences: [Preferences]? = managedObjectContext!.executeFetchRequest(preferencesFetchRequest, error: &error) as? [Preferences]
			
			if let preferences = fetchedPreferences {
				self.preferences = preferences[0]
			} else {
				if((error) != nil) {
					NSLog(error!.description)
				}
			}
		}
		
		self.accounts = self.getAccount()
		
	}
	
	func getAccount() -> [EmailAccount]? {
		var managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext as NSManagedObjectContext!
		var retaccount = [EmailAccount]()
		let fetchRequest: NSFetchRequest = NSFetchRequest(entityName: "EmailAccount")
		var error: NSError?
		var result = managedObjectContext!.executeFetchRequest(fetchRequest, error: &error)
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
