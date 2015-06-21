//
//  ActionItem.swift
//  FixMyMail
//
//  Created by Sebastian Thürauf on 29.05.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit

class ActionItem: NSObject {
	var cellIcon: UIImage?
	var cellName: String
	var viewController: String
	var emailAddress: String?
    var emailFolder: MCOIMAPFolder?
	
    init(Name: String, viewController: String, emailAddress: String? = nil, icon: UIImage? = nil, emailFolder: MCOIMAPFolder? = nil) {
		self.cellName = Name
		self.cellIcon = icon
		self.viewController = viewController
		self.emailAddress = emailAddress
        self.emailFolder = emailFolder
	}
}