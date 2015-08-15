//
//  KeyItem.swift
//  FixMyMail
//
//  Created by Sebastian Thürauf on 16.05.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit

class KeyItem: NSObject {
	
	var userIDprimary: String
	var emailAddressPrimary: String
	var keyID: String
	var isSecretKey: Bool
	var isPublicKey: Bool
	var keyType: String
	var created: NSDate
	var validThru: NSDate
	
	var keyLength: NSNumber
	var algorithm: String
	var fingerprint: String
	var trust: NSNumber
	var userIDs: NSSet
	var subKeys: NSSet
	var keyData: NSData
	
	override init(){
		self.userIDprimary = ""
		self.emailAddressPrimary = ""
		self.keyID = ""
		self.isSecretKey = false
		self.isPublicKey = false
		self.keyType = ""
		self.created = NSDate()
		self.validThru = NSDate()
		self.keyLength = 0
		self.algorithm = ""
		self.fingerprint = ""
		self.trust = 0
		self.userIDs = NSSet()
		self.subKeys = NSSet()
		self.keyData = NSData()
	}
	
	
	init(userIDprimary:String, emailAddressPrimary:String, keyID:String, isSecretKey:Bool, isPublicKey:Bool, keyType:String,
		created:NSDate, validThru:NSDate, keyLength: NSNumber, algorithm: String, fingerprint: String, trust: NSNumber, userIDs: NSSet, subKeys: NSSet, keyData: NSData) {
		self.userIDprimary = userIDprimary
		self.emailAddressPrimary = emailAddressPrimary
		self.keyID = keyID
		self.isSecretKey = isSecretKey
		self.isPublicKey = isPublicKey
		self.keyType = keyType
		self.created = created
		self.validThru = validThru
		self.keyLength = keyLength
		self.algorithm = algorithm
		self.fingerprint = fingerprint
		self.trust = trust
		self.userIDs = userIDs
		self.subKeys = subKeys
		self.keyData = keyData
	}
}
