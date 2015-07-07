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
    
    //IMAP folder names
    var trashFolderName: String?
    var archiveFolderName: String?
    
    //required in the edit mode
    var selectedEmails = NSMutableArray()
    var allCellsSelected = false
    
    var folderToQuery: String?
    var sessionDictionary = [String: MCOIMAPSession]()
    
    //@IBOutlet weak var cell: CustomMailTableViewCell!
    var managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext as NSManagedObjectContext!
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let mailFetchRequest = NSFetchRequest(entityName: "Email")
        let primarySortDescriptor = NSSortDescriptor(key: "mcomessage.header.receivedDate", ascending: false)
        mailFetchRequest.sortDescriptors = [primarySortDescriptor];
        if self.folderToQuery == nil {
            self.folderToQuery = "INBOX"
        }
        if let acc = self.getAccount() {
            if acc.count == 0 {
                mailFetchRequest.predicate = NSPredicate(format: "toAccount.emailAddress == %@", "alwaysFalse")
            }
            if acc.count == 1 {
                mailFetchRequest.predicate = NSPredicate(format: "toAccount.emailAddress == %@ && folder == %@", acc[0].emailAddress, self.folderToQuery!)
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
    
    
    
    
    //MARK: - Override functions
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mailTableView.registerNib(UINib(nibName: "CustomMailTableViewCell", bundle: nil), forCellReuseIdentifier: "MailCell")
        
        var menuItem: UIBarButtonItem = UIBarButtonItem(title: "Menu", style: .Plain, target: self, action: "menuTapped:")
        self.navigationItem.leftBarButtonItems = [menuItem]
        var editButton: UIBarButtonItem = UIBarButtonItem(title: "Edit", style: .Plain, target: self, action: "editToggled:")
        self.navigationItem.rightBarButtonItem = editButton
        mailTableView.allowsMultipleSelectionDuringEditing = true
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.addTarget(self, action: "imapSynchronize", forControlEvents: UIControlEvents.ValueChanged)
        self.mailTableView.addSubview(self.refreshControl)
        if self.folderToQuery == nil {
            self.folderToQuery = "INBOX"
        }
        
        //set tableView title
        if getAccount() == nil {
            self.title = "SMile"
        }else if getAccount()?.count > 1 {
            self.title = "All"
        } else {
            self.title = folderToQuery
        }
        
        //fetch local Emails from CoreData
        var error: NSError? = nil
        if (fetchedResultsController.performFetch(&error) == false) {
            print("An error occurred: \(error?.localizedDescription)")
        }
        
        imapSynchronize()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setToolbarWithComposeButton()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setToolbarHidden(true, animated: false)
        
        var error: NSError? = nil
        self.managedObjectContext!.save(&error)
        if error != nil {
            NSLog("%@", error!.description)
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        for (key, session) in sessionDictionary {
            session.disconnectOperation().start({ (error) -> Void in
                if error != nil {
                    NSLog("%@", error!.description)
                }
            })
        }
    }
    
    
    
    
    // MARK: - TableView
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var mailcell = tableView.dequeueReusableCellWithIdentifier("MailCell", forIndexPath: indexPath) as! CustomMailTableViewCell
        let mail = fetchedResultsController.objectAtIndexPath(indexPath) as! Email
        
        mailcell.mailFrom.text = mail.sender
        mailcell.mailSubject.text = mail.title
        mailcell.mail = mail
        mailcell.height = mailTableView.rowHeight
        mailcell.delegate = self
        
        var header = mail.mcomessage.header!
        mailcell.dateLabel.text = header.receivedDate.toEuropeanShortDateString()
        
        var parser = MCOMessageParser(data: mail.data)
        mailcell.mailBody.text = parser.plainTextBodyRendering()
        
        var previewLines = NSUserDefaults.standardUserDefaults().valueForKey("previewLines") as! Int
        if previewLines == 0 {
            mailcell.mailBody.hidden = true
        } else {
            mailcell.mailBody.hidden = false
            mailcell.mailBody.lineBreakMode = .ByWordWrapping
            mailcell.mailBody.numberOfLines = previewLines
        }
        
        if (mail.mcomessage as! MCOIMAPMessage).flags & MCOMessageFlag.Seen == MCOMessageFlag.Seen{
            mailcell.unseendot.hidden = true
        } else {
            mailcell.unseendot.hidden = false
        }
        
        return mailcell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = mailTableView.cellForRowAtIndexPath(indexPath) as! CustomMailTableViewCell
        
        if !(cell.editing) {
            //open Email
            var mailView: WebViewController = WebViewController()
            mailView.putMessage()
            mailView.message = cell.mail
            mailView.session = getSession(mailView.message.toAccount)
            self.navigationController?.pushViewController(mailView, animated: true)
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            
            setEmailToSeen(mailView.message)
            self.refreshTableView()
        } else {
            //select Email
            selectedEmails.addObject(cell.mail)
            if selectedEmails.count == 1 {
                setToolbarWhileEditingAndSomethingSelected()
            }
        }
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        selectedEmails.removeObject((mailTableView.cellForRowAtIndexPath(indexPath) as! CustomMailTableViewCell).mail)
        if selectedEmails.count == 0 {
            setToolbarWhileEditingAndNothingSelected()
        }
    }

    
    
    
    // MARK: - IMAP functions
    func imapSynchronize() {
        NSLog("refeshing..")
        
        if let accounts = getAccount(){
            for account in accounts {
                NSLog("emailAdresse in imapSynchronize:  " + account.emailAddress)
                let session = getSession(account)
                
                let requestKind:MCOIMAPMessagesRequestKind = (MCOIMAPMessagesRequestKind.Uid | MCOIMAPMessagesRequestKind.Flags | MCOIMAPMessagesRequestKind.Headers)
                
                //Check for new Emails
                var currentMaxUID = self.getMaxUID(account)
                var localEmails: NSMutableArray = NSMutableArray(array: account.emails.allObjects)
                for localEmail in localEmails {
                    if (localEmail as! Email).folder != self.folderToQuery {
                        localEmails.removeObject(localEmail)
                    }
                }
                
                let fetchNewEmailsOp = session.fetchMessagesOperationWithFolder(self.folderToQuery!, requestKind: requestKind, uids: MCOIndexSet(range: MCORangeMake(UInt64(currentMaxUID + 1), UINT64_MAX)))
                
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
                            newEmail.title = (message as! MCOIMAPMessage).header.subject ?? " "
                            
                            //Set folder
                            newEmail.folder = self.folderToQuery!
                            
                            //Fetch data
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
                        }
                    }
                })
                
                //Check for deleted or moved Emails and update Flags
                if currentMaxUID > 0 {
                    let fetchMessageInfoForLocalEmails = session.fetchMessagesOperationWithFolder(self.folderToQuery!, requestKind: requestKind, uids: MCOIndexSet(range: MCORangeMake(1, UInt64(currentMaxUID - 1))))
                    
                    fetchMessageInfoForLocalEmails.start({ (error, messages, range) -> Void in
                        if error != nil {
                            NSLog("Could not update local Emails: %@", error)
                        }else {
                            for mail in localEmails {
                                var deleted = true
                                for message in messages {1
                                    if (message as! MCOIMAPMessage).uid == ((mail as! Email).mcomessage as! MCOIMAPMessage).uid {
                                        if ((mail as! Email).mcomessage as! MCOIMAPMessage).flags != (message as! MCOIMAPMessage).flags{
                                            NSLog("Updated Flags " + String(((mail as! Email).mcomessage as! MCOIMAPMessage).uid))
                                            (mail as! Email).mcomessage = (message as! MCOIMAPMessage)
                                        }
                                        deleted = false
                                        break
                                    }
                                }
                                
                                if deleted {
                                    NSLog("email has been deleted or moved")
                                    self.managedObjectContext.deleteObject(mail as! NSManagedObject)
                                    self.refreshTableView()
                                }
                            }
                        }
                        self.refreshTableView()
                        self.refreshControl.endRefreshing()
                    })
                }
            }
        }
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
                    let expungeFolder = session.expungeOperation("INBOX")
                    expungeFolder.start({ (error) -> Void in })
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
                    let expungeFolder = session.expungeOperation("INBOX")
                    expungeFolder.start({ (error) -> Void in })
                }
            })
        }
    }
    
    func deleteEmail(mail: Email) {
        let session = getSession(mail.toAccount)
        
        //get trashFolderName
        /* How it should work
        if trashFolderName == nil {
        self.trashFolderName = getFolderPathWithMCOIMAPFolderFlag(mail.toAccount, folderFlag: MCOIMAPFolderFlag.Trash)
        }
        */
        
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
                if self.folderToQuery == self.trashFolderName {
                    self.setDeleteFlagToEmail(mail, session: session)
                } else {
                    self.moveEmailToFolder(self.folderToQuery, destFolder: self.trashFolderName, mail: mail, session: session)
                }
                self.managedObjectContext.deleteObject(mail)
            } else {
                NSLog("error: trashFolderName == nil")
            }
            
            self.refreshTableView()
        })
    }
    
    func archiveEmail(mail: Email) {
        let session = getSession(mail.toAccount)
        
        //get archiveFolderName
        /* How it should work
        if archiveFolderName == nil {
        self.archiveFolderName = getFolderPathWithMCOIMAPFolderFlag(mail.toAccount, folderFlag: MCOIMAPFolderFlag.Archive)
        }
        */
        let fetchFoldersOp = session.fetchAllFoldersOperation()
        var folders = [MCOIMAPFolder]()
        fetchFoldersOp.start({ (error, folders) -> Void in
            for folder in folders {
                if self.archiveFolderName != nil {
                    break
                }
                if ((folder as! MCOIMAPFolder).flags & MCOIMAPFolderFlag.Archive) == MCOIMAPFolderFlag.Archive {
                    self.archiveFolderName = (folder as! MCOIMAPFolder).path
                    NSLog("found archiveFolderName: " + self.archiveFolderName!)
                    break
                }
            }
            if self.archiveFolderName != nil {
                if self.folderToQuery != self.archiveFolderName {
                    self.moveEmailToFolder(self.folderToQuery, destFolder: self.archiveFolderName, mail: mail, session: session)
                    self.managedObjectContext.deleteObject(mail)
                }
            } else {
                NSLog("error: archiveFolderName == nil")
            }
            self.refreshTableView()
        })
    }
    
    
    
    
    // MARK: - Toolbar
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
    
    func showMailSendView() {
        var sendAccount: EmailAccount? = nil
        if self.getAccount()?.count > 1 {
            var accountName = NSUserDefaults.standardUserDefaults().stringForKey("standardAccount")
            if accountName == "" {
                sendAccount = self.getAccount()?.first
            } else {
                let fetchRequest: NSFetchRequest = NSFetchRequest(entityName: "EmailAccount")
                var error: NSError?
                var result = managedObjectContext.executeFetchRequest(fetchRequest, error: &error)
                if error != nil {
                    NSLog("%@", error!.description)
                } else {
                    if let emailAccounts = result {
                        for account in emailAccounts {
                            if (account as! EmailAccount).accountName == accountName {
                                sendAccount = account as? EmailAccount
                                break
                            }
                        }
                    }
                }
            }
        } else if let account = self.getAccount()?.first {
            sendAccount = account
        }
        if let account = sendAccount {
            var sendView = MailSendViewController(nibName: "MailSendViewController", bundle: nil)
            sendView.account = account
            self.navigationController?.pushViewController(sendView, animated: true)
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
    
    
    
    
    //MARK: - editing mode
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
    
    func endEditing() {
        self.navigationItem.rightBarButtonItem?.title = "Edit"
        setToolbarWithComposeButton()
        self.refreshTableView()
        mailTableView.layoutIfNeeded()
        mailTableView.setEditing(false, animated: true)
    }
    
    //MARK: - Actionsheets
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



    
    //MARK: - Help functions for tableview
    func refreshTableView() {
        var error: NSError? = nil
        if (fetchedResultsController.performFetch(&error) == false) {
            print("An error occurred: \(error?.localizedDescription)")
        }
        
        mailTableView.layoutIfNeeded()
        self.mailTableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.None)
    }
    
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
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        mailTableView.rowHeight = 55 + (NSUserDefaults.standardUserDefaults().valueForKey("previewLines") as! CGFloat) * 18
        return mailTableView.rowHeight
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
    
    
    //MARK: - Help functions for imap
    func getSession(account: EmailAccount) -> MCOIMAPSession {
        if sessionDictionary[account.accountName] == nil {
            //Neue Session
            let session = MCOIMAPSession()
            session.hostname = account.imapHostname
            session.port = UInt32(account.imapPort.unsignedIntegerValue)
            session.username = account.username
            
            let (dictionary, error) = Locksmith.loadDataForUserAccount(account.emailAddress)
            if error == nil {
                session.password = dictionary?.valueForKey("Password:") as! String
            }
            
            session.authType = StringToAuthType(account.authTypeImap)
            session.connectionType = StringToConnectionType(account.connectionTypeImap)
            
            sessionDictionary[account.accountName] = session
        }
        
        return sessionDictionary[account.accountName]!
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
                    if (account as! EmailAccount).active && (account as! EmailAccount).isActivated {
                        retaccount.append(account as! EmailAccount)
                    }
                }
            }
        }
        
        return retaccount
    }
    
    //Dont work
    func getFolderPathWithMCOIMAPFolderFlag (account: EmailAccount, folderFlag: MCOIMAPFolderFlag) -> String? {
        for folder in account.folders {
            var imapFolder: ImapFolder = folder as! ImapFolder
            let curFolder: MCOIMAPFolder = imapFolder.mcoimapfolder as MCOIMAPFolder
            
            if curFolder.flags & folderFlag == folderFlag {
                return curFolder.path
            }
        }
        return nil
    }
    
    func setDeleteFlagToEmail (mail: Email, session: MCOIMAPSession) {
        let setDeleteFlagOP = session.storeFlagsOperationWithFolder(folderToQuery, uids: MCOIndexSet(index: UInt64((mail.mcomessage as! MCOIMAPMessage).uid)), kind: MCOIMAPStoreFlagsRequestKind.Add, flags: MCOMessageFlag.Deleted)
        
        setDeleteFlagOP.start({ (error) -> Void in
            if let error = error {
                NSLog("error in setDeleteFlagToMail : \(error.userInfo)")
            } else {
                NSLog("email deleted")
                
                let expungeFolder = session.expungeOperation(self.folderToQuery)
                expungeFolder.start({ (error) -> Void in })
            }
        })
    }
    
    func moveEmailToFolder (originFolder: String!, destFolder: String!, mail: Email!, session: MCOIMAPSession!) {
        //copy email to destFolder
        let localCopyMessageOp = session.copyMessagesOperationWithFolder(originFolder, uids: MCOIndexSet(index: UInt64((mail.mcomessage as! MCOIMAPMessage).uid)), destFolder: destFolder)
        
        localCopyMessageOp.start {(error, uidMapping) -> Void in
            if let error = error {
                NSLog("error in moveEmailToFolder in localCopyMessageOp: \(error.userInfo!)")
            }
        }
        
        //set deleteFlag
        let setDeleteFlagOP = session.storeFlagsOperationWithFolder(originFolder, uids: MCOIndexSet(index: UInt64((mail.mcomessage as! MCOIMAPMessage).uid)), kind: MCOIMAPStoreFlagsRequestKind.Add, flags: MCOMessageFlag.Deleted)
        
        setDeleteFlagOP.start({ (error) -> Void in
            if let error = error {
                NSLog("error in moveEmailToFolder in setDeleteFlagOp : \(error.userInfo)")
            } else {
                NSLog("email moved/deleted")
                
                let expungeFolder = session.expungeOperation(originFolder)
                expungeFolder.start({ (error) -> Void in })
            }
        })
    }
    
    func getMaxUID(account: EmailAccount) -> UInt32 {
        var maxUID : UInt32 = 0
        for email in account.emails {
            if (email as! Email).folder == self.folderToQuery {
                if ((email as! Email).mcomessage as! MCOIMAPMessage).uid > maxUID {
                    maxUID = ((email as! Email).mcomessage as! MCOIMAPMessage).uid
                }
            }
        }
        
        return maxUID
    }
    
    
    //MARK: - Navigation
    @IBAction func menuTapped(sender: AnyObject) -> Void {
        self.delegate?.toggleLeftPanel()
    }
}
