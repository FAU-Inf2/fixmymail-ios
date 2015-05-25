//
//  Email.swift
//  FixMyMail
//
//  Created by Jan Weiß on 05.05.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import Foundation
import CoreData

class Email: NSManagedObject {

    @NSManaged var title: String
    @NSManaged var mcomessage: AnyObject
    @NSManaged var message: String
    @NSManaged var sender: String
    @NSManaged var smime: Bool
    @NSManaged var pgp: Bool
    @NSManaged var data: NSData
    @NSManaged var toAccount: EmailAccount

}
