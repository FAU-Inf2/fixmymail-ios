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
    var delegate: SideBarProtocol?
    var emailAccounts: [EmailAccount] = [EmailAccount]()
    var currAccountName: String?
    @IBOutlet weak var subFolderLeftSpaceConstraint: NSLayoutConstraint!
    let leftSpaceIncrement: Float = 20.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var accountArr: [EmailAccount] = [EmailAccount]();
        let appDel: AppDelegate? = UIApplication.sharedApplication().delegate as? AppDelegate
        if let appDelegate = appDel {
            managedObjectContext = appDelegate.managedObjectContext
            var emailAccountsFetchRequest = NSFetchRequest(entityName: "EmailAccount")
            var error: NSError?
            let acc: [EmailAccount]? = managedObjectContext.executeFetchRequest(emailAccountsFetchRequest, error: &error) as? [EmailAccount]
            if let account = acc {
                //For fist expand comand
                self.currAccountName = self.currAccountName == nil ? account[0].accountName : self.currAccountName
                for emailAcc: EmailAccount in account {
                    accountArr.append(emailAcc)
                }
            } else {
                if((error) != nil) {
                    NSLog(error!.description)
                }
            }
        }
        
        self.sections = ["Inboxes", "Accounts", ""]
        var inboxRows: [ActionItem] = [ActionItem]()
        inboxRows.append(ActionItem(Name: "All", viewController: "EmailAll", icon: UIImage(named: "smile-gray.png")))
        for emailAcc: EmailAccount in accountArr {
            var actionItem = ActionItem(Name: emailAcc.accountName, viewController: "EmailSpecific", emailAccount: emailAcc, icon: PreferenceAccountListTableViewController.getImageFromEmailAccount(emailAcc))
            inboxRows.append(actionItem)
        }
        
        
        
        var settingsArr: [ActionItem] = [ActionItem]()
        settingsArr.append(ActionItem(Name: "REMIND ME!", viewController: "TODO"))
        settingsArr.append(ActionItem(Name: "Keychain", viewController: "KeyChain"))
        settingsArr.append(ActionItem(Name: "Preferences", viewController: "Preferences"))

        self.rows.append(inboxRows)
        self.rows.append(self.getIMAPFoldersFromCoreData(WithEmailAccounts: accountArr))
        self.rows.append(settingsArr)
        self.tableView.reloadData()
        
        self.emailAccounts = accountArr
        self.fetchIMAPFolders()
    }
    
    override func viewWillAppear(animated: Bool) {
        if let currAccName = self.currAccountName {
            var sectionItems: [ActionItem] = self.rows[1] as! [ActionItem]
            var indexOfLastAcc: Int!
            for item in sectionItems {
                if item.cellName == self.currAccountName! {
                    indexOfLastAcc = find(sectionItems, item)
                    
                    var firstPart: [ActionItem] = Array(sectionItems[0...indexOfLastAcc])
                    var lastPart: [ActionItem]? = (sectionItems.count - 1) == indexOfLastAcc ? nil : Array(sectionItems[(indexOfLastAcc + 1)...(sectionItems.count - 1)])
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
                var inboxCell = tableView.dequeueReusableCellWithIdentifier("SideBarCell") as? SideBarTableViewCell
                if let cell = inboxCell {
                    if(indexPath.row == 0) {
                        cell.menuLabel.text = "All"
                    } else {
                        cell.menuLabel.text = mailAcc.cellName
                    }
                    if let icon = mailAcc.cellIcon {
                        cell.menuImg.image = icon
                    } else {
                        cell.menuImg.image = nil
                    }
                    
                    return cell
                } else {
                    NSBundle.mainBundle().loadNibNamed("SideBarTableViewCell", owner: self, options: nil)
                    var sideBarCell: SideBarTableViewCell = self.sidebarCell
                    self.sidebarCell = nil
                    let mailAcc: ActionItem = self.rows[indexPath.section][indexPath.row] as! ActionItem
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
                }
            } else {
                var accCell: AnyObject? = self.tableView.dequeueReusableCellWithIdentifier("SideBarSubFolder")
                if accCell != nil {
                    var cell = accCell as! SideBarSubFolderTableViewCell
                    let mailAcc: ActionItem = self.rows[indexPath.section][indexPath.row] as! ActionItem
                    cell.menuLabel.text = mailAcc.cellName
                    if let icon = mailAcc.cellIcon {
                        cell.menuImg.image = icon
                    } else {
                        cell.menuImg.image = nil
                    }
                    return cell
                } else {
                    var viewArr = NSBundle.mainBundle().loadNibNamed("SideBarSubFolderTableViewCell", owner: self, options: nil)
                    var cell = viewArr[0] as! SideBarSubFolderTableViewCell
                    let mailAcc: ActionItem = self.rows[indexPath.section][indexPath.row] as! ActionItem
                    cell.menuLabel.text = mailAcc.cellName
                    if let icon = mailAcc.cellIcon {
                        cell.menuImg.image = icon
                    } else {
                        cell.menuImg.image = nil
                    }
                    return cell
                }
            }
        } else if indexPath.section == 1 {
            let actionItem: ActionItem = self.rows[indexPath.section][indexPath.row] as! ActionItem
            if actionItem.viewController == "NoVC" {
                var inboxCell = tableView.dequeueReusableCellWithIdentifier("SideBarCell") as? SideBarTableViewCell
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
                    var sideBarCell: SideBarTableViewCell = self.sidebarCell
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
                var cell = viewArr[0] as! SideBarSubFolderTableViewCell
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
                        var triangleImageView: UIImageView = UIImageView(image: img)
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
            var inboxCell = tableView.dequeueReusableCellWithIdentifier("SideBarCell") as? SideBarTableViewCell
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
                var sideBarCell: SideBarTableViewCell = self.sidebarCell
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
            if actionItem.actionItems != nil {
                if actionItem.folderExpanded == false {
                    var sectionItems: [ActionItem] = self.rows[indexPath.section] as! [ActionItem]
                    var firstPart: [ActionItem] = Array(sectionItems[0...indexPath.row])
                    var lastPart: [ActionItem]? = (sectionItems.count - 1) == indexPath.row ? nil : Array(sectionItems[(indexPath.row + 1)...(sectionItems.count - 1)])
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
            if sucess == true {
                var actionItems: [ActionItem] = self.rows[1] as! [ActionItem]
                let accItem = ActionItem(Name: account!.accountName, viewController: "NoVC", emailAccount: account!, icon: PreferenceAccountListTableViewController.getImageFromEmailAccount(account!))
                var indexOfAccount: Int? = find(actionItems, accItem)
                if let index = indexOfAccount {
                    if index == 0 {
                        var indexTo: Int!
                        for var i = index; i < actionItems.count; i++ {
                            let item = actionItems[i]
                            if item.viewController == "NoVC" {
                                indexTo = i
                                break
                            }
                        }
                        var subArr = Array(actionItems[index...indexTo])
                        var newAccItemArr = [ActionItem]()
                        newAccItemArr.append(self.getActionItemsFromEmailAccount(account!, andFolders: folders))
                        for item in subArr {
                            newAccItemArr.append(item)
                        }
                        self.rows[1] = newAccItemArr
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.tableView.reloadData()
                        })
                    } else {
                        var firstPart = Array(actionItems[0...index])
                        var indexTo: Int? = nil
                        for var i = index; i < actionItems.count; i++ {
                            let item = actionItems[i]
                            if item.viewController == "NoVC" {
                                indexTo = i
                                break
                            }
                        }
                        if indexTo == nil {
                            firstPart.append(self.getActionItemsFromEmailAccount(account!, andFolders: folders))
                            self.rows[1] = firstPart
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                self.tableView.reloadData()
                            })
                        } else {
                            var lastPart = Array(actionItems[indexTo!...actionItems.count - 1])
                            firstPart.append(self.getActionItemsFromEmailAccount(account!, andFolders: folders))
                            for item in lastPart {
                                firstPart.append(item)
                            }
                            self.rows[1] = firstPart
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                self.tableView.reloadData()
                            })
                        }
                    }
                } else {
                    if newFolders == true {
                        actionItems.append(self.getActionItemsFromEmailAccount(account!, andFolders: folders))
                        self.rows[1] = actionItems
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.tableView.reloadData()
                        })
                    }
                }
            }
        }
    }
    
    private func getIMAPFoldersFromCoreData(WithEmailAccounts emailAccounts: [EmailAccount]) -> [ActionItem] {
        var resultItems = [ActionItem]()
        for account in emailAccounts {
            if account.folders.count > 0 {
                resultItems.append(self.getActionItemsFromEmailAccount(account, andFolders: nil))
            }
        }
        return resultItems
    }
    
    private func getActionItemsFromEmailAccount(emailAccount: EmailAccount, andFolders folders: [MCOIMAPFolder]?) -> ActionItem {
        var actionItem = ActionItem(Name: emailAccount.accountName, viewController: "NoVC", emailAccount: emailAccount, icon: PreferenceAccountListTableViewController.getImageFromEmailAccount(emailAccount))
        var subItems = [ActionItem]()
        if folders != nil {
            for fol in folders! {
                var pathComponents = fol.path.pathComponents
                if pathComponents.count > 1 {
                    for var i = 0; i < (pathComponents.count - 1); i++ {
                        let parentFolderName = pathComponents[i]
                        var parentItem: ActionItem? = self.getParentItemFromItems(subItems, andParentFolderName: parentFolderName)
                        if let parItem = parentItem {
                            if pathComponents[i + 1] != fol.path.lastPathComponent {
                                var acItem = ActionItem(Name: pathComponents[i + 1], viewController: "NoVC", emailAccount: emailAccount, icon: UIImage(named: "folder.png"))
                                var subItemArr: [ActionItem] = parentItem?.actionItems ?? [ActionItem]()
                                if contains(subItemArr, acItem) == false {
                                    subItemArr.append(acItem)
                                    acItem.actionItems = subItemArr
                                }
                            } else {
                                var acItem = ActionItem(Name: pathComponents[i + 1], viewController: "NoVC", emailAccount: emailAccount, icon: UIImage(named: "folder.png"), emailFolder: fol)
                                var subItemArr: [ActionItem] = parentItem?.actionItems ?? [ActionItem]()
                                if contains(subItemArr, acItem) == false {
                                    subItemArr.append(acItem)
                                    acItem.actionItems = subItemArr
                                }
                            }
                        }
                    }
                } else {
                    var item = ActionItem(Name: fol.path, viewController: "EmailSpecific", emailAccount: emailAccount, emailFolder: fol, icon: UIImage(named: "folder.png"))
                    if contains(subItems, item) == false {
                        subItems.append(item)
                    }
                }
            }
        } else {
            for imapFolder in emailAccount.folders {
                var fol: MCOIMAPFolder = (imapFolder as! ImapFolder).mcoimapfolder
                var pathComponents = fol.path.pathComponents
                if pathComponents.count > 1 {
                    for var i = 0; i < (pathComponents.count - 1); i++ {
                        let parentFolderName = pathComponents[i]
                        var parentItem: ActionItem?
                        for item in subItems {
                            if item.cellName == parentFolderName {
                                parentItem = item
                                break;
                            }
                        }
                        if let parItem = parentItem {
                            parItem.viewController = "SubFolder"
                            if pathComponents[i + 1] != fol.path.lastPathComponent {
                                var acItem = ActionItem(Name: pathComponents[i + 1], viewController: "SubFolder", emailAccount: emailAccount, icon: UIImage(named: "folder.png"))
                                var subItemArr: [ActionItem] = parentItem?.actionItems ?? [ActionItem]()
                                if contains(subItemArr, acItem) == false {
                                    subItemArr.append(acItem)
                                    acItem.actionItems = subItemArr
                                }
                            } else {
                                var acItem = ActionItem(Name: pathComponents[i + 1], viewController: "EmailSpecific", emailAccount: emailAccount, icon: UIImage(named: "folder.png"), emailFolder: fol)
                                acItem.pathComponentNumber = i + 1
                                var subItemArr: [ActionItem] = parentItem?.actionItems ?? [ActionItem]()
                                if contains(subItemArr, acItem) == false {
                                    subItemArr.append(acItem)
                                    parItem.actionItems = subItemArr
                                }
                            }
                        } else {
                            var acItem = ActionItem(Name: pathComponents[i], viewController: "SubFolder", emailAccount: emailAccount, icon: UIImage(named: "folder.png"))
                            acItem.pathComponentNumber = i
                            acItem.actionItems = [ActionItem]()
                        }
                    }
                } else {
                    var item = ActionItem(Name: fol.path, viewController: "EmailSpecific", emailAccount: emailAccount, emailFolder: fol, icon: UIImage(named: "folder.png"))
                    if contains(subItems, item) == false {
                        subItems.append(item)
                    }
                }
            }
        }
        
        
        actionItem.actionItems = subItems.sorted { $0.cellName < $1.cellName }
        actionItem.folderExpanded = false
        return actionItem
    }
    
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
        
        var constraints = cell.contentView.constraints() as? [NSLayoutConstraint]
        if let constArr = constraints {
            cell.removeConstraints(constArr)
        }
        
        var constraint1: NSLayoutConstraint = NSLayoutConstraint(item: cell.menuImg, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: cell.contentView, attribute: NSLayoutAttribute.Leading, multiplier: 1.0, constant: (CGFloat(pathComponentNumber) * CGFloat(self.leftSpaceIncrement) + 33.0))
        cell.addConstraint(constraint1)
        
        var constraint2 = NSLayoutConstraint(item: cell.menuImg, attribute: .Top, relatedBy: .Equal, toItem: cell.contentView, attribute: .Top, multiplier: 1.0, constant: 0.0)
        cell.addConstraint(constraint2)
        
        var constraint3 = NSLayoutConstraint(item: cell.menuLabel, attribute: .Leading, relatedBy: .Equal, toItem: cell.menuImg, attribute: .Trailing, multiplier: 1.0, constant: 8.0)
        cell.addConstraint(constraint3)
        
        var constraint4 = NSLayoutConstraint(item: cell.contentView, attribute: .Trailing, relatedBy: .Equal, toItem: cell.menuLabel, attribute: .Trailing, multiplier: 1.0, constant: 20.0)
        cell.addConstraint(constraint4)
        
        var constraint5 = NSLayoutConstraint(item: cell.menuLabel, attribute: .Top, relatedBy: .Equal, toItem: cell.contentView, attribute: .Top, multiplier: 1.0, constant: 11.0)
        cell.addConstraint(constraint5)
        
        var constraint6 = NSLayoutConstraint(item: cell.menuImg, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1.0, constant: 43.0)
        cell.addConstraint(constraint6)
        
        var constraint7 = NSLayoutConstraint(item: cell.menuImg, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 43.0)
        cell.addConstraint(constraint7)
        
        cell.updateConstraints()
    }

}
