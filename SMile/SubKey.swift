//
//  SubKey.swift
//  SMile
//
//  Created by Sebastian Thürauf on 14.08.15.
//  Copyright (c) 2015 SMile. All rights reserved.
//

import Foundation
import CoreData

class SubKey: NSManagedObject {
	@NSManaged var subKeyID: String
	@NSManaged var length: NSNumber
	@NSManaged var algorithm: String
	@NSManaged var created: NSDate
	@NSManaged var validThru: NSDate
	@NSManaged var toKey: Key
}
