//
//  RemindMe.swift
//  SMile
//
//  Created by Andrea Albrecht on 14.09.15.
//  Copyright (c) 2015 SMile. All rights reserved.
//

import Foundation
import SwiftyJSON
import Locksmith

extension JSON {
    public init(_ jsonArray:[JSON]) {
        self.init(jsonArray.map { $0.object })
    }
}

class RemindMe{
    var jsonmail:Email?
    var jsonstring:String?
    var folderStorage:String?
    var folderRemind:String?
    
    func checkIfJSONEmailExists(email:Email){
        folderStorage = "SmileStorage"
        var exists:Bool = false
        let currentMaxUID = getMaxUID(email.toAccount, folderToQuery: folderStorage!)
        fetchEmails(email.toAccount, folderToQuery: folderStorage!, uidRange: MCOIndexSet(range: MCORangeMake(UInt64(currentMaxUID+1), UINT64_MAX-UInt64(currentMaxUID+2))))
        for mail in email.toAccount.emails {
            if mail.folder == folderStorage {
                exists = true
            }
            
        }
        if(exists == false){
            jsonstring = "{\"allRemindMes\":[]}"
            uploadJsonMail(email)
        }
    }

    
    
    //Adds Json Entry for new RemindMe email
    func setJSONforUpcomingRemind(email:Email, remindTime: NSDate){
        folderStorage = "SmileStorage"
        jsonmail = email
        //Get current JsonMail from SmileStorage Folder
        saveCoreDataChanges()
        let currentMaxUID = getMaxUID(email.toAccount, folderToQuery: folderStorage!)
        //updateLocalEmail(email.toAccount, folderToQuery: folderStorage!)
        fetchEmails(email.toAccount, folderToQuery: folderStorage!, uidRange: MCOIndexSet(range: MCORangeMake(UInt64(currentMaxUID+1), UINT64_MAX-UInt64(currentMaxUID+2))))
        for mail in email.toAccount.emails {
            print(mail.folder)
            if mail.folder == folderStorage {
                jsonmail = mail as? Email
            }
        }
        if jsonmail == email{
            print("something went wrong")
        }
            
        else{
            //add new json entry
            let dataFromString = jsonmail!.plainText.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
            if dataFromString != nil {
                var json = JSON(data: dataFromString!)
                var json2 = json["allRemindMes"].arrayValue
                
                
                let now = NSDate().timeIntervalSince1970
                let remindTimeTimestamp = remindTime.timeIntervalSince1970
                moveEmailToFolder(email, destFolder: "RemindMe")
                let header : MCOMessageHeader = email.mcomessage.header
                let messageId = header.messageID
                let newjson = JSON(["folderId": NSNull(), "id": NSNull(), "lastModified": now, "messageId": messageId, "remindInterval": NSNull(), "remindTime": remindTimeTimestamp, "seen": NSNull(), "title": email.title, "uid": NSNull(), "reference": NSNull()])
                //Add newjson to json2
                json2.append(newjson)
                json["allRemindMes"] = JSON(json2)
                
                jsonstring = json.rawString()!
                uploadJsonMail(email)
                
                //delete old json email
                deleteEmail(jsonmail!)
            }
        }
    }
    
    func uploadJsonMail(email:Email){
        saveCoreDataChanges()
                
        //load new jsonemail to SmileStorage Folder
        var imapSession: MCOIMAPSession!
        do {
            imapSession = try getSession(email.toAccount)
        } catch _ {
            print("Error while trying to move email to drafts folder")
            return
        }
                
        let appendMsgOp = imapSession.appendMessageOperationWithFolder(folderStorage, messageData: self.buildEmail(), flags: [MCOMessageFlag.Seen])
        appendMsgOp.start({ (error, uid) -> Void in
            if error != nil {
                NSLog("%@", error.description)
            } else {
                NSLog("Draft saved")
            }
        })
    }
    
    
    
