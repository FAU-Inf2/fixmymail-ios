//
//  MailTableViewController.swift
//  FixMyMail
//
//  Created by Jan Weiß on 13.05.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit
import CoreData

class MailTableViewController: UIViewController, NSFetchedResultsControllerDelegate, UITableViewDataSource, UITableViewDelegate, TableViewCellDelegate, UIActionSheetDelegate {
    
    @IBOutlet weak var mailTableView: UITableView!
    var refreshControl: UIRefreshControl!
    var delegate: ContentViewControllerProtocol?
    var session: MCOIMAPSession?
    var trashFolderName: String?
    var selectedEmails = NSMutableArray()
    var allCellsSelected = false
    var folderToQuery: String?
    
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

        var menuItem: UIBarButtonItem = UIBarButtonItem(title: "Menu", style: .Plain, target: self, action: "menuTapped:")
        self.navigationItem.leftBarButtonItems = [menuItem]
        var editButton: UIBarButtonItem = UIBarButtonItem(title: "Edit", style: .Plain, target: self, action: "editToggled:")
        self.navigationItem.rightBarButtonItem = editButton
        mailTableView.allowsMultipleSelectionDuringEditing = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setToolbarWithComposeButton()
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
    
    func showMailSendView() {
        if self.getAccount()?.first != nil {
            var sendView = MailSendViewController(nibName: "MailSendViewController", bundle: nil)
            sendView.account = self.getAccount()!.first!
            self.navigationController?.pushViewController(sendView, animated: true)
        }
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
        /*if let accounts = getAccount(){
            for account in accounts {
                NSLog("emailAdresse in pullToRefresh:  " + account.emailAddress)
                let session = getSession(account)
                
                let requestKind:MCOIMAPMessagesRequestKind = (MCOIMAPMessagesRequestKind.Uid | MCOIMAPMessagesRequestKind.Flags | MCOIMAPMessagesRequestKind.Headers)
                
                //Check for new Emails
                var currentMaxUID = self.getMaxUID(account)
                var localEmails = account.emails
                let fetchNewEmailsOp = session.fetchMessagesOperationWithFolder("INBOX", requestKind: requestKind, uids: MCOIndexSet(range: MCORangeMake(UInt64(currentMaxUID+1), UINT64_MAX)))
                
                fetchNewEmailsOp.start({ (error, messages, range) -> Void in
                    if error != nil {
                        NSLog("Could not load messages: %@", error)
                    } else {
                        NSLog("%i new Emails", messages.count)
                        //Load new Emails
                        for message in messages {
                            var newEmail: Email = NSEntityDescription.insertNewObjectForEntityForName("Email", inManagedObjectContext: self.managedObjectContext!) as! Email
                            newEmail.mcomessage = message
                            
                            //Set sender
                            if (message as! MCOIMAPMessage).header.from.displayName != nil {
                                newEmail.sender = (message as! MCOIMAPMessage).header.from.displayName
                            }else if (message as! MCOIMAPMessage).header.sender.displayName != nil {
                                newEmail.sender = (message as! MCOIMAPMessage).header.sender.displayName
                            }else {
                                newEmail.sender = (message as! MCOIMAPMessage).header.sender.mailbox
                            }
                            
                            //Set Title
                            newEmail.title = (message as! MCOIMAPMessage).header.subject
                            
                            //Fetch data
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
                        }
                    }
                })
                
                //Check for deleted Emails and update Flags
                let fetchMessageInfoForLocalEmails = session.fetchMessagesOperationWithFolder("INBOX", requestKind: requestKind, uids: MCOIndexSet(range: MCORangeMake(1, UInt64(currentMaxUID))))
                
                fetchMessageInfoForLocalEmails.start({ (error, messages, range) -> Void in
                    if currentMaxUID == 0 {
                        return
                    }
                    if error != nil {
                        NSLog("Could not update local Emails: %@", error)
                    }else {
                        NSLog(String(localEmails.count) + " LocalEmails   " + account.emailAddress)
                        NSLog(String(messages.count) + " EmailsOnServer   " + account.emailAddress)
                        for mail in localEmails {
                            var deleted = true
                            for message in messages {
                                if (message as! MCOIMAPMessage).uid == ((mail as! Email).mcomessage as! MCOIMAPMessage).uid {
                                    if ((mail as! Email).mcomessage as! MCOIMAPMessage).flags != (message as! MCOIMAPMessage).flags{
                                        NSLog("Updated Flags " + String(((mail as! Email).mcomessage as! MCOIMAPMessage).uid))
                                        (mail as! Email).mcomessage = (message as! MCOIMAPMessage)
                                    }
                                    deleted = false
                                    continue
                                }
                            }
                            
                            if deleted {
                                NSLog("email has been deleted by another device")
                                self.managedObjectContext.deleteObject(mail as! NSManagedObject)
                                self.refreshTableView()
                            }
                        }
                    }
                    self.refreshTableView()
                })
            }
        }*/
        
        
        if let accounts = getAccount() {
            for account in accounts {
                NSLog("emailAdresse in pullToRefresh:  " + account.emailAddress)
                let session = getSession(account)
                
                let requestKind:MCOIMAPMessagesRequestKind = (MCOIMAPMessagesRequestKind.Uid | MCOIMAPMessagesRequestKind.Flags | MCOIMAPMessagesRequestKind.Headers)
                
                if self.folderToQuery == nil {
                    self.folderToQuery = "INBOX"
                }
                
                let fetchAllOp = session.fetchMessagesOperationWithFolder(self.folderToQuery!, requestKind: requestKind, uids: MCOIndexSet(range: MCORangeMake(1, UINT64_MAX)))
                
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
                                
                                let fetchOp = session.fetchMessageOperationWithFolder(self.folderToQuery!, uid: (message as! MCOIMAPMessage).uid)
                                
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
        
        mailcell.mailFrom.text = mail.sender
        mailcell.mailBody.text = mail.title
        mailcell.height = mailTableView.rowHeight
        mailcell.delegate = self
        
        if (mail.mcomessage as! MCOIMAPMessage).flags & MCOMessageFlag.Seen == MCOMessageFlag.Seen{
            mailcell.unseendot.hidden = true
        } else {
            mailcell.unseendot.hidden = false
        }
        mailcell.mail = mail
        
        return mailcell
    }
    
    func setEmailToSeen(mail: Email) {
        if (mail.mcomessage as! MCOIMAPMessage).flags & MCOMessageFlag.Seen != MCOMessageFlag.Seen {
            //Set seen flag local
            var newmcomessage = (mail.mcomessage as! MCOIMAPMessage)
            newmcomessage.flags |= MCOMessageFlag.Seen
            mail.mcomessage = newmcomessage
            
            //set seen flag remote
            var session = getSession(mail.toAccount)
            let setSeenFlagOP = session.storeFlagsOperationWithFolder("INBOX", uids: MCOIndexSet(index: UInt64((mail.mcomessage as! MCOIMAPMessage).uid)), kind: MCOIMAPStoreFlagsRequestKind.Add, flags: MCOMessageFlag.Seen)
            
            setSeenFlagOP.start({ (error) -> Void in
                if let error = error {
                    NSLog("error in setSeenFlagOP: \(error.userInfo)")
                } else {
                    let expangeFolder = session.expungeOperation("INBOX")
                    expangeFolder.start({ (error) -> Void in })
                }
            })
        }
    }
    
    func setEmailToUnSeen(mail: Email) {
        if (mail.mcomessage as! MCOIMAPMessage).flags & MCOMessageFlag.Seen == MCOMessageFlag.Seen {
            //remove seen flag local
            var newmcomessage = (mail.mcomessage as! MCOIMAPMessage)
            newmcomessage.flags &= ~MCOMessageFlag.Seen
            mail.mcomessage = newmcomessage
            
            //remove seen flag remote
            var session = getSession(mail.toAccount)
            let removeSeenFlagOP = session.storeFlagsOperationWithFolder("INBOX", uids: MCOIndexSet(index: UInt64((mail.mcomessage as! MCOIMAPMessage).uid)), kind: MCOIMAPStoreFlagsRequestKind.Remove, flags: MCOMessageFlag.Seen)
            
            removeSeenFlagOP.start({ (error) -> Void in
                if let error = error {
                    NSLog("error in removeSeenFlagOP: \(error.userInfo)")
                }else {
                    let expangeFolder = session.expungeOperation("INBOX")
                    expangeFolder.start({ (error) -> Void in })
                }
            })
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = mailTableView.cellForRowAtIndexPath(indexPath) as! CustomMailTableViewCell
        if !(cell.editing) {
            var mailView: WebViewController = WebViewController()
            mailView.putMessage()
            mailView.message = cell.mail
            mailView.session = getSession(mailView.message.toAccount)
            self.navigationController?.pushViewController(mailView, animated: true)
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            
            setEmailToSeen(mailView.message)
            
            self.refreshTableView()
        } else {
            selectedEmails.addObject(cell.mail)
            setToolbarWhileEditingAndSomethingSelected()
        }
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        selectedEmails.removeObject((mailTableView.cellForRowAtIndexPath(indexPath) as! CustomMailTableViewCell).mail)
        if selectedEmails.count == 0 {
            setToolbarWhileEditingAndNothingSelected()
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let sections = fetchedResultsController.sections {
            let currentSection = sections[section] as! NSFetchedResultsSectionInfo
            return currentSection.name
        }
        
        return nil
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
            self.session!.port = UInt32(account.imapPort.unsignedIntegerValue)
            self.session!.username = account.username
            let (dictionary, error) = Locksmith.loadDataForUserAccount(account.emailAddress)
            if error == nil {
                self.session!.password = dictionary?.valueForKey("Password:") as! String
            }
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
    
    func deleteEmail(mail: Email) {
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
                
                self.managedObjectContext.deleteObject(mail)
                
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
    }
    
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.None
    }
    
    func tableView(tableView: UITableView, shouldIndentWhileEditingRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    
    func editToggled(sender: AnyObject) {
        if self.navigationItem.rightBarButtonItem?.title == "Edit" {
            self.navigationItem.rightBarButtonItem?.title = "Done"
            selectedEmails.removeAllObjects()
            setToolbarWhileEditingAndNothingSelected()
            mailTableView.setEditing(true, animated: true)
        } else {
            endEditing()
        }
    }
    
    func markAllButtonAction() {
        for var i = 0; i < mailTableView.numberOfRowsInSection(0); i++ {
            var cell = tableView(mailTableView, cellForRowAtIndexPath: NSIndexPath(forRow: i, inSection: 0)) as! CustomMailTableViewCell
            selectedEmails.addObject(cell.mail)
        }
        allCellsSelected = true
        viewActionSheetWithDeleteAll()
    }
    
    func markButtonAction(){
        viewActionSheet()
    }
    
    func moveButtonAction(){
    
    }
    
    func deleteButtonAction(){
        for var i = 0; i < selectedEmails.count; i++ {
            deleteEmail(selectedEmails[i] as! Email)
        }
        endEditing()
    }
    
    func viewActionSheetWithDeleteAll(){
        var actionSheet = UIActionSheet(title: nil, delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil, otherButtonTitles: "Mark as Read", "Mark as Unread", "Delete All")
        actionSheet.destructiveButtonIndex = 3
        actionSheet.showInView(self.view)
    }
    
    func viewActionSheet() {
        var actionSheet = UIActionSheet(title: nil, delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil, otherButtonTitles: "Mark as Read", "Mark as Unread")
        actionSheet.showInView(self.view)
    }
    
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        var actionSheetWithDeleteAll = (actionSheet.destructiveButtonIndex == 3)

        switch buttonIndex {
        case 1: //Mark as Read
            for var i = 0; i < selectedEmails.count; i++ {
                setEmailToSeen(selectedEmails[i] as! Email)
            }
            endEditing()
        case 2: //Mark as Unread
            for var i = 0; i < selectedEmails.count; i++ {
                setEmailToUnSeen(selectedEmails[i] as! Email)
            }
            endEditing()
        case 3: //Delete All
            deleteButtonAction()
        case 0: //Cancel
            if allCellsSelected {
                selectedEmails.removeAllObjects()
            }
            allCellsSelected = false
        default:
            break
        }
        
        
    }
    
    func endEditing() {
        self.navigationItem.rightBarButtonItem?.title = "Edit"
        setToolbarWithComposeButton()
        self.refreshTableView()
        mailTableView.layoutIfNeeded()
        mailTableView.setEditing(false, animated: true)
    }
    
    func setToolbarWithComposeButton() {
        var composeButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Compose, target: self, action: "showMailSendView")
        var items = [UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil), composeButton]
        self.navigationController?.visibleViewController.setToolbarItems(items, animated: false)
        self.navigationController?.setToolbarHidden(false, animated: false)
    }
    
    func setToolbarWhileEditingAndNothingSelected() {
        var flexibleSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        var markAllButton = UIBarButtonItem(title: "Mark All", style: UIBarButtonItemStyle.Plain, target: self, action: "markAllButtonAction")
        var moveButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Organize, target: nil, action: "")
        var deleteButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Trash, target: nil, action: "")
        moveButton.enabled = false
        deleteButton.enabled = false
        var items = [markAllButton, flexibleSpace, moveButton, flexibleSpace, deleteButton]
        self.navigationController?.visibleViewController.setToolbarItems(items, animated: false)
        self.navigationController?.setToolbarHidden(false, animated: false)

    }
    
    func setToolbarWhileEditingAndSomethingSelected() {
        var flexibleSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        var markAllButton = UIBarButtonItem(title: "Mark", style: UIBarButtonItemStyle.Plain, target: self, action: "markButtonAction")
        var moveButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Organize, target: self, action: "moveButtonAction")
        var deleteButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Trash, target: self, action: "deleteButtonAction")
        var items = [markAllButton, flexibleSpace, moveButton, flexibleSpace, deleteButton]
        self.navigationController?.visibleViewController.setToolbarItems(items, animated: false)
        self.navigationController?.setToolbarHidden(false, animated: false)
    }
    /*
    // Override to support rearranging the table view.
    func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

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
