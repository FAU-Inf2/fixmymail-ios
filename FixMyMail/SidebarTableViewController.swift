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

    override func awakeFromNib() {
        self.tableView.registerNib(UINib(nibName: "SideBarSubFolderTableViewCell", bundle: nil), forCellReuseIdentifier: "SideBarSubFolder")
    }
    
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
            var actionItem = ActionItem(Name: emailAcc.accountName, viewController: "EmailSpecific", emailAddress: emailAcc.emailAddress, icon: PreferenceAccountListTableViewController.getImageFromEmailAccount(emailAcc))
            inboxRows.append(actionItem)
        }
        
        
        
        var settingsArr: [ActionItem] = [ActionItem]()
        settingsArr.append(ActionItem(Name: "TODO", viewController: "TODO"))
        settingsArr.append(ActionItem(Name: "Keychain", viewController: "KeyChain"))
        settingsArr.append(ActionItem(Name: "Preferences", viewController: "Preferences"))

        self.rows.append(inboxRows)
        self.rows.append(self.getIMAPFoldersFromCoreData(WithEmailAccounts: accountArr))
        self.rows.append(settingsArr)
        
        self.emailAccounts = accountArr
        self.fetchIMAPFolders()
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
                var inboxCell = tableView.dequeueReusableCellWithIdentifier("SideBarCell") as? SideBarTableViewCell
                if let cell = inboxCell {
                    let mailAcc: ActionItem = self.rows[indexPath.section][indexPath.row] as! ActionItem
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
            var inboxCell = tableView.dequeueReusableCellWithIdentifier("SideBarCell") as? SideBarTableViewCell
            if let cell = inboxCell {
                let actionItem: ActionItem = self.rows[indexPath.section][indexPath.row] as! ActionItem
                if actionItem.viewController == "NoVC" {
                    cell.selectionStyle = UITableViewCellSelectionStyle.None
                } else {
                    //cell.menuLabel.frame.origin.x += 20.0
                    //cell.menuImg.frame.origin.x += 20.0
                    
                }
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
        delegate?.cellSelected!(actionItem)
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
    
    
    //MARK: - IMAPFolder fetch
    
    func fetchIMAPFolders() -> Void {
        IMAPFolderFetcher.sharedInstance.getAllIMAPFoldersWithAccounts { (account, folders, sucess, newFolders) -> Void in
            if sucess == true {
                var actionItems: [ActionItem] = self.rows[1] as! [ActionItem]
                let accItem = ActionItem(Name: account!.accountName, viewController: "NoVC", emailAddress: account!.emailAddress, icon: PreferenceAccountListTableViewController.getImageFromEmailAccount(account!))
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
                        var actionItem = ActionItem(Name: account!.accountName, viewController: "NoVC", emailAddress: account!.emailAddress, icon: PreferenceAccountListTableViewController.getImageFromEmailAccount(account!))
                        newAccItemArr.append(actionItem)
                        for fol in folders! {
                            var item = ActionItem(Name: fol.path, viewController: "EmailSpecific", emailAddress: account!.emailAddress, emailFolder: fol)
                            newAccItemArr.append(item)
                        }
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
                            var actionItem = ActionItem(Name: account!.accountName, viewController: "NoVC", emailAddress: account!.emailAddress, icon: PreferenceAccountListTableViewController.getImageFromEmailAccount(account!))
                            firstPart.append(actionItem)
                            for fol in folders! {
                                var item = ActionItem(Name: fol.path, viewController: "EmailSpecific", emailAddress: account!.emailAddress, emailFolder: fol)
                                firstPart.append(item)
                            }
                            self.rows[1] = firstPart
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                self.tableView.reloadData()
                            })
                        } else {
                            var lastPart = Array(actionItems[indexTo!...actionItems.count - 1])
                            var actionItem = ActionItem(Name: account!.accountName, viewController: "NoVC", emailAddress: account!.emailAddress, icon: PreferenceAccountListTableViewController.getImageFromEmailAccount(account!))
                            firstPart.append(actionItem)
                            for fol in folders! {
                                var item = ActionItem(Name: fol.path, viewController: "EmailSpecific", emailAddress: account!.emailAddress, emailFolder: fol)
                                firstPart.append(item)
                            }
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
                        var actionItem = ActionItem(Name: account!.accountName, viewController: "NoVC", emailAddress: account!.emailAddress, icon: PreferenceAccountListTableViewController.getImageFromEmailAccount(account!))
                        actionItems.append(actionItem)
                        for fol in folders! {
                            var item = ActionItem(Name: fol.path, viewController: "EmailSpecific", emailAddress: account!.emailAddress, emailFolder: fol)
                            actionItems.append(item)
                        }
                        self.rows[1] = actionItems
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.tableView.reloadData()
                        })
                    }
                }
            }
        }
    }
    
    func getIMAPFoldersFromCoreData(WithEmailAccounts emailAccounts: [EmailAccount]) -> [ActionItem] {
        var actionItems = [ActionItem]()
        for account in emailAccounts {
            if account.folders.count > 0 {
                var actionItem = ActionItem(Name: account.accountName, viewController: "NoVC", emailAddress: account.emailAddress, icon: PreferenceAccountListTableViewController.getImageFromEmailAccount(account))
                actionItems.append(actionItem)
                for imapFolder in account.folders {
                    var imapFol: ImapFolder = imapFolder as! ImapFolder
                    let fol: MCOIMAPFolder = imapFol.mcoimapfolder as MCOIMAPFolder
                    var item = ActionItem(Name: fol.path, viewController: "EmailSpecific", emailAddress: account.emailAddress, emailFolder: fol)
                    actionItems.append(item)
                }
            }
        }
        return actionItems
    }

}
