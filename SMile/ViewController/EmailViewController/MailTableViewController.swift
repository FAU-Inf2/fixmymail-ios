//
//  MailTableViewController.swift
//  FixMyMail
//
//  Created by Jan Weiß on 13.05.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit
import CoreData

class MailTableViewController: UIViewController, NSFetchedResultsControllerDelegate, UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, UISearchBarDelegate, UISearchResultsUpdating, TableViewCellDelegate {
    
    @IBOutlet weak var mailTableView: UITableView!
    var refreshController: UIRefreshControl!
    var searchController: UISearchController!
    weak var delegate: ContentViewControllerProtocol?
    var emails = [Email]()
    var filterdEmails = [Email]()
    
    //required in the edit mode
    var selectedEmails = NSMutableArray()
    var allCellsSelected = false
    
    var accounts: [EmailAccount]?
    var folderToQuery: String?
    var sessionDictionary = [String: MCOIMAPSession]()
    
    var managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext as NSManagedObjectContext!
    
    
    //MARK: - Searchfunction
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        self.filterdEmails.removeAll(keepCapacity: false)
        var searchPredicate: NSPredicate!
        
        switch searchController.searchBar.selectedScopeButtonIndex {
        case 0: //everywhere
            searchPredicate = NSPredicate(format: "sender CONTAINS[c] %@ || title CONTAINS[c] %@ || plainText CONTAINS[c] %@", searchController.searchBar.text!, searchController.searchBar.text!, searchController.searchBar.text!)
        case 1: //sender
            searchPredicate = NSPredicate(format: "sender CONTAINS[c] %@", searchController.searchBar.text!)
        case 2: //subject
            searchPredicate = NSPredicate(format: "title CONTAINS[c] %@", searchController.searchBar.text!)
        case 3: //body
            searchPredicate = NSPredicate(format: "plainText CONTAINS[c] %@", searchController.searchBar.text!)
        default: break
        }
        
