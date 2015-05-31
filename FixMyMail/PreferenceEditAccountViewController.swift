//
//  PreferenceEditAccountViewController.swift
//  FixMyMail
//
//  Created by Sebastian Thürauf on 31.05.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit
import CoreData

class PreferenceEditAccountViewController: UIViewController {
	
	var emailAcc: EmailAccount?
	var actionItem: ActionItem?
	var filledTextfieldCount: Int?

	@IBOutlet weak var textfieldEmailAddress: TextfieldWithPadding!
	@IBOutlet weak var textfieldUsername: TextfieldWithPadding!
	@IBOutlet weak var textfieldPassword: TextfieldWithPadding!
	@IBOutlet weak var textfieldImapHostname: TextfieldWithPadding!
	@IBOutlet weak var textfieldImapPort: TextfieldWithPadding!
	@IBOutlet weak var textfieldSmtpHostname: TextfieldWithPadding!
	@IBOutlet weak var textfieldSmtpPort: TextfieldWithPadding!
	
	@IBAction func buttonDone(sender: UIButton) {
		filledTextfieldCount = 0
		
		// check if textfields are empty
		checkAllTextfieldsFilled()
		
		if filledTextfieldCount == 7 {
			// write / update entity
			var appDel: AppDelegate = (UIApplication.sharedApplication().delegate as! AppDelegate)
			var context: NSManagedObjectContext = appDel.managedObjectContext!
			
			if actionItem?.mailAdress == "Add New Account" {
				var newEntry = NSEntityDescription.insertNewObjectForEntityForName("EmailAccount", inManagedObjectContext: context) as!EmailAccount
				
				newEntry.setValue(textfieldEmailAddress.text, forKey: "emailAddress")
				newEntry.setValue(textfieldUsername.text, forKey: "username")
				newEntry.setValue(textfieldPassword.text, forKey: "password")
				newEntry.setValue(textfieldImapHostname.text, forKey: "imapHostname")
				newEntry.setValue(textfieldImapPort.text.toInt(), forKey: "imapPort")
				newEntry.setValue(textfieldSmtpHostname.text, forKey: "smtpHostname")
				newEntry.setValue(textfieldSmtpPort.text.toInt(), forKey: "smtpPort")
				
				
			} else {
				
				var fetchRequest = NSFetchRequest(entityName: "EmailAccount")
				fetchRequest.predicate = NSPredicate(format: "emailAddress = %@", emailAcc!.emailAddress)
				
				if let fetchResults = appDel.managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [NSManagedObject] {
					if fetchResults.count != 0{
						
						var managedObject = fetchResults[0]
						managedObject.setValue(textfieldEmailAddress.text, forKey: "emailAddress")
						managedObject.setValue(textfieldUsername.text, forKey: "username")
						managedObject.setValue(textfieldPassword.text, forKey: "password")
						managedObject.setValue(textfieldImapHostname.text, forKey: "imapHostname")
						managedObject.setValue(textfieldImapPort.text.toInt(), forKey: "imapPort")
						managedObject.setValue(textfieldSmtpHostname.text, forKey: "smtpHostname")
						managedObject.setValue(textfieldSmtpPort.text.toInt(), forKey: "smtpPort")
						
					}
				}
				
			}
			context.save(nil)
			self.navigationController?.popViewControllerAnimated(true)
		}
	}
	
	@IBAction func buttonDeleteAccount(sender: UIButton) {
		
		if actionItem?.mailAdress != "Add New Account" {
			var appDel: AppDelegate = (UIApplication.sharedApplication().delegate as! AppDelegate)
			var context: NSManagedObjectContext = appDel.managedObjectContext!
			var fetchRequest = NSFetchRequest(entityName: "EmailAccount")
			fetchRequest.predicate = NSPredicate(format: "emailAddress = %@", emailAcc!.emailAddress)
			
			if let fetchResults = appDel.managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [NSManagedObject] {
				if fetchResults.count != 0{
					
					var managedObject = fetchResults[0]
					context.deleteObject(managedObject)
				}
			}
			
			context.save(nil)
			self.navigationController?.popViewControllerAnimated(true)
		}
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
			self.textfieldSmtpHostname.text = emailAcc!.smtpHostname
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
	
	func checkAllTextfieldsFilled() {
		if textfieldEmailAddress.text.isEmpty {
			textfieldEmailAddress.attributedPlaceholder = NSAttributedString(string: textfieldEmailAddress.placeholder!, attributes: [NSForegroundColorAttributeName: UIColor.redColor()])
		} else {
			filledTextfieldCount! += 1
		}
		
		if textfieldUsername.text.isEmpty {
			textfieldUsername.attributedPlaceholder = NSAttributedString(string: textfieldUsername.placeholder!, attributes: [NSForegroundColorAttributeName: UIColor.redColor()])
		} else {
			filledTextfieldCount! += 1
		}
		
		if textfieldPassword.text.isEmpty {
			textfieldPassword.attributedPlaceholder = NSAttributedString(string: textfieldPassword.placeholder!, attributes: [NSForegroundColorAttributeName: UIColor.redColor()])
		} else {
			filledTextfieldCount! += 1
		}
		
		if textfieldImapHostname.text.isEmpty {
			textfieldImapHostname.attributedPlaceholder = NSAttributedString(string: textfieldImapHostname.placeholder!, attributes: [NSForegroundColorAttributeName: UIColor.redColor()])
		} else {
			filledTextfieldCount! += 1
		}
		
		if textfieldImapPort.text.isEmpty {
			textfieldImapPort.attributedPlaceholder = NSAttributedString(string: textfieldImapPort.placeholder!, attributes: [NSForegroundColorAttributeName: UIColor.redColor()])
		} else {
			filledTextfieldCount! += 1
		}
		
		if textfieldSmtpHostname.text.isEmpty {
			textfieldSmtpHostname.attributedPlaceholder = NSAttributedString(string: textfieldSmtpHostname.placeholder!, attributes: [NSForegroundColorAttributeName: UIColor.redColor()])
		} else {
			filledTextfieldCount! += 1
		}
		
		if textfieldSmtpPort.text.isEmpty {
			textfieldSmtpPort.attributedPlaceholder = NSAttributedString(string: textfieldSmtpPort.placeholder!, attributes: [NSForegroundColorAttributeName: UIColor.redColor()])
		} else {
			filledTextfieldCount! += 1
		}

	}

}
