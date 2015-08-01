//
//  PrefFolderSelectionTableViewController.swift
//  SMile
//
//  Created by Sebastian Thürauf on 29.07.15.
//  Copyright (c) 2015 SMile. All rights reserved.
//

import UIKit

class PrefFolderSelectionTableViewController: UITableViewController {
	var emailAcc: EmailAccount?
	var StringForFolderBehavior: String?
	var selectedFolderPath: String?
	var folderPaths = [String]()
	var lastTappedIndexPath: NSIndexPath?
	var isChecked: [Bool] = [Bool]()
	var cellItems: [ActionItem] = []
	let leftSpaceIncrement: Float = 20.0
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.tableView.registerNib(UINib(nibName: "PreferenceTableViewCell", bundle: nil),forCellReuseIdentifier:"PreferenceCell")
		
		self.tableView.registerNib(UINib(nibName: "SideBarSubFolderTableViewCell", bundle: nil), forCellReuseIdentifier: "SideBarSubFolder")
		
		self.navigationItem.title = self.StringForFolderBehavior
		loadData()
		self.tableView.reloadData()
	}
	
	//MARK: - TableViewDelegate
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.cellItems.count
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let actionItem: ActionItem = self.cellItems[indexPath.row]
		if actionItem.viewController == "NoVC" {
			var cell = tableView.dequeueReusableCellWithIdentifier("PreferenceCell", forIndexPath: indexPath) as! PreferenceTableViewCell
			
			cell.selectionStyle = UITableViewCellSelectionStyle.None
			cell.menuLabel.text = actionItem.cellName
			cell.menuLabel.textColor = UIColor.grayColor()
			if let icon = actionItem.cellIcon {
				cell.menuImg.image = icon
			} else {
				cell.menuImg.image = nil
			}
			// if checked
			if self.isChecked[indexPath.row] {
				cell.accessoryType = UITableViewCellAccessoryType.Checkmark
			} else {
				cell.accessoryType = UITableViewCellAccessoryType.None
			}
			return cell
			
		} else {
			var viewArr = NSBundle.mainBundle().loadNibNamed("SideBarSubFolderTableViewCell", owner: self, options: nil)
			var cell = viewArr[0] as! SideBarSubFolderTableViewCell
			let mailAcc: ActionItem = self.cellItems[indexPath.row]
			if mailAcc.actionItems != nil {
				cell.selectionStyle = UITableViewCellSelectionStyle.None
				cell.menuLabel.textColor = UIColor.grayColor()
			} else {
				cell.selectionStyle = UITableViewCellSelectionStyle.Default
				cell.menuLabel.textColor = UIColor.blackColor()
			}
			cell.menuLabel.text = mailAcc.cellName
			self.setConstraintsForSubFolderCell(cell, andPathComponentNumber: mailAcc.pathComponentNumber)
			cell.menuImg.image = mailAcc.cellIcon
			
			// if checked
			if self.isChecked[indexPath.row] {
				cell.accessoryType = UITableViewCellAccessoryType.Checkmark
			} else {
				cell.accessoryType = UITableViewCellAccessoryType.None
			}
			
			return cell
		}
	}
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		
		if self.cellItems[indexPath.row].actionItems == nil {
			if let folder = self.cellItems[indexPath.row].emailFolder {
				for var i = 0; i < self.isChecked.count; i++ {
					self.isChecked[i] = false
				}
				self.isChecked[indexPath.row] = true
				self.selectedFolderPath = folder.path
				
				// uncheck previous
				if self.lastTappedIndexPath != nil {
					self.isChecked[self.lastTappedIndexPath!.row] = false
				}
				
				self.lastTappedIndexPath = indexPath
			}
		} else {
			tableView.deselectRowAtIndexPath(indexPath, animated: true)
		}
	
		self.tableView.reloadData()
		
	}
	
	//MARK: - Supportive methods
	
	func getActionItemsFromEmailAccount(emailAccount: EmailAccount) -> ActionItem {
		var actionItem = ActionItem(Name: emailAccount.accountName, viewController: "NoVC", emailAccount: emailAccount, icon: PreferenceAccountListTableViewController.getImageFromEmailAccount(emailAccount))
		var subItems = [ActionItem]()
		for imapFolder in emailAccount.folders {
			var fol: MCOIMAPFolder = (imapFolder as! ImapFolder).mcoimapfolder
			var pathComponents = fol.path.pathComponents
			if pathComponents.count > 1 {
				for var i = 0; i < (pathComponents.count - 1); i++ {
					let parentFolderName = pathComponents[i]
					var parentItem: ActionItem? = self.getParentItemFromItems(subItems, andParentFolderName: parentFolderName)
					if parentItem == nil {
						var acItem = ActionItem(Name: pathComponents[i], viewController: "SubFolder", emailAccount: emailAccount, icon: UIImage(named: "folder.png"))
						acItem.pathComponentNumber = i
						acItem.actionItems = [ActionItem]()
						parentItem = acItem
						if i == 0 {
							subItems.append(acItem)
						} else {
							self.addItemToParentItemWithItem(acItem, andParentItemName: pathComponents[i - 1])
						}
					}
					if let parItem = parentItem {
						parItem.viewController = "SubFolder"
						if pathComponents[i + 1] != fol.path.lastPathComponent {
							var acItem = ActionItem(Name: pathComponents[i + 1], viewController: "SubFolder", emailAccount: emailAccount, icon: UIImage(named: "folder.png"))
							var subItemArr: [ActionItem] = parentItem?.actionItems ?? [ActionItem]()
							if self.containsActionItem(acItem, inActionItemArray: subItemArr) == false {
								subItemArr.append(acItem)
								subItemArr = subItemArr.sorted { $0.cellName < $1.cellName }
								acItem.actionItems = subItemArr
							}
						} else {
							var acItem = ActionItem(Name: pathComponents[i + 1], viewController: "EmailSpecific", emailAccount: emailAccount, icon: UIImage(named: "folder.png"), emailFolder: fol)
							acItem.pathComponentNumber = i + 1
							var subItemArr: [ActionItem] = parentItem?.actionItems ?? [ActionItem]()
							if self.containsActionItem(acItem, inActionItemArray: subItemArr) == false {
								subItemArr.append(acItem)
								subItemArr = subItemArr.sorted { $0.cellName < $1.cellName }
								parItem.actionItems = subItemArr
							}
						}
					}
				}
			} else {
				var isParentFolder = false
				for imapFolder in emailAccount.folders {
					var folder: MCOIMAPFolder = (imapFolder as! ImapFolder).mcoimapfolder
					var folPath: NSString = NSString(string: folder.path)
					var range: NSRange = folPath.rangeOfString(NSString(format: "%@/", fol.path) as String)
					if range.location != NSNotFound {
						isParentFolder = true
						break;
					}
				}
				var item: ActionItem!
				if isParentFolder == true {
					item = ActionItem(Name: fol.path, viewController: "SubFolder", emailAccount: emailAccount, icon: UIImage(named: "folder.png"))
				} else {
					item = ActionItem(Name: fol.path, viewController: "EmailSpecific", emailAccount: emailAccount, emailFolder: fol, icon: UIImage(named: "folder.png"))
				}
				if self.containsActionItem(item, inActionItemArray: subItems) == false {
					subItems.append(item)
				}
			}
		}
		
		actionItem.actionItems = subItems.sorted { $0.cellName < $1.cellName }
		actionItem.folderExpanded = false
		return actionItem
	}
	
	func addItemToParentItemWithItem(childItem: ActionItem, andParentItemName parentName: String) -> Bool {
		var actionItems: [ActionItem] = self.cellItems
		var parentItem: ActionItem?
		for item in actionItems {
			if item.cellName == parentName {
				parentItem = item
				break
			}else if item.actionItems != nil && item.actionItems?.count > 0 {
				parentItem = self.getParentItemFromItems(item.actionItems!, andParentFolderName: parentName)
				if parentItem != nil {
					break
				}
			}
		}
		if parentItem == nil {
			return false
		} else {
			var parItemArr: [ActionItem] = parentItem?.actionItems ?? [ActionItem]()
			parItemArr.append(childItem)
			parentItem?.actionItems = parItemArr.sorted{ $0.cellName < $1.cellName }
			return true
		}
	}
	
	func containsActionItem(actionItem: ActionItem, inActionItemArray actionItemArray: [ActionItem]) -> Bool {
		for item in actionItemArray {
			if actionItem.cellName == item.cellName && actionItem.viewController == item.viewController &&
				actionItem.emailAccount == item.emailAccount && actionItem.cellIcon == item.cellIcon {
					return true
			}
		}
		return false
	}
	
	func setConstraintsForSubFolderCell(cell: SideBarSubFolderTableViewCell, andPathComponentNumber pathComponentNumber: Int) -> Void {
		
		cell.menuImg.removeConstraints(cell.menuImg.constraints())
		cell.contentView.removeConstraints(cell.contentView.constraints())
		
		var constraint1: NSLayoutConstraint = NSLayoutConstraint(item: cell.menuImg, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: cell.contentView, attribute: NSLayoutAttribute.Leading, multiplier: 1.0, constant: (CGFloat(pathComponentNumber) * CGFloat(self.leftSpaceIncrement) + 33.0))
		cell.contentView.addConstraint(constraint1)
		
		var constraint2 = NSLayoutConstraint(item: cell.menuImg, attribute: .Top, relatedBy: .Equal, toItem: cell.contentView, attribute: .Top, multiplier: 1.0, constant: 0.0)
		cell.contentView.addConstraint(constraint2)
		
		var constraint3 = NSLayoutConstraint(item: cell.menuLabel, attribute: .Leading, relatedBy: .Equal, toItem: cell.menuImg, attribute: .Trailing, multiplier: 1.0, constant: 8.0)
		cell.contentView.addConstraint(constraint3)
		
		var constraint4 = NSLayoutConstraint(item: cell.contentView, attribute: .Trailing, relatedBy: .Equal, toItem: cell.menuLabel, attribute: .Trailing, multiplier: 1.0, constant: 20.0)
		cell.contentView.addConstraint(constraint4)
		
		var constraint5 = NSLayoutConstraint(item: cell.menuLabel, attribute: .Top, relatedBy: .Equal, toItem: cell.contentView, attribute: .Top, multiplier: 1.0, constant: 11.0)
		cell.contentView.addConstraint(constraint5)
		
		var constraint6 = NSLayoutConstraint(item: cell.menuImg, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1.0, constant: 43.0)
		cell.menuImg.addConstraint(constraint6)
		
		var constraint7 = NSLayoutConstraint(item: cell.menuImg, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 43.0)
		cell.menuImg.addConstraint(constraint7)
		
		cell.updateConstraints()
	}
	
	func getParentItemFromItems(items: [ActionItem], andParentFolderName parentFolderName: String) -> ActionItem? {
		var parentItem: ActionItem?
		for item in items {
			if item.cellName == parentFolderName {
				parentItem = item
				break;
			} else if item.actionItems != nil {
				parentItem = self.getParentItemFromItems(item.actionItems!, andParentFolderName: parentFolderName)
				if parentItem != nil {
					break
				}
			}
		}
		return parentItem
	}
	
	func getSubFolderFromParentFolder(folder: ActionItem) -> [ActionItem] {
		var array:[ActionItem] = []
		array.append(folder)
		if folder.actionItems != nil {
			for subFolder in folder.actionItems! {
				for newFolder in getSubFolderFromParentFolder(subFolder) {
					array.append(newFolder)
				}
			}
		}
		return array
	}

	func loadData(){
		cellItems = getSubFolderFromParentFolder(self.getActionItemsFromEmailAccount(self.emailAcc!))
		var dummyfolder = MCOIMAPFolder()
		dummyfolder.path = ""
		var standardBehaviorActionItem = ActionItem(Name: "Use account standard folders", viewController: "NoVC", emailAddress: nil, icon: nil, emailFolder: dummyfolder, actionItems: nil)
		
		self.cellItems.insert(standardBehaviorActionItem, atIndex: 0)
		
		for item in cellItems {
			if item.emailFolder?.path == self.selectedFolderPath! {
				self.isChecked.append(true)
			} else {
				self.isChecked.append(false)
			}
		}
		if self.selectedFolderPath == "" {
			self.isChecked[0] = true
		}
	}
	
}
