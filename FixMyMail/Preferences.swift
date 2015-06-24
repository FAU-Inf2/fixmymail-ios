//
//  Preferences.swift
//  FixMyMail
//
//  Created by Sebastian Thürauf on 14.06.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import Foundation
import CoreData

class Preferences: NSManagedObject {
	
	@NSManaged var loadPictures: Bool
	@NSManaged var standardAccount: String

}
