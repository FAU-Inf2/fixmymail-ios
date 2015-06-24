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
    var actionItems: [ActionItem]?
    var emailAccount: EmailAccount?
    var folderExpanded: Bool!
	
    init(Name: String, viewController: String, emailAddress: String? = nil, icon: UIImage? = nil, emailFolder: MCOIMAPFolder? = nil, actionItems: [ActionItem]? = nil) {
		self.cellName = Name
		self.cellIcon = icon
		self.viewController = viewController
		self.emailAddress = emailAddress
        self.emailFolder = emailFolder
        self.actionItems = actionItems
        self.folderExpanded = false
	}
    
    init(Name: String, viewController: String, emailAccount: EmailAccount, icon: UIImage? = nil, actionItems: [ActionItem]? = nil, emailFolder: MCOIMAPFolder? = nil) {
        self.cellName = Name
        self.cellIcon = icon
        self.viewController = viewController
        self.emailAddress = emailAccount.emailAddress
        self.emailFolder = emailFolder
        self.actionItems = actionItems
        self.emailAccount = emailAccount
        self.folderExpanded = false
    }
}