//
//  SidebarTableViewController.swift
//  FixMyMail
//
//  Created by Jan Weiß on 11.05.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import CoreData
import UIKit

@objc
protocol SideBarProtocol {
    optional func cellSelected(actionItem: ActionItem)
}


class SidebarTableViewController: UITableViewController {
    
    @IBOutlet var sidebarCell: SideBarTableViewCell!
    var sections = [String]()
    var rows = [AnyObject]()
    var managedObjectContext: NSManagedObjectContext!
    weak var delegate: SideBarProtocol?
    var emailAccounts: [EmailAccount] = [EmailAccount]()
    var currAccountName: String?
    let leftSpaceIncrement: Float = 20.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
		var accountArr: [EmailAccount] = [EmailAccount]();
		let appDel: AppDelegate? = UIApplication.sharedApplication().delegate as? AppDelegate
		if let appDelegate = appDel {
			managedObjectContext = appDelegate.managedObjectContext
			let emailAccountsFetchRequest = NSFetchRequest(entityName: "EmailAccount")
			var acc: [EmailAccount]? = nil
            do {
                acc = try managedObjectContext.executeFetchRequest(emailAccountsFetchRequest) as? [EmailAccount]
            } catch _ {
                print("Error while fetching emailaccounts from CoreData")
            }
			
			if acc != nil {
				//For fist expand comand
				if acc!.count > 0 {
					self.currAccountName = self.currAccountName == nil ? acc![0].accountName : self.currAccountName
					for emailAcc: EmailAccount in acc! {
						accountArr.append(emailAcc)
					}
				}
			}
		}
		
        self.sections = ["Inboxes", "Accounts", ""]
        var inboxRows: [ActionItem] = [ActionItem]()
        inboxRows.append(ActionItem(Name: "All", viewController: "EmailAll", icon: UIImage(named: "smile-gray.png")))
        for emailAcc: EmailAccount in accountArr {
            let actionItem = ActionItem(Name: emailAcc.accountName, viewController: "EmailSpecific", emailAccount: emailAcc, icon: PreferenceAccountListTableViewController.getImageFromEmailAccount(emailAcc))
            inboxRows.append(actionItem)
        }
        inboxRows = inboxRows.sort{ $0.cellName < $1.cellName }
        
        var settingsArr: [ActionItem] = [ActionItem]()
        settingsArr.append(ActionItem(Name: "REMIND ME!", viewController: "TODO"))
        settingsArr.append(ActionItem(Name: "Keychain", viewController: "KeyChain"))
        settingsArr.append(ActionItem(Name: "Preferences", viewController: "Preferences"))

        self.rows.append(inboxRows)
        self.rows.append([ActionItem]())
        self.rows.append(settingsArr)
        self.rows[1] = self.getIMAPFoldersFromCoreData(WithEmailAccounts: accountArr)
        self.tableView.reloadData()
        
