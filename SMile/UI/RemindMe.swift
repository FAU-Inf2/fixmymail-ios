//
//  RemindMe.swift
//  SMile
//
//  Created by Andrea Albrecht on 14.09.15.
//  Copyright (c) 2015 SMile. All rights reserved.
//

import Foundation


class RemindMe{
    func setJSONforUpcomingRemind(email:Email, remindTime: NSDate){
        print(remindTime)
        //moveEmailToFolder(mail, "RemindMe")
        var folderStorage: String = "SmileStorage"
        var jsonmail:Email = email
        var folders = email.toAccount.folders
        let currentMaxUID = getMaxUID(email.toAccount, folderToQuery: folderStorage)
        fetchEmails(email.toAccount, folderStorage, MCOIndexSet(range: MCORangeMake(UInt64(currentMaxUID+1), UINT64_MAX-UInt64(currentMaxUID+2))))
        var downloadMailDuration: NSDate? = getDateFromPreferencesDurationString(email.toAccount.downloadMailDuration)
        for mail in email.toAccount.emails {
            if mail.folder == folderStorage {
                if let dMD = downloadMailDuration {
                    if ((mail as! Email).mcomessage as! MCOIMAPMessage).header.receivedDate.laterDate(dMD) == dMD {
                        continue
                    }
                }
                jsonmail = mail as! Email
            }
        }
        if jsonmail == email{
            print("something went wrong")
        }
            //RemindMe Datum auslesen und in NSDate umformen
        else{
            if let dataFromString = jsonmail.plainText.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
                let json = JSON(data: dataFromString)
                var json2 = json["allRemindMes"].arrayValue
                var anzahl = json2.count
                var header : MCOMessageHeader = email.mcomessage.header
                var messageId = header.messageID
                var now = NSDate().timeIntervalSince1970
                var remindTimeTimestamp = remindTime.timeIntervalSince1970
                var newjson = JSON(["folderId": NSNull(), "id": NSNull(), "last modified": now, "messageId": messageId, "remindInterval": NSNull(), "remindTime": remindTimeTimestamp, "seen": NSNull(), "title": email.title, "uid": NSNull(), "reference": NSNull()]).array
                //Add newjson to json2
                //push json2 to folder storage
            }
        }
    }
    
    
    
    func downlaodJsonAndCheckForUpcomingReminds(toAccount: EmailAccount){ // ich gehe davon aus das SmileStorage vorhanden ist weil ich es vorher ja abgeprüft habe und notfalls erstellt habe
        //JsonFile aus Folder SmileStorage auslesen
        var folderStorage: String = "SmileStorage"
        var jsonmail:Email? //= Email()
        var folders = toAccount.folders
        let currentMaxUID = getMaxUID(toAccount, folderToQuery: folderStorage)
        fetchEmails(toAccount, folderStorage, MCOIndexSet(range: MCORangeMake(UInt64(currentMaxUID+1), UINT64_MAX-UInt64(currentMaxUID+2))))
        var downloadMailDuration: NSDate? = getDateFromPreferencesDurationString(toAccount.downloadMailDuration)
        for mail in toAccount.emails {
            if mail.folder == folderStorage {
                if let dMD = downloadMailDuration {
                    if ((mail as! Email).mcomessage as! MCOIMAPMessage).header.receivedDate.laterDate(dMD) == dMD {
                        continue
                    }
                }
                jsonmail = (mail as! Email)
            }
        }
        print(jsonmail!.plainText)               // noch rausnehmen
        //RemindMe Datum auslesen und in NSDate umformen
        
            if let dataFromString = jsonmail!.plainText.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
                let json = JSON(data: dataFromString)
                var key = "remindTime"
                
                for result in json["allRemindMes"].arrayValue {
                    
                    let time = result["remindTime"].stringValue
                    let prefix:String = "/Date("
                    let suffix:String = ")/"
                    var time2 = prefix + time + suffix
                    var now = NSDate()
                    //RemindMe Datum mit akutellem Datum vergleichen
                    if let theDate = NSDate(jsonDate: time2)
                    {
                        let compareResult = now.compare(theDate)
                        if compareResult == NSComparisonResult.OrderedDescending {
                            //move email to Inbox
                            var id = json["messageId"].stringValue
                            var upcomingEmail:Email = returnEmailWithSpecificID(toAccount, folder: "RemindMe", id: id)
                            addFlagToEmail(upcomingEmail, flag: MCOMessageFlag.None) //Flag auf unseen setzten bzw. vielleicht auf remind
                            moveEmailToFolder(upcomingEmail, destFolder: "INBOX")
                            print("push email")
                        }
                        else{
                            //Do nothing. Its not time yet
                            print("time in future")
                        }
                    }
                    else //Datum hatte falsches Format - Dürfte nicht passieren
                    {
                        print("wrong format")
                    }
                }
            
        }
    }
    
    
    
    func returnEmailWithSpecificID(account: EmailAccount, folder: String, id: String)->Email{
        var email:Email?
        let currentMaxUID = getMaxUID(account, folderToQuery: folder)
        var downloadMailDuration: NSDate? = getDateFromPreferencesDurationString(account.downloadMailDuration)
        for mail in account.emails {
            if mail.folder == folder {
                if let dMD = downloadMailDuration {
                    if ((mail as! Email).mcomessage as! MCOIMAPMessage).header.receivedDate.laterDate(dMD) == dMD {
                        continue
                    }
                }
                var header : MCOMessageHeader = (mail as! Email).mcomessage.header
                var messageId = header.messageID
                if messageId == id { //schauen ob id der mail die selbe ist wie der der remindEmail
                    email = mail as? Email
                }
            }
        }
        return email!
    }
}

