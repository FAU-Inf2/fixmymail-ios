//
//  PreferenceEditAccountTableViewController.swift
//  FixMyMail
//
//  Created by Sebastian Thürauf on 02.06.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit
import CoreData
import Locksmith

class PreferenceEditAccountTableViewController: UITableViewController, UITextFieldDelegate {
	
	var emailAcc: EmailAccount?
	var newEmailAcc: EmailAccount?
	var actionItem: ActionItem?
	var allAccounts: [EmailAccount] = [EmailAccount]()
	var managedObjectContext: NSManagedObjectContext!
	var sections = [String]()
	var labelAccountDetailString = [String]()
	var labelImapConnectionDetailString = [String]()
	var labelSmtpConnectionDetailString = [String]()
	var cellAccountTextfielString = [String]()
	var cellImapConnectionTextfielString = [String]()
	var cellSmtpConnectionTextfielString = [String]()
	var AccountBehaviorString = [String]()
	var labels = [AnyObject]()
	var textfields = [AnyObject]()
	var entries = [String: String]()
	var entriesChecked = [String: Bool]()
	var deleteString = [String]()
	var isActivatedString = [String]()
	var alert: UIAlertController?
	var selectedTextfield: UITextField?
	var selectedIndexPath: NSIndexPath?
	var authConVC: AuthConTableViewController?
	var accountBehaviorVC: PrefAccountBehaviorTableViewController?
	var origintableViewInsets: UIEdgeInsets?
	var isActivated: Bool = false
	var imapOperation: MCOIMAPOperation?
	var smtpOperation: MCOSMTPOperation?
	var isInImapOperation: Bool = false
	var isInSmtpOperation: Bool = false
	var isSimpleWizard: Bool = true
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		if self.emailAcc != nil {
			self.isSimpleWizard = false
		}
		
		loadAccountDetails()
		
		tableView.registerNib(UINib(nibName: "PreferenceAccountTableViewCell", bundle: nil),forCellReuseIdentifier:"PreferenceAccountCell")
		tableView.registerNib(UINib(nibName: "SwitchTableViewCell", bundle: nil), forCellReuseIdentifier: "SwitchTableViewCell")
		
		// set navigationbar
		self.navigationItem.title = actionItem?.emailAddress
		let doneButton: UIBarButtonItem = UIBarButtonItem(title: "Done  ", style: .Plain, target: self, action: "doneTapped:")
		let cancelButton: UIBarButtonItem = UIBarButtonItem(title: "Cancel", style: .Plain, target: self, action: "cancelTapped:")
		self.navigationItem.rightBarButtonItem = doneButton
		self.navigationItem.leftBarButtonItem = cancelButton
		
		// set expert button on toolbar if new account
		if self.emailAcc == nil {
			self.activateToolbarItems()
		}
		
