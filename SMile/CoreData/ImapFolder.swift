//
//  ImapFolder.swift
//  FixMyMail
//
//  Created by Jan Weiß on 15.06.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import Foundation
import CoreData

class ImapFolder: NSManagedObject {

    @NSManaged var mcoimapfolder: MCOIMAPFolderWrapper
    @NSManaged var toEmailAccount: EmailAccount

}
