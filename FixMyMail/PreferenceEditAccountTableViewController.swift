//
//  PreferenceEditAccountTableViewController.swift
//  FixMyMail
//
//  Created by Sebastian Thürauf on 02.06.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit
import CoreData

class PreferenceEditAccountTableViewController: UITableViewController, UITextFieldDelegate {
	
	var emailAcc: EmailAccount?
	var newEmailAcc: EmailAccount?
	var actionItem: ActionItem?
	var managedObjectContext: NSManagedObjectContext!
	var sections = [String]()
	var labelAccountDetailString = [String]()
	var labelConnectionDetailString = [String]()
	var cellAccountTextfielString = [String]()
	var cellConnectionTextfielString = [String]()
	var rows = [AnyObject]()
	var rowsEmail = [AnyObject]()
	var entries = [String: String]()
	var deleteString = [String]()
	var filledTextfieldCount: Int = 0
	var alert: UIAlertController?
	var selectedTextfield: UITextField?
	
        
    override func viewDidLoad() {
        super.viewDidLoad()
		
		loadAccountDetails()
		
		tableView.registerNib(UINib(nibName: "PreferenceAccountTableViewCell", bundle: nil),forCellReuseIdentifier:"PreferenceAccountCell")
		self.navigationItem.title = actionItem?.mailAdress
		var doneButton: UIBarButtonItem = UIBarButtonItem(title: "Done  ", style: .Plain, target: self, action: "doneTapped:")
		self.navigationItem.rightBarButtonItem = doneButton
		self.sections = ["Account Details:", "", "Connection Details:", ""]
		
		// set alert dialog
	    alert = UIAlertController(title: "Delete", message: "Really delete account?", preferredStyle: UIAlertControllerStyle.Alert)
		self.alert!.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { action in
			// save data to CoreData
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
			self.navigationController?.popViewControllerAnimated(true)
		}))
		
		self.alert!.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { action in
		}))
	
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
		
		
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
		return self.rows[section].count
	}
	
	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return self.sections[section]
	}

	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
		
		// show alert dialog
		if self.rows[indexPath.section][indexPath.row] as? String == "DELETE" {
			self.presentViewController(self.alert!, animated: true, completion: nil)
		}
	}
	
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PreferenceAccountCell", forIndexPath: indexPath) as! PreferenceAccountTableViewCell

        // Configure the cell...
		cell.textfield.delegate = self
		cell.labelCellContent.text = self.rows[indexPath.section][indexPath.row] as? String
		cell.textfield.placeholder = self.rows[indexPath.section][indexPath.row] as? String
	
		if emailAcc != nil {
			cell.textfield.text = self.rowsEmail[indexPath.section][indexPath.row] as! String
			cell.labelCellContent.textAlignment = NSTextAlignment.Left
			cell.textfield.enabled = true
			self.entries[cell.labelCellContent.text!] = cell.textfield.text
			
			// configure delete cell
			if cell.labelCellContent.text == deleteString[0] {
				cell.labelCellContent.textAlignment = NSTextAlignment.Center
				cell.labelCellContent.attributedText = NSAttributedString(string: cell.labelCellContent.text!, attributes: [NSForegroundColorAttributeName: UIColor.redColor()])
				cell.textfield.text = ""
				cell.textfield.placeholder = ""
				cell.textfield.enabled = false
				self.entries.removeValueForKey(deleteString[0])
			}
		}
		
        return cell
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
		self.labelAccountDetailString.append("Accountname:")
		self.labelAccountDetailString.append("Password:")
		self.labelConnectionDetailString.append("IMAP Hostname:")
		self.labelConnectionDetailString.append("IMAP Port:")
		self.labelConnectionDetailString.append("SMTP Hostname:")
		self.labelConnectionDetailString.append("SMTP Port:")
		
		if emailAcc != nil {
			self.cellAccountTextfielString.append(emailAcc!.emailAddress)
			self.cellAccountTextfielString.append(emailAcc!.username)
			self.cellAccountTextfielString.append(emailAcc!.password)
			self.cellConnectionTextfielString.append(emailAcc!.imapHostname)
			self.cellConnectionTextfielString.append(String(Int(emailAcc!.imapPort)))
			self.cellConnectionTextfielString.append(emailAcc!.smtpHostname)
			self.cellConnectionTextfielString.append(String(Int(emailAcc!.smtpPort)))
			
			self.entries["Mailaddress:"] = emailAcc!.emailAddress
			self.entries["Accountname:"] = emailAcc!.username
			self.entries["Password:"] = emailAcc!.password
			self.entries["IMAP Hostname:"] = emailAcc!.imapHostname
			self.entries["IMAP Port:"] = String(Int(emailAcc!.imapPort))
			self.entries["SMTP Hostname:"] = emailAcc!.smtpHostname
			self.entries["SMTP Port:"] = String(Int(emailAcc!.smtpPort))
		} else {
			self.entries["Mailaddress:"] = ""
			self.entries["Accountname:"] = ""
			self.entries["Password:"] = ""
			self.entries["IMAP Hostname:"] = ""
			self.entries["IMAP Port:"] = ""
			self.entries["SMTP Hostname:"] = ""
			self.entries["SMTP Port:"] = ""
		}
		
		if actionItem?.mailAdress != "Add New Account" {
			deleteString.append("DELETE")
		}
		
		rows.append(labelAccountDetailString)
		rows.append([])
		rows.append(labelConnectionDetailString)
		rows.append(deleteString)
		
		rowsEmail.append(cellAccountTextfielString)
		rowsEmail.append([])
		rowsEmail.append(cellConnectionTextfielString)
		rowsEmail.append(deleteString)
		
		
	}
	
	@IBAction func doneTapped(sender: AnyObject) -> Void {
		
		// check if textfields are empty
		if (self.selectedTextfield != nil) {
		self.textFieldShouldReturn(self.selectedTextfield!)
		}
		
		checkAllTextfieldsFilled()
		
		if filledTextfieldCount == labelAccountDetailString.count + labelConnectionDetailString.count {
			// write | update entity
			var appDel: AppDelegate = (UIApplication.sharedApplication().delegate as! AppDelegate)
			var context: NSManagedObjectContext = appDel.managedObjectContext!
			
			if actionItem?.mailAdress == "Add New Account" {
				var newEntry = NSEntityDescription.insertNewObjectForEntityForName("EmailAccount", inManagedObjectContext: context) as!EmailAccount
			
				for (key, value) in self.entries {
							switch key {
							case "Mailaddress:": 	newEntry.setValue(value, forKey: "emailAddress")
							case "Accountname:": 	newEntry.setValue(value, forKey: "username")
							case "Password:": 		newEntry.setValue(value, forKey: "password")
							case "IMAP Hostname:": 	newEntry.setValue(value, forKey: "imapHostname")
							case "IMAP Port:": 		newEntry.setValue(value.toInt(), forKey: "imapPort")
							case "SMTP Hostname:": 	newEntry.setValue(value, forKey: "smtpHostname")
							case "SMTP Port:": 		newEntry.setValue(value.toInt(), forKey: "smtpPort")
							default: break
							}
				}
			} else {
				
				var fetchRequest = NSFetchRequest(entityName: "EmailAccount")
				fetchRequest.predicate = NSPredicate(format: "emailAddress = %@", emailAcc!.emailAddress)
				
				if let fetchResults = appDel.managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [NSManagedObject] {
					if fetchResults.count != 0{
						
						var managedObject = fetchResults[0]
						
						for (key, value) in self.entries {
									switch key {
									case "Mailaddress:": 	managedObject.setValue(value, forKey: "emailAddress")
									case "Accountname:": 	managedObject.setValue(value, forKey: "username")
									case "Password:": 		managedObject.setValue(value, forKey: "password")
									case "IMAP Hostname:": 	managedObject.setValue(value, forKey: "imapHostname")
									case "IMAP Port:": 		managedObject.setValue(value.toInt(), forKey: "imapPort")
									case "SMTP Hostname:": 	managedObject.setValue(value, forKey: "smtpHostname")
									case "SMTP Port:": 		managedObject.setValue(value.toInt(), forKey: "smtpPort")
									default: break
									}
						}
					}
				}
			}
			context.save(nil)
			self.navigationController?.popViewControllerAnimated(true)
		}
	}

	func checkAllTextfieldsFilled() {
		for var section = 0; section < self.tableView.numberOfSections(); section++ {
			for var row = 0; row < self.tableView.numberOfRowsInSection(section); row++ {
				var cellPath = NSIndexPath(forRow: row, inSection: section)
				if let cell = self.tableView.cellForRowAtIndexPath(cellPath) as? PreferenceAccountTableViewCell {
					
					if cell.textfield.text.isEmpty {
						cell.labelCellContent.attributedText = NSAttributedString(string: cell.labelCellContent.text!, attributes: [NSForegroundColorAttributeName: UIColor.redColor()])
					} else {
						cell.labelCellContent.attributedText = NSAttributedString(string: cell.labelCellContent.text!, attributes: [NSForegroundColorAttributeName: UIColor.blackColor()])
						
					}
				}
			}
		}
		
		self.filledTextfieldCount = 0
		for (key, value) in self.entries {
			if value != "" {
				self.filledTextfieldCount += 1
			}
		}
	}
	
	
	func textFieldDidBeginEditing(textField: UITextField) {
		self.selectedTextfield = textField
	}
	
	func textFieldDidEndEditing(textField: UITextField) {
		
		self.entries[textField.placeholder!] = textField.text

	}
	
	func textFieldShouldReturn(textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
	
	override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
		self.view.endEditing(true)
	}
	
}
