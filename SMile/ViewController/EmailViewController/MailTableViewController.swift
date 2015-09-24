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
        
        let menuItem: UIBarButtonItem = UIBarButtonItem(title: "Menu", style: .Plain, target: self, action: "menuTapped:")
        self.navigationItem.leftBarButtonItems = [menuItem]
        let editButton: UIBarButtonItem = UIBarButtonItem(title: "Edit", style: .Plain, target: self, action: "editToggled:")
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
                let downloadMailDuration: NSDate? = getDateFromPreferencesDurationString(account.downloadMailDuration)
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
        for (_, session) in sessionDictionary {
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
				if let mimetype = (UIApplication.sharedApplication().delegate as! AppDelegate).fileExtension {
                let sendView = MailSendViewController(nibName: "MailSendViewController", bundle: nil)
                var sendAccount: EmailAccount? = nil
                
                let accountName = NSUserDefaults.standardUserDefaults().stringForKey("standardAccount")
                let fetchRequest: NSFetchRequest = NSFetchRequest(entityName: "EmailAccount")
                var error: NSError?
                var result: [AnyObject]?
                do {
                    result = try managedObjectContext.executeFetchRequest(fetchRequest)
                } catch let error1 as NSError {
                    error = error1
                    result = nil
                }
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
                    sendView.attachFile(fileName, data: data, mimetype: mimetype)
                    
                    (UIApplication.sharedApplication().delegate as! AppDelegate).fileName = nil
                    (UIApplication.sharedApplication().delegate as! AppDelegate).fileData = nil
					(UIApplication.sharedApplication().delegate as! AppDelegate).fileExtension = nil
                    self.navigationController?.pushViewController(sendView, animated: true)
                }
				}
            }
        }

    }
	
    
    //MARK: - IMAPSynchronize
    func imapSynchronize() {
        if let accs = accounts {
            for account in accs {
                let currentMaxUID = getMaxUID(account, folderToQuery: self.folderToQuery!)
                updateLocalEmail(account, folderToQuery: self.folderToQuery!)
                fetchEmails(account, folderToQuery: self.folderToQuery!, uidRange: MCOIndexSet(range: MCORangeMake(UInt64(currentMaxUID+1), UINT64_MAX-UInt64(currentMaxUID+2))))
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
            let receivedUserInfo = notification.userInfo
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
            let receivedUserInfo = notification.userInfo
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
        let mailcell = tableView.dequeueReusableCellWithIdentifier("MailCell", forIndexPath: indexPath) as! CustomMailTableViewCell
        
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
        
        let header = mail.mcomessage.header!
        mailcell.dateLabel.text = header.receivedDate.toEuropeanShortDateString()
        
        let previewLines = NSUserDefaults.standardUserDefaults().valueForKey("previewLines") as! Int
        if previewLines == 0 {
            mailcell.mailBody.hidden = true
        } else {
            mailcell.mailBody.text = (mail.valueForKey("plainText") as! String?) ?? ""
            mailcell.mailBody.hidden = false
            mailcell.mailBody.lineBreakMode = .ByWordWrapping
            mailcell.mailBody.numberOfLines = previewLines
        }
        
        if (mail.mcomessage as! MCOIMAPMessage).flags.intersect(MCOMessageFlag.Seen) == MCOMessageFlag.Seen{
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
            if ((cell.mail.mcomessage as! MCOIMAPMessage).flags.intersect(MCOMessageFlag.Draft)) == MCOMessageFlag.Draft {
                //open sendview
                let mail = (cell.mail.mcomessage as! MCOIMAPMessage)
                let parser = MCOMessageParser(data: cell.mail.data)
                addFlagToEmail(cell.mail, flag: MCOMessageFlag.Deleted)
                self.showMailSendView(mail.header.to == nil ? nil : NSMutableArray(array: mail.header.to),
                    ccRecipients: mail.header.cc == nil ? nil : NSMutableArray(array: mail.header.cc),
                    bccRecipients: mail.header.bcc == nil ? nil : NSMutableArray(array: mail.header.bcc),
                    subject: mail.header.subject,
                    textBody: parser.plainTextBodyRenderingAndStripWhitespace(false))
            } else {
                
                let mail: MCOIMAPMessage = cell.mail.mcomessage as! MCOIMAPMessage
                
                let emailVC = EmailViewController()
                emailVC.message = cell.mail
                emailVC.mcoimapmessage = mail
                emailVC.session = try! getSession(cell.mail.toAccount)
                self.navigationController?.pushViewController(emailVC, animated: true)
                
                addFlagToEmail(cell.mail, flag: MCOMessageFlag.Seen)
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
        if let trashFolder = getFolderPathWithMCOIMAPFolderFlag(mail.toAccount, folderFlag: MCOIMAPFolderFlag.Trash) {
            if self.folderToQuery == trashFolder {
                addFlagToEmail(mail, flag: MCOMessageFlag.Deleted)
                managedObjectContext.deleteObject(mail)
                saveCoreDataChanges()
                self.removeEmailFromArray(mail)
                self.refreshTableView(true)
            } else {
                moveEmailToFolder(mail, destFolder: trashFolder)
            }
        } else {
            showAlert("Unable to delete Message", message: "Please check your preferences for \(mail.toAccount.emailAddress) to select a specific Trash")
            NSLog("error: trashFolderName == nil")
        }
    }
    
    func archiveEmail(mail: Email) {
        if let archiveFolder = getFolderPathWithMCOIMAPFolderFlag(mail.toAccount, folderFlag: MCOIMAPFolderFlag.Archive) {
            if self.folderToQuery == archiveFolder {
                refreshTableView(false)
            } else {
                moveEmailToFolder(mail, destFolder: archiveFolder)
            }
        } else {
            showAlert("Unable to archive Message", message: "Please check your preferences for \(mail.toAccount.emailAddress) to select a specific Archive")
            NSLog("error: archiveFolderName == nil")
        }
    }
    
    func remindEmail(mail: Email){
        // open view with more opportunities
        let folderRemind: String = "RemindMe"
        let folderStorage: String = "SmileStorage"
        var remind: Bool = false
        var storage: Bool = false
        
        for imapFolder in mail.toAccount.folders{
            let fol: MCOIMAPFolder = (imapFolder as! ImapFolder).mcoimapfolder
            if(fol.path == folderRemind){
                remind = true
            }
            else if(fol.path == folderStorage){
                storage = true
                //check if file exists
            }
            if(remind == false){
                //create folder
            }else{}
            if(storage == false){
                //create folder
                //create file
            }else{}
        }
        
        
        let remindView = RemindViewController(nibName: "RemindViewController", bundle: nil)
        remindView.email = mail
        remindView.view.frame = self.view.frame
        let layer = UIApplication.sharedApplication().keyWindow!.layer
        let scale = UIScreen.mainScreen().scale
        UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, scale);
        
        layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let screenshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        remindView.imageView.image = screenshot
        self.presentViewController(remindView, animated: true, completion: nil)
    }

    
    
    // MARK: - Toolbar
    func setToolbarWithComposeButton() {
        let composeButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Compose, target: self, action: "showEmptyMailSendView:")
        if accounts!.count == 0 {
            composeButton.enabled = false
        }
        let items = [UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil), composeButton]
        self.navigationController?.visibleViewController!.setToolbarItems(items, animated: false)
        self.navigationController?.setToolbarHidden(false, animated: false)
    }
    
    func setToolbarWhileEditing(){
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        var markAllButton = UIBarButtonItem(title: "Mark", style: UIBarButtonItemStyle.Plain, target: self, action: "markButtonAction")
        let moveButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Organize, target: self, action: "moveButtonAction")
        let deleteButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Trash, target: self, action: "deleteButtonAction")
        
        if selectedEmails.count == 0 { //If nothing selected
            markAllButton = UIBarButtonItem(title: "Mark All", style: UIBarButtonItemStyle.Plain, target: self, action: "markAllButtonAction")
            moveButton.enabled = false
            deleteButton.enabled = false
        }
        
        let items = [markAllButton, flexibleSpace, moveButton, flexibleSpace, deleteButton]
        self.navigationController?.visibleViewController!.setToolbarItems(items, animated: false)
        self.navigationController?.setToolbarHidden(false, animated: false)
    }
    
    func showEmptyMailSendView(sender: AnyObject) {
        (sender as! UIBarButtonItem).enabled = false
        self.showMailSendView(nil, ccRecipients: nil, bccRecipients: nil, subject: nil, textBody: nil)
    }
    
    func showMailSendView(recipients: NSMutableArray?, ccRecipients: NSMutableArray?, bccRecipients: NSMutableArray?, subject: String?, textBody: String?) {
        var sendAccount: EmailAccount? = nil
        if accounts?.count > 1 {
            let accountName = NSUserDefaults.standardUserDefaults().stringForKey("standardAccount")
            if accountName == "" {
                sendAccount = accounts?.first
            } else {
                let fetchRequest: NSFetchRequest = NSFetchRequest(entityName: "EmailAccount")
                var error: NSError?
                var result: [AnyObject]?
                do {
                    result = try managedObjectContext.executeFetchRequest(fetchRequest)
                } catch let error1 as NSError {
                    error = error1
                    result = nil
                }
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
            let sendView = MailSendViewController(nibName: "MailSendViewController", bundle: nil)
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
            let cell = tableView(mailTableView, cellForRowAtIndexPath: NSIndexPath(forRow: i, inSection: 0)) as! CustomMailTableViewCell
            selectedEmails.addObject(cell.mail)
        }
        allCellsSelected = true
        viewActionSheetWithDeleteAll()
    }
    
    func markButtonAction(){
        viewActionSheet()
    }
    
    func moveButtonAction(){
        let moveViewController = MoveEmailViewController(nibName: "MoveEmailViewController", bundle: nil)
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
        self.presentViewController(self.getAlertControllerWithDeleteAllOption(true), animated: true, completion: nil)
    }
    
    func viewActionSheet() {
        self.presentViewController(self.getAlertControllerWithDeleteAllOption(false), animated: true, completion: nil)
    }
    
    private func getAlertControllerWithDeleteAllOption(deleteAllOption: Bool) -> UIAlertController {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action) -> Void in
            if self.allCellsSelected {
                self.selectedEmails.removeAllObjects()
            }
            self.allCellsSelected = false
        })
        actionSheet.addAction(cancelAction)
        let markAsReadAction = UIAlertAction(title: "Mark as read", style: .Default) { (action) -> Void in
            for var i = 0; i < self.selectedEmails.count; i++ {
                addFlagToEmail(self.selectedEmails[i] as! Email, flag: MCOMessageFlag.Seen)
            }
            self.refreshTableView(false)
            self.endEditing()
        }
        actionSheet.addAction(markAsReadAction)
        let markAsUnreadAction = UIAlertAction(title: "Mark as unread", style: .Default) { (action) -> Void in
            for var i = 0; i < self.selectedEmails.count; i++ {
                removeFlagFromEmail(self.selectedEmails[i] as! Email, flag: MCOMessageFlag.Seen)
            }
            self.refreshTableView(false)
            self.endEditing()
        }
        actionSheet.addAction(markAsUnreadAction)
        if deleteAllOption == true {
            let deleteAllAction = UIAlertAction(title: "Delete All", style: .Default, handler: { (action) -> Void in
                self.deleteButtonAction()
            })
            actionSheet.addAction(deleteAllAction)
        }
        return actionSheet
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
        let array = NSMutableArray(array: emails)
        let index = array.indexOfObject(email)
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
            let array: NSMutableArray = NSMutableArray(array: self.emails)
            if array.containsObject(newEmail) {
                return
            }
            //Binary Search?
            emails.append(newEmail)
            emails.sortInPlace({($0.mcomessage as! MCOIMAPMessage).header.receivedDate > ($1.mcomessage as! MCOIMAPMessage).header.receivedDate})
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
        var result: [AnyObject]?
        do {
            result = try managedObjectContext.executeFetchRequest(fetchRequest)
        } catch let error1 as NSError {
            error = error1
            result = nil
        }
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
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        
        //Create Actions
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel) {
            UIAlertAction in
            self.refreshTableView(false)
        }
        let cancelAction = UIAlertAction(title: "Preferences", style: UIAlertActionStyle.Default) {
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
