//
//  UserIDItem.swift
//  SMile
//
//  Created by Sebastian Thürauf on 15.08.15.
//  Copyright (c) 2015 SMile. All rights reserved.
//

import Foundation

class UserIdItem: NSObject {
	var name: String
	var emailAddress: String
	var comment: String
	
	override init() {
		self.name = ""
		self.emailAddress = ""
		self.comment = ""
	}
	
	init(name: String, emailAddress: String, comment: String) {
		self.name = name
		self.emailAddress = emailAddress
		self.comment = comment
	}
}
