//
//  EmailAccount.swift
//  FixMyMail
//
//  Created by Jan Weiß on 14.06.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import Foundation
import CoreData

class EmailAccount: NSManagedObject {

    @NSManaged var accountName: String
    @NSManaged var active: Bool
    @NSManaged var authTypeImap: String
    @NSManaged var authTypeSmtp: String
    @NSManaged var connectionTypeImap: String
    @NSManaged var connectionTypeSmtp: String
    @NSManaged var emailAddress: String
    @NSManaged var imapHostname: String
    @NSManaged var imapPort: NSNumber
    @NSManaged var isActivated: Bool
    @NSManaged var password: String
    @NSManaged var realName: String
    @NSManaged var smtpHostname: String
    @NSManaged var smtpPort: NSNumber
    @NSManaged var username: String
    @NSManaged var emails: NSSet
    @NSManaged var folders: NSSet
	@NSManaged var signature: String

}
