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
    
    func setJSONforUpcomingRemind(email:Email, remindTime: NSDate){
        let folderStorage: String = "SmileStorage"
        jsonmail = email
        let currentMaxUID = getMaxUID(email.toAccount, folderToQuery: folderStorage)
        fetchEmails(email.toAccount, folderToQuery: folderStorage, uidRange: MCOIndexSet(range: MCORangeMake(UInt64(currentMaxUID+1), UINT64_MAX-UInt64(currentMaxUID+2))))
        for mail in email.toAccount.emails {
            if mail.folder == folderStorage {
                jsonmail = mail as? Email
            }
        }
        if jsonmail == email{
            print("something went wrong")
        }
            
        else{
            let dataFromString = jsonmail!.plainText.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
            if dataFromString != nil {
                var json = JSON(data: dataFromString!)
                var json2 = json["allRemindMes"].arrayValue
                let header : MCOMessageHeader = email.mcomessage.header
                let messageId = header.messageID
                let now = NSDate().timeIntervalSince1970
                let remindTimeTimestamp = remindTime.timeIntervalSince1970
                moveEmailToFolder(email, destFolder: "RemindMe")
                let newjson = JSON(["folderId": NSNull(), "id": NSNull(), "lastModified": now, "messageId": messageId, "remindInterval": NSNull(), "remindTime": remindTimeTimestamp, "seen": NSNull(), "title": email.title, "uid": NSNull(), "reference": NSNull()])
                //Add newjson to json2
                json2.append(newjson)
                json["allRemindMes"] = JSON(json2)
                
                jsonmail!.plainText = json.rawString()!
                
                saveCoreDataChanges()
                
                
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
                deleteEmail(jsonmail!)
            }
        }
    }
    
    func buildEmail() -> NSData {
        let builder = MCOMessageBuilder()
        
        builder.header.subject = "Internal from Smile"
        print("builder")
        print(jsonmail!.plainText)
        builder.textBody = jsonmail!.plainText
        
        return builder.data()
    }

    func deleteEmail(mail: Email) {
        
        addFlagToEmail(mail, flag: MCOMessageFlag.Deleted)
        managedObjectContext.deleteObject(mail)
        saveCoreDataChanges()
    }

    
    
    
    func downlaodJsonAndCheckForUpcomingReminds(toAccount: EmailAccount){ // ich gehe davon aus das SmileStorage vorhanden ist weil ich es vorher ja abgeprüft habe und notfalls erstellt habe
        let folderStorage: String = "SmileStorage"
        var jsonmail:Email?
        let currentMaxUID = getMaxUID(toAccount, folderToQuery: folderStorage)
        fetchEmails(toAccount, folderToQuery: folderStorage, uidRange: MCOIndexSet(range: MCORangeMake(UInt64(currentMaxUID+1), UINT64_MAX-UInt64(currentMaxUID+2))))
        for mail in toAccount.emails {
            print(mail.folder)
            if mail.folder == folderStorage {
                jsonmail = mail as? Email
            }
        }
        
        //RemindMe Datum auslesen und in NSDate umformen
        
        if let dataFromString = jsonmail!.plainText.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            let json = JSON(data: dataFromString)
            //var key = "remindTime"
            
            for result in json["allRemindMes"].arrayValue {
                print(result)
                
                //RemindMe Datum mit akutellem Datum vergleichen
                let now = NSDate()
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
                    let upcomingEmail:Email = returnEmailWithSpecificID(toAccount, folder: "RemindMe", id: id)
                    addFlagToEmail(upcomingEmail, flag: MCOMessageFlag.None) //Flag auf unseen setzten bzw. vielleicht auf remind
                    moveEmailToFolder(upcomingEmail, destFolder: "INBOX")
                    
                }
                else{
                    //Do nothing. Its not time yet
                    print("time in future")
                }
            }
        }
    }
}




func returnEmailWithSpecificID(account: EmailAccount, folder: String, id: String)->Email{
    var email:Email?
    //let currentMaxUID = getMaxUID(account, folderToQuery: folder)
    let downloadMailDuration: NSDate? = getDateFromPreferencesDurationString(account.downloadMailDuration)
    for mail in account.emails {
        if mail.folder == folder {
            if let dMD = downloadMailDuration {
                if ((mail as! Email).mcomessage as! MCOIMAPMessage).header.receivedDate.laterDate(dMD) == dMD {
                    continue
                }
            }
            let header : MCOMessageHeader = (mail as! Email).mcomessage.header
            let messageId = header.messageID
            if messageId == id { //schauen ob id der mail die selbe ist wie der der remindEmail
                email = mail as? Email
            }
        }
    }
    return email!
}


