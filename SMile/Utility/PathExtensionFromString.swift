//
//  PathExtensionFromString.swift
//  SMile
//
//  Created by Jan Weiß on 23.09.15.
//  Copyright © 2015 SMile. All rights reserved.
//

import UIKit

func getPathExtensionFromString(string: String) -> String? {
    return NSURL(fileURLWithPath: string).pathExtension
}

func appendPathExtensionToString(stingToAppend: String, andPathExtension pathExtension: String) -> String? {
    return NSURL(fileURLWithPath: stingToAppend).URLByAppendingPathComponent(pathExtension).path
}

func getPathComponentsFromString(string: String) -> [String]? {
    var urlParts = NSURL(fileURLWithPath: string).pathComponents
    if urlParts != nil {
        if urlParts![0] == "/" {
            urlParts!.removeFirst()
        }
    }
    return urlParts
}

func getLastPathComponentFromString(string: String) -> String? {
    return NSURL(fileURLWithPath: string).lastPathComponent
}