        let array = (self.emails as NSArray).filteredArrayUsingPredicate(searchPredicate)
        self.filterdEmails = array as! [Email]
        refreshTableView()
    }
    
    func searchBar(searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        updateSearchResultsForSearchController(searchController)
    }
    
    //MARK: - Override functions
    override func viewDidLoad() {
        super.viewDidLoad()
		
        //init SearchController
        definesPresentationContext = true
        self.searchController = UISearchController(searchResultsController: nil)
        self.searchController.searchResultsUpdater = self
        self.searchController.dimsBackgroundDuringPresentation = false
        self.searchController.searchBar.sizeToFit()
        self.mailTableView.tableHeaderView = self.searchController.searchBar
        self.searchController.searchBar.scopeButtonTitles = ["Everywhere", "Sender", "Subject", "Body"]
        self.searchController.searchBar.delegate = self
        
        
        self.mailTableView.registerNib(UINib(nibName: "CustomMailTableViewCell", bundle: nil), forCellReuseIdentifier: "MailCell")
        
        var menuItem: UIBarButtonItem = UIBarButtonItem(title: "Menu", style: .Plain, target: self, action: "menuTapped:")
        self.navigationItem.leftBarButtonItems = [menuItem]
        var editButton: UIBarButtonItem = UIBarButtonItem(title: "Edit", style: .Plain, target: self, action: "editToggled:")
        editButton.enabled = false
        self.navigationItem.rightBarButtonItem = editButton
        mailTableView.allowsMultipleSelectionDuringEditing = true
        
        self.refreshController = UIRefreshControl()
        self.refreshController.addTarget(self, action: "imapSynchronize", forControlEvents: UIControlEvents.ValueChanged)
        self.mailTableView.addSubview(self.refreshController)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
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
        
        emails.removeAll(keepCapacity: false)
        //fetch local Emails from CoreData
        if let accs = accounts {
            for account in accs {
                for mail in account.emails {
                    if mail.folder == folderToQuery {
                        emails.append(mail as! Email)
                        
                        //activate Edit Button
                        self.navigationItem.rightBarButtonItem?.enabled = true
                    }
                }
            }
            
            emails.sort({($0.mcomessage as! MCOIMAPMessage).header.receivedDate > ($1.mcomessage as! MCOIMAPMessage).header.receivedDate})
        }
        
        if selectedEmails.count == 0 {
            setToolbarWithComposeButton()
        } else {
            setToolbarWhileEditing()
        }
        
        imapSynchronize()
	}
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
		
		// Register notification if email account has changed
		NSNotificationCenter.defaultCenter().removeObserver(self)
		NSNotificationCenter.defaultCenter().addObserver(self,
			selector: "accountHasChanged:",
			name: accountUpdatedNotificationKey,
			object: nil)
		
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
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if let fileName = (UIApplication.sharedApplication().delegate as! AppDelegate).fileName {
            if let data = (UIApplication.sharedApplication().delegate as! AppDelegate).fileData {
                var sendView = MailSendViewController(nibName: "MailSendViewController", bundle: nil)
                var sendAccount: EmailAccount? = nil
                
                var accountName = NSUserDefaults.standardUserDefaults().stringForKey("standardAccount")
                let fetchRequest: NSFetchRequest = NSFetchRequest(entityName: "EmailAccount")
                var error: NSError?
                var result = managedObjectContext.executeFetchRequest(fetchRequest, error: &error)
                if error != nil {
                    NSLog("%@", error!.description)
                    return
                } else {
                    if let emailAccounts = result {
                        for account in emailAccounts {
                            if (account as! EmailAccount).accountName == accountName {
                                sendAccount = account as? EmailAccount
                                break
                            }
                        }
                        if sendAccount == nil {
                            sendAccount = emailAccounts.first as? EmailAccount
                        }
                    }
                }
                
                if let account = sendAccount {
                    sendView.account = account
                    sendView.attachFile(fileName, data: data, mimetype: fileName.pathExtension)
                    
                    (UIApplication.sharedApplication().delegate as! AppDelegate).fileName = nil
                    (UIApplication.sharedApplication().delegate as! AppDelegate).fileData = nil
                    self.navigationController?.pushViewController(sendView, animated: true)
                }
            }
        }

    }
	
	// MARK: - Notification
	func accountHasChanged(notification: NSNotification) {
		//NSLog("MailTableViewController: Update Notification received!")
		var receivedUserInfo = notification.userInfo
		if let userInfo = receivedUserInfo as? Dictionary<String,EmailAccount> {
			//NSLog("Received account is: " + (userInfo["Account"])!.emailAddress)
            fetchOlderEmails(userInfo["Account"]!)
		}
	}
	
	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}
    
    // MARK: - TableView
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var mailcell = tableView.dequeueReusableCellWithIdentifier("MailCell", forIndexPath: indexPath) as! CustomMailTableViewCell
        
        var mail: Email!
        if self.searchController.active {
            mail = self.filterdEmails[indexPath.row]
        }else {
            mail = self.emails[indexPath.row]
        }
        
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
                
                var emailVC = EmailViewController()
                emailVC.message = cell.mail
                emailVC.mcoimapmessage = mail
                emailVC.session = getSession(cell.mail.toAccount)
                self.navigationController?.pushViewController(emailVC, animated: true)
                
                addFlagToEmail(cell.mail, MCOMessageFlag.Seen)
            }
            self.refreshTableView()
        } else { //edit mode enabled
            //select Email
            selectedEmails.addObject(cell.mail)
            if selectedEmails.count == 1 {
                setToolbarWhileEditing()
            }
        }
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        selectedEmails.removeObject((mailTableView.cellForRowAtIndexPath(indexPath) as! CustomMailTableViewCell).mail)
        if selectedEmails.count == 0 {
            setToolbarWhileEditing()
        }
    }

    
    
    // MARK: - IMAP functions
    func imapSynchronize() {
        //NSLog("refeshing..")
        if let accs = self.accounts {
            for account in accs {
                //NSLog("emailAdresse in imapSynchronize:  " + account.emailAddress)
                let session = getSession(account)
                
                let requestKind:MCOIMAPMessagesRequestKind = (MCOIMAPMessagesRequestKind.Uid | MCOIMAPMessagesRequestKind.Flags | MCOIMAPMessagesRequestKind.Headers | MCOIMAPMessagesRequestKind.Structure)
                
                var currentMaxUID = self.getMaxUID(account)
                var localEmails: NSMutableArray = NSMutableArray(array: account.emails.allObjects)
                for localEmail in localEmails {
                    if (localEmail as! Email).folder != self.folderToQuery {
                        localEmails.removeObject(localEmail)
                    }
                }
                
                //Check for deleted or moved Emails and update Flags
                if currentMaxUID > 0 {
                    let fetchMessageInfoForLocalEmails = session.fetchMessagesOperationWithFolder(self.folderToQuery!, requestKind: requestKind, uids: MCOIndexSet(range: MCORangeMake(1, UInt64(currentMaxUID - 1))))
                    
                    fetchMessageInfoForLocalEmails.start({ (error, messages, range) -> Void in
                        if error != nil {
                            NSLog("Could not update local Emails: %@", error)
                        }else {
                            for mail in localEmails {
                                var deleted = true
                                
                                var mailReceivedData: NSDate = ((mail as! Email).mcomessage as! MCOIMAPMessage).header.receivedDate
                                var downloadMailDuration: NSDate? = getDateFromPreferencesDurationString(account.downloadMailDuration)
                                if downloadMailDuration != nil {
                                    if mailReceivedData.laterDate(downloadMailDuration!) == downloadMailDuration {
                                        //NSLog("removed local Email (downloadMailDuration)")
                                        self.removeEmailFromArray(mail as! Email)
                                        self.managedObjectContext.deleteObject(mail as! NSManagedObject)
                                        self.saveCoreDataChanges()
                                        self.refreshTableView()
                                        continue
                                    }
                                }
                                
                                //reload missing data
                                if (mail as! Email).data.length == 0 {
                                    //Fetch data
                                    let fetchEmailDataOp = session.fetchMessageOperationWithFolder(self.folderToQuery!, uid: ((mail as! Email).mcomessage as! MCOIMAPMessage).uid)
                                    
                                    fetchEmailDataOp.start({(error, data) in
                                        if error != nil {
                                            NSLog("Could not recieve mail: %@", error)
                                        } else {
                                            (mail as! Email).data = data
                                            let parser: MCOMessageParser! = MCOMessageParser(data: data)
                                            (mail as! Email).plainText = parser.plainTextBodyRendering()
                                            
                                            self.saveCoreDataChanges()
                                            self.refreshTableView()
                                        }
                                    })
                                }
                                
                                for message in messages {
                                    if (message as! MCOIMAPMessage).uid == ((mail as! Email).mcomessage as! MCOIMAPMessage).uid {
                                        if ((mail as! Email).mcomessage as! MCOIMAPMessage).flags != (message as! MCOIMAPMessage).flags{
                                            //NSLog("Updated Flags " + String(((mail as! Email).mcomessage as! MCOIMAPMessage).uid))
                                            (mail as! Email).mcomessage = (message as! MCOIMAPMessage)
                                        }
                                        deleted = false
                                        break
                                    }
                                }
                                
                                if deleted {
                                    //NSLog("email has been deleted or moved")
                                    self.removeEmailFromArray(mail as! Email)
                                    self.managedObjectContext.deleteObject(mail as! NSManagedObject)
                                    self.saveCoreDataChanges()
                                    self.refreshTableView()
                                }
                            }
                        }
                        self.refreshTableView()
                    })
                }
                
                //Check for new Emails
                let fetchNewEmailsOp = session.fetchMessagesOperationWithFolder(self.folderToQuery!, requestKind: requestKind, uids: MCOIndexSet(range: MCORangeMake(UInt64(currentMaxUID+1), UINT64_MAX - UInt64(currentMaxUID+2))))
                
                fetchNewEmailsOp.start({ (error, messages, range) -> Void in
                    if error != nil {
                        NSLog("Could not load messages: %@", error)
                    } else {
                        //Load new Emails
                        var newEmailsCounter = 0
                        for message in messages {
                            
                            var msgRecievedData: NSDate = (message as! MCOIMAPMessage).header.receivedDate
                            var downloadMailDuration: NSDate? = getDateFromPreferencesDurationString(account.downloadMailDuration)
                            if downloadMailDuration != nil {
                                if msgRecievedData.laterDate(downloadMailDuration!) == downloadMailDuration {
                                    continue
                                }
                            }
                            newEmailsCounter++
                            
                            var newEmail: Email = NSEntityDescription.insertNewObjectForEntityForName("Email", inManagedObjectContext: self.managedObjectContext!) as! Email
                            newEmail.mcomessage = message
                            
                            //Set sender
                            if (message as! MCOIMAPMessage).header.from != nil {
                                if (message as! MCOIMAPMessage).header.from.displayName != "" && (message as! MCOIMAPMessage).header.from.displayName != nil {
                                    newEmail.sender = (message as! MCOIMAPMessage).header.from.displayName
                                }else {
                                    newEmail.sender = (message as! MCOIMAPMessage).header.from.mailbox
                                }
                            }else if (message as! MCOIMAPMessage).header.sender != nil {
                                if (message as! MCOIMAPMessage).header.sender.displayName != "" && (message as! MCOIMAPMessage).header.sender.displayName != nil {
                                    newEmail.sender = (message as! MCOIMAPMessage).header.sender.displayName
                                }else {
                                    newEmail.sender = (message as! MCOIMAPMessage).header.sender.mailbox
                                }
                            } else {
                                newEmail.sender = ""
                            }
                            
                            //Set Title
                            newEmail.title = (message as! MCOIMAPMessage).header.subject ?? " "
                            
                            //Set folder
                            newEmail.folder = self.folderToQuery!
                            
                            //Fetch data
                            let fetchEmailDataOp = session.fetchMessageOperationWithFolder(self.folderToQuery!, uid: (message as! MCOIMAPMessage).uid)
                            fetchEmailDataOp.start({(error, data) in
                                if error != nil {
                                    NSLog("Could not recieve mail: %@", error)
                                } else {
                                    newEmail.data = data
                                    let parser: MCOMessageParser! = MCOMessageParser(data: data)
                                    newEmail.plainText = parser.plainTextBodyRendering()
                                    
                                    //Add newEmail to Array
                                    //NSLog("data downlaod")
                                    self.insertEmailToArray(newEmail)
                                    
                                    self.saveCoreDataChanges()
                                    self.refreshTableView()
                                }
                            })
                            newEmail.toAccount = account
                        }
                        //NSLog("%i new Emails", newEmailsCounter)
                    }
                    self.refreshController.endRefreshing()
                })
            }
        }
    }
    
    func fetchOlderEmails(account: EmailAccount) {
        var curMinUID = UInt64(getMinUID(account))
        let session = getSession(account)
        
        let requestKind:MCOIMAPMessagesRequestKind = (MCOIMAPMessagesRequestKind.Uid | MCOIMAPMessagesRequestKind.Flags | MCOIMAPMessagesRequestKind.Headers | MCOIMAPMessagesRequestKind.Structure)
        
        let fetchOlderEmailsOp = session.fetchMessagesOperationWithFolder(self.folderToQuery!, requestKind: requestKind, uids: MCOIndexSet(range: MCORangeMake(1, curMinUID-2)))
        
        println(MCOIndexSet(range: MCORangeMake(1, curMinUID-2)))
        fetchOlderEmailsOp.start { (error, messages, range) -> Void in
            if error != nil {
                NSLog("Could not load messages: %@", error)
            } else {
                //Load Emails
                println(messages.count)
                for message in messages {
                    
                    var msgReceivedDate: NSDate = (message as! MCOIMAPMessage).header.receivedDate
                    var downloadMailDuration: NSDate? = getDateFromPreferencesDurationString(account.downloadMailDuration)
                    if downloadMailDuration != nil {
                        if msgReceivedDate.laterDate(downloadMailDuration!) == downloadMailDuration {
                            println(msgReceivedDate)
                            continue
                        }
                    }
                    
                    var newEmail: Email = NSEntityDescription.insertNewObjectForEntityForName("Email", inManagedObjectContext: self.managedObjectContext!) as! Email
                    newEmail.mcomessage = message
                    
                    //Set sender
                    if (message as! MCOIMAPMessage).header.from != nil {
                        if (message as! MCOIMAPMessage).header.from.displayName != "" && (message as! MCOIMAPMessage).header.from.displayName != nil {
                            newEmail.sender = (message as! MCOIMAPMessage).header.from.displayName
                        }else {
                            newEmail.sender = (message as! MCOIMAPMessage).header.from.mailbox
                        }
                    }else if (message as! MCOIMAPMessage).header.sender != nil {
                        if (message as! MCOIMAPMessage).header.sender.displayName != "" && (message as! MCOIMAPMessage).header.sender.displayName != nil {
                            newEmail.sender = (message as! MCOIMAPMessage).header.sender.displayName
                        }else {
                            newEmail.sender = (message as! MCOIMAPMessage).header.sender.mailbox
                        }
                    } else {
                        newEmail.sender = ""
                    }
                    
                    //Set Title
                    newEmail.title = (message as! MCOIMAPMessage).header.subject ?? " "
                    
                    //Set folder
                    newEmail.folder = self.folderToQuery!
                    
                    //Fetch data
                    let fetchEmailDataOp = session.fetchMessageOperationWithFolder(self.folderToQuery!, uid: (message as! MCOIMAPMessage).uid)
                    fetchEmailDataOp.start({(error, data) in
                        if error != nil {
                            NSLog("Could not recieve mail: %@", error)
                        } else {
                            newEmail.data = data
                            let parser: MCOMessageParser! = MCOMessageParser(data: data)
                            newEmail.plainText = parser.plainTextBodyRendering()
                            
                            //Add newEmail to Array
                            //NSLog("data downlaod")
                            self.insertEmailToArray(newEmail)
                            
                            self.saveCoreDataChanges()
                            self.refreshTableView()
                        }
                    })
                    newEmail.toAccount = account
                }
            }
        }
    }
    
    func deleteEmail(mail: Email) {
        if let trashFolder = getFolderPathWithMCOIMAPFolderFlag(mail.toAccount, MCOIMAPFolderFlag.Trash) {
            if self.folderToQuery == trashFolder {
                addFlagToEmail(mail, MCOMessageFlag.Deleted)
            } else {
                moveEmailToFolder(mail, trashFolder)
            }
            self.removeEmailFromArray(mail)
        } else {
            showAlert("Unable to delete Message", message: "Please check your preferences for \(mail.toAccount.emailAddress) to select a specific Trash")
            NSLog("error: trashFolderName == nil")
        }
        self.refreshTableView()
    }
    
    func archiveEmail(mail: Email) {
        if let archiveFolder = getFolderPathWithMCOIMAPFolderFlag(mail.toAccount, MCOIMAPFolderFlag.Archive) {
            if self.folderToQuery != archiveFolder {
                moveEmailToFolder(mail, archiveFolder)
                self.removeEmailFromArray(mail)
            }
        } else {
            showAlert("Unable to archive Message", message: "Please check your preferences for \(mail.toAccount.emailAddress) to select a specific Archive")
            NSLog("error: archiveFolderName == nil")
        }
        self.refreshTableView()
    }
    
    func remindEmail(mail: Email){
        // view öffnen mit mehreren auswahlmöglichkeiten
        folderToQuery = "RemindMe"
        let account = mail.toAccount
        let session = getSession(account)
        
        for imapFolder in mail.toAccount.folders{
            var fol: MCOIMAPFolder = (imapFolder as! ImapFolder).mcoimapfolder
            if(fol.path == folderToQuery){}
            else{
                //folder RemindMe erstellen
                
            }
        }
        
        var remindView = MailRemindViewController(nibName: "MailRemindViewController", bundle: nil)
        self.navigationController?.pushViewController(remindView, animated: false)
        // email mit info wann es wieder hochpopen soll in RemindMe ordner schieben
        moveEmailToFolder(mail, folderToQuery)
        self.removeEmailFromArray(mail)
        self.refreshTableView()
    }

    
    
    // MARK: - Toolbar
    func setToolbarWithComposeButton() {
        var composeButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Compose, target: self, action: "showEmptyMailSendView:")
        if accounts!.count == 0 {
            composeButton.enabled = false
        }
        var items = [UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil), composeButton]
        self.navigationController?.visibleViewController.setToolbarItems(items, animated: false)
        self.navigationController?.setToolbarHidden(false, animated: false)
    }
    
    func setToolbarWhileEditing(){
        var flexibleSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        var markAllButton = UIBarButtonItem(title: "Mark", style: UIBarButtonItemStyle.Plain, target: self, action: "markButtonAction")
        var moveButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Organize, target: self, action: "moveButtonAction")
        var deleteButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Trash, target: self, action: "deleteButtonAction")
        
        if selectedEmails.count == 0 {
            markAllButton = UIBarButtonItem(title: "Mark All", style: UIBarButtonItemStyle.Plain, target: self, action: "markAllButtonAction")
            moveButton.enabled = false
            deleteButton.enabled = false
        }
        
        var items = [markAllButton, flexibleSpace, moveButton, flexibleSpace, deleteButton]
        self.navigationController?.visibleViewController.setToolbarItems(items, animated: false)
        self.navigationController?.setToolbarHidden(false, animated: false)
    }
    
    func showEmptyMailSendView(sender: AnyObject) {
        (sender as! UIBarButtonItem).enabled = false
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
    
    
    
    
    //MARK: - Editing mode
    func editToggled(sender: AnyObject) {
        if self.navigationItem.rightBarButtonItem?.title == "Edit" {
            self.navigationItem.rightBarButtonItem?.title = "Done"
            setToolbarWhileEditing()//AndNothingSelected()
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
        mailTableView.reloadData()
    }
    
    func removeEmailFromArray(email: Email) {
        objc_sync_enter(self.emails)
        var array = NSMutableArray(array: emails)
        var index = array.indexOfObject(email)
        if index != NSNotFound {
            emails.removeAtIndex(index)
        }
        objc_sync_exit(self.emails)
    }
    
    func insertEmailToArray(newEmail: Email) {
        objc_sync_enter(self.emails)
        if emails.count == 0 {
            emails.append(newEmail)
            
            //activate Edit Button
            self.navigationItem.rightBarButtonItem?.enabled = true
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
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.searchController.active {
            return self.filterdEmails.count
        } else {
            return self.emails.count
        }
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
    
    func getMinUID(account: EmailAccount) -> UInt32 {
        var minUID : UInt32 = UINT32_MAX
        for email in account.emails {
            if (email as! Email).folder == folderToQuery {
                if ((email as! Email).mcomessage as! MCOIMAPMessage).uid < minUID {
                    minUID = ((email as! Email).mcomessage as! MCOIMAPMessage).uid
                }
            }
        }
        
        return minUID
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
    
    
    //MARK: - Alert View
    func showAlert(title: String, message: String) {
        var alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        
        //Create Actions
        var okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel) {
            UIAlertAction in
            
        }
        var cancelAction = UIAlertAction(title: "Preferences", style: UIAlertActionStyle.Default) {
            UIAlertAction in
            //Push Preferences
            self.navigationController?.pushViewController(PreferenceAccountListTableViewController(nibName: "PreferenceAccountListTableViewController", bundle: NSBundle.mainBundle()), animated: true)
        }
    
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
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
