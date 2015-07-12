//
//  KeyItem.swift
//  FixMyMail
//
//  Created by Sebastian Thürauf on 16.05.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit

class KeyItem: NSObject {
	
	var keyOwner: String
	var mailAddress: String
	let keyID: String?
	var isSecretKey: Bool
	var isPublicKey: Bool
	var keyType: String
	let created: NSDate
	let validThru: NSDate
	
	
	init(keyOwner:String, mailAddress:String, keyID:String, isSecretKey:Bool, isPublicKey:Bool, keyType:String,
		created:NSDate, validThru:NSDate) {
		self.keyOwner = keyOwner
		self.mailAddress = mailAddress
		self.keyID = keyID
		self.isSecretKey = isSecretKey
		self.isPublicKey = isPublicKey
		self.keyType = keyType
		self.created = created
		self.validThru = validThru
	}
}
