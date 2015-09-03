//
//  PGPKey.swift
//  SMile
//
//  Created by Sebastian Thürauf on 03.09.15.
//  Copyright (c) 2015 SMile. All rights reserved.
//

import Foundation

class PGPKey: NSObject {
	
	let type: PGPKeyType
	let keyID: PGPKeyID
	let creationDate: NSDate
	var users: NSMutableArray
	var subKeys: NSMutableArray
	// TODO
	var primaryKeyPacket: NSObject
	
	enum PGPKeyType: Int {
		case PGPKeyUnknown = 0
		case PGPKeySecret  = 1
		case PGPKeyPublic  = 2
	}
	
	init(type: PGPKeyType, keyID: PGPKeyID, creationDate: NSDate, users: NSMutableArray, subKeys: NSMutableArray, primaryKeyPacket: NSObject) {
		self.type = type
		self.keyID = keyID
		self.creationDate = creationDate
		self.users = users
		self.subKeys = subKeys
		self.primaryKeyPacket = primaryKeyPacket
	}
	
	
	
}