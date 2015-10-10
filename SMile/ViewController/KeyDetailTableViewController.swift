//
//  KeyDetailTableViewController.swift
//  SMile
//
//  Created by Sebastian Thürauf on 17.08.15.
//  Copyright (c) 2015 SMile. All rights reserved.
//

import UIKit
import CoreData
import Foundation

class KeyDetailTableViewController: UITableViewController {
	
	let magicDate: NSDate = NSDate(dateString: "9999-01-01")
	
	var keyItem: Key?
	var keyInfoLabelStrings: [String] = [String]()
	var keyInfoContentStrings: [String] = [String]()
	var userIDsContentStrings = [String]()
	var userIDsLabelStrings = [String]()
	var subKeyLabelStrings = [String]()
	var subKeyContentStrings = [String]()
	var sectionContents: [AnyObject] = [AnyObject]()
	var sectionLables: [AnyObject] = [AnyObject]()
	var sections = [String]()
        
    override func viewDidLoad() {
        super.viewDidLoad()
		
		tableView.registerNib(UINib(nibName: "KeyDetailTableViewCell", bundle: nil),forCellReuseIdentifier:"KeyDetailCell")

        loadData()
		
		if self.keyItem!.isSecretKey && self.keyItem!.isPublicKey {
			self.sections = ["Secret & Public Key Info:","UserID Info:", "Sub Keys:"]
		} else if self.keyItem!.isSecretKey && !self.keyItem!.isPublicKey {
			self.sections = ["Secret Key Info:","UserID Info:", "Sub Keys:"]
		} else if !self.keyItem!.isSecretKey && self.keyItem!.isPublicKey {
			self.sections = ["Public Key Info:","UserID Info:", "Sub Keys:"]
		}
		
		self.navigationItem.title = "Key Details"

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
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
                    
                    self.navigationController?.pushViewController(sendView, animated: true)
                }
				}
            }
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.sectionContents.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sectionContents[section].count
    }
	
	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return self.sections[section]
	}
	
	override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
		let header = view as! UITableViewHeaderFooterView
		header.textLabel!.textColor = UIColor.blackColor()
		header.textLabel!.font = UIFont.boldSystemFontOfSize(18.0)
	}
	
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("KeyDetailCell", forIndexPath: indexPath) as! KeyDetailTableViewCell
		
		cell.label.text = self.sectionLables[indexPath.section][indexPath.row] as? String
		cell.content.text = self.sectionContents[indexPath.section][indexPath.row] as? String
		

        // Configure the cell...

        return cell
    }
	

	func loadData() {
		if keyItem != nil {
			self.keyInfoLabelStrings.append("Key ID:")
			self.keyInfoContentStrings.append(self.keyItem!.keyID)
			
			self.keyInfoLabelStrings.append("Name:")
			self.keyInfoContentStrings.append(self.keyItem!.userIDprimary)
			
			self.keyInfoLabelStrings.append("Email Address:")
			self.keyInfoContentStrings.append(self.keyItem!.emailAddressPrimary)
			
			self.keyInfoLabelStrings.append("Key Type:")
			self.keyInfoContentStrings.append(self.keyItem!.keyType)
			
			self.keyInfoLabelStrings.append("Created:")
			self.keyInfoContentStrings.append(self.keyItem!.created.toLongDateString())
			
			self.keyInfoLabelStrings.append("Valid Thru:")
			if self.keyItem!.validThru == self.magicDate {
				self.keyInfoContentStrings.append("does not expire")
			} else {
				self.keyInfoContentStrings.append(self.keyItem!.validThru.toLongDateString())
			}
			self.keyInfoLabelStrings.append("Key Length:")
			let keylength = Int(self.keyItem!.keyLength)
			self.keyInfoContentStrings.append(keylength.description)
			
			self.keyInfoLabelStrings.append("Algorithm:")
			self.keyInfoContentStrings.append(self.keyItem!.algorithm)
			
			self.keyInfoLabelStrings.append("Fingerprint:")
			self.keyInfoContentStrings.append(self.keyItem!.fingerprint)
			
			self.keyInfoLabelStrings.append("Trust:")
			self.keyInfoContentStrings.append(self.getTrustString(Int(self.keyItem!.trust)))
			
			self.sectionLables.append(self.keyInfoLabelStrings)
			self.sectionContents.append(self.keyInfoContentStrings)
			
			
			for anyUser in self.keyItem!.userIDs {
				let user = anyUser as! UserID
				self.userIDsLabelStrings.append(user.name)
				self.userIDsContentStrings.append(user.emailAddress)
			}
			
			self.sectionLables.append(self.userIDsLabelStrings)
			self.sectionContents.append(self.userIDsContentStrings)
			
			for anySubKey in self.keyItem!.subKeys {
				let subKey = anySubKey as! SubKey
				self.subKeyLabelStrings.append(subKey.subKeyID)
				self.subKeyContentStrings.append(subKey.length.stringValue + " " + subKey.algorithm)
			}
			
			self.sectionLables.append(self.subKeyLabelStrings)
			self.sectionContents.append(self.subKeyContentStrings)
			
			
		}
	}
	
	func getTrustString(value: Int) -> String {
		switch value {
		case 2: return "Never"
		case 3: return "Marginally"
		case 4: return "Fully"
		case 5: return "Ultimately"
		default: return "Unknown"
		}
	}
}
