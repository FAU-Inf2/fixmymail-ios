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
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "updateEmailsArray:",
            name: fetchedNewEmailsNotificationKey,
            object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "updateEmailsArray:",
            name: deleteLocalEmailsNotificationKey,
            object: nil)
        
        imapSynchronize()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "updateEmailsArray:",
            name: fetchedNewEmailsNotificationKey,
            object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "updateEmailsArray:",
            name: deleteLocalEmailsNotificationKey,
            object: nil)
        
        emails.removeAll(keepCapacity: false)
        //fetch local Emails from CoreData
        if let accs = accounts {
            for account in accs {
                var downloadMailDuration: NSDate? = getDateFromPreferencesDurationString(account.downloadMailDuration)
                for mail in account.emails {
                    if mail.folder == folderToQuery {
                        if let dMD = downloadMailDuration {
                            if ((mail as! Email).mcomessage as! MCOIMAPMessage).header.receivedDate.laterDate(dMD) == dMD {
                                continue
                            }
                        }
                        self.insertEmailToArray(mail as! Email)
                    }
                }
            }
        }
        
        if selectedEmails.count == 0 {
            setToolbarWithComposeButton()
        } else {
            setToolbarWhileEditing()
        }
	}
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
		self.navigationController?.setToolbarHidden(true, animated: false)
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
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
	
    
    //MARK: - IMAPSynchronize
    func imapSynchronize() {
        if let accs = accounts {
            for account in accs {
                let currentMaxUID = getMaxUID(account, self.folderToQuery!)
                updateLocalEmail(account, self.folderToQuery!)
                fetchEmails(account, self.folderToQuery!, MCOIndexSet(range: MCORangeMake(UInt64(currentMaxUID+1), UINT64_MAX-UInt64(currentMaxUID+2))))
            }
        }
        self.refreshController.endRefreshing()
    }
    
    
    
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
        self.refreshTableView(false)
    }
    
    func searchBar(searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        updateSearchResultsForSearchController(searchController)
    }
    
    
    
	// MARK: - Notification
    func updateEmailsArray(notification: NSNotification) {
        var removedIndex = -2
        
        switch notification.name {
        case fetchedNewEmailsNotificationKey:
            var receivedUserInfo = notification.userInfo
            if let userInfo = receivedUserInfo as? Dictionary<String,[Email]> {
                let array: [Email] = userInfo["Emails"]!
                for email in array {
                    if let accs = accounts {
                        if accs.count == 1 { //Specific Folder
                            if email.folder == folderToQuery && email.toAccount == accounts!.first {
                                self.insertEmailToArray(email)
                            }
                        } else { //All
                            self.insertEmailToArray(email)
                        }
                    }
                }
            }
            
        case deleteLocalEmailsNotificationKey:
            var receivedUserInfo = notification.userInfo
            if let userInfo = receivedUserInfo as? Dictionary<String,NSMutableArray> {
                let array: NSMutableArray = userInfo["Emails"]!
                for email in array {
                    removedIndex = self.removeEmailFromArray(email as! Email)
                    managedObjectContext.deleteObject(email as! Email)
                    saveCoreDataChanges()
                }
            }
            
        default: break
        }
        
        if removedIndex != -1 {
            self.refreshTableView(true)
        }
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
            self.mailTableView.deselectRowAtIndexPath(indexPath, animated: false)
            //self.refreshTableView()
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

    func deleteEmail(mail: Email) {
        if let trashFolder = getFolderPathWithMCOIMAPFolderFlag(mail.toAccount, MCOIMAPFolderFlag.Trash) {
            if self.folderToQuery == trashFolder {
                addFlagToEmail(mail, MCOMessageFlag.Deleted)
                managedObjectContext.deleteObject(mail)
                saveCoreDataChanges()
                self.removeEmailFromArray(mail)
                self.refreshTableView(true)
            } else {
                moveEmailToFolder(mail, trashFolder)
            }
        } else {
            showAlert("Unable to delete Message", message: "Please check your preferences for \(mail.toAccount.emailAddress) to select a specific Trash")
            NSLog("error: trashFolderName == nil")
        }
    }
    
    func archiveEmail(mail: Email) {
        if let archiveFolder = getFolderPathWithMCOIMAPFolderFlag(mail.toAccount, MCOIMAPFolderFlag.Archive) {
            if self.folderToQuery == archiveFolder {
                refreshTableView(false)
            } else {
                moveEmailToFolder(mail, archiveFolder)
            }
        } else {
            showAlert("Unable to archive Message", message: "Please check your preferences for \(mail.toAccount.emailAddress) to select a specific Archive")
            NSLog("error: archiveFolderName == nil")
        }
    }
    
    func remindEmail(mail: Email){
        // view öffnen mit mehreren auswahlmöglichkeiten
        //Don't touch folderToQuery!!!
        //folderToQuery = "RemindMe"
        /*let account = mail.toAccount
        let session = getSession(account)
        
        for imapFolder in mail.toAccount.folders{
            var fol: MCOIMAPFolder = (imapFolder as! ImapFolder).mcoimapfolder
            if(fol.path == folderToQuery){}
            else{
                //folder RemindMe erstellen
                
            }
        }*/
        
        var remindView = MailRemindViewController(nibName: "MailRemindViewController", bundle: nil)
        self.navigationController?.pushViewController(remindView, animated: false)
        // email mit info wann es wieder hochpopen soll in RemindMe ordner schieben
        //moveEmailToFolder(mail, folderToQuery)
        //self.refreshTableView(true)
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
        
        if selectedEmails.count == 0 { //If nothing selected
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
    }
    
    func deleteButtonAction(){
        setToolbarWithComposeButton()
        for var i = 0; i < selectedEmails.count; i++ {
            deleteEmail(selectedEmails[i] as! Email)
        }
        endEditing()
    }
    
    
    
    
    //MARK: - Editing mode
    func editToggled(sender: AnyObject) {
        if self.navigationItem.rightBarButtonItem?.title == "Edit" {
            self.navigationItem.rightBarButtonItem?.title = "Done"
            setToolbarWhileEditing()
            mailTableView.setEditing(true, animated: true)
        } else {
            endEditing()
        }
    }
    
    func endEditing() {
        self.navigationItem.rightBarButtonItem?.title = "Edit"
        selectedEmails.removeAllObjects()
        setToolbarWithComposeButton()
        //self.refreshTableView()
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
            self.refreshTableView(false)
            endEditing()
        case 2: //Mark as Unread
            for var i = 0; i < selectedEmails.count; i++ {
                removeFlagFromEmail(selectedEmails[i] as! Email, MCOMessageFlag.Seen)
            }
            self.refreshTableView(false)
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
    func refreshTableView(animated: Bool) {
        if emails.count == 0 {
            self.navigationItem.rightBarButtonItem?.enabled = false
        }

        if animated {
            self.mailTableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
        }else {
            self.mailTableView.reloadData()
        }
    }
    
    func removeEmailFromArray(email: Email) -> Int{
        var array = NSMutableArray(array: emails)
        var index = array.indexOfObject(email)
        if index != NSNotFound {
            emails.removeAtIndex(index)
            return index
        }
        return -1
    }
    
    func insertEmailToArray(newEmail: Email) {
        if emails.count == 0 {
            emails.append(newEmail)
            
            //activate Edit Button
            self.navigationItem.rightBarButtonItem?.enabled = true
            return
        } else {
            var array: NSMutableArray = NSMutableArray(array: self.emails)
            if array.containsObject(newEmail) {
                return
            }
            //Binary Search?
            emails.append(newEmail)
            emails.sort({($0.mcomessage as! MCOIMAPMessage).header.receivedDate > ($1.mcomessage as! MCOIMAPMessage).header.receivedDate})
        }
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
            self.refreshTableView(false)
        }
        var cancelAction = UIAlertAction(title: "Preferences", style: UIAlertActionStyle.Default) {
            UIAlertAction in
            //Push Preferences
            self.refreshTableView(false)
            self.navigationController?.pushViewController(PreferenceAccountListTableViewController(nibName: "PreferenceAccountListTableViewController", bundle: NSBundle.mainBundle()), animated: true)
        }
    
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    //MARK: - Navigation
    @IBAction func menuTapped(sender: AnyObject) -> Void {
        self.delegate?.toggleLeftPanel()
    }
}
