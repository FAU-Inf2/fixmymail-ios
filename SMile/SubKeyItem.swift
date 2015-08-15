//
//  SubKeyItem.swift
//  SMile
//
//  Created by Sebastian Thürauf on 15.08.15.
//  Copyright (c) 2015 SMile. All rights reserved.
//

import Foundation

class SubKeyItem: NSObject {
	var subKeyID: String
	var length: NSNumber
	var algorithm: String
	var created: NSDate
	var validThru: NSDate
	
	override init() {
		self.subKeyID = ""
		self.length = 0
		self.algorithm = ""
		self.created = NSDate()
		self.validThru = NSDate()
	}
	
	init(subKeyID: String, length: NSNumber, algorithm: String, created: NSDate, validThru: NSDate) {
		self.subKeyID = subKeyID
		self.length = length
		self.algorithm = algorithm
		self.created = created
		self.validThru = validThru
	}
}
