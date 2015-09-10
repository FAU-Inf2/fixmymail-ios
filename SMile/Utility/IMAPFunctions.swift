//
//  ImapSessions.swift
//  SMile
//
//  Created by Martin on 09.07.15.
//  Copyright (c) 2015 SMile. All rights reserved.
//

import Foundation
import CoreData

var managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext as NSManagedObjectContext!

//Dictionaries
var sessionDictionary = [String: MCOIMAPSession]()
var trashFolderDictionary = [String: String]()
var archiveFolderDictionary = [String: String]()

//Notification helper
let fetchedNewEmailsNotificationKey = "fetchedNewEmails"
let deleteLocalEmailsNotificationKey = "deleteLocalEmails"
var msgCount: Int32 = 0
var fetchedNewEmails: [Email] = [Email]()

func createNewSession(account: EmailAccount) {
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

func getSession(account: EmailAccount) -> MCOIMAPSession {
    if sessionDictionary[account.accountName] == nil {
        //Neue Session
        createNewSession(account)
    }
    
    return sessionDictionary[account.accountName]!
}

func addFlagToEmail(mail: Email, flag: MCOMessageFlag){
    if (mail.mcomessage as! MCOIMAPMessage).flags & flag != flag {
        //add local
        var newmcomessage = (mail.mcomessage as! MCOIMAPMessage)
        newmcomessage.flags |= flag
        mail.mcomessage = newmcomessage
        
        //add remote
        var mailFolder = mail.folder
        var session = getSession(mail.toAccount)
        let setFlagOP = session.storeFlagsOperationWithFolder(mailFolder, uids: MCOIndexSet(index: UInt64((mail.mcomessage as! MCOIMAPMessage).uid)), kind: MCOIMAPStoreFlagsRequestKind.Add, flags: flag)
        
        setFlagOP.start({ (error) -> Void in
            if let error = error {
                NSLog("error in setFlagOP: \(error.userInfo)")
            } else {
                let expungeFolder = session.expungeOperation(mailFolder)
                expungeFolder.start({ (error) -> Void in })
                saveCoreDataChanges()
            }
        })
    }
}

func removeFlagFromEmail(mail: Email, flag: MCOMessageFlag){
    if (mail.mcomessage as! MCOIMAPMessage).flags & flag == flag {
        //remove local
        var newmcomessage = (mail.mcomessage as! MCOIMAPMessage)
        newmcomessage.flags &= ~flag
        mail.mcomessage = newmcomessage
        
        //remove remote
        var session = getSession(mail.toAccount)
        let removeFlagOP = session.storeFlagsOperationWithFolder(mail.folder, uids: MCOIndexSet(index: UInt64((mail.mcomessage as! MCOIMAPMessage).uid)), kind: MCOIMAPStoreFlagsRequestKind.Remove, flags: flag)
        
        removeFlagOP.start({ (error) -> Void in
            if let error = error {
                NSLog("error in removeFlagOP: \(error.userInfo)")
            }else {
                let expungeFolder = session.expungeOperation(mail.folder)
                expungeFolder.start({ (error) -> Void in })
                saveCoreDataChanges()
            }
        })
    }
}

func moveEmailToFolder(mail: Email!, destFolder: String!) {
    //copy email to destFolder
    let session = getSession(mail.toAccount)
    let copyMessageOp = session.copyMessagesOperationWithFolder(mail.folder, uids: MCOIndexSet(index: UInt64((mail.mcomessage as! MCOIMAPMessage).uid)), destFolder: destFolder)
    
    copyMessageOp.start {(error, uidMapping) -> Void in
        if let error = error {
            NSLog("error in moveEmailToFolder in copyMessageOp: \(error.userInfo!)")
        } else {
            NSLog("email deleted or moved")
            //set deleteFlag
            addFlagToEmail(mail, MCOMessageFlag.Deleted)
            
            var notificationData: Dictionary<String,NSMutableArray>
            notificationData = ["Emails": NSMutableArray(array: [mail])]
            NSNotificationCenter.defaultCenter().postNotificationName(deleteLocalEmailsNotificationKey, object: nil, userInfo: notificationData)
        }
    }
}

func getFolderPathWithMCOIMAPFolderFlag (account: EmailAccount, folderFlag: MCOIMAPFolderFlag) -> String? {
    //User Defaults
    switch folderFlag {
    case MCOIMAPFolderFlag.Trash:
        if account.deletedFolder != "" {
            return account.deletedFolder
        }
        fallthrough
        
    case MCOIMAPFolderFlag.Drafts:
        if account.draftFolder != "" {
            return account.draftFolder
        }
        fallthrough
        
    case MCOIMAPFolderFlag.SentMail:
        if account.sentFolder != "" {
            return account.sentFolder
        }
        fallthrough
        
    case MCOIMAPFolderFlag.Archive:
        if account.archiveFolder != "" {
            return account.archiveFolder
        }
        fallthrough
        
    default:
        for folder in account.folders {
            let curFolder: MCOIMAPFolder = (folder as! ImapFolder).mcoimapfolder
            if curFolder.flags & folderFlag == folderFlag {
                return curFolder.path
            }
        }
    }
    
    return nil
}

//MARK: - Help functions for imap
func getMaxUID(account: EmailAccount, folderToQuery: String) -> UInt32 {
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

func getMinUID(account: EmailAccount, folderToQuery: String) -> UInt32 {
    var minUID : UInt32 = UINT32_MAX
    var nothingFound = true
    for email in account.emails {
        if (email as! Email).folder == folderToQuery {
            if ((email as! Email).mcomessage as! MCOIMAPMessage).uid < minUID {
                nothingFound = false
                minUID = ((email as! Email).mcomessage as! MCOIMAPMessage).uid
            }
        }
    }
    
    return nothingFound ? 0 : minUID
}

//FetchEmails
func fetchEmails(account: EmailAccount, folderToQuery: String, uidRange: MCOIndexSet) {
    let session = getSession(account)
    
    let requestKind:MCOIMAPMessagesRequestKind = (MCOIMAPMessagesRequestKind.Uid | MCOIMAPMessagesRequestKind.Flags | MCOIMAPMessagesRequestKind.Headers | MCOIMAPMessagesRequestKind.Structure)
    
    let fetchEmailsOp = session.fetchMessagesOperationWithFolder(folderToQuery, requestKind: requestKind, uids: uidRange)
    fetchEmailsOp.start({ (error, messages, range) -> Void in
        if error != nil {
            NSLog("Could not load messages: %@", error)
        } else {
            //Load new Emails
            for message in messages {
                //Workaround for YahooAcc
                if (message as! MCOIMAPMessage).uid == getMaxUID(account, folderToQuery) {
                    continue
                }
                
                var msgReceivedDate: NSDate = (message as! MCOIMAPMessage).header.receivedDate
                var downloadMailDuration: NSDate? = getDateFromPreferencesDurationString(account.downloadMailDuration)
                if downloadMailDuration != nil { //!Ever
                    if msgReceivedDate.laterDate(downloadMailDuration!) == downloadMailDuration {
                        continue
                    }
                }
                
                saveRemoteMessageToCoreData(account, folderToQuery, message as! MCOIMAPMessage, (messages.last! as! MCOIMAPMessage).uid == (message as! MCOIMAPMessage).uid)
            }
        }
    })
}

//Update local Emails
func updateLocalEmail(account: EmailAccount, folderToQuery: String) {
    let session = getSession(account)
    let currentMaxUID = getMaxUID(account, folderToQuery)
    
    let requestKind:MCOIMAPMessagesRequestKind = (MCOIMAPMessagesRequestKind.Uid | MCOIMAPMessagesRequestKind.Flags | MCOIMAPMessagesRequestKind.Headers | MCOIMAPMessagesRequestKind.Structure)
    
    var localEmails: NSMutableArray = NSMutableArray(array: account.emails.allObjects)
    for localEmail in localEmails {
        if (localEmail as! Email).folder != folderToQuery {
            localEmails.removeObject(localEmail)
        }
    }
    
    if currentMaxUID > 0 {
        let fetchMessageInfoForLocalEmails = session.fetchMessagesOperationWithFolder(folderToQuery, requestKind: requestKind, uids: MCOIndexSet(range: MCORangeMake(1, UInt64(currentMaxUID - 1))))
    
        fetchMessageInfoForLocalEmails.start({ (error, messages, range) -> Void in
            if error != nil {
                NSLog("Could not update local Emails: %@", error)
            }else {
                //Array for emails which should get deleted from CoreData cause they're too old or were deleted on server
                var deleteLocalEmails: NSMutableArray = NSMutableArray(array: localEmails)
                var missingEmails: [MCOIMAPMessage] = [MCOIMAPMessage]()
                var notificationNeeded = false
                
                for remoteEmail in messages {
                    var emailIsMissing = true
                    for localEmail in localEmails {
                        if (remoteEmail as! MCOIMAPMessage).uid == ((localEmail as! Email).mcomessage as! MCOIMAPMessage).uid {
                            //update local email
                            emailIsMissing = false
                            
                            //delete local Email if it's too old
                            var localEmailReceivedDate: NSDate = ((localEmail as! Email).mcomessage as! MCOIMAPMessage).header.receivedDate
                            var limitForReceivedDate: NSDate? = getDateFromPreferencesDurationString(account.downloadMailDuration)
                            if limitForReceivedDate != nil {
                                if localEmailReceivedDate.laterDate(limitForReceivedDate!) == localEmailReceivedDate { //keep email
                                    deleteLocalEmails.removeObject(localEmail)
                                } else { //email is too old
                                    notificationNeeded = true
                                    break
                                }
                            } else { //Keep email
                                deleteLocalEmails.removeObject(localEmail)
                            }
                            
                            //update flags and fetch missing data if needed
                            if ((localEmail as! Email).mcomessage as! MCOIMAPMessage).flags != (remoteEmail as! MCOIMAPMessage).flags{
                                (localEmail as! Email).mcomessage = (remoteEmail as! MCOIMAPMessage)
                                saveCoreDataChanges()
                                notificationNeeded = true
                            }
                            if (localEmail as! Email).data.length == 0 {
                                //Fetch missing data
                                let fetchEmailDataOp = session.fetchMessageOperationWithFolder(folderToQuery, uid: ((localEmail as! Email).mcomessage as! MCOIMAPMessage).uid)
                                
                                fetchEmailDataOp.start({(error, data) in
                                    if error != nil {
                                        NSLog("Could not recieve mail: %@", error)
                                    } else {
                                        (localEmail as! Email).data = data
                                        let parser: MCOMessageParser! = MCOMessageParser(data: data)
                                        (localEmail as! Email).plainText = parser.plainTextBodyRendering()
                                        saveCoreDataChanges()
                                    }
                                })
                            }
                        }
                    }
                    //fetch missing message to CoreData
                    if emailIsMissing {
                        var msgReceivedDate: NSDate = (remoteEmail as! MCOIMAPMessage).header.receivedDate
                        var downloadMailDuration: NSDate? = getDateFromPreferencesDurationString(account.downloadMailDuration)
                        if downloadMailDuration != nil { //!Ever
                            if msgReceivedDate.laterDate(downloadMailDuration!) == downloadMailDuration {
                                continue
                            }
                        }
                        missingEmails.append(remoteEmail as! MCOIMAPMessage)
                    }
                }
                
                if notificationNeeded {
                    //Send Update Notification to MailTableViewController
                    var notificationData: Dictionary<String,NSMutableArray>
                    notificationData = ["Emails": deleteLocalEmails]
                    NSNotificationCenter.defaultCenter().postNotificationName(deleteLocalEmailsNotificationKey, object: nil, userInfo: notificationData)
                }
                
                for missingEmail in missingEmails {
                    saveRemoteMessageToCoreData(account, folderToQuery, missingEmail, missingEmail.uid == missingEmails.last!.uid)
                }
            }
        })
    }
}

//MARK: - CoreData
func saveRemoteMessageToCoreData(account: EmailAccount, folderToQuery: String, message: MCOIMAPMessage, sendNotificationAnyway: Bool) {
    var session = getSession(account)
    var newEmail: Email = NSEntityDescription.insertNewObjectForEntityForName("Email", inManagedObjectContext: managedObjectContext!) as! Email
    newEmail.mcomessage = message
    
    //Fetch data
    let fetchEmailDataOp = session.fetchMessageOperationWithFolder(folderToQuery, uid: message.uid)
    fetchEmailDataOp.start({(error, data) in
        if error != nil {
            NSLog("Could not recieve mail: %@", error)
        } else {
            newEmail.data = data
            let parser: MCOMessageParser! = MCOMessageParser(data: data)
            newEmail.plainText = parser.plainTextBodyRendering()
            
            saveCoreDataChanges()
            fetchedNewEmails.append(newEmail)
            OSAtomicIncrement32(&msgCount)
            
            if msgCount >= 10 || sendNotificationAnyway {
                var notificationData: Dictionary<String,[Email]>
                notificationData = ["Emails": fetchedNewEmails]
                NSNotificationCenter.defaultCenter().postNotificationName(fetchedNewEmailsNotificationKey, object: nil, userInfo: notificationData)
                
                fetchedNewEmails.removeAll(keepCapacity: false)
                OSAtomicCompareAndSwap32(msgCount, 0, &msgCount)
            }
        }
    })
    
    //init database entry
    if message.header.from != nil {
        if message.header.from.displayName != "" && message.header.from.displayName != nil {
            newEmail.sender = message.header.from.displayName
        }else {
            newEmail.sender = message.header.from.mailbox
        }
    }else if message.header.sender != nil {
        if message.header.sender.displayName != "" && message.header.sender.displayName != nil {
            newEmail.sender = message.header.sender.displayName
        }else {
            newEmail.sender = message.header.sender.mailbox
        }
    } else {
        newEmail.sender = ""
    }
    
    newEmail.title = message.header.subject ?? " "
    newEmail.folder = folderToQuery
    newEmail.toAccount = account
}

func saveCoreDataChanges(){
    var error: NSError?
    managedObjectContext!.save(&error)
    if error != nil {
        NSLog("%@", error!.description)
    }
}

