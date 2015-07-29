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
            NSLog("error in moveEmailToFolder in localCopyMessageOp: \(error.userInfo!)")
        }else{
            NSLog("email deleted or moved")
        }
    }
    
    //set deleteFlag
    addFlagToEmail(mail, MCOMessageFlag.Deleted)
}

/*//Does not work yet
func getFolderPathWithMCOIMAPFolderFlag (account: EmailAccount, folderFlag: MCOIMAPFolderFlag) -> String? {
    for folder in account.folders {
        let curFolder: MCOIMAPFolder = (folder as! ImapFolder).mcoimapfolder
        
        if curFolder.flags & folderFlag == folderFlag {
            NSLog("got a folder with flag!!")
            return curFolder.path
        }
    }
    NSLog("NIL")
    return nil
}*/
