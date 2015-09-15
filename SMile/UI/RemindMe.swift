//
//  RemindMe.swift
//  SMile
//
//  Created by Andrea Albrecht on 14.09.15.
//  Copyright (c) 2015 SMile. All rights reserved.
//

import Foundation


class RemindMe: Hashable{
    var id:Int?
    var title:String?
    var remindTime:NSDate?
    var mail:Email?
    var folderID:Int? //?
    var uid:String? //?
    var messageId:String?
    //var remindInterval:String?
    var lastModified:NSDate?
    //var seen:NSDate?
    var hashValue: Int{
        return self.id!
    }
    
    
    func RemindMe(remindDate: NSDate, mail: Email, folderID: Int, uid: String, messageId: String)-> Void{
        self.remindTime = remindDate
        self.mail = mail
        self.title = mail.title //Betreff
        self.messageId = mail.mcomessage.identifier // erst nach verschieben?
        
        
        //self.folderID = folderID
        /*if(uid.isEmpty  && !mail.isEqual(nil)){
            //?
        }else{
             self.uid = uid
        }*/
    }
}
func ==(lhs: RemindMe, rhs: RemindMe) -> Bool {
    return lhs.hashValue == rhs.hashValue
    }