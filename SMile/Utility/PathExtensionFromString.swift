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
    return NSURL(fileURLWithPath: string).pathComponents
}

func getLastPathComponentFromString(string: String) -> String? {
    return NSURL(fileURLWithPath: string).lastPathComponent
}
