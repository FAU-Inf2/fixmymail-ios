//
//  Key.swift
//  SMile
//
//  Created by Sebastian Thürauf on 06.08.15.
//  Copyright (c) 2015 SMile. All rights reserved.
//

import Foundation
import CoreData

class Key: NSManagedObject {
	@NSManaged var userIDprimary: String
	@NSManaged var emailAddressPrimary: String
	@NSManaged var keyID: String
	@NSManaged var isSecretKey: Bool
	@NSManaged var isPublicKey: Bool
	@NSManaged var keyType: String
	@NSManaged var created: NSDate
	@NSManaged var validThru: NSDate
	@NSManaged var keyLength: NSNumber
	@NSManaged var algorithm: String
	@NSManaged var fingerprint: String
	@NSManaged var trust: NSNumber
	@NSManaged var userIDs: NSSet
	@NSManaged var subKeys: NSSet
	@NSManaged var keyData: NSData
	
	
	
	
}