//
//  SessionPreferenceObject.swift
//  SMile
//
//  Created by Sebastian Thürauf on 17.09.15.
//  Copyright (c) 2015 SMile. All rights reserved.
//

import Foundation


class SessionPreferenceObject: NSObject {
	
	var imapHostname: String
	var imapPort: Int
	var imapAuthType: MCOAuthType
	var imapConType: MCOConnectionType
	
	var smtpHostname: String
	var smtpPort: Int
	var smtpAuthType: MCOAuthType
	var smtpConType: MCOConnectionType
	
	init(imapHostname: String, imapPort: Int, imapAuthType: MCOAuthType, imapConType: MCOConnectionType,
		smtpHostname: String, smtpPort: Int, smtpAuthType: MCOAuthType, smtpConType: MCOConnectionType){
			self.imapHostname = imapHostname
			self.imapPort = imapPort
			self.imapAuthType = imapAuthType
			self.imapConType = imapConType
			
			self.smtpHostname = smtpHostname
			self.smtpPort = smtpPort
			self.smtpAuthType = smtpAuthType
			self.smtpConType = smtpConType
		
	}
}