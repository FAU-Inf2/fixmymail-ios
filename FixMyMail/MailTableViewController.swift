//
//  MailTableViewController.swift
//  FixMyMail
//
//  Created by Jan Weiß on 13.05.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit
import CoreData

class MailTableViewController: UIViewController, NSFetchedResultsControllerDelegate, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var mailTableView: UITableView!
    var refreshControl: UIRefreshControl!
    var delegate: ContentViewControllerProtocol?
    var session: MCOIMAPSession?
    var trashFolderName: String?
    
    //@IBOutlet weak var cell: CustomMailTableViewCell!
    var managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext as NSManagedObjectContext!
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let mailFetchRequest = NSFetchRequest(entityName: "Email")
        let primarySortDescriptor = NSSortDescriptor(key: "mcomessage.header.date", ascending: true)
        mailFetchRequest.sortDescriptors = [primarySortDescriptor];
        if let acc = self.getAccount() {
            if acc.count == 1 {
              mailFetchRequest.predicate = NSPredicate(format: "toAccount.emailAddress == %@", acc[0].emailAddress)
            }
        }
        
        let frc = NSFetchedResultsController(
            fetchRequest: mailFetchRequest,
            managedObjectContext: self.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        frc.delegate = self
        
        return frc
        }()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if getAccount() == nil {
            self.title = "SMile"
        }
        if getAccount()?.count > 1 {
            self.title = "All"
        } else {
            self.title = getAccount()?.first?.username
        }
        
        //self.mailTableView.contentInset = UIEdgeInsetsMake(0, 0, 35, 0)
        self.mailTableView.registerNib(UINib(nibName: "CustomMailTableViewCell", bundle: nil), forCellReuseIdentifier: "MailCell")
        self.refreshControl = UIRefreshControl()
        self.refreshControl.addTarget(self, action: "pullToRefresh", forControlEvents: UIControlEvents.ValueChanged)
        self.mailTableView.addSubview(self.refreshControl)
        
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshTableView:", name: "notification", object: nil)
        NSLog("viewdidload")
        
        var error: NSError? = nil
        if (fetchedResultsController.performFetch(&error) == false) {
            print("An error occurred: \(error?.localizedDescription)")
        }
        
        pullToRefresh()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        var menuItem: UIBarButtonItem = UIBarButtonItem(title: "   Menu", style: .Plain, target: self, action: "menuTapped:")
        self.navigationItem.leftBarButtonItem = menuItem
        //var editButton: UIBarButtonItem = UIBarButtonItem(title: "Edit", style: .Plain, target: self, action: "editToggled:")
        self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        var composeButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Compose, target: self, action: "showMailSendView")
        var items = [composeButton]
        self.navigationController?.visibleViewController.setToolbarItems(items, animated: animated)
        self.navigationController?.setToolbarHidden(false, animated: false)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setToolbarHidden(true, animated: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*override func viewDidDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }*/
    
    
    
    /*@IBAction func refresh(sender: AnyObject) {
        var error: NSError? = nil
        if (fetchedResultsController.performFetch(&error) == false) {
            print("An error occurred: \(error?.localizedDescription)")
        }
        self.mailTableView.reloadData()
    }*/
    
    /*func editToggled(sender: AnyObject) {
        if self.navigationItem.rightBarButtonItem?.title == "Edit" {
            self.navigationItem.rightBarButtonItem?.title = "Done"
            self.setEditing(true, animated: true)
        } else {
            self.navigationItem.rightBarButtonItem?.title = "Edit"
            self.setEditing(false, animated: true)
        }
    }*/
    
    func showMailSendView() {
        self.navigationController?.pushViewController(MailSendViewController(nibName: "MailSendViewController", bundle: nil), animated: true)
    }
    
    func refreshTableView(/*notifaction: NSNotification*/) {
        var error: NSError? = nil
        if (fetchedResultsController.performFetch(&error) == false) {
            print("An error occurred: \(error?.localizedDescription)")
        }
        
        self.managedObjectContext!.save(&error)
        if error != nil {
            NSLog("%@", error!.description)
        }

        self.mailTableView.reloadData()
    }
    
    func getMaxUID(account: EmailAccount) -> UInt32 {
        var maxUID : UInt32 = 0
        for email in account.emails {
            if ((email as! Email).mcomessage as! MCOIMAPMessage).uid > maxUID {
                maxUID = ((email as! Email).mcomessage as! MCOIMAPMessage).uid
            }
        }

        return maxUID
    }
    
    //PullToRefresh
    func pullToRefresh() {
        
        if let accounts = getAccount() {
            for account in accounts {
                NSLog("emailAdresse in pullToRefresh:  " + account.emailAddress)
                let session = getSession(account)
                
                let requestKind:MCOIMAPMessagesRequestKind = (MCOIMAPMessagesRequestKind.Uid | MCOIMAPMessagesRequestKind.Flags | MCOIMAPMessagesRequestKind.Headers)
                
                let fetchAllOp = session.fetchMessagesOperationWithFolder("INBOX", requestKind: requestKind, uids: MCOIndexSet(range: MCORangeMake(1, UINT64_MAX)))
                
                fetchAllOp.start({ (error, messages, range) -> Void in
                    if error != nil {
                        NSLog("Could not load messages: %@", error)
                    } else {
                        var newMails = 0
                        var emails: NSMutableArray = NSMutableArray(array: account.emails.allObjects)
                        for message in messages {
                            if (message as! MCOIMAPMessage).uid > self.getMaxUID(account) {
                                newMails++
                                var newEmail: Email = NSEntityDescription.insertNewObjectForEntityForName("Email", inManagedObjectContext: self.managedObjectContext!) as! Email
                                newEmail.mcomessage = message
                                if (message as! MCOIMAPMessage).header.from.displayName != nil {
                                    newEmail.sender = (message as! MCOIMAPMessage).header.from.displayName
                                }else if (message as! MCOIMAPMessage).header.sender.displayName != nil {
                                    newEmail.sender = (message as! MCOIMAPMessage).header.sender.displayName
                                }else {
                                    newEmail.sender = (message as! MCOIMAPMessage).header.sender.mailbox
                                }
                                newEmail.title = (message as! MCOIMAPMessage).header.subject
                                
                                let fetchOp = session.fetchMessageOperationWithFolder("INBOX", uid: (message as! MCOIMAPMessage).uid)
                                
                                fetchOp.start({(error, data) in
                                    if error != nil {
                                        NSLog("Could not recieve mail: %@", error)
                                    } else {
                                        newEmail.data = data
                                        let parser: MCOMessageParser! = MCOMessageParser(data: data)
                                        self.refreshTableView()
                                    }
                                })
                                newEmail.toAccount = account
                            } else {
                                for mail in emails {
                                    var email = mail as! Email
                                    if (email.mcomessage as! MCOIMAPMessage).uid == (message as! MCOIMAPMessage).uid {
                                        if (email.mcomessage as! MCOIMAPMessage).flags != (message as! MCOIMAPMessage).flags {
                                            NSLog("Updated Flags " + String((email.mcomessage as! MCOIMAPMessage).uid))
                                            email.mcomessage = (message as! MCOIMAPMessage)
                                        }
                                        emails.removeObject(mail)
                                        break
                                    }
                                }
                            }
                        }
                        for email in emails {
                            NSLog("email has been deleted by another device")
                            self.managedObjectContext.deleteObject(email as! Email)
                        }
                        NSLog("\(newMails) new Mails")
                        self.refreshTableView()
                    }
                })
            }
        }
        
        NSLog("refeshing..")
        self.refreshControl.endRefreshing()
    }

    // MARK: - Table view data source

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let sections = fetchedResultsController.sections {
            return sections.count
        }
        
        return 0
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultsController.sections {
            let currentSection = sections[section] as! NSFetchedResultsSectionInfo
            return currentSection.numberOfObjects
        }
        
        return 0
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var mailcell = tableView.dequeueReusableCellWithIdentifier("MailCell", forIndexPath: indexPath) as! CustomMailTableViewCell
        let mail = fetchedResultsController.objectAtIndexPath(indexPath) as! Email
        //if let mailcell = mycell {
            mailcell.mailFrom.text = mail.sender
            mailcell.mailBody.text = mail.title
            if (mail.mcomessage as! MCOIMAPMessage).flags & MCOMessageFlag.Seen == MCOMessageFlag.Seen{
                mailcell.unseendot.hidden = true
            } else {
                mailcell.unseendot.hidden = false
            }
            mailcell.mail = mail
        
            return mailcell
        /*} else {
            NSBundle.mainBundle().loadNibNamed("CustomMailTableViewCell", owner: self, options: nil)
            var mailcell: CustomMailTableViewCell = self.cell
            self.cell = nil
            
            mailcell.mail = mail
            mailcell.mailFrom.text = mail.sender
            mailcell.mailBody.text = mail.title
            
            return mailcell
        }*/
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        /*var mailView: MCTMsgViewController = MCTMsgViewController()
        mailView.message = (mailTableView.cellForRowAtIndexPath(indexPath) as! CustomMailTableViewCell).mail?.mcomessage as! MCOIMAPMessage
        var session: MCOIMAPSession = getSession()
        
        mailView.session = session
        mailView.folder = "INBOX"
        self.navigationController?.pushViewController(mailView, animated: true)*/
        var mailView: WebViewController = WebViewController()
        mailView.putMessage()
        mailView.message = (mailTableView.cellForRowAtIndexPath(indexPath) as! CustomMailTableViewCell).mail
        var session: MCOIMAPSession = getSession(mailView.message.toAccount)
        mailView.session = session
        self.navigationController?.pushViewController(mailView, animated: true)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        //set seen flag
        if (mailView.message.mcomessage as! MCOIMAPMessage).flags & MCOMessageFlag.Seen != MCOMessageFlag.Seen {
            var newmcomessage = (mailView.message.mcomessage as! MCOIMAPMessage)
            newmcomessage.flags |= MCOMessageFlag.Seen
            mailView.message.mcomessage = newmcomessage
            let setSeenFlagOP = session.storeFlagsOperationWithFolder("INBOX", uids: MCOIndexSet(index: UInt64((mailView.message.mcomessage as! MCOIMAPMessage).uid)), kind: MCOIMAPStoreFlagsRequestKind.Add, flags: MCOMessageFlag.Seen)
            
            setSeenFlagOP.start({ (error) -> Void in
                if let error = error {
                    NSLog("error in setSeenFlagOP: \(error.userInfo)")
                } else {
                    NSLog("email.seenflag = true")
                    
                    let expangeFolder = session.expungeOperation("INBOX")
                    expangeFolder.start({ (error) -> Void in })
                }
            })
            
            self.refreshTableView()
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let sections = fetchedResultsController.sections {
            let currentSection = sections[section] as! NSFetchedResultsSectionInfo
            return currentSection.name
        }
        
        return nil
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            let mail = (tableView.cellForRowAtIndexPath(indexPath) as! CustomMailTableViewCell).mail
            
            let session = getSession(mail.toAccount)
            
            //get trashFolderName
            let fetchFoldersOp = session.fetchAllFoldersOperation()
            var folders = [MCOIMAPFolder]()
            fetchFoldersOp.start({ (error, folders) -> Void in
                for folder in folders {
                    if self.trashFolderName != nil {
                        break
                    }
                    if ((folder as! MCOIMAPFolder).flags & MCOIMAPFolderFlag.Trash) == MCOIMAPFolderFlag.Trash {
                        self.trashFolderName = (folder as! MCOIMAPFolder).path
                        //NSLog("found it" + self.trashFolderName!)
                        break
                    }
                }
                if self.trashFolderName != nil {
                    //copy email to trash folder
                    let localCopyMessageOperation = session.copyMessagesOperationWithFolder("INBOX", uids: MCOIndexSet(index: UInt64((mail.mcomessage as! MCOIMAPMessage).uid)), destFolder: self.trashFolderName)
                    
                    localCopyMessageOperation.start {(error, uidMapping) -> Void in
                        if let error = error {
                            NSLog("error in deleting email : \(error.userInfo!)")
                        }
                    }
                    
                    //set deleteFlag
                    let setDeleteFlagOP = session.storeFlagsOperationWithFolder("INBOX", uids: MCOIndexSet(index: UInt64((mail.mcomessage as! MCOIMAPMessage).uid)), kind: MCOIMAPStoreFlagsRequestKind.Add, flags: MCOMessageFlag.Deleted)
                    
                    setDeleteFlagOP.start({ (error) -> Void in
                        if let error = error {
                            NSLog("error in deleting email (flags) : \(error.userInfo)")
                        } else {
                            NSLog("email deleted")
                            
                            let expangeFolder = session.expungeOperation("INBOX")
                            expangeFolder.start({ (error) -> Void in })
                        }
                    })
                    
                    self.managedObjectContext.deleteObject(mail!)
                    
                    var error: NSError? = nil
                    self.managedObjectContext!.save(&error)
                    if error != nil {
                        NSLog("%@", error!.description)
                    }
                    self.mailTableView.reloadData()
                    
                } else {
                    NSLog("error: trashFolderName == nil")
                }
            })
            
        } else if editingStyle == UITableViewCellEditingStyle.Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Delete:
            mailTableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
        default: break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        mailTableView.endUpdates()
    }
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        mailTableView.beginUpdates()
    }
    
    func getSession(account: EmailAccount) -> MCOIMAPSession {
        //if self.session == nil {
            self.session = MCOIMAPSession()
        
            self.session!.hostname = account.imapHostname
            self.session!.port = account.imapPort
            self.session!.username = account.username
            self.session!.password = account.password
            self.session!.authType = MCOAuthType.SASLPlain
            self.session!.connectionType = MCOConnectionType.TLS
        //}
        
        return self.session!
    }

    func getAccount() -> [EmailAccount]? {
        var retaccount = [EmailAccount]()
        let fetchRequest: NSFetchRequest = NSFetchRequest(entityName: "EmailAccount")
        var error: NSError?
        var result = managedObjectContext.executeFetchRequest(fetchRequest, error: &error)
        if error != nil {
            NSLog("%@", error!.description)
        } else {
            if let emailAccounts = result {
                for account in emailAccounts {
                    if (account as! EmailAccount).active {
                        retaccount.append(account as! EmailAccount)
                    }
                }
            }
        }
        
        return retaccount
    }
    /*
    // Override to support conditional editing of the table view.
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
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
    func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
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
    
    @IBAction func menuTapped(sender: AnyObject) -> Void {
        self.delegate?.toggleLeftPanel()
    }

}
