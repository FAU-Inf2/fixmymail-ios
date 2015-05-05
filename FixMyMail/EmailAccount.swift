//
//  EmailAccount.swift
//  FixMyMail
//
//  Created by Jan Weiß on 05.05.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import Foundation
import CoreData

class EmailAccount: NSManagedObject {

    @NSManaged var username: String
    @NSManaged var password: String
    @NSManaged var emails: NSSet

}
