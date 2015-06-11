//
//  PreferenceEditAccountTableViewController.swift
//  FixMyMail
//
//  Created by Sebastian Thürauf on 02.06.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit
import CoreData

class PreferenceEditAccountTableViewController: UITableViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
	
	var emailAcc: EmailAccount?
	var newEmailAcc: EmailAccount?
	var actionItem: ActionItem?
	var managedObjectContext: NSManagedObjectContext!
	var sections = [String]()
	var labelAccountDetailString = [String]()
	var labelImapConnectionDetailString = [String]()
	var labelSmtpConnectionDetailString = [String]()
	var cellAccountTextfielString = [String]()
	var cellImapConnectionTextfielString = [String]()
	var cellSmtpConnectionTextfielString = [String]()
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
	var origintableViewInsets: UIEdgeInsets?
	var isActivated: Bool?
	
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		loadAccountDetails()
		
		tableView.registerNib(UINib(nibName: "PreferenceAccountTableViewCell", bundle: nil),forCellReuseIdentifier:"PreferenceAccountCell")
		tableView.registerNib(UINib(nibName: "SwitchTableViewCell", bundle: nil), forCellReuseIdentifier: "SwitchTableViewCell")
		self.navigationItem.title = actionItem?.emailAddress
		var doneButton: UIBarButtonItem = UIBarButtonItem(title: "Done  ", style: .Plain, target: self, action: "doneTapped:")
		self.navigationItem.rightBarButtonItem = doneButton
		self.sections = ["Account Details:", "IMAP Details", "SMTP Details:", "",""]
		
		// set alert dialog for delete
		alert = UIAlertController(title: "Delete", message: "Really delete account?", preferredStyle: UIAlertControllerStyle.Alert)
		self.alert!.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { action in
			// save data to CoreData (respectively deleting data from CoreData)
			var appDel: AppDelegate = (UIApplication.sharedApplication().delegate as! AppDelegate)
			var context: NSManagedObjectContext = appDel.managedObjectContext!
			var fetchRequest = NSFetchRequest(entityName: "EmailAccount")
			fetchRequest.predicate = NSPredicate(format: "emailAddress = %@", self.emailAcc!.emailAddress)
			
			if let fetchResults = appDel.managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [NSManagedObject] {
				if fetchResults.count != 0{
					
					var managedObject = fetchResults[0]
					context.deleteObject(managedObject)
				}
			}
			
			context.save(nil)
			// delete Password from iOS Keychain
			let errorLocksmith = Locksmith.deleteDataForUserAccount(self.entries["Mailaddress:"]!)
			if errorLocksmith == nil {
				NSLog("deleting data")
			}
			
			// ###### only for dev testing, DELETE before release!!!!!!!! #######
			let (dictionary, error) = Locksmith.loadDataForUserAccount(self.entries["Mailaddress:"]!)
			if error == nil {
				var value = dictionary?.valueForKey("Password:") as! String
				self.entries["Password:"] = value
				NSLog("loaded value: \(value)")
			} else {
				NSLog("no data for userid found")
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
		
		var labelString = self.labels[indexPath.section][indexPath.row] as! String
		var textfieldString = self.entries[labelString]
		
		// if auth or con cell -> load AuthConTableViewController
		if labelString == "IMAP Auth:" || labelString == "SMTP Auth:"  ||
			labelString == "IMAP ConType:" ||  labelString == "SMTP ConType:" {
				self.authConVC = AuthConTableViewController(nibName:"AuthConTableViewController", bundle: nil)
				self.authConVC!.labelPreviousVC = labelString
				self.authConVC!.selectedString = textfieldString!
				self.navigationController?.pushViewController(self.authConVC!, animated: true)
		}
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
		
		// show alert dialog if delete is tapped
		if self.labels[indexPath.section][indexPath.row] as? String == "DELETE" {
			self.presentViewController(self.alert!, animated: true, completion: nil)
		}
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		var labelString = self.labels[indexPath.section][indexPath.row] as? String
		// decide witch cell must be loaded
		if labelString == "Activate:" {
			let cell = tableView.dequeueReusableCellWithIdentifier("SwitchTableViewCell", forIndexPath: indexPath) as! SwitchTableViewCell
			
			cell.label.text = labelString
			cell.activateSwitch.addTarget(self, action: Selector("stateChanged:"), forControlEvents: UIControlEvents.ValueChanged)
			
			// get the emailAcc.isActivated value only once
			if self.isActivated == nil {
				if emailAcc != nil {
					cell.activateSwitch.on = emailAcc!.isActivated
					self.isActivated = emailAcc?.isActivated
				} else {
					cell.activateSwitch.on = false
					self.isActivated = false
				}
			} else {
				cell.activateSwitch.on = self.isActivated!
			}
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
			} else {
				cell.textfield.enabled = true
			}
			
			// fill the textfields
			cell.textfield.text = self.entries[cell.labelCellContent.text!]
			cell.labelCellContent.textAlignment = NSTextAlignment.Left
			self.entriesChecked[cell.labelCellContent.text!] = false
			
			if emailAcc != nil {
				// configure delete cell
				if cell.labelCellContent.text == deleteString[0] {
					cell.labelCellContent.textAlignment = NSTextAlignment.Center
					cell.labelCellContent.attributedText = NSAttributedString(string: cell.labelCellContent.text!, attributes: [NSForegroundColorAttributeName: UIColor.redColor()])
					cell.textfield.text = ""
					cell.textfield.placeholder = ""
					cell.textfield.enabled = false
					self.entries.removeValueForKey(self.deleteString[0])
					self.entriesChecked.removeValueForKey(self.deleteString[0])
				}
			}
			
			return cell
		}
		
	}
	
	
	/*
	// Override to support conditional editing of the table view.
	override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
	// Return NO if you do not want the specified item to be editable.
	return true
	}
	*/
	
	/*
	// Override to support editing the table view.
	override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
	if editingStyle == .Delete {
	// Delete the row from the data source
	tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
	} else if editingStyle == .Insert {
	// Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
	}
	}
	*/
	
	/*
	// Override to support rearranging the table view.
	override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
	
	}
	*/
	
	/*
	// Override to support conditional rearranging of the table view.
	override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
	// Return NO if you do not want the item to be re-orderable.
	return true
	}
	*/
	
	/*
	// MARK: - Navigation
	
	// In a storyboard-based application, you will often want to do a little preparation before navigation
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
	// Get the new view controller using [segue destinationViewController].
	// Pass the selected object to the new view controller.
	}
	*/
	
	func loadAccountDetails() {
		
		self.labelAccountDetailString.append("Mailaddress:")
		self.labelAccountDetailString.append("Realname:")
		self.labelAccountDetailString.append("Accountname:")
		self.labelAccountDetailString.append("Username:")
		self.labelAccountDetailString.append("Password:")
		
		self.labelImapConnectionDetailString.append("IMAP Hostname:")
		self.labelImapConnectionDetailString.append("IMAP Port:")
		self.labelImapConnectionDetailString.append("IMAP Auth:")
		self.labelImapConnectionDetailString.append("IMAP ConType:")
		
		self.labelSmtpConnectionDetailString.append("SMTP Hostname:")
		self.labelSmtpConnectionDetailString.append("SMTP Port:")
		self.labelSmtpConnectionDetailString.append("SMTP Auth:")
		self.labelSmtpConnectionDetailString.append("SMTP ConType:")
		
		if emailAcc != nil {
			self.cellAccountTextfielString.append(emailAcc!.emailAddress)
			self.cellAccountTextfielString.append(emailAcc!.realName)
			self.cellAccountTextfielString.append(emailAcc!.accountName)
			self.cellAccountTextfielString.append(emailAcc!.username)
			self.cellAccountTextfielString.append(emailAcc!.password)
			
			self.cellImapConnectionTextfielString.append(emailAcc!.imapHostname)
			self.cellImapConnectionTextfielString.append(String(Int(emailAcc!.imapPort)))
			self.cellImapConnectionTextfielString.append(emailAcc!.authTypeImap)
			self.cellImapConnectionTextfielString.append(emailAcc!.connectionTypeImap)
			
			self.cellSmtpConnectionTextfielString.append(emailAcc!.smtpHostname)
			self.cellSmtpConnectionTextfielString.append(String(Int(emailAcc!.smtpPort)))
			self.cellSmtpConnectionTextfielString.append(emailAcc!.authTypeSmtp)
			self.cellSmtpConnectionTextfielString.append(emailAcc!.connectionTypeSmtp)
			
			self.entries["Mailaddress:"] = emailAcc!.emailAddress
			self.entries["Realname:"] = emailAcc!.realName
			self.entries["Accountname:"] = emailAcc!.accountName
			self.entries["Username:"] = emailAcc!.username
			
			// load password for account from iOS keychain
			let (dictionary, error) = Locksmith.loadDataForUserAccount(self.entries["Mailaddress:"]!)
			if error == nil {
				var value = dictionary?.valueForKey("Password:") as! String
				self.entries["Password:"] = value
				NSLog("loaded value from keychain")
			}
			
			self.entries["IMAP Hostname:"] = emailAcc!.imapHostname
			self.entries["IMAP Port:"] = String(Int(emailAcc!.imapPort))
			self.entries["IMAP Auth:"] = emailAcc!.authTypeImap
			self.entries["IMAP ConType:"] = emailAcc!.connectionTypeImap
			
			self.entries["SMTP Hostname:"] = emailAcc!.smtpHostname
			self.entries["SMTP Port:"] = String(Int(emailAcc!.smtpPort))
			self.entries["SMTP Auth:"] = emailAcc!.authTypeSmtp
			self.entries["SMTP ConType:"] = emailAcc!.connectionTypeSmtp
		} else {
			self.entries["Mailaddress:"] = ""
			self.entries["Realname:"] = ""
			self.entries["Accountname:"] = ""
			self.entries["Username:"] = ""
			self.entries["Password:"] = ""
			
			self.entries["IMAP Hostname:"] = ""
			self.entries["IMAP Port:"] = ""
			self.entries["IMAP Auth:"] = ""
			self.entries["IMAP ConType:"] = ""
			
			self.entries["SMTP Hostname:"] = ""
			self.entries["SMTP Port:"] = ""
			self.entries["SMTP Auth:"] = ""
			self.entries["SMTP ConType:"] = ""
		}
		
		if actionItem?.emailAddress != "Add New Account" {
			self.deleteString.append("DELETE")
		}
		
		self.isActivatedString.append("Activate:")
		
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
	
	@IBAction func doneTapped(sender: AnyObject) -> Void {
		
		self.navigationItem.rightBarButtonItem?.enabled = false
		
		// check if textfields are empty
		if (self.selectedTextfield != nil) {
			self.textFieldShouldReturn(self.selectedTextfield!)
		}
		
		for (key, value) in self.entriesChecked{
			self.entriesChecked[key] = false
		}
		self.tableView.reloadData()
		if self.allEntriesSet() {
			// test the imap connection
			var imapOperation = self.getImapOperation()
			imapOperation.start({(NSError error) in
				if (error != nil) {
					NSLog("can't establish Imap connection: %@", error)
					var alert = UIAlertController(title: "Error", message: "Your Properties for IMAP seem to be wrong!", preferredStyle: UIAlertControllerStyle.Alert)
					alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { action in }))
					self.presentViewController(alert, animated: true, completion: nil)
					self.navigationItem.rightBarButtonItem?.enabled = true
					return
					
					
				} else {
					// imap connection valid -> test the smtp connection
					println("Imap connection valid")
					self.entriesChecked["IMAP Hostname:"] = true
					self.entriesChecked["IMAP Port:"] = true
					self.entriesChecked["Username:"] = true
					self.entriesChecked["Password:"] = true
					self.entriesChecked["IMAP Auth:"] = true
					self.entriesChecked["IMAP ConType:"] = true
					self.tableView.reloadData()
					var smtpOperation = self.getSmtpOperation()
					smtpOperation.start({(NSError error) in
						if (error != nil) {
							NSLog("can't establish Smpt connection: %@", error)
							var alert = UIAlertController(title: "Error", message: "Your Properties for SMTP seem to be wrong!", preferredStyle: UIAlertControllerStyle.Alert)
							alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { action in }))
							self.presentViewController(alert, animated: true, completion: nil)
							self.navigationItem.rightBarButtonItem?.enabled = true
							return
							
							
						} else {
							// imap and smtp connections returned valid
							println("Smpt connection valid")
							self.entriesChecked["SMTP Hostname:"] = true
							self.entriesChecked["SMTP Port:"] = true
							self.entriesChecked["Username:"] = true
							self.entriesChecked["Password:"] = true
							self.entriesChecked["SMTP Auth:"] = true
							self.entriesChecked["SMTP ConType:"] = true
							self.tableView.reloadData()
							// write | update entity
							var appDel: AppDelegate = (UIApplication.sharedApplication().delegate as! AppDelegate)
							var context: NSManagedObjectContext = appDel.managedObjectContext!
							
							if self.actionItem?.emailAddress == "Add New Account" {
								var newEntry = NSEntityDescription.insertNewObjectForEntityForName("EmailAccount", inManagedObjectContext: context) as!EmailAccount
								
								for (key, value) in self.entries {
									switch key {
									case "Mailaddress:": 		newEntry.setValue(value, forKey: "emailAddress")
									case "Realname:":			newEntry.setValue(value, forKey: "realName")
									case "Accountname:":		newEntry.setValue(value, forKey: "accountName")
									case "Username:": 			newEntry.setValue(value, forKey: "username")
									case "Password:":
										newEntry.setValue("*", forKey: "password")
										let errorLocksmith = Locksmith.saveData([key: value], forUserAccount: self.entries["Mailaddress:"]!)
										if errorLocksmith == nil {
											println("saving data")
										}
									case "IMAP Hostname:": 		newEntry.setValue(value, forKey: "imapHostname")
									case "IMAP Port:": 			newEntry.setValue(value.toInt(), forKey: "imapPort")
									case "IMAP Auth:":			newEntry.setValue(value, forKey: "authTypeImap")
									case "IMAP ConType:":		newEntry.setValue(value, forKey: "connectionTypeImap")
									case "SMTP Hostname:": 		newEntry.setValue(value, forKey: "smtpHostname")
									case "SMTP Port:": 			newEntry.setValue(value.toInt(), forKey: "smtpPort")
									case "SMTP Auth:": 			newEntry.setValue(value, forKey: "authTypeSmtp")
									case "SMTP ConType:":		newEntry.setValue(value, forKey: "connectionTypeSmtp")
									default: break
									}
								}
								newEntry.setValue(self.isActivated, forKey: "isActivated")
								
							} else {
								
								var fetchRequest = NSFetchRequest(entityName: "EmailAccount")
								fetchRequest.predicate = NSPredicate(format: "emailAddress = %@", self.emailAcc!.emailAddress)
								
								if let fetchResults = appDel.managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [NSManagedObject] {
									if fetchResults.count != 0{
										
										var managedObject = fetchResults[0]
										
										for (key, value) in self.entries {
											switch key {
											case "Mailaddress:": 		managedObject.setValue(value, forKey: "emailAddress")
											case "Realname:":			managedObject.setValue(value, forKey: "realName")
											case "Accountname:":		managedObject.setValue(value, forKey: "accountName")
											case "Username:": 			managedObject.setValue(value, forKey: "username")
											case "Password:":
												managedObject.setValue("*", forKey: "password")
												let errorLocksmith = Locksmith.updateData([key: value], forUserAccount: self.entries["Mailaddress:"]!)
												if errorLocksmith == nil {
													NSLog("saving data")
												}
											case "IMAP Hostname:": 		managedObject.setValue(value, forKey: "imapHostname")
											case "IMAP Port:": 			managedObject.setValue(value.toInt(), forKey: "imapPort")
											case "IMAP Auth:":			managedObject.setValue(value, forKey: "authTypeImap")
											case "IMAP ConType:":		managedObject.setValue(value, forKey: "connectionTypeImap")
											case "SMTP Hostname:": 		managedObject.setValue(value, forKey: "smtpHostname")
											case "SMTP Port:": 			managedObject.setValue(value.toInt(), forKey: "smtpPort")
											case "SMTP Auth:": 			managedObject.setValue(value, forKey: "authTypeSmtp")
											case "SMTP ConType:":		managedObject.setValue(value, forKey: "connectionTypeSmtp")
											default: break
											}
										}
										managedObject.setValue(self.isActivated, forKey: "isActivated")
									}
								}
							}
							context.save(nil)
							self.navigationController?.popViewControllerAnimated(true)
						}
					})
					
				}
			})
			
		}
			
		else {
			self.navigationItem.rightBarButtonItem?.enabled = true
		}
	}
	
	func checkAllTextfieldsFilled() {
		for var section = 0; section < self.tableView.numberOfSections(); section++ {
			for var row = 0; row < self.tableView.numberOfRowsInSection(section); row++ {
				var cellPath = NSIndexPath(forRow: row, inSection: section)
				if let cell = self.tableView.cellForRowAtIndexPath(cellPath) as? PreferenceAccountTableViewCell {
					if cell.labelCellContent.text != "Activate:" {
						if cell.textfield.text.isEmpty {
							cell.labelCellContent.attributedText = NSAttributedString(string: cell.labelCellContent.text!, attributes: [NSForegroundColorAttributeName: UIColor.redColor()])
						} else {
							cell.labelCellContent.attributedText = NSAttributedString(string: cell.labelCellContent.text!, attributes: [NSForegroundColorAttributeName: UIColor.blackColor()])
							
						}
					}
				}
			}
		}
	}
	
	func allEntriesSet() -> Bool {
		for (key, value) in self.entries {
			if key != "Activate:" {
				if value == "" {
					checkAllTextfieldsFilled()
					return false
				}
			}
		}
		checkAllTextfieldsFilled()
		return true
	}
	
	func getImapOperation() -> MCOIMAPOperation {
		
		var session = MCOIMAPSession()
		session.hostname = self.entries["IMAP Hostname:"]
		session.port = uint(self.entries["IMAP Port:"]!.toInt()!)
		session.username = self.entries["Username:"]
		session.password = self.entries["Password:"]
		var con = StringToConnectionType(self.entries["IMAP ConType:"]!)
		var auth = StringToAuthType(self.entries["IMAP Auth:"]!)
		session.connectionType = StringToConnectionType(self.entries["IMAP ConType:"]!)
		session.authType = StringToAuthType(self.entries["IMAP Auth:"]!)
		var address: MCOAddress = MCOAddress(mailbox: self.entries["Mailaddress:"])
		let op = session.checkAccountOperation()
		return op!
		
	}
	
	func getSmtpOperation() -> MCOSMTPOperation {
		var session = MCOSMTPSession()
		session.hostname = self.entries["SMTP Hostname:"]
		session.port = uint(self.entries["SMTP Port:"]!.toInt()!)
		session.username = self.entries["Username:"]
		session.password = self.entries["Password:"]
		session.connectionType = StringToConnectionType(self.entries["SMTP ConType:"]!)
		session.authType = StringToAuthType(self.entries["SMTP Auth:"]!)
		var address: MCOAddress = MCOAddress(mailbox: self.entries["Mailaddress:"])
		let op = session.checkAccountOperationWithFrom(address)
		return op
	}
	
	
	
	func textFieldDidBeginEditing(textField: UITextField) {
		self.selectedTextfield = textField
		var cellView = textField.superview
		var cell = cellView?.superview as! PreferenceAccountTableViewCell
		var indexPath = self.tableView.indexPathForCell(cell)
		self.selectedIndexPath = indexPath
	}
	
	func textFieldDidEndEditing(textField: UITextField) {
		if textField.placeholder! == "Mailaddress:" {
			// check if mail address
			if !(textField.text.rangeOfString("@") != nil) {
				textField.text = ""
			}
		}
		
		// check if port entries are numbers
		if textField.placeholder! == "IMAP Port:" || textField.placeholder! == "SMTP Port:" {
			if textField.text.toInt() == nil {
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
	override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
		self.view.endEditing(true)
	}
	
	// add keyboard size to tableView size
	func keyboardWillShow(notification: NSNotification) {
		if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue().size {
			var contentInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardSize.height, 0.0)
			
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
	
}
