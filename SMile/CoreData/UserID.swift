//
//  UserID.swift
//  SMile
//
//  Created by Sebastian Thürauf on 14.08.15.
//  Copyright (c) 2015 SMile. All rights reserved.
//

import Foundation
import CoreData

class UserID: NSManagedObject {
	@NSManaged var name: String
	@NSManaged var emailAddress: String
	@NSManaged var comment: String
	@NSManaged var toKey: Key
}