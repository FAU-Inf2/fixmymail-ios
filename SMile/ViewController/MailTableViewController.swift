//
//  MailTableViewController.swift
//  FixMyMail
//
//  Created by Jan Weiß on 13.05.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit
import CoreData

class MailTableViewController: UIViewController, NSFetchedResultsControllerDelegate, UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, TableViewCellDelegate {
    
    @IBOutlet weak var mailTableView: UITableView!
    var refreshControl: UIRefreshControl!
    var delegate: ContentViewControllerProtocol?
    var emails = [Email]()
    
    //IMAP folder names
    var trashFolderName: String?
    var archiveFolderName: String?
    
    //required in the edit mode
    var selectedEmails = NSMutableArray()
    var allCellsSelected = false
    
    var accounts: [EmailAccount]?
    var folderToQuery: String?
    var sessionDictionary = [String: MCOIMAPSession]()
    
    //@IBOutlet weak var cell: CustomMailTableViewCell!
    var managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext as NSManagedObjectContext!
    /*lazy var fetchedResultsController: NSFetchedResultsController = {
        let mailFetchRequest = NSFetchRequest(entityName: "Email")
        let primarySortDescriptor = NSSortDescriptor(key: "mcomessage.header.receivedDate", ascending: false)
        mailFetchRequest.sortDescriptors = [primarySortDescriptor];
        if self.folderToQuery == nil {
            self.folderToQuery = "INBOX"
        }
        
        if self.accounts == nil {
            mailFetchRequest.predicate = NSPredicate(format: "toAccount.emailAddress == %@", "alwaysFalse")
        } else if self.accounts?.count == 1 {
            mailFetchRequest.predicate = NSPredicate(format: "toAccount.emailAddress == %@ && folder == %@", self.accounts!.first!.emailAddress, self.folderToQuery!)
        }
        
        let frc = NSFetchedResultsController(
            fetchRequest: mailFetchRequest,
            managedObjectContext: self.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        frc.delegate = self
        
        return frc
        }()*/
    
    
    
    
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
       
        accounts = getRecentlyUsedAccount()
        //set tableView title
        if accounts!.count == 0 {
            self.title = "SMile"
        } else if accounts!.count > 1 {
            self.title = "All"
        } else {
            self.title = folderToQuery
        }
        
        //fetch local Emails from CoreData
        if let accs = accounts {
            for account in accs {
                for mail in account.emails {
                    if mail.folder == folderToQuery {
                        emails.append(mail as! Email)
                    }
                }
            }
            
            emails.sort({($0.mcomessage as! MCOIMAPMessage).header.receivedDate > ($1.mcomessage as! MCOIMAPMessage).header.receivedDate})
        }
        /*var error: NSError? = nil
        if (fetchedResultsController.performFetch(&error) == false) {
            print("An error occurred: \(error?.localizedDescription)")
        }*/
        
