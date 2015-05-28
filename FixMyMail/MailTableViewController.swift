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
    
    //@IBOutlet weak var cell: CustomMailTableViewCell!
    var managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext as NSManagedObjectContext!
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let mailFetchRequest = NSFetchRequest(entityName: "Email")
        let primarySortDescriptor = NSSortDescriptor(key: "sender", ascending: true)
        mailFetchRequest.sortDescriptors = [primarySortDescriptor];
        
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
        
        //self.mailTableView.contentInset = UIEdgeInsetsMake(0, 0, 35, 0)
        self.mailTableView.registerNib(UINib(nibName: "CustomMailTableViewCell", bundle: nil), forCellReuseIdentifier: "MailCell")
        self.refreshControl = UIRefreshControl()
        self.refreshControl.addTarget(self, action: "pullToRefresh", forControlEvents: UIControlEvents.ValueChanged)
        self.mailTableView.addSubview(self.refreshControl)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshTableView:", name: "notification", object: nil)
        NSLog("viewdidload")
        
        var error: NSError? = nil
        if (fetchedResultsController.performFetch(&error) == false) {
            print("An error occurred: \(error?.localizedDescription)")
        }

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
        self.navigationController?.setToolbarHidden(false, animated: animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setToolbarHidden(true, animated: animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    
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
    
    func refreshTableView(notifaction: NSNotification) {
        var error: NSError? = nil
        if (fetchedResultsController.performFetch(&error) == false) {
            print("An error occurred: \(error?.localizedDescription)")
        }
        self.managedObjectContext.save(nil)
        self.mailTableView.reloadData()
    }
    
    //PullToRefresh
    func pullToRefresh() {
        
        //Fetch Account Data
        var account : EmailAccount?
        let session = MCOIMAPSession()
        let fetchRequest: NSFetchRequest = NSFetchRequest(entityName: "EmailAccount")
        var error: NSError?
        var result = managedObjectContext.executeFetchRequest(fetchRequest, error: &error)
        if error != nil {
            NSLog("%@", error!.description)
        } else {
            if let emailAccounts = result {
                account = emailAccounts[0] as? EmailAccount
                session.hostname = account!.imapHostname
                session.port = account!.imapPort
                session.username = account!.username
                session.password = account!.password
                session.authType = MCOAuthType.SASLPlain
                session.connectionType = MCOConnectionType.TLS
            }
        }
        
        let requestKind:MCOIMAPMessagesRequestKind = (MCOIMAPMessagesRequestKind.Headers | MCOIMAPMessagesRequestKind.Structure |
            MCOIMAPMessagesRequestKind.InternalDate | MCOIMAPMessagesRequestKind.HeaderSubject |
            MCOIMAPMessagesRequestKind.Flags)
        
        let fetchallOp = session.fetchMessagesByNumberOperationWithFolder("INBOX", requestKind: requestKind, numbers: MCOIndexSet(range: MCORangeMake(1, UINT64_MAX)))
        
        fetchallOp.start({(error, messages, range) in
            if error != nil {
                NSLog("Could not load messages: %@", error)
            } else {
                self.managedObjectContext!.performBlockAndWait({ () -> Void in
                    NSLog("mailcount:%i", messages.count)
                    for message in messages {
                        var newMail = true
                        var managedObjectContext: NSManagedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!
                        let fetchRequest: NSFetchRequest = NSFetchRequest(entityName: "EmailAccount")
                        var error: NSError?
                        var result = managedObjectContext.executeFetchRequest(fetchRequest, error: &error)
                        if error != nil {
                            NSLog("%@", error!.description)
                        } else {
                            if let emailAccounts = result {
                                let emailAccount : EmailAccount = emailAccounts[0] as! EmailAccount
                                for emails in emailAccount.emails {
                                    if ((emails as! Email).mcomessage as! MCOIMAPMessage).uid == (message as! MCOIMAPMessage).uid {
                                        newMail = false
                                        break
                                    }
                                }
                            }
                        }
                        
                        if newMail == true {
                            var newEmail: Email = NSEntityDescription.insertNewObjectForEntityForName("Email", inManagedObjectContext: self.managedObjectContext!) as! Email
                            newEmail.mcomessage = message
                            newEmail.sender = ""
                            newEmail.title = ""
                            
                            let fetchOp = session.fetchMessageOperationWithFolder("INBOX", uid: (message as! MCOIMAPMessage).uid)
                            
                            fetchOp.start({(error, data) in
                                if error != nil {
                                    NSLog("Could not recieve mail: %@", error)
                                } else {
                                    newEmail.data = data
                                    let parser: MCOMessageParser! = MCOMessageParser(data: data)
                                    newEmail.sender = parser.header.from.displayName
                                    newEmail.title = parser.header.subject
                                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                        NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "notification", object: nil))
                                    })
                                }
                            })
                            newEmail.toAccount = account!
                        }
                    }
                })
            }
        })
        
        self.managedObjectContext!.save(&error)
        
        if error != nil {
            NSLog("%@", error!.description)
        }
        
        NSLog("refeshed")
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
        var mailView: MCTMsgViewController = MCTMsgViewController()
        mailView.message = (mailTableView.cellForRowAtIndexPath(indexPath) as! CustomMailTableViewCell).mail?.mcomessage as! MCOIMAPMessage
        var session: MCOIMAPSession = MCOIMAPSession()
        let fetchRequest: NSFetchRequest = NSFetchRequest(entityName: "EmailAccount")
        var error: NSError?
        var result = managedObjectContext.executeFetchRequest(fetchRequest, error: &error)
        if error != nil {
            NSLog("%@", error!.description)
        } else {
            if let emailAccounts = result {
                var account = emailAccounts[0] as? EmailAccount
                session.hostname = account!.imapHostname
                session.port = account!.imapPort
                session.username = account!.username
                session.password = account!.password
                session.authType = MCOAuthType.SASLPlain
                session.connectionType = MCOConnectionType.TLS
            }
        }
        mailView.session = session
        mailView.folder = "INBOX"
        self.navigationController?.pushViewController(mailView, animated: true)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
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
            managedObjectContext.deleteObject(mail!)
            
            managedObjectContext.save(nil)
            mailTableView.reloadData()
            
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
