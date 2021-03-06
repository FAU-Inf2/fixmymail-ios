//
//  Email.swift
//  FixMyMail
//
//  Created by Jan Weiß on 14.06.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import Foundation
import CoreData

class Email: NSManagedObject {

    @NSManaged var data: NSData
    @NSManaged var folder: String
    @NSManaged var mcomessage: AnyObject
    @NSManaged var message: String
    @NSManaged var pgp: NSNumber
    @NSManaged var plainText: String
    @NSManaged var sender: String
    @NSManaged var smime: NSNumber
    @NSManaged var title: String
    @NSManaged var toAccount: EmailAccount
    
}