        self.emailAccounts = accountArr
        self.fetchIMAPFolders()
    }
    
    override func viewWillAppear(animated: Bool) {
        if self.currAccountName != nil {
            var sectionItems: [ActionItem] = self.rows[1] as! [ActionItem]
            var indexOfLastAcc: Int!
            for item in sectionItems {
                if item.cellName == self.currAccountName! {
                    indexOfLastAcc = sectionItems.indexOf(item)
                    
                    var firstPart: [ActionItem] = Array(sectionItems[0...indexOfLastAcc])
                    let lastPart: [ActionItem]? = (sectionItems.count - 1) == indexOfLastAcc ? nil : Array(sectionItems[(indexOfLastAcc + 1)...(sectionItems.count - 1)])
                    for item: ActionItem in item.actionItems! {
                        firstPart.append(item)
                    }
                    if lastPart != nil {
                        for acItem: ActionItem in lastPart! {
                            firstPart.append(acItem)
                        }
                    }
                    self.rows[1] = firstPart
                    item.folderExpanded = true
                    self.tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: UITableViewRowAnimation.Automatic)
                    break;
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
        return self.sections.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.rows[section].count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sections[section]
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                let mailAcc: ActionItem = self.rows[indexPath.section][indexPath.row] as! ActionItem
                    NSBundle.mainBundle().loadNibNamed("SideBarTableViewCell", owner: self, options: nil)
                    let sideBarCell: SideBarTableViewCell = self.sidebarCell
                    self.sidebarCell = nil
                    if(indexPath.row == 0) {
                        sideBarCell.menuLabel.text = "All"
                    } else {
                        sideBarCell.menuLabel.text = mailAcc.cellName
                    }
                    if let icon = mailAcc.cellIcon {
                        sideBarCell.menuImg.image = icon
                    } else {
                        sideBarCell.menuImg.image = nil
                    }
                    
                    return sideBarCell
            } else {
                    var viewArr = NSBundle.mainBundle().loadNibNamed("SideBarSubFolderTableViewCell", owner: self, options: nil)
                    let cell = viewArr[0] as! SideBarSubFolderTableViewCell
                    let mailAcc: ActionItem = self.rows[indexPath.section][indexPath.row] as! ActionItem
                    cell.menuLabel.text = mailAcc.cellName
                    if let icon = mailAcc.cellIcon {
                        cell.menuImg.image = icon
                    } else {
                        cell.menuImg.image = nil
                    }
                    return cell
                }
        } else if indexPath.section == 1 {
            let actionItem: ActionItem = self.rows[indexPath.section][indexPath.row] as! ActionItem
            if actionItem.viewController == "NoVC" {
                let inboxCell = tableView.dequeueReusableCellWithIdentifier("SideBarCell") as? SideBarTableViewCell
                if let cell = inboxCell {
                    cell.selectionStyle = UITableViewCellSelectionStyle.Default
                    cell.menuLabel.text = actionItem.cellName
                    if let icon = actionItem.cellIcon {
                        cell.menuImg.image = icon
                    } else {
                        cell.menuImg.image = nil
                    }
                    return cell
                } else {
                    NSBundle.mainBundle().loadNibNamed("SideBarTableViewCell", owner: self, options: nil)
                    let sideBarCell: SideBarTableViewCell = self.sidebarCell
                    self.sidebarCell = nil
                    let actionItem: ActionItem = self.rows[indexPath.section][indexPath.row] as! ActionItem
                    if actionItem.viewController == "NoVC" {
                        sideBarCell.selectionStyle = UITableViewCellSelectionStyle.None
                    }
                    sideBarCell.menuLabel.text = actionItem.cellName
                    if let icon = actionItem.cellIcon {
                        sideBarCell.menuImg.image = icon
                    } else {
                        sideBarCell.menuImg.image = nil
                    }
                    return sideBarCell
                }
            } else {
                var viewArr = NSBundle.mainBundle().loadNibNamed("SideBarSubFolderTableViewCell", owner: self, options: nil)
                let cell = viewArr[0] as! SideBarSubFolderTableViewCell
                let mailAcc: ActionItem = self.rows[indexPath.section][indexPath.row] as! ActionItem
                cell.menuLabel.text = mailAcc.cellName
                self.setConstraintsForSubFolderCell(cell, andPathComponentNumber: mailAcc.pathComponentNumber)
                if let icon = mailAcc.cellIcon {
                    cell.menuImg.image = icon
                    if mailAcc.actionItems != nil && mailAcc.actionItems?.count > 0 {
                        var img: UIImage!
                        if mailAcc.folderExpanded == true {
                            img = UIImage(named: "triangle_bottom.png")
                        } else {
                            img = UIImage(named: "triangle_right.png")
                        }
                        let triangleImageView: UIImageView = UIImageView(image: img)
                        triangleImageView.contentMode = UIViewContentMode.ScaleAspectFill
                        triangleImageView.frame.size = CGSize(width: cell.menuImg.frame.size.width / 4, height: cell.menuImg.frame.size.height / 4)
                        triangleImageView.center = CGPointMake(cell.menuImg.center.x, cell.menuImg.center.y + cell.menuImg.frame.size.height / 8)
                        cell.addSubview(triangleImageView)
                    }
                } else {
                    cell.menuImg.image = nil
                }
                return cell
            }
        } else if indexPath.section == 2 {
            let inboxCell = tableView.dequeueReusableCellWithIdentifier("SideBarCell") as? SideBarTableViewCell
            if let cell = inboxCell {
                let actionItem: ActionItem = self.rows[indexPath.section][indexPath.row] as! ActionItem
                cell.menuLabel.text = actionItem.cellName
                if let icon = actionItem.cellIcon {
                    cell.menuImg.image = icon
                } else {
                    cell.menuImg.image = nil
                }
                return cell
            } else {
                NSBundle.mainBundle().loadNibNamed("SideBarTableViewCell", owner: self, options: nil)
                let sideBarCell: SideBarTableViewCell = self.sidebarCell
                self.sidebarCell = nil
                let actionItem: ActionItem = self.rows[indexPath.section][indexPath.row] as! ActionItem
                sideBarCell.menuLabel.text = actionItem.cellName
                if let icon = actionItem.cellIcon {
                    sideBarCell.menuImg.image = icon
                } else {
                    sideBarCell.menuImg.image = nil
                }
                return sideBarCell
            }
        } else {
            let inboxCell: SideBarTableViewCell = tableView.dequeueReusableCellWithIdentifier("SideBarCell") as! SideBarTableViewCell
            return inboxCell
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let actionItem: ActionItem = self.rows[indexPath.section][indexPath.row] as! ActionItem
        if actionItem.viewController != "NoVC" && actionItem.viewController != "SubFolder" {
            delegate?.cellSelected!(actionItem)
        } else {
            self.removeExpandedSubItemsWithActionItem(actionItem)
            if actionItem.actionItems != nil {
                if actionItem.folderExpanded == false {
                    var sectionItems: [ActionItem] = self.rows[indexPath.section] as! [ActionItem]
                    var firstPart: [ActionItem] = Array(sectionItems[0...indexPath.row])
                    let lastPart: [ActionItem]? = (sectionItems.count - 1) == indexPath.row ? nil : Array(sectionItems[(indexPath.row + 1)...(sectionItems.count - 1)])
                    for item: ActionItem in actionItem.actionItems! {
                        firstPart.append(item)
                    }
                    if lastPart != nil {
                        for item: ActionItem in lastPart! {
                            firstPart.append(item)
                        }
                    }
                    self.rows[indexPath.section] = firstPart
                    actionItem.folderExpanded = true
                    self.tableView.reloadSections(NSIndexSet(index: indexPath.section), withRowAnimation: UITableViewRowAnimation.Automatic)
                } else {
                    var sectionItems: [ActionItem] = self.rows[indexPath.section] as! [ActionItem]
                    sectionItems.removeRange((indexPath.row + 1)...(actionItem.actionItems!.count + indexPath.row))
                    actionItem.folderExpanded = false
                    self.rows[indexPath.section] = sectionItems
                    self.tableView.reloadSections(NSIndexSet(index: indexPath.section), withRowAnimation: UITableViewRowAnimation.Automatic)
                }
            }
        }
    }
    
    //MARK: - IMAPFolder fetch
    
    private func fetchIMAPFolders() -> Void {
        IMAPFolderFetcher.sharedInstance.getAllIMAPFoldersWithAccounts { (account, folders, sucess, newFolders) -> Void in
            if sucess == true && newFolders == true {
                var sectionItems = self.rows[1] as! [ActionItem]
                let newActionItem = self.getActionItemsFromEmailAccount(account!)
                if self.containsActionItem(newActionItem, inActionItemArray: self.rows[1] as! [ActionItem]) == false {
                    sectionItems.append(newActionItem)
                } else {
                    sectionItems = self.removeActionItemFromArrayWithActionItem(newActionItem, withActionItemArray: sectionItems)
                    sectionItems.append(newActionItem)
                }
                sectionItems = sectionItems.sort { $0.cellName < $1.cellName }
                self.rows[1] = sectionItems
                self.tableView.reloadData()
            }
        }
    }
    
    private func getIMAPFoldersFromCoreData(WithEmailAccounts emailAccounts: [EmailAccount]) -> [ActionItem] {
        var resultItems = [ActionItem]()
        for account in emailAccounts {
            if account.folders.count > 0 {
                resultItems.append(self.getActionItemsFromEmailAccount(account))
            }
        }
        return resultItems.sort{ $0.cellName < $1.cellName }
    }
    
    private func getActionItemsFromEmailAccount(emailAccount: EmailAccount) -> ActionItem {
        let actionItem = ActionItem(Name: emailAccount.accountName, viewController: "NoVC", emailAccount: emailAccount, icon: PreferenceAccountListTableViewController.getImageFromEmailAccount(emailAccount))
        var subItems = [ActionItem]()
            for imapFolder in emailAccount.folders {
                let fol: MCOIMAPFolder = (imapFolder as! ImapFolder).mcoimapfolder
                var pathComponents = getPathComponentsFromString(fol.path)
                if pathComponents!.count > 1 {
                    for var i = 0; i < (pathComponents!.count - 1); i++ {
                        let parentFolderName = pathComponents![i]
                        var parentItem: ActionItem? = self.getParentItemFromItems(subItems, andParentFolderName: parentFolderName)
                        if parentItem == nil {
                            let acItem = ActionItem(Name: pathComponents![i], viewController: "SubFolder", emailAccount: emailAccount, icon: UIImage(named: "folder.png"))
                            acItem.pathComponentNumber = i
                            acItem.actionItems = [ActionItem]()
                            parentItem = acItem
                            if i == 0 {
                                subItems.append(acItem)
                            } else {
                                self.addItemToParentItemWithItem(acItem, andParentItemName: pathComponents![i - 1])
                            }
                        }
                        if let parItem = parentItem {
                            parItem.viewController = "SubFolder"
                            if pathComponents![i + 1] != getLastPathComponentFromString(fol.path) {
                                let acItem = ActionItem(Name: pathComponents![i + 1], viewController: "SubFolder", emailAccount: emailAccount, icon: UIImage(named: "folder.png"))
                                var subItemArr: [ActionItem] = parentItem?.actionItems ?? [ActionItem]()
                                if self.containsActionItem(acItem, inActionItemArray: subItemArr) == false {
                                    subItemArr.append(acItem)
                                    subItemArr = subItemArr.sort { $0.cellName < $1.cellName }
                                    acItem.actionItems = subItemArr
                                }
                            } else {
                                let acItem = ActionItem(Name: pathComponents![i + 1], viewController: "EmailSpecific", emailAccount: emailAccount, icon: UIImage(named: "folder.png"), emailFolder: fol)
                                acItem.pathComponentNumber = i + 1
                                var subItemArr: [ActionItem] = parentItem?.actionItems ?? [ActionItem]()
                                if self.containsActionItem(acItem, inActionItemArray: subItemArr) == false {
                                    subItemArr.append(acItem)
                                    subItemArr = subItemArr.sort { $0.cellName < $1.cellName }
                                    parItem.actionItems = subItemArr
                                }
                            }
                        }
                    }
                } else {
                    var isParentFolder = false
                    for imapFolder in emailAccount.folders {
                        let folder: MCOIMAPFolder = (imapFolder as! ImapFolder).mcoimapfolder
                        let folPath: NSString = NSString(string: folder.path)
                        let range: NSRange = folPath.rangeOfString(NSString(format: "%@/", fol.path) as String)
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
        
        
        actionItem.actionItems = subItems.sort { $0.cellName < $1.cellName }
        actionItem.folderExpanded = false
        return actionItem
    }
    
    //MARK: - Folder helper operations
    
    private func getParentItemFromItems(items: [ActionItem], andParentFolderName parentFolderName: String) -> ActionItem? {
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
    
    private func setConstraintsForSubFolderCell(cell: SideBarSubFolderTableViewCell, andPathComponentNumber pathComponentNumber: Int) -> Void {
        
        cell.menuImg.removeConstraints(cell.menuImg.constraints)
        cell.contentView.removeConstraints(cell.contentView.constraints)
        
        let constraint1: NSLayoutConstraint = NSLayoutConstraint(item: cell.menuImg, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: cell.contentView, attribute: NSLayoutAttribute.Leading, multiplier: 1.0, constant: (CGFloat(pathComponentNumber) * CGFloat(self.leftSpaceIncrement) + 33.0))
        cell.addConstraint(constraint1)
        
        let constraint2 = NSLayoutConstraint(item: cell.menuImg, attribute: .Top, relatedBy: .Equal, toItem: cell.contentView, attribute: .Top, multiplier: 1.0, constant: 0.0)
        cell.addConstraint(constraint2)
        
        let constraint3 = NSLayoutConstraint(item: cell.menuLabel, attribute: .Leading, relatedBy: .Equal, toItem: cell.menuImg, attribute: .Trailing, multiplier: 1.0, constant: 8.0)
        cell.addConstraint(constraint3)
        
        let constraint4 = NSLayoutConstraint(item: cell.contentView, attribute: .Trailing, relatedBy: .Equal, toItem: cell.menuLabel, attribute: .Trailing, multiplier: 1.0, constant: 20.0)
        cell.addConstraint(constraint4)
        
        let constraint5 = NSLayoutConstraint(item: cell.menuLabel, attribute: .Top, relatedBy: .Equal, toItem: cell.contentView, attribute: .Top, multiplier: 1.0, constant: 11.0)
        cell.addConstraint(constraint5)
        
        let constraint6 = NSLayoutConstraint(item: cell.menuImg, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1.0, constant: 43.0)
        cell.menuImg.addConstraint(constraint6)
        
        let constraint7 = NSLayoutConstraint(item: cell.menuImg, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 43.0)
        cell.menuImg.addConstraint(constraint7)
        
        cell.updateConstraints()
    }
    
    private func removeExpandedSubItemsWithActionItem(actionItem: ActionItem) -> Void {
        if actionItem.actionItems != nil && actionItem.actionItems?.count > 0 {
            for item in actionItem.actionItems! {
                if item.actionItems != nil && item.actionItems?.count > 0 {
                    self.removeExpandedSubItemsWithActionItem(item)
                }
                if item.folderExpanded == true {
                    var section: [ActionItem] = self.rows[1] as! [ActionItem]
                    let index: Int? = section.indexOf(item)
                    if let i = index {
                        section.removeRange((i + 1)...(item.actionItems!.count + i))
                        item.folderExpanded = false
                        self.rows[1] = section
                        self.tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: UITableViewRowAnimation.Automatic)
                    }
                }
            }
        }
    }
    
    private func containsActionItem(actionItem: ActionItem, inActionItemArray actionItemArray: [ActionItem]) -> Bool {
        for item in actionItemArray {
            if actionItem.cellName == item.cellName && actionItem.viewController == item.viewController &&
                actionItem.emailAccount == item.emailAccount && actionItem.cellIcon == item.cellIcon {
                    return true
            }
        }
        return false
    }
    
    private func removeActionItemFromArrayWithActionItem(actionItem: ActionItem, var withActionItemArray acArray: [ActionItem]) -> [ActionItem] {
        for var i = 0; i < acArray.count; i++ {
            let item = acArray[i]
            if actionItem.cellName == item.cellName && actionItem.viewController == item.viewController &&
                actionItem.emailAccount == item.emailAccount && actionItem.cellIcon == item.cellIcon {
                    acArray.removeAtIndex(i)
                    break
            }
        }
        return acArray
    }
    
    private func addItemToParentItemWithItem(childItem: ActionItem, andParentItemName parentName: String) -> Bool {
        let actionItems: [ActionItem] = self.rows[1] as! [ActionItem]
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
            parentItem?.actionItems = parItemArr.sort{ $0.cellName < $1.cellName }
            return true
        }
    }

}
