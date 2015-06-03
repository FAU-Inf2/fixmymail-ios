//
//  IMAPFolderFetcher.swift
//  FixMyMail
//
//  Created by Jan Weiß on 01.06.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit

class IMAPFolderFetcher: NSObject {
    
    private static let fetcher: IMAPFolderFetcher = IMAPFolderFetcher()
    
    internal static func getSharedIMAPFolderFetcherInstance() -> IMAPFolderFetcher {
        return self.fetcher
    }
   
}
