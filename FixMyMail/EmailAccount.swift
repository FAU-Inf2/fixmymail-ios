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

	@NSManaged var realName: String
	@NSManaged var accountName: String
    @NSManaged var emailAddress: String
    @NSManaged var username: String
    @NSManaged var password: String
    @NSManaged var imapHostname: String
    @NSManaged var imapPort: UInt32
    @NSManaged var smtpHostname: String
    @NSManaged var smtpPort: UInt32
    @NSManaged var emails: NSSet
    @NSManaged var active: Bool
	@NSManaged var authTypeImap: String
	@NSManaged var connectionTypeImap: String
	@NSManaged var authTypeSmtp: String
	@NSManaged var connectionTypeSmtp: String
	@NSManaged var isActivated: Bool
	
}
