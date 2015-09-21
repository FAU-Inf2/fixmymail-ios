//
//  PreferenceAccountListTableViewController.swift
//  FixMyMail
//
//  Created by Sebastian Thürauf on 30.05.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import CoreData
import UIKit

class PreferenceAccountListTableViewController: UITableViewController, UITextFieldDelegate {
	
	var emailAcc: EmailAccount?
	weak var delegate: ContentViewControllerProtocol?
	var navController: UINavigationController!
	var managedObjectContext: NSManagedObjectContext!
	var allAccounts: [EmailAccount] = [EmailAccount]()
	var accountPreferenceCellItem: [ActionItem] = [ActionItem]()
	var newAccountItem: [ActionItem] = [ActionItem]()
	var otherItem: [ActionItem] = [ActionItem]()
	var sections = [String]()
	var rows = [AnyObject]()
	var sectionsContent = [AnyObject]()
	var loadPictures: Bool?
	var selectedTextfield: UITextField?
	var selectedIndexPath: NSIndexPath?
	var origintableViewInsets: UIEdgeInsets?
	var standardAccountVC: PreferenceStandardAccountTableViewController?
	var previewLinesVC: PreferencesPreviewLinesTableViewController?
	
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		loadCoreDataAccounts()
		tableView.registerNib(UINib(nibName: "PreferenceTableViewCell", bundle: nil),forCellReuseIdentifier:"PreferenceCell")
		tableView.registerNib(UINib(nibName: "PreferenceAccountTableViewCell", bundle: nil),forCellReuseIdentifier:"PreferenceAccountCell")
		tableView.registerNib(UINib(nibName: "SwitchTableViewCell", bundle: nil), forCellReuseIdentifier: "SwitchTableViewCell")
		self.navigationItem.title = "Accounts"
		self.sections = ["Accounts:", "", "Options:"]
		
		
		//DELETE before release
		let buttonInfo: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Bookmarks, target: self, action: "showPasswordView")
		self.navigationItem.rightBarButtonItem = buttonInfo

    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if let fileName = (UIApplication.sharedApplication().delegate as! AppDelegate).fileName {
            if let data = (UIApplication.sharedApplication().delegate as! AppDelegate).fileData {
				if let mimetype = (UIApplication.sharedApplication().delegate as! AppDelegate).fileExtension {
                let sendView = MailSendViewController(nibName: "MailSendViewController", bundle: nil)
                var sendAccount: EmailAccount? = nil
                
                let accountName = NSUserDefaults.standardUserDefaults().stringForKey("standardAccount")
                let fetchRequest: NSFetchRequest = NSFetchRequest(entityName: "EmailAccount")
                var error: NSError?
                var result: [AnyObject]?
				do {
					result = try managedObjectContext.executeFetchRequest(fetchRequest)
				} catch let error1 as NSError {
					error = error1
					result = nil
				}
                if error != nil {
                    NSLog("%@", error!.description)
                    return
                } else {
                    if let emailAccounts = result {
                        for account in emailAccounts {
                            if (account as! EmailAccount).accountName == accountName {
                                sendAccount = account as? EmailAccount
                                break
                            }
                        }
                        if sendAccount == nil {
                            sendAccount = emailAccounts.first as? EmailAccount
                        }
                    }
                }
                
                if let account = sendAccount {
                    sendView.account = account
                    sendView.attachFile(fileName, data: data, mimetype: mimetype)
                    
                    (UIApplication.sharedApplication().delegate as! AppDelegate).fileName = nil
                    (UIApplication.sharedApplication().delegate as! AppDelegate).fileData = nil
					(UIApplication.sharedApplication().delegate as! AppDelegate).fileExtension = nil
                    
                    self.navigationController?.pushViewController(sendView, animated: true)
                }
				}
            }
        }
        
    }
	
	//DELETE before release
	func showPasswordView() {
		self.navigationController?.pushViewController(DevPasswordViewController(nibName: "DevPasswordViewController", bundle: nil), animated: true)
	}
	
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(true)
		self.allAccounts.removeAll(keepCapacity: false)
		self.accountPreferenceCellItem.removeAll(keepCapacity: false)
		self.newAccountItem.removeAll(keepCapacity: false)
		self.rows.removeAll(keepCapacity: false)
		self.sectionsContent.removeAll(keepCapacity: false)
		self.otherItem.removeAll(keepCapacity: false)
		
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
		
		// get selection from standard account VC
		if self.standardAccountVC != nil {
            NSUserDefaults.standardUserDefaults().setObject(self.standardAccountVC!.selectedString, forKey: "standardAccount")
		}
		
		// get selection from preview lines VC
		if self.previewLinesVC != nil {
			NSUserDefaults.standardUserDefaults().setInteger(Int(self.previewLinesVC!.selectedString)!, forKey: "previewLines")
		}
		
		loadCoreDataAccounts()
		self.tableView.reloadData()
		
	}
	
	override func viewWillDisappear(animated: Bool) {
		if (self.selectedTextfield != nil) {
		self.textFieldShouldReturn(self.selectedTextfield!)
		}
		
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

	
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

	
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cellItem: ActionItem = self.rows[indexPath.section][indexPath.row] as! ActionItem
		
		// Configure the cell...
		switch cellItem.cellName {
			case "Standardaccount:":
				let cell = tableView.dequeueReusableCellWithIdentifier("PreferenceAccountCell", forIndexPath: indexPath) as! PreferenceAccountTableViewCell
				cell.labelCellContent.text = cellItem.cellName
				cell.textfield.placeholder = "Standard Account"
				cell.textfield.textAlignment = NSTextAlignment.Right
				cell.textfield.enabled = false
				cell.textfield.delegate = self
				if cellItem.emailAddress != nil {
					cell.textfield.text = cellItem.emailAddress
				}
				return cell
			case "Preview lines:":
				let cell = tableView.dequeueReusableCellWithIdentifier("PreferenceAccountCell", forIndexPath: indexPath) as! PreferenceAccountTableViewCell
				cell.labelCellContent.text = cellItem.cellName
				cell.textfield.placeholder = ""
				cell.textfield.textAlignment = NSTextAlignment.Right
				cell.textfield.enabled = false
				cell.textfield.delegate = self
				if cellItem.emailAddress != nil {
					cell.textfield.text = cellItem.emailAddress
				}
				return cell
			case "Load pictures automatically:":
				let cell = tableView.dequeueReusableCellWithIdentifier("SwitchTableViewCell", forIndexPath: indexPath) as! SwitchTableViewCell
				cell.label.text = cellItem.cellName
				cell.activateSwitch.addTarget(self, action: Selector("stateChanged:"), forControlEvents: UIControlEvents.ValueChanged)
				cell.activateSwitch.on = self.loadPictures!
				return cell
		default:
			let cell = tableView.dequeueReusableCellWithIdentifier("PreferenceCell", forIndexPath: indexPath) as! PreferenceTableViewCell
			cell.menuLabel.text = cellItem.emailAddress
			cell.menuImg.image = cellItem.cellIcon
			
			return cell
			
		}
    }
	
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let actionItem = self.rows[indexPath.section][indexPath.row] as! ActionItem

		switch actionItem.viewController {
		case "PreferencesPreviewLinesTableViewController":
			// Select preview lines
			self.previewLinesVC = PreferencesPreviewLinesTableViewController(nibName: "PreferencesPreviewLinesTableViewController", bundle: nil)
			self.previewLinesVC!.selectedString = String(NSUserDefaults.standardUserDefaults().integerForKey("previewLines"))
			self.navigationController?.pushViewController(self.previewLinesVC!, animated: true)
			tableView.deselectRowAtIndexPath(indexPath, animated: true)
		case "PreferenceStandardAccountTableViewController":
			// Select standard Account
			self.standardAccountVC = PreferenceStandardAccountTableViewController(nibName: "PreferenceStandardAccountTableViewController", bundle: nil)
			self.standardAccountVC!.accounts = self.allAccounts
			self.standardAccountVC!.selectedString = NSUserDefaults.standardUserDefaults().stringForKey("standardAccount")!
			self.navigationController?.pushViewController(self.standardAccountVC!, animated: true)
			tableView.deselectRowAtIndexPath(indexPath, animated: true)
		case "PreferenceAccountView":
			// PreferenceAccountView
			let editAccountVC = PreferenceEditAccountTableViewController(nibName:"PreferenceEditAccountTableViewController", bundle: nil)
			if let emailAccountItem = self.sectionsContent[indexPath.section][indexPath.row] as? EmailAccount {
				editAccountVC.emailAcc = emailAccountItem
			}
			
			editAccountVC.actionItem = actionItem
			editAccountVC.allAccounts = self.allAccounts
			self.navigationController?.pushViewController(editAccountVC, animated: true)
			tableView.deselectRowAtIndexPath(indexPath, animated: true)
		default:
			tableView.deselectRowAtIndexPath(indexPath, animated: true)
		}

		tableView.reloadData()
		
	}
	
	
	func loadCoreDataAccounts() {
		// get mail accounts from coredata
		
		let appDel: AppDelegate? = UIApplication.sharedApplication().delegate as? AppDelegate
		if let appDelegate = appDel {
			managedObjectContext = appDelegate.managedObjectContext
			let emailAccountsFetchRequest = NSFetchRequest(entityName: "EmailAccount")
			var acc: [EmailAccount]?
			do {
				acc = try managedObjectContext.executeFetchRequest(emailAccountsFetchRequest) as? [EmailAccount]
			} catch {
				print("CoreData fetch error!")
			}
			
			if let account = acc {
				for emailAcc: EmailAccount in account {
					allAccounts.append(emailAcc)
				}
			}
			
		}
		
		// create ActionItems for mail accounts
		for emailAcc: EmailAccount in allAccounts {
			
            let accountImage: UIImage? = PreferenceAccountListTableViewController.getImageFromEmailAccount(emailAcc)
			
			let actionItem = ActionItem(Name: emailAcc.username, viewController: "PreferenceAccountView",emailAddress: emailAcc.emailAddress, icon: accountImage)
			accountPreferenceCellItem.append(actionItem)
		}

		// Add New Account Cell
		newAccountItem.append(ActionItem(Name: "Add New Account", viewController: "PreferenceAccountView", emailAddress: "Add New Account", icon: UIImage(named: "ios7-plus.png")))
		
		// Preferences
		var standardAccountMatch = false
		for account: EmailAccount in allAccounts {
			if account.accountName == NSUserDefaults.standardUserDefaults().stringForKey("standardAccount")! {
				standardAccountMatch = true
				break
			}
		}
		if standardAccountMatch == false {
            NSUserDefaults.standardUserDefaults().setObject("", forKey: "standardAccount")
		}
	
		let standardAccountItem = ActionItem(Name: "Standardaccount:", viewController: "PreferenceStandardAccountTableViewController", emailAddress: NSUserDefaults.standardUserDefaults().stringForKey("standardAccount")!, icon: nil)
		
		let previewLinesItem = ActionItem(Name: "Preview lines:", viewController: "PreferencesPreviewLinesTableViewController", emailAddress: String(NSUserDefaults.standardUserDefaults().integerForKey("previewLines")), icon: nil)
		
		
		let loadPictureItem = ActionItem(Name: "Load pictures automatically:", viewController: "", emailAddress: nil, icon: nil)
		if self.loadPictures == nil {
			self.loadPictures = NSUserDefaults.standardUserDefaults().boolForKey("loadPictures")
		}
		
		self.otherItem.append(standardAccountItem)
		self.otherItem.append(previewLinesItem)
		self.otherItem.append(loadPictureItem)
		
		self.rows.append(accountPreferenceCellItem)
		self.rows.append(newAccountItem)
		self.rows.append(otherItem)
		
		self.sectionsContent.append(allAccounts)
		self.sectionsContent.append(newAccountItem)
		self.sectionsContent.append(otherItem)

	}
	
	// set value if switchstate has changed
	func stateChanged(switchState: UISwitch) {
		self.loadPictures = switchState.on
        NSUserDefaults.standardUserDefaults().setBool(switchState.on, forKey: "loadPictures")
	}
	
	func textFieldDidBeginEditing(textField: UITextField) {
		self.selectedTextfield = textField
		let cellView = textField.superview
		let cell = cellView?.superview as! PreferenceAccountTableViewCell
		let indexPath = self.tableView.indexPathForCell(cell)
		self.selectedIndexPath = indexPath
	}
	
	func textFieldDidEndEditing(textField: UITextField) {
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
    
    static func getImageFromEmailAccount(emailAccount: EmailAccount) -> UIImage? {
        var accountImage: UIImage?
        
        // set icons
        switch emailAccount.emailAddress {
        case let s where s.rangeOfString("@gmail.com") != nil:
            accountImage = UIImage(named: "Gmail-128.png")
            
        case let s where s.rangeOfString("@outlook") != nil:
            accountImage = UIImage(named: "outlook.png")
            
        case let s where s.rangeOfString("@yahoo") != nil:
            accountImage = UIImage(named: "Yahoo-icon.png")
            
        case let s where s.rangeOfString("@web.de") != nil:
            accountImage = UIImage(named: "webde.png")
            
        case let s where s.rangeOfString("@gmx") != nil:
            accountImage = UIImage(named: "gmx.png")
            
        case let s where s.rangeOfString("@me.com") != nil:
            accountImage = UIImage(named: "icloud-icon.png")
            
        case let s where s.rangeOfString("@icloud.com") != nil:
            accountImage = UIImage(named: "icloud-icon.png")
            
        case let s where s.rangeOfString("@fau.de") != nil:
            accountImage = UIImage(named: "fau-logo.png")
            
        case let s where s.rangeOfString("@studium.fau.de") != nil:
            accountImage = UIImage(named: "fau-logo.png")
            
        default:
            accountImage = UIImage(named: "smile-gray.png")
            
        }
        
        return accountImage
    }
	
}