        imapSynchronize()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if selectedEmails.count == 0 {
            setToolbarWithComposeButton()
        } else {
            setToolbarWhileEditingAndSomethingSelected()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setToolbarHidden(true, animated: false)
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
        let mail = self.emails[indexPath.row]
        //let mail = fetchedResultsController.objectAtIndexPath(indexPath) as! Email
        
        mailcell.mailFrom.text = mail.sender
        mailcell.mailSubject.text = mail.title
        mailcell.mail = mail
        mailcell.height = mailTableView.rowHeight
        mailcell.delegate = self
        
        var header = mail.mcomessage.header!
        mailcell.dateLabel.text = header.receivedDate.toEuropeanShortDateString()
        
        var previewLines = NSUserDefaults.standardUserDefaults().valueForKey("previewLines") as! Int
        if previewLines == 0 {
            mailcell.mailBody.hidden = true
        } else {
            mailcell.mailBody.text = (mail.valueForKey("plainText") as! String?) ?? ""
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
            if ((cell.mail.mcomessage as! MCOIMAPMessage).flags & MCOMessageFlag.Draft) == MCOMessageFlag.Draft {
                //open sendview
                var mail = (cell.mail.mcomessage as! MCOIMAPMessage)
                var parser = MCOMessageParser(data: cell.mail.data)
                addFlagToEmail(cell.mail, MCOMessageFlag.Deleted)
                imapSynchronize()
                self.showMailSendView(mail.header.to == nil ? nil : NSMutableArray(array: mail.header.to),
                        ccRecipients: mail.header.cc == nil ? nil : NSMutableArray(array: mail.header.cc),
                       bccRecipients: mail.header.bcc == nil ? nil : NSMutableArray(array: mail.header.bcc),
                             subject: mail.header.subject,
                            textBody: parser.plainTextBodyRenderingAndStripWhitespace(false))
            } else {
                
                var mail: MCOIMAPMessage = cell.mail.mcomessage as! MCOIMAPMessage
                var messageParser : MCOMessageParser = MCOMessageParser(data: cell.mail.data)
                
//                var emailVC = EmailViewController(nibName: "EmailViewController", bundle: nil)
                var emailVC = EmailViewController()
                emailVC.message = cell.mail
                emailVC.mcoimapmessage = mail
                emailVC.session = getSession(cell.mail.toAccount)
                self.navigationController?.pushViewController(emailVC, animated: true)
                
                
//                var msgVC: MCTMsgViewController = MCTMsgViewController()
//                MCOIMAPMessage *msg = self.messages[indexPath.row];
//                MCTMsgViewController *vc = [[MCTMsgViewController alloc] init];
//                vc.folder = @"INBOX";
//                vc.message = msg;
//                vc.session = self.imapSession;
//                [self.navigationController pushViewController:vc animated:YES];
//                
                
//                var mailView: WebViewController = WebViewController()
//                mailView.putMessage()
//                mailView.message = cell.mail
//                mailView.session = getSession(mailView.message.toAccount)
//                self.navigationController?.pushViewController(mailView, animated: true)
//                tableView.deselectRowAtIndexPath(indexPath, animated: true)
                
                addFlagToEmail(cell.mail, MCOMessageFlag.Seen)
            }
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
        
        if let accs = accounts {
            for account in accs {
                NSLog("emailAdresse in imapSynchronize:  " + account.emailAddress)
                let session = getSession(account)
                
                let requestKind:MCOIMAPMessagesRequestKind = (MCOIMAPMessagesRequestKind.Uid | MCOIMAPMessagesRequestKind.Flags | MCOIMAPMessagesRequestKind.Headers | MCOIMAPMessagesRequestKind.Structure)
                
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
                            NSLog(String((message as! MCOIMAPMessage).uid))
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
                                    newEmail.plainText = parser.plainTextBodyRendering()
                                    
                                    //Add newEmail to Array
                                    self.insertEmailToArray(newEmail)
                                    
                                    self.saveCoreDataChanges()
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
                                for message in messages {
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
                                    self.removeEmailFromArray(mail as! Email)
                                    self.saveCoreDataChanges()
                                    self.refreshTableView()
                                }
                            }
                        }
                        self.refreshTableView()
                    })
                }
            }
        }
        self.refreshControl.endRefreshing()
    }
    
    func deleteEmail(mail: Email) {
        let session = getSession(mail.toAccount)
        
        //Want to use getFolderPathWithMCOIMAPFolderFlag soon here
        
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
                    addFlagToEmail(mail, MCOMessageFlag.Deleted)
                } else {
                    moveEmailToFolder(mail, self.trashFolderName)
                }
                self.removeEmailFromArray(mail)
            } else {
                NSLog("error: trashFolderName == nil")
            }
            
            self.refreshTableView()
        })
    }
    
    func archiveEmail(mail: Email) {
        let session = getSession(mail.toAccount)
        
        //Want to use getFolderPathWithMCOIMAPFolderFlag soon here

        let fetchFoldersOp = session.fetchAllFoldersOperation()
        var folders = [MCOIMAPFolder]()
        fetchFoldersOp.start({ (error, folders) -> Void in
            for folder in folders {
                if self.archiveFolderName != nil {
                    break
                }
                if ((folder as! MCOIMAPFolder).flags & MCOIMAPFolderFlag.Archive) == MCOIMAPFolderFlag.Archive {
                    self.archiveFolderName = (folder as! MCOIMAPFolder).path
                    //NSLog("found archiveFolderName: " + self.archiveFolderName!)
                    break
                }
            }
            if self.archiveFolderName != nil {
                if self.folderToQuery != self.archiveFolderName {
                    moveEmailToFolder(mail, self.archiveFolderName)
                    self.removeEmailFromArray(mail)
                    NSLog("email archived")
                }
            } else {
                NSLog("error: archiveFolderName == nil")
            }
            self.refreshTableView()
        })
    }
    
    
    
    
    // MARK: - Toolbar
    func setToolbarWithComposeButton() {
        var composeButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Compose, target: self, action: "showEmptyMailSendView")
        if accounts!.count == 0 {
            composeButton.enabled = false
        }
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
    
    func showEmptyMailSendView() {
        self.showMailSendView(nil, ccRecipients: nil, bccRecipients: nil, subject: nil, textBody: nil)
    }
    
    func showMailSendView(recipients: NSMutableArray?, ccRecipients: NSMutableArray?, bccRecipients: NSMutableArray?, subject: String?, textBody: String?) {
        var sendAccount: EmailAccount? = nil
        if accounts?.count > 1 {
            var accountName = NSUserDefaults.standardUserDefaults().stringForKey("standardAccount")
            if accountName == "" {
                sendAccount = accounts?.first
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
        } else if let account = accounts?.first {
            sendAccount = account
        }
        if let account = sendAccount {
            var sendView = MailSendViewController(nibName: "MailSendViewController", bundle: nil)
            sendView.account = account
            if let array = recipients {
                sendView.recipients = array
            }
            if let array = ccRecipients {
                sendView.ccRecipients = array
            }
            if let array = bccRecipients {
                sendView.bccRecipients = array
            }
            if let string = subject {
                sendView.subject = string
            }
            if let string = textBody {
                sendView.textBody = string
            }
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
        var moveViewController = MoveEmailViewController(nibName: "MoveEmailViewController", bundle: nil)
        moveViewController.emailsToMove = self.selectedEmails
        self.navigationController?.pushViewController(moveViewController, animated: true)
        //endEditing()
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
            setToolbarWhileEditingAndNothingSelected()
            mailTableView.setEditing(true, animated: true)
        } else {
            endEditing()
        }
    }
    
    func endEditing() {
        self.navigationItem.rightBarButtonItem?.title = "Edit"
        selectedEmails.removeAllObjects()
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
                addFlagToEmail(selectedEmails[i] as! Email, MCOMessageFlag.Seen)
            }
            endEditing()
        case 2: //Mark as Unread
            for var i = 0; i < selectedEmails.count; i++ {
                removeFlagFromEmail(selectedEmails[i] as! Email, MCOMessageFlag.Seen)
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
        //Load Emails from CoreData
        /*emails.removeAll()
        if let accs = accounts {
            for account in accs {
                for mail in account.emails {
                    emails.append(mail as! Email)
                }
            }
            
            emails.sort({($0.mcomessage as! MCOIMAPMessage).header.receivedDate > ($1.mcomessage as! MCOIMAPMessage).header.receivedDate})
        }*/
        /*var error: NSError? = nil
        if (fetchedResultsController.performFetch(&error) == false) {
            print("An error occurred: \(error?.localizedDescription)")
        }*/
        
        mailTableView.reloadData()
        //mailTableView.layoutIfNeeded()
        //self.mailTableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.None)
    }
    
    func removeEmailFromArray(email: Email) {
        objc_sync_enter(self.emails)
        var array = NSMutableArray(array: emails)
        var index = array.indexOfObject(email)
        if index != NSNotFound {
            emails.removeAtIndex(index)
        }
        /*for var i = 0; i < emails.count; i++ {
            if emails[i] == email {
                NSLog("removedEmailFromArray")
                emails.removeAtIndex(i)
            }
        }*/
        

        objc_sync_exit(self.emails)
    }
    
    func insertEmailToArray(newEmail: Email) {
        objc_sync_enter(self.emails)
        if emails.count == 0 {
            emails.append(newEmail)
            return
        }
        if (newEmail.mcomessage as! MCOIMAPMessage).header.receivedDate > (emails.first!.mcomessage as! MCOIMAPMessage).header.receivedDate {
            emails.insert(newEmail, atIndex: 0)
        }else {
            //Binary Search?
            emails.append(newEmail)
            emails.sort({($0.mcomessage as! MCOIMAPMessage).header.receivedDate > ($1.mcomessage as! MCOIMAPMessage).header.receivedDate})
        }
        objc_sync_exit(self.emails)
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
        
        /*if let sections = fetchedResultsController.sections {
            return sections.count
        }*/
        
        //return 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.emails.count
        
        /*if let sections = fetchedResultsController.sections {
            let currentSection = sections[section] as! NSFetchedResultsSectionInfo
            return currentSection.numberOfObjects
        }*/
        
        //return 0
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
    func getMaxUID(account: EmailAccount) -> UInt32 {
        var maxUID : UInt32 = 0
        for email in account.emails {
            if (email as! Email).folder == folderToQuery {
                if ((email as! Email).mcomessage as! MCOIMAPMessage).uid > maxUID {
                    maxUID = ((email as! Email).mcomessage as! MCOIMAPMessage).uid
                }
            }
        }
        
        return maxUID
    }
    
    func getRecentlyUsedAccount() -> [EmailAccount]? {
        var retaccount = [EmailAccount]()
        let fetchRequest: NSFetchRequest = NSFetchRequest(entityName: "EmailAccount")
        var error: NSError?
        var result = managedObjectContext.executeFetchRequest(fetchRequest, error: &error)
        if error != nil {
            NSLog("%@", error!.description)
        } else {
            if let emailAccounts = result {
                for account in emailAccounts {
                    if (account as! EmailAccount).recentlyUsed {
                        retaccount.append(account as! EmailAccount)
                    }
                }
            }
        }
        
        return retaccount
    }
    
    //MARK: - CoreData
    func saveCoreDataChanges(){
        var error: NSError?
        self.managedObjectContext!.save(&error)
        if error != nil {
            NSLog("%@", error!.description)
        }
    }
    
    //MARK: - Navigation
    @IBAction func menuTapped(sender: AnyObject) -> Void {
        self.delegate?.toggleLeftPanel()
    }
}