    func buildEmail() -> NSData {
        let builder = MCOMessageBuilder()
        
        builder.header.subject = "Internal from Smile"
        builder.textBody = jsonstring
        return builder.data()
    }

    
    
    
    func deleteEmail(mail: Email) {
        
        addFlagToEmail(mail, flag: MCOMessageFlag.Deleted)
        managedObjectContext.deleteObject(mail)
        saveCoreDataChanges()
    }

    
    
    
    func downlaodJsonAndCheckForUpcomingReminds(toAccount: EmailAccount){ // ich gehe davon aus das SmileStorage vorhanden ist weil ich es vorher ja abgeprüft habe und notfalls erstellt habe
        var somethingChanged:Bool = false
        let folderStorage: String = "SmileStorage"
        let currentMaxUID = getMaxUID(toAccount, folderToQuery: folderStorage)
        saveCoreDataChanges()
        //updateLocalEmail(toAccount, folderToQuery: folderStorage)
        fetchEmails(toAccount, folderToQuery: folderStorage, uidRange: MCOIndexSet(range: MCORangeMake(UInt64(currentMaxUID+1), UINT64_MAX-UInt64(currentMaxUID+2))))
        for mail in toAccount.emails {
            print(mail.folder)
            if mail.folder == folderStorage {
                jsonmail = mail as? Email
            }
        }
        if(jsonmail == nil){
            print("something went wrong")
            return
        }
        //RemindMe Datum auslesen und in NSDate umformen
        
        if let dataFromString = jsonmail!.plainText.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            var json = JSON(data: dataFromString)
            //var key = "remindTime"
            var cleanarray:[JSON] = []
            let now = NSDate()
            for result in json["allRemindMes"].arrayValue {
                print(result)
                
                //RemindMe Datum mit akutellem Datum vergleichen
                let time = result["remindTime"].doubleValue
                var theDate = NSDate(timeIntervalSince1970: time)
                
                
                if theDate.year()>10000{
                    let time = result["remindTime"].stringValue
                    let prefix:String = "/Date("
                    let suffix:String = ")/"
                    let time2 = prefix + time + suffix
                    theDate = NSDate(jsonDate: time2)!
                }
                print(theDate)
                let compareResult = now.compare(theDate)
                if compareResult == NSComparisonResult.OrderedDescending {
                    //move email to Inbox
                    print("push email")
                    
                    let id = result["messageId"].stringValue
                    
                    if( returnEmailWithSpecificID(toAccount, folder: "RemindMe", id: id) != nil){
                        let upcomingEmail:Email = returnEmailWithSpecificID(toAccount, folder: "RemindMe", id: id)!
                        addFlagToEmail(upcomingEmail, flag: MCOMessageFlag.Flagged) //Flag auf unseen setzten bzw. vielleicht auf remind
                        let inboxfolder = getFolderPathWithMCOIMAPFolderFlag(toAccount, folderFlag: MCOIMAPFolderFlag.Inbox)
                        moveEmailToFolder(upcomingEmail, destFolder: inboxfolder)
                        somethingChanged = true
                    }
                }
                else{
                    //Do nothing. Its not time yet
                    let id = result["messageId"].stringValue
                    if(returnEmailWithSpecificID(toAccount, folder: "RemindMe", id: id) != nil){
                       cleanarray.append(result)
                    }
                    else{
                        somethingChanged = true
                    }
                    print("time in future")
                }
            }
            if( somethingChanged == true){
                json["allRemindMes"] = JSON(cleanarray)
                jsonstring = json.rawString()!
                uploadJsonMail(jsonmail!)
                deleteEmail(jsonmail!)
            }
        }
    }
    func returnEmailWithSpecificID(account: EmailAccount, folder: String, id: String)->Email?{
        let currentMaxUID = getMaxUID(account, folderToQuery: folder)
        //let downloadMailDuration: NSDate? = getDateFromPreferencesDurationString(account.downloadMailDuration)
        saveCoreDataChanges()
        //updateLocalEmail(account, folderToQuery: folderStorage!)
        fetchEmails(account, folderToQuery: folder, uidRange: MCOIndexSet(range: MCORangeMake(UInt64(currentMaxUID+1), UINT64_MAX-UInt64(currentMaxUID+2))))
        for mail in account.emails {
            print(mail.folder)
            if mail.folder == folder {
                let header : MCOMessageHeader = (mail as! Email).mcomessage.header
                let messageId = header.messageID
                print(header.subject)
                if messageId == id { //schauen ob id der mail die selbe ist wie der der remindEmail
                    return (mail as? Email)
                }
            }
        }
        return nil
    }

}






