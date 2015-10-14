//
//  EmailCache.swift
//  SMile
//
//  Created by Jan Weiß on 18.08.15.
//  Copyright (c) 2015 SMile. All rights reserved.
//

import UIKit

struct MailContent {
    var cachedHTML: String
    var wasDecrypted: Bool
    var sucessfulDecrypted: Bool
}

class EmailCache: NSObject {
    
    static let sharedInstance = EmailCache()
    var emailContentCache = [String: MailContent]()
    var imapPartCache = [String: NSData]()
   
    
    func getHTMLStringWithUniqueEmailID(emailId: String) -> MailContent? {
        if self.emailContentCache[emailId] != nil {
            return self.emailContentCache[emailId]
        } else {
            return nil
        }
    }
    
    func getIMAPPartDataWithUniquePartID(partId: String) -> NSData? {
        if self.imapPartCache[partId] != nil {
            return self.imapPartCache[partId]
        } else {
            return nil
        }
    }
}
