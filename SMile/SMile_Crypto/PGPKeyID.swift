//
//  PGPKeyID.swift
//  SMile
//
//  Created by Sebastian Thürauf on 03.09.15.
//  Copyright (c) 2015 SMile. All rights reserved.
//

import Foundation

class PGPKeyID: NSObject {
	let longKeyString: String
	let shortKeyString: String
	let fingerprint: String
	
	init(longKeyString: String, shortKeyString: String, fingerprint: String) {
		self.longKeyString = longKeyString
		self.shortKeyString = shortKeyString
		self.fingerprint = fingerprint
		
	}
}