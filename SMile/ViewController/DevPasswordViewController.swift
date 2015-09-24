//
//  DevPasswordViewController.swift
//  SMile
//
//  Created by Sebastian Thürauf on 03.08.15.
//  Copyright (c) 2015 SMile. All rights reserved.
//

import UIKit
import CoreData
import Locksmith

class DevPasswordViewController: UIViewController {
	@IBOutlet weak var label: UILabel!
	@IBOutlet weak var textfield: UITextField!
	
	

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
		self.navigationItem.title = "Enter password"
		let doneButton: UIBarButtonItem = UIBarButtonItem(title: "Done  ", style: .Plain, target: self, action: "doneTapped:")
		self.navigationItem.rightBarButtonItem = doneButton

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
	
	func doneTapped(sender: AnyObject) -> Void {
		if self.textfield.text != "" {
			self.textfield.resignFirstResponder()
			let appDel: AppDelegate? = UIApplication.sharedApplication().delegate as? AppDelegate
			if let appDelegate = appDel {
				managedObjectContext = appDelegate.managedObjectContext
				let emailAccountsFetchRequest = NSFetchRequest(entityName: "EmailAccount")
				var acc: [EmailAccount]? = nil
				do {
					acc = try managedObjectContext.executeFetchRequest(emailAccountsFetchRequest) as? [EmailAccount]
				} catch {
					print("CoreData fetch error")
				}
				if let account = acc {
					for emailAcc: EmailAccount in account {
//						let errorLocksmithUpdateAccount = Locksmith.deleteDataForUserAccount(emailAcc.emailAddress)
//						if errorLocksmithUpdateAccount == nil {
//							NSLog("found old data -> deleted!")
//						}
                        do {
                            try Locksmith.deleteDataForUserAccount(emailAcc.emailAddress)
                        } catch _ {
                            print("LocksmithError while deleting data for useraccount: \(emailAcc.emailAddress)")
                        }
						// save data to iOS keychain
						// change for locksmith 2.0
//						let NewSaveRequest = LocksmithRequest(userAccount: emailAcc.emailAddress, requestType: .Create, data: ["Password:": self.textfield.text])
//						NewSaveRequest.accessible = .AfterFirstUnlockThisDeviceOnly
//						let (NewDictionary, NewRequestError) = Locksmith.performRequest(NewSaveRequest)
//						if NewRequestError == nil {
//							NSLog("saving data for " + emailAcc.emailAddress)
//							createNewSession(emailAcc)
//						} else {
//							NSLog("could not save data for " + emailAcc.emailAddress)
//						}
                        do {
                            try Locksmith.saveData(["Password:": self.textfield.text!], forUserAccount: emailAcc.emailAddress)
                            print("Locksmith: saving data for \(emailAcc.emailAddress)")
                            try createNewSession(emailAcc)
                        } catch SessionError.NoDataForUserAccount {
                            print("There are no userdata to create an imapsession!")
                        } catch _ {
                            print("LocksmithError while trying to save data for useraccount: \(emailAcc.emailAddress)")
                        }
					}
				}
			}
			self.textfield.text = ""
			self.navigationController?.popViewControllerAnimated(true)
		}
	}

}
