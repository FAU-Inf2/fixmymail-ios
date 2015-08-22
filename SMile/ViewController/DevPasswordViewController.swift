//
//  DevPasswordViewController.swift
//  SMile
//
//  Created by Sebastian Thürauf on 03.08.15.
//  Copyright (c) 2015 SMile. All rights reserved.
//

import UIKit
import CoreData

class DevPasswordViewController: UIViewController {
	@IBOutlet weak var label: UILabel!
	@IBOutlet weak var textfield: UITextField!
	
	

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
		self.navigationItem.title = "Enter password"
		var doneButton: UIBarButtonItem = UIBarButtonItem(title: "Done  ", style: .Plain, target: self, action: "doneTapped:")
		self.navigationItem.rightBarButtonItem = doneButton

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
	
	func doneTapped(sender: AnyObject) -> Void {
		if self.textfield.text != "" {
			self.textfield.resignFirstResponder()
			let appDel: AppDelegate? = UIApplication.sharedApplication().delegate as? AppDelegate
			if let appDelegate = appDel {
				managedObjectContext = appDelegate.managedObjectContext
				var emailAccountsFetchRequest = NSFetchRequest(entityName: "EmailAccount")
				var error: NSError?
				let acc: [EmailAccount]? = managedObjectContext.executeFetchRequest(emailAccountsFetchRequest, error: &error) as? [EmailAccount]
				if let account = acc {
					for emailAcc: EmailAccount in account {
						let errorLocksmithUpdateAccount = Locksmith.deleteDataForUserAccount(emailAcc.emailAddress)
						if errorLocksmithUpdateAccount == nil {
							NSLog("found old data -> deleted!")
						}
						// save data to iOS keychain
						let NewSaveRequest = LocksmithRequest(userAccount: emailAcc.emailAddress, requestType: .Create, data: ["Password:": self.textfield.text])
						NewSaveRequest.accessible = .AfterFirstUnlockThisDeviceOnly
						let (NewDictionary, NewRequestError) = Locksmith.performRequest(NewSaveRequest)
						if NewRequestError == nil {
							NSLog("saving data for " + emailAcc.emailAddress)
						} else {
							NSLog("could not save data for " + emailAcc.emailAddress)
						}
					}
				} else {
					if((error) != nil) {
						NSLog(error!.description)
					}
				}
			}
			self.textfield.text = ""
			self.navigationController?.popViewControllerAnimated(true)
		}
	}

}
