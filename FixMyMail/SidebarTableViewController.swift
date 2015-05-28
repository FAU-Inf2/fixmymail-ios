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

class ActionItem: NSObject {
    var cellIcon: UIImage?
    var cellName: String
    var viewController: String
    var mailAdress: String?
    
    init(Name: String, viewController: String, mailAdress: String? = nil, icon: UIImage? = nil) {
        self.cellName = Name
        self.cellIcon = icon
        self.viewController = viewController
        self.mailAdress = mailAdress
    }
}

class SidebarTableViewController: UITableViewController {
    
    @IBOutlet var sidebarCell: SideBarTableViewCell!
    var sections = [String]()
    var rows = [AnyObject]()
    var managedObjectContext: NSManagedObjectContext!
    var delegate: SideBarProtocol?

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
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
        inboxRows.append(ActionItem(Name: "All", viewController: "EmailAll"))
        for emailAcc: EmailAccount in accountArr {
            var actionItem = ActionItem(Name: emailAcc.username, viewController: "EmailSpecific", mailAdress: emailAcc.emailAddress)
            inboxRows.append(actionItem)
        }
        
        var settingsArr: [ActionItem] = [ActionItem]()
        settingsArr.append(ActionItem(Name: "TODO", viewController: "TODO"))
        settingsArr.append(ActionItem(Name: "Keychain", viewController: "KeyChain"))
        settingsArr.append(ActionItem(Name: "Preferences", viewController: "Preferences"))

        self.rows.append(inboxRows)
        self.rows.append([])
        self.rows.append(settingsArr)
        
        
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
            var inboxCell = tableView.dequeueReusableCellWithIdentifier("SideBarCell") as? SideBarTableViewCell
            if let cell = inboxCell {
                if(indexPath.row == 0) {
                    cell.menuLabel.text = "All"
                } else {
                    let mailAcc: ActionItem = self.rows[indexPath.section][indexPath.row] as! ActionItem
                    cell.menuLabel.text = mailAcc.cellName
                }
                
                return cell
            } else {
                NSBundle.mainBundle().loadNibNamed("SideBarTableViewCell", owner: self, options: nil)
                var sideBarCell: SideBarTableViewCell = self.sidebarCell
                self.sidebarCell = nil
                if(indexPath.row == 0) {
                    sideBarCell.menuLabel.text = "All"
                } else {
                    let mailAcc: ActionItem = self.rows[indexPath.section][indexPath.row] as! ActionItem
                    sideBarCell.menuLabel.text = mailAcc.cellName
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