		// set alert dialog for delete
		self.alert = UIAlertController(title: "Delete", message: "Really delete account?", preferredStyle: UIAlertControllerStyle.Alert)
		self.alert!.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { action in
			// save data to CoreData (respectively deleting data from CoreData)
			let appDel: AppDelegate = (UIApplication.sharedApplication().delegate as! AppDelegate)
			let context: NSManagedObjectContext = appDel.managedObjectContext!
			let fetchRequest = NSFetchRequest(entityName: "EmailAccount")
			fetchRequest.predicate = NSPredicate(format: "emailAddress = %@", self.emailAcc!.emailAddress)
			
			if let fetchResults = (try? appDel.managedObjectContext!.executeFetchRequest(fetchRequest)) as? [NSManagedObject] {
				if fetchResults.count != 0{
					
					let managedObject = fetchResults[0]
					context.deleteObject(managedObject)
				}
			}
			
			do {
				try context.save()
			} catch _ {
			}
			// delete Password from iOS Keychain
//			let errorLocksmith = Locksmith.deleteDataForUserAccount(self.entries["Mailaddress:"]!)
//			if errorLocksmith == nil {
//				NSLog("deleting data for " + self.entries["Mailaddress:"]!)
//			}
            do {
                try Locksmith.deleteDataForUserAccount(self.entries["Mailaddress:"]!)
            } catch _ {
                print("Locksmitherror while trying to delete data for useraccount!")
            }
			
			self.navigationController?.popViewControllerAnimated(true)
		}))
		
		self.alert!.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { action in
		}))
		
		// Uncomment the following line to preserve selection between presentations
		// self.clearsSelectionOnViewWillAppear = false
		
		// Uncomment the following line to display an Edit button in the navigation bar for this view controller.
		// self.navigationItem.rightBarButtonItem = self.editButtonItem()
		
	}
	
	override func viewWillAppear(animated: Bool) {
		// Register notification when the keyboard will be show
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
		self.tableView.reloadData()
        
	}
	
	override func viewWillDisappear(animated: Bool) {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	// MARK: - Table view data source
	
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		// Return the number of sections.
		return self.sections.count
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.labels[section].count
	}
	
	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return self.sections[section]
	}
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		
		let labelString = self.labels[indexPath.section][indexPath.row] as! String
		let textfieldString = self.entries[labelString]
		
		
		
		
		
		// if auth or con cell -> load AuthConTableViewController
		if labelString == "IMAP Auth:" || labelString == "SMTP Auth:"  ||
			labelString == "IMAP ConType:" ||  labelString == "SMTP ConType:" {
				self.authConVC = AuthConTableViewController(nibName:"AuthConTableViewController", bundle: nil)
				self.authConVC!.labelPreviousVC = labelString
				self.authConVC!.selectedString = textfieldString!
				self.navigationController?.pushViewController(self.authConVC!, animated: true)
		}
		// if advanved cell -> load PrefAccountBehaviorTableViewController
		else if labelString == "Advanced" {
			self.accountBehaviorVC = PrefAccountBehaviorTableViewController(nibName: "PrefAccountBehaviorTableViewController", bundle: nil)
			self.accountBehaviorVC!.emailAcc = self.emailAcc!
			self.navigationController?.pushViewController(self.accountBehaviorVC!, animated: true)
		}
		// normal cells
		else {
			if labelString != "DELETE" && labelString != "Activate:" && labelString != "Advanced" {
				let cell = tableView.cellForRowAtIndexPath(indexPath) as! PreferenceAccountTableViewCell
				cell.textfield.becomeFirstResponder()
			}
			
		}
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
		
		// show alert dialog if delete is tapped
		if labelString == "DELETE" {
			self.presentViewController(self.alert!, animated: true, completion: nil)
		}
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let labelString = self.labels[indexPath.section][indexPath.row] as? String
		// decide witch cell must be loaded
		if labelString == "Activate:" {
			let cell = tableView.dequeueReusableCellWithIdentifier("SwitchTableViewCell", forIndexPath: indexPath) as! SwitchTableViewCell
			
			cell.label.text = labelString
			cell.activateSwitch.addTarget(self, action: Selector("stateChanged:"), forControlEvents: UIControlEvents.ValueChanged)
			cell.activateSwitch.on = self.isActivated
			
			return cell
			
		// normal account cells
		} else {
			let cell = tableView.dequeueReusableCellWithIdentifier("PreferenceAccountCell", forIndexPath: indexPath) as! PreferenceAccountTableViewCell
			
			// auth or con were previously selected
			if self.authConVC != nil {
				self.entries[self.authConVC!.labelPreviousVC] = self.authConVC!.selectedString
			}
			
			// Configure the cell...
			cell.textfield.delegate = self
			cell.labelCellContent.text = self.labels[indexPath.section][indexPath.row] as? String
			cell.textfield.placeholder = self.labels[indexPath.section][indexPath.row] as? String
			
			// set checkmarks on cell
			if self.entriesChecked[cell.labelCellContent.text!] == true {
				cell.accessoryType = UITableViewCellAccessoryType.Checkmark
			} else {
				cell.accessoryType = UITableViewCellAccessoryType.None
			}
			
			// secure text entry for password cell
			if cell.textfield.placeholder == "Password:" {
				cell.textfield.secureTextEntry = true
			} else {
				cell.textfield.secureTextEntry = false
			}
			
			// set auth and conn cells
			if cell.textfield.placeholder == "IMAP Auth:" || cell.textfield.placeholder == "SMTP Auth:"
				|| cell.textfield.placeholder == "IMAP ConType:" || cell.textfield.placeholder == "SMTP ConType:" {
					cell.textfield.enabled = false
					cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
			} else {
				cell.textfield.enabled = true
			}
			
			// fill the textfields
			cell.textfield.text = self.entries[cell.labelCellContent.text!]
			cell.labelCellContent.textAlignment = NSTextAlignment.Left
			self.entriesChecked[cell.labelCellContent.text!] = false
			
			if emailAcc != nil {
				// configure delete cell
				if cell.labelCellContent.text == self.deleteString[0] {
					cell.labelCellContent.textAlignment = NSTextAlignment.Center
					cell.labelCellContent.attributedText = NSAttributedString(string: cell.labelCellContent.text!, attributes: [NSForegroundColorAttributeName: UIColor.redColor()])
					cell.textfield.text = ""
					cell.textfield.placeholder = ""
					cell.textfield.enabled = false
					self.entries.removeValueForKey(self.deleteString[0])
					self.entriesChecked.removeValueForKey(self.deleteString[0])
				}
				// configure account behavior cell
				if cell.labelCellContent.text == self.AccountBehaviorString[0] {
					cell.textfield.text = ""
					cell.textfield.placeholder = ""
					cell.textfield.enabled = false
					cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
					self.entries.removeValueForKey(self.AccountBehaviorString[0])
					self.entriesChecked.removeValueForKey(self.AccountBehaviorString[0])
				}
			}
			
			return cell
		}
		
	}
	
	
	func loadAccountDetails() {
		
		if actionItem?.emailAddress != "Add New Account" {
			self.sections = ["Account Details:", "Account behavior", "IMAP Details", "SMTP Details:", "",""]
		} else {
			if self.isSimpleWizard {
				self.sections = ["Account Details:", "", "", "",""]
			} else {
				self.sections = ["Account Details:", "IMAP Details", "SMTP Details:", "",""]
			}
		}
		// clear arrays when reloading the data
		self.labelAccountDetailString.removeAll(keepCapacity: false)
		self.labelImapConnectionDetailString.removeAll(keepCapacity: false)
		self.labelSmtpConnectionDetailString.removeAll(keepCapacity: false)
		self.cellAccountTextfielString.removeAll(keepCapacity: false)
		self.cellImapConnectionTextfielString.removeAll(keepCapacity: false)
		self.cellSmtpConnectionTextfielString.removeAll(keepCapacity: false)
		self.labels.removeAll(keepCapacity: false)
		self.textfields.removeAll(keepCapacity: false)
		self.isActivatedString.removeAll(keepCapacity: false)
		self.AccountBehaviorString.removeAll(keepCapacity: false)
		self.deleteString.removeAll(keepCapacity: false)

		// the cell label strings
		self.labelAccountDetailString.append("Mailaddress:")
		self.labelAccountDetailString.append("Username:")
		self.labelAccountDetailString.append("Password:")
		self.labelAccountDetailString.append("Realname:")
		self.labelAccountDetailString.append("Accountname:")
		self.labelAccountDetailString.append("Signature:")
		
		if !self.isSimpleWizard {
		self.labelImapConnectionDetailString.append("IMAP Hostname:")
		self.labelImapConnectionDetailString.append("IMAP Port:")
		self.labelImapConnectionDetailString.append("IMAP Auth:")
		self.labelImapConnectionDetailString.append("IMAP ConType:")
		
		self.labelSmtpConnectionDetailString.append("SMTP Hostname:")
		self.labelSmtpConnectionDetailString.append("SMTP Port:")
		self.labelSmtpConnectionDetailString.append("SMTP Auth:")
		self.labelSmtpConnectionDetailString.append("SMTP ConType:")
		
		self.isActivatedString.append("Activate:")
		}
		
		if emailAcc != nil {
			
			if self.entries["Mailaddress:"] == nil {self.entries["Mailaddress:"] = emailAcc!.emailAddress}
			if self.entries["Realname:"] == nil {self.entries["Realname:"] = emailAcc!.realName}
			if self.entries["Accountname:"] == nil {self.entries["Accountname:"] = emailAcc!.accountName}
			if self.entries["Username:"] == nil {self.entries["Username:"] = emailAcc!.username}
			if self.entries["Signature:"] == nil {self.entries["Signature:"] = emailAcc!.signature}
			
			// load password for account from iOS keychain
			if self.entries["Password:"] == nil {
//				let (dictionary, error) = Locksmith.loadDataForUserAccount(self.entries["Mailaddress:"]!)
//				if error == nil {
//					let value = dictionary?.valueForKey("Password:") as! String
//					self.entries["Password:"] = value
//					NSLog("loaded value from keychain")
//				} else {
//					self.entries["Password:"] = ""
//				}
                let dict = Locksmith.loadDataForUserAccount(self.entries["Mailaddress:"]!)
                if dict == nil {
                    self.entries["Password:"] = ""
                } else {
                    let value = dict!["Password:"] as! String
                    self.entries["Password:"] = value
                    print("loaded value from keychain")
                }
			}
			if self.entries["IMAP Hostname:"] == nil {self.entries["IMAP Hostname:"] = emailAcc!.imapHostname}
			if self.entries["IMAP Port:"] == nil {self.entries["IMAP Port:"] = String(Int(emailAcc!.imapPort))}
			if self.entries["IMAP Auth:"] == nil {self.entries["IMAP Auth:"] = emailAcc!.authTypeImap}
			if self.entries["IMAP ConType:"] == nil {self.entries["IMAP ConType:"] = emailAcc!.connectionTypeImap}
			
			if self.entries["SMTP Hostname:"] == nil {self.entries["SMTP Hostname:"] = emailAcc!.smtpHostname}
			if self.entries["SMTP Port:"] == nil {self.entries["SMTP Port:"] = String(Int(emailAcc!.smtpPort))}
			if self.entries["SMTP Auth:"] == nil {self.entries["SMTP Auth:"] = emailAcc!.authTypeSmtp}
			if self.entries["SMTP ConType:"] == nil {self.entries["SMTP ConType:"] = emailAcc!.connectionTypeSmtp}
			self.isActivated = emailAcc!.isActivated

			self.cellAccountTextfielString.append(emailAcc!.emailAddress)
			self.cellAccountTextfielString.append(emailAcc!.username)
			self.cellAccountTextfielString.append(emailAcc!.password)
			self.cellAccountTextfielString.append(emailAcc!.realName)
			self.cellAccountTextfielString.append(emailAcc!.accountName)
			self.cellAccountTextfielString.append(emailAcc!.signature)
			
			self.cellImapConnectionTextfielString.append(emailAcc!.imapHostname)
			self.cellImapConnectionTextfielString.append(String(Int(emailAcc!.imapPort)))
			self.cellImapConnectionTextfielString.append(emailAcc!.authTypeImap)
			self.cellImapConnectionTextfielString.append(emailAcc!.connectionTypeImap)
			
			self.cellSmtpConnectionTextfielString.append(emailAcc!.smtpHostname)
			self.cellSmtpConnectionTextfielString.append(String(Int(emailAcc!.smtpPort)))
			self.cellSmtpConnectionTextfielString.append(emailAcc!.authTypeSmtp)
			self.cellSmtpConnectionTextfielString.append(emailAcc!.connectionTypeSmtp)

			
		} else {
			if self.entries["Mailaddress:"] == nil {self.entries["Mailaddress:"] = ""}
			if self.entries["Realname:"] == nil {self.entries["Realname:"] = ""}
			if self.entries["Accountname:"] == nil {self.entries["Accountname:"] = ""}
			if self.entries["Username:"] == nil {self.entries["Username:"] = ""}
			if self.entries["Password:"] == nil {self.entries["Password:"] = ""}
			if self.entries["Signature:"] == nil {self.entries["Signature:"] = ""}
			
			if self.entries["IMAP Hostname:"] == nil {self.entries["IMAP Hostname:"] = ""}
			if self.entries["IMAP Port:"] == nil {self.entries["IMAP Port:"] = ""}
			if self.entries["IMAP Auth:"] == nil {self.entries["IMAP Auth:"] = ""}
			if self.entries["IMAP ConType:"] == nil {self.entries["IMAP ConType:"] = ""}
			
			if self.entries["SMTP Hostname:"] == nil {self.entries["SMTP Hostname:"] = ""}
			if self.entries["SMTP Port:"] == nil {self.entries["SMTP Port:"] = ""}
			if self.entries["SMTP Auth:"] == nil {self.entries["SMTP Auth:"] = ""}
			if self.entries["SMTP ConType:"] == nil {self.entries["SMTP ConType:"] = ""}
		}
		
		if actionItem?.emailAddress != "Add New Account" {
			self.deleteString.append("DELETE")
			self.AccountBehaviorString.append("Advanced")
			
			self.labels.append(self.labelAccountDetailString)
			self.labels.append(self.AccountBehaviorString)
			self.labels.append(self.labelImapConnectionDetailString)
			self.labels.append(self.labelSmtpConnectionDetailString)
			self.labels.append(self.isActivatedString)
			self.labels.append(self.deleteString)
			
			self.textfields.append(self.cellAccountTextfielString)
			self.textfields.append(self.AccountBehaviorString)
			self.textfields.append(self.cellImapConnectionTextfielString)
			self.textfields.append(self.cellSmtpConnectionTextfielString)
			self.textfields.append(self.isActivatedString)
			self.textfields.append(self.deleteString)

		} else {
			self.labels.append(self.labelAccountDetailString)
			self.labels.append(self.labelImapConnectionDetailString)
			self.labels.append(self.labelSmtpConnectionDetailString)
			self.labels.append(self.isActivatedString)
			self.labels.append(self.deleteString)
			
			self.textfields.append(self.cellAccountTextfielString)
			self.textfields.append(self.cellImapConnectionTextfielString)
			self.textfields.append(self.cellSmtpConnectionTextfielString)
			self.textfields.append(self.isActivatedString)
			self.textfields.append(self.deleteString)

		}
		
	}
	
	func setValueThatAppHasRunOnce() {
		// app runs for the first time
		let defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
		if(!defaults.boolForKey("AppHasRunOnce")) {
			defaults.setBool(true, forKey: "AppHasRunOnce")
		}
	}
	
	@IBAction func expertTapped(sender: AnyObject) -> Void {
		self.isSimpleWizard = !self.isSimpleWizard
		self.loadAccountDetails()
		self.tableView.reloadData()
	}
	
	@IBAction func cancelTapped(sender: AnyObject) -> Void {
		self.setValueThatAppHasRunOnce()
		self.navigationController?.popViewControllerAnimated(true)
	}
	
	@IBAction func stopTapped(sender: AnyObject) -> Void {
		NSLog("Cancel Button tapped!")
		if self.imapOperation != nil {
			NSLog("imapOperation is not nil")
			if self.isInImapOperation {
				NSLog("is in ImapOperation")
				self.imapOperation!.cancel()
			}
		}
		
		if self.smtpOperation != nil {
			NSLog("smtpOperation is not nil")
			if self.isInSmtpOperation {
				NSLog("is in SmtpOperation")
				self.smtpOperation!.cancel()
			}
		}
		
		let doneButton: UIBarButtonItem = UIBarButtonItem(title: "Done  ", style: .Plain, target: self, action: "doneTapped:")
		self.navigationItem.rightBarButtonItem = doneButton
	}
	
	@IBAction func doneTapped(sender: AnyObject) -> Void {
		
		self.navigationItem.rightBarButtonItem?.enabled = false
		let doneButton = self.navigationItem.rightBarButtonItem
		
		// end textfield editing
		if (self.selectedTextfield != nil) {
			self.textFieldShouldReturn(self.selectedTextfield!)
		}
		
		// complete data if simpleWizard
		if self.isSimpleWizard {
			if !completeAccountData() {
				let alert = UIAlertController(title: "Error", message: "Could not automatically get the right settings!", preferredStyle: UIAlertControllerStyle.Alert)
				alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { action in
					self.isSimpleWizard = false
					self.navigationItem.rightBarButtonItem?.enabled = true
					self.tableView.reloadData()
					return
				}))
			}
		}
		
		
		for (key, _) in self.entriesChecked{
			self.entriesChecked[key] = false
		}
		self.tableView.reloadData()
		if self.allEntriesSet() {
			
			// check if duplicate account emailaddress and return if so
			if self.checkIfDuplicateAccountMailAddress() {
				let alert = UIAlertController(title: "Duplicate", message: "An account with address: \"" + self.entries["Mailaddress:"]!.lowercaseString + "\" already exists!", preferredStyle: UIAlertControllerStyle.Alert)
				alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { action in }))
				
				self.presentViewController(alert, animated: true, completion: nil)
				self.navigationItem.rightBarButtonItem?.enabled = true
				return
			}
			
			// check if duplicate accountname and return if so
			if self.checkIfDuplicateAccountName() {
				let alert = UIAlertController(title: "Duplicate", message: "An account with name: \"" + self.entries["Accountname:"]! + "\" already exists!", preferredStyle: UIAlertControllerStyle.Alert)
				alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { action in }))
				
				self.presentViewController(alert, animated: true, completion: nil)
				self.navigationItem.rightBarButtonItem?.enabled = true
				return
			}
			
			
			
			
			let stopButton: UIBarButtonItem = UIBarButtonItem(title: "Stop ", style: .Plain, target: self, action: "stopTapped:")
			stopButton.tintColor = UIColor.redColor()
			self.navigationItem.rightBarButtonItem = stopButton
			
			// test the imap connection
			self.imapOperation = self.getImapOperation()
			self.isInImapOperation = true
			self.imapOperation!.start({(NSError error) in
				self.isInImapOperation = false
				if (error != nil) {
					self.navigationItem.rightBarButtonItem = doneButton
					NSLog("can't establish Imap connection: %@", error)
					let alert = UIAlertController(title: "Error", message: "Your Properties for IMAP seem to be wrong!", preferredStyle: UIAlertControllerStyle.Alert)
					alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { action in
						self.navigationItem.rightBarButtonItem?.enabled = true
						self.isSimpleWizard = false
						self.loadAccountDetails()
						self.tableView.reloadData()
						return
					}))
					alert.addAction(UIAlertAction(title: "Save anyway!", style: .Cancel, handler: { action in
						self.isActivated = false
						self.saveEntriesToCoreData()
						self.setValueThatAppHasRunOnce()
						self.navigationController?.popViewControllerAnimated(true)
					}))
					
					self.presentViewController(alert, animated: true, completion: nil)
					
				} else {
					// imap connection valid -> test the smtp connection
					print("Imap connection valid")
					self.entriesChecked["IMAP Hostname:"] = true
					self.entriesChecked["IMAP Port:"] = true
					self.entriesChecked["Username:"] = true
					self.entriesChecked["Password:"] = true
					self.entriesChecked["IMAP Auth:"] = true
					self.entriesChecked["IMAP ConType:"] = true
					self.tableView.reloadData()
					self.smtpOperation = self.getSmtpOperation()
					self.isInSmtpOperation = true
					self.smtpOperation!.start({(NSError error) in
						self.isInSmtpOperation = false
						if (error != nil) {
							self.navigationItem.rightBarButtonItem = doneButton
							NSLog("can't establish Smpt connection: %@", error)
							let alert = UIAlertController(title: "Error", message: "Your Properties for SMTP seem to be wrong!", preferredStyle: UIAlertControllerStyle.Alert)
							alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { action in
								self.navigationItem.rightBarButtonItem?.enabled = true
								self.isSimpleWizard = false
								self.loadAccountDetails()
								self.tableView.reloadData()
								return
							}))
							alert.addAction(UIAlertAction(title: "Save anyway!", style: .Cancel, handler: { action in
								self.isActivated = false
								self.saveEntriesToCoreData()
								self.setValueThatAppHasRunOnce()
								self.navigationController?.popViewControllerAnimated(true)
							}))
							
							self.presentViewController(alert, animated: true, completion: nil)
							
							
						} else {
							// imap and smtp connections returned valid
							if self.isSimpleWizard {
								self.isActivated = true
							}
							
							self.navigationItem.rightBarButtonItem = doneButton
							print("Smpt connection valid")
							self.entriesChecked["IMAP Hostname:"] = true
							self.entriesChecked["IMAP Port:"] = true
							self.entriesChecked["Username:"] = true
							self.entriesChecked["Password:"] = true
							self.entriesChecked["IMAP Auth:"] = true
							self.entriesChecked["IMAP ConType:"] = true
							self.entriesChecked["SMTP Hostname:"] = true
							self.entriesChecked["SMTP Port:"] = true
							self.entriesChecked["Username:"] = true
							self.entriesChecked["Password:"] = true
							self.entriesChecked["SMTP Auth:"] = true
							self.entriesChecked["SMTP ConType:"] = true
							self.tableView.reloadData()
							
							// write | update entity
							self.saveEntriesToCoreData()
							if self.newEmailAcc != nil {
                                do {
                                    try createNewSession(self.newEmailAcc!)
                                } catch _ {
                                    print("Could not create new imapsession for new emailaccount!")
                                }
//								createNewSession(self.newEmailAcc!)
							}
							
							
							self.delay(1.0) {
								self.setValueThatAppHasRunOnce()
								self.navigationController?.popViewControllerAnimated(true)
							}
						}
					})
					
				}
			})
			
		} else {
			
			self.navigationItem.rightBarButtonItem = doneButton
			self.navigationItem.rightBarButtonItem?.enabled = true
		}
	}
	
	func checkAllTextfieldsFilled() {
		for var section = 0; section < self.tableView.numberOfSections; section++ {
			for var row = 0; row < self.tableView.numberOfRowsInSection(section); row++ {
				let cellPath = NSIndexPath(forRow: row, inSection: section)
				if let cell = self.tableView.cellForRowAtIndexPath(cellPath) as? PreferenceAccountTableViewCell {
					
					if cell.textfield.text!.isEmpty {
						if cell.labelCellContent.text == "Signature:" {}
						else if cell.labelCellContent.text == "Activate:" {}
						else if cell.labelCellContent.text == "Advanced" {}
						else {
							cell.labelCellContent.attributedText = NSAttributedString(string: cell.labelCellContent.text!, attributes: [NSForegroundColorAttributeName: UIColor.redColor()])
						}
					}
					else {
						cell.labelCellContent.attributedText = NSAttributedString(string: cell.labelCellContent.text!, attributes: [NSForegroundColorAttributeName: UIColor.blackColor()])
						
					}
				}
			}
		}
	}


	func saveEntriesToCoreData() {
		let appDel: AppDelegate = (UIApplication.sharedApplication().delegate as! AppDelegate)
		let context: NSManagedObjectContext = appDel.managedObjectContext!
		
		if self.actionItem?.emailAddress == "Add New Account" {
			let newEntry = NSEntityDescription.insertNewObjectForEntityForName("EmailAccount", inManagedObjectContext: context) as!EmailAccount
			
			for (key, value) in self.entries {
				switch key {
				case "Mailaddress:": 		newEntry.setValue(value.lowercaseString, forKey: "emailAddress")
				case "Realname:":			newEntry.setValue(value, forKey: "realName")
				case "Accountname:":		newEntry.setValue(value, forKey: "accountName")
				case "Username:": 			newEntry.setValue(value, forKey: "username")
				case "Signature:":			newEntry.setValue(value, forKey: "signature")
				case "Password:":
					newEntry.setValue("*", forKey: "password")
					// assure to create key for useraccount
                    do {
                        try Locksmith.deleteDataForUserAccount(self.entries["Mailaddress:"]!)
                    } catch _ {
                        print("Locksmitherror while trying to delete data for useraccount")
                    }
//					let errorLocksmithNewAccount = Locksmith.deleteDataForUserAccount(self.entries["Mailaddress:"]!)
//					if errorLocksmithNewAccount == nil {
//						NSLog("found old data -> deleted!")
//					}
					// save password to iOS keychain
//					let NewSaveRequest = LocksmithRequest(userAccount: self.entries["Mailaddress:"]!, requestType: .Create, data: [key: value])
//					NewSaveRequest.accessible = .AfterFirstUnlockThisDeviceOnly
//					let (NewDictionary, NewRequestError) = Locksmith.performRequest(NewSaveRequest)
//					if NewRequestError == nil {
//						NSLog("saving data for " + self.entries["Mailaddress:"]!)
//					} else {
//						NSLog("could not save data for " + self.entries["Mailaddress:"]!)
//					}
                    do {
                        try Locksmith.saveData([key: value], forUserAccount: self.entries["Mailaddress:"]!)
                    } catch _ {
                        let account = self.entries["Mailaddress"]!
                        print("could not save data for \(account)")
                    }
					
				case "IMAP Hostname:": 		newEntry.setValue(value, forKey: "imapHostname")
				case "IMAP Port:": 			newEntry.setValue(Int(value), forKey: "imapPort")
				case "IMAP Auth:":			newEntry.setValue(value, forKey: "authTypeImap")
				case "IMAP ConType:":		newEntry.setValue(value, forKey: "connectionTypeImap")
				case "SMTP Hostname:": 		newEntry.setValue(value, forKey: "smtpHostname")
				case "SMTP Port:": 			newEntry.setValue(Int(value), forKey: "smtpPort")
				case "SMTP Auth:": 			newEntry.setValue(value, forKey: "authTypeSmtp")
				case "SMTP ConType:":		newEntry.setValue(value, forKey: "connectionTypeSmtp")
				default: break
				}
			}
			newEntry.setValue(self.isActivated, forKey: "isActivated")
			// save initial account behavoir
			newEntry.setValue("", forKey: "draftFolder")
			newEntry.setValue("", forKey: "sentFolder")
			newEntry.setValue("", forKey: "deletedFolder")
			newEntry.setValue("", forKey: "archiveFolder")
			newEntry.setValue("One month", forKey: "downloadMailDuration")
			
			self.newEmailAcc = newEntry
			
		} else {
			
			let fetchRequest = NSFetchRequest(entityName: "EmailAccount")
			fetchRequest.predicate = NSPredicate(format: "emailAddress = %@", self.emailAcc!.emailAddress)
			
			if let fetchResults = (try? appDel.managedObjectContext!.executeFetchRequest(fetchRequest)) as? [NSManagedObject] {
				if fetchResults.count != 0{
					
					let managedObject = fetchResults[0] as! EmailAccount
					
					for (key, value) in self.entries {
						switch key {
						case "Mailaddress:": 		managedObject.setValue(value.lowercaseString, forKey: "emailAddress")
						case "Realname:":			managedObject.setValue(value, forKey: "realName")
						case "Accountname:":		managedObject.setValue(value, forKey: "accountName")
						case "Username:": 			managedObject.setValue(value, forKey: "username")
						case "Signature:":			managedObject.setValue(value, forKey: "signature")
						case "Password:":
							managedObject.setValue("*", forKey: "password")
							// assure to create key for useraccount
                            do {
                                try Locksmith.deleteDataForUserAccount(self.entries["Mailaddress:"]!)
                            } catch _ {
                                print("found old data -> deleted!")
                            }
                            
//							let errorLocksmithUpdateAccount = Locksmith.deleteDataForUserAccount(self.entries["Mailaddress:"]!)
//							if errorLocksmithUpdateAccount == nil {
//								NSLog("found old data -> deleted!")
//							}
							// save data to iOS keychain
//							let NewSaveRequest = LocksmithRequest(userAccount: self.entries["Mailaddress:"]!, requestType: .Create, data: [key: value])
//							NewSaveRequest.accessible = .AfterFirstUnlockThisDeviceOnly
//							let (NewDictionary, NewRequestError) = Locksmith.performRequest(NewSaveRequest)
//							if NewRequestError == nil {
//								NSLog("saving data for " + self.entries["Mailaddress:"]!)
//							} else {
//								NSLog("could not save data for " + self.entries["Mailaddress:"]!)
//							}
                            do {
                                try Locksmith.saveData([key: value], forUserAccount: self.entries["Mailaddress:"]!)
                            } catch _ {
                                let mailaddress = self.entries["Mailaddress:"]!
                                print("could not save data for \(mailaddress)")
                            }

						case "IMAP Hostname:": 		managedObject.setValue(value, forKey: "imapHostname")
						case "IMAP Port:": 			managedObject.setValue(Int(value), forKey: "imapPort")
						case "IMAP Auth:":			managedObject.setValue(value, forKey: "authTypeImap")
						case "IMAP ConType:":		managedObject.setValue(value, forKey: "connectionTypeImap")
						case "SMTP Hostname:": 		managedObject.setValue(value, forKey: "smtpHostname")
						case "SMTP Port:": 			managedObject.setValue(Int(value), forKey: "smtpPort")
						case "SMTP Auth:": 			managedObject.setValue(value, forKey: "authTypeSmtp")
						case "SMTP ConType:":		managedObject.setValue(value, forKey: "connectionTypeSmtp")
						default: break
						}
					}
					managedObject.setValue(self.isActivated, forKey: "isActivated")
					// save account behavior selections
					if self.accountBehaviorVC != nil {
						managedObject.setValue(self.accountBehaviorVC!.entries["Drafts"], forKey: "draftFolder")
						managedObject.setValue(self.accountBehaviorVC!.entries["Sent"], forKey: "sentFolder")
						managedObject.setValue(self.accountBehaviorVC!.entries["Deleted"], forKey: "deletedFolder")
						managedObject.setValue(self.accountBehaviorVC!.entries["Archive"], forKey: "archiveFolder")
						managedObject.setValue(self.accountBehaviorVC!.entries["Download mails for:"], forKey: "downloadMailDuration")
					}
					
					self.newEmailAcc = managedObject

				}
			}
		}
		do {
			try context.save()
		} catch _ {
		}
	}
	
	
	func allEntriesSet() -> Bool {
		for (key, value) in self.entries {
			if key == "Activate:" || key == "Signature:" {
				
			} else {
				if value == "" {
					checkAllTextfieldsFilled()
					return false
				}
			}
		}
		checkAllTextfieldsFilled()
		return true
	}
	
	func checkIfDuplicateAccountMailAddress() -> Bool {
		if !self.allAccounts.isEmpty {
			
			// save if same account is just edited
			if self.entries["Mailaddress:"] == emailAcc?.emailAddress {
				return false
			}
			
			for account in self.allAccounts {
				
				if account.emailAddress.lowercaseString == self.entries["Mailaddress:"]!.lowercaseString {
					return true
				}
			}
		}
		return false
	}
	
	func completeAccountData() -> Bool {
		if let sessionSettings = getSessionPreferences(self.entries["Mailaddress:"]!) {
			self.entries["IMAP Hostname:"] = sessionSettings.imapHostname
			self.entries["IMAP Port:"] = String(sessionSettings.imapPort)
			self.entries["IMAP Auth:"] = authTypeToString(sessionSettings.imapAuthType)
			self.entries["IMAP ConType:"] = connectionTypeToString(sessionSettings.imapConType)
			
			self.entries["SMTP Hostname:"] = sessionSettings.smtpHostname
			self.entries["SMTP Port:"] = String(sessionSettings.smtpPort)
			self.entries["SMTP Auth:"] = authTypeToString(sessionSettings.smtpAuthType)
			self.entries["SMTP ConType:"] = connectionTypeToString(sessionSettings.smtpConType)
			return true
		} else {
			return false
		}
	}
	
	func checkIfDuplicateAccountName() -> Bool {
		if !self.allAccounts.isEmpty {
			
			// save if same account is just edited
			if self.entries["Accountname:"]! == emailAcc?.accountName {
				return false
			}
			
			for account in self.allAccounts {
				
				if account.accountName.lowercaseString == self.entries["Accountname:"]!.lowercaseString {
					return true
				}
			}
		}
		return false
	}

	func getImapOperation() -> MCOIMAPOperation {
		
		let session = MCOIMAPSession()
		session.hostname = self.entries["IMAP Hostname:"]
		session.port = uint(Int(self.entries["IMAP Port:"]!)!)
		session.username = self.entries["Username:"]
		session.password = self.entries["Password:"]
		session.connectionType = StringToConnectionType(self.entries["IMAP ConType:"]!)
		session.authType = StringToAuthType(self.entries["IMAP Auth:"]!)
		let op = session.checkAccountOperation()
		return op!
		
	}
	
	func getSmtpOperation() -> MCOSMTPOperation {
		let session = MCOSMTPSession()
		session.hostname = self.entries["SMTP Hostname:"]
		session.port = uint(Int(self.entries["SMTP Port:"]!)!)
		session.username = self.entries["Username:"]
		session.password = self.entries["Password:"]
		session.connectionType = StringToConnectionType(self.entries["SMTP ConType:"]!)
		session.authType = StringToAuthType(self.entries["SMTP Auth:"]!)
		let address: MCOAddress = MCOAddress(mailbox: self.entries["Mailaddress:"])
		let op = session.checkAccountOperationWithFrom(address)
		return op
	}
	
	
	
	func textFieldDidBeginEditing(textField: UITextField) {
		self.selectedTextfield = textField
		let cellView = textField.superview
		let cell = cellView?.superview as! PreferenceAccountTableViewCell
		let indexPath = self.tableView.indexPathForCell(cell)
		self.selectedIndexPath = indexPath
	}
	
	func textFieldDidEndEditing(textField: UITextField) {
		if textField.placeholder! == "Mailaddress:" {
			// check if mail address
			if !(textField.text!.rangeOfString("@") != nil) {
				textField.text = ""
			}
		}
		
		// check if port entries are numbers
		if textField.placeholder! == "IMAP Port:" || textField.placeholder! == "SMTP Port:" {
			if Int(textField.text!) == nil {
				textField.text = ""
			}
		}
		// save data to entries
		self.entries[textField.placeholder!] = textField.text
		self.entriesChecked[textField.placeholder!] = false
		self.selectedTextfield = nil
		self.selectedIndexPath = nil
	}
	
	// return on keyboard is triggered
	func textFieldShouldReturn(textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
	
	// end editing when tapping somewhere in the view
	override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
		self.view.endEditing(true)
	}
	
	// add keyboard size to tableView size
	func keyboardWillShow(notification: NSNotification) {
		if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue().size {
			let contentInsets = UIEdgeInsetsMake(self.navigationController!.navigationBar.frame.size.height + UIApplication.sharedApplication().statusBarFrame.size.height, 0.0, keyboardSize.height, 0.0)
			
			if self.origintableViewInsets == nil {
				self.origintableViewInsets = self.tableView.contentInset
			}
			
			self.tableView.contentInset = contentInsets
			self.tableView.scrollIndicatorInsets = contentInsets
			if self.selectedIndexPath != nil {
				self.tableView.scrollToRowAtIndexPath(self.selectedIndexPath!, atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
			}
		}
		
	}
	// bring tableview size back to origin
	func keyboardWillHide(notification: NSNotification) {
		if let animationDuration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double) {
			if self.origintableViewInsets != nil {
				UIView.animateWithDuration(animationDuration, animations: { () -> Void in
					self.tableView.contentInset = self.origintableViewInsets!
					self.tableView.scrollIndicatorInsets = self.origintableViewInsets!
				})
			}
		}
	}
	
	// set value if switchstate has changed
	func stateChanged(switchState: UISwitch) {
		self.isActivated = switchState.on
	}
	
	// delay block for seconds
	func delay(delay:Double, closure:()->()) {
		dispatch_after(
			dispatch_time(
				DISPATCH_TIME_NOW,
				Int64(delay * Double(NSEC_PER_SEC))
			),
			dispatch_get_main_queue(), closure)
	}
	
	func activateToolbarItems() {
		// set toolbar
		let expertButton: UIBarButtonItem = UIBarButtonItem(title: "Expert Mode  ", style: .Plain, target: self, action: "expertTapped:")
		let items = [UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil), expertButton]
		self.navigationController?.visibleViewController!.setToolbarItems(items, animated: false)
	}
	
	func notificationSent() {
		NSLog("PreferenceEditAccountTableViewController: Update Notification sent!")
	}
	
}
