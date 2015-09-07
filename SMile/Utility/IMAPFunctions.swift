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
var sessionDictionary = [String: MCOIMAPSession]()
var trashFolderDictionary = [String: String]()
var archiveFolderDictionary = [String: String]()

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
        var session = getSession(mail.toAccount)
        let setFlagOP = session.storeFlagsOperationWithFolder(mail.folder, uids: MCOIndexSet(index: UInt64((mail.mcomessage as! MCOIMAPMessage).uid)), kind: MCOIMAPStoreFlagsRequestKind.Add, flags: flag)
        
        setFlagOP.start({ (error) -> Void in
            if let error = error {
                NSLog("error in setFlagOP: \(error.userInfo)")
            } else {
                let expungeFolder = session.expungeOperation(mail.folder)
                expungeFolder.start({ (error) -> Void in })
            }
            if flag == MCOMessageFlag.Deleted {
                managedObjectContext.deleteObject(mail)
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
        }
    }
    //CoreData changes
    mail.folder = destFolder
    var error: NSError?
    managedObjectContext!.save(&error)
    if error != nil {
        NSLog("%@", error!.description)
    }
    
    //set deleteFlag
    addFlagToEmail(mail, MCOMessageFlag.Deleted)
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
    for email in account.emails {
        if (email as! Email).folder == folderToQuery {
            if ((email as! Email).mcomessage as! MCOIMAPMessage).uid < minUID {
                minUID = ((email as! Email).mcomessage as! MCOIMAPMessage).uid
            }
        }
    }
    
    return minUID
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
                
                var msgReceivedDate: NSDate = (message as! MCOIMAPMessage).header.receivedDate
                var downloadMailDuration: NSDate? = getDateFromPreferencesDurationString(account.downloadMailDuration)
                if downloadMailDuration != nil { //!Ever
                    if msgReceivedDate.laterDate(downloadMailDuration!) == downloadMailDuration {
                        continue
                    }
                }
                
                var newEmail: Email = NSEntityDescription.insertNewObjectForEntityForName("Email", inManagedObjectContext: managedObjectContext!) as! Email
                newEmail.mcomessage = message
                
                //Fetch data
                let fetchEmailDataOp = session.fetchMessageOperationWithFolder(folderToQuery, uid: (message as! MCOIMAPMessage).uid)
                fetchEmailDataOp.start({(error, data) in
                    if error != nil {
                        NSLog("Could not recieve mail: %@", error)
                    } else {
                        newEmail.data = data
                        let parser: MCOMessageParser! = MCOMessageParser(data: data)
                        newEmail.plainText = parser.plainTextBodyRendering()
                        
                        saveCoreDataChanges()
                    }
                })
                
                //init database entry
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
                
                newEmail.title = (message as! MCOIMAPMessage).header.subject ?? " "
                newEmail.folder = folderToQuery
                newEmail.toAccount = account
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
                for mail in localEmails {
                    var deleted = true
                    
                    var mailReceivedDate: NSDate = ((mail as! Email).mcomessage as! MCOIMAPMessage).header.receivedDate
                    var downloadMailDuration: NSDate? = getDateFromPreferencesDurationString(account.downloadMailDuration)
                    if downloadMailDuration != nil {
                        if mailReceivedDate.laterDate(downloadMailDuration!) == downloadMailDuration {
                            managedObjectContext.deleteObject(mail as! NSManagedObject)
                            saveCoreDataChanges()
                            continue
                        }
                    }
                    
                    //reload missing data
                    if (mail as! Email).data.length == 0 {
                        //Fetch data
                        let fetchEmailDataOp = session.fetchMessageOperationWithFolder(folderToQuery, uid: ((mail as! Email).mcomessage as! MCOIMAPMessage).uid)
                        
                        fetchEmailDataOp.start({(error, data) in
                            if error != nil {
                                NSLog("Could not recieve mail: %@", error)
                            } else {
                                (mail as! Email).data = data
                                let parser: MCOMessageParser! = MCOMessageParser(data: data)
                                (mail as! Email).plainText = parser.plainTextBodyRendering()
                                saveCoreDataChanges()
                            }
                        })
                    }
                    
                    for message in messages {
                        if (message as! MCOIMAPMessage).uid == ((mail as! Email).mcomessage as! MCOIMAPMessage).uid {
                            if ((mail as! Email).mcomessage as! MCOIMAPMessage).flags != (message as! MCOIMAPMessage).flags{
                                (mail as! Email).mcomessage = (message as! MCOIMAPMessage)
                                saveCoreDataChanges()
                            }
                            deleted = false
                            break
                        }
                    }
                    
                    if deleted {
                        managedObjectContext.deleteObject(mail as! NSManagedObject)
                        saveCoreDataChanges()
                    }
                }
            }
        })
    }
}

//MARK: - CoreData
func saveCoreDataChanges(){
    var error: NSError?
    managedObjectContext!.save(&error)
    if error != nil {
        NSLog("%@", error!.description)
    }
}

