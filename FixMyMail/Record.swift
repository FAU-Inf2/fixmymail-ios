//
//  Record.swift
//  FixMyMail
//
//  Created by Moritz Müller on 15.06.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import Foundation

class Record: NSObject{
    let email: String
    let lastname: String
    let firstname: String
    
    init ( firstname: String, lastname: String, email: String){
        self.email = email
        self.lastname = lastname
        self.firstname = firstname
    }
    
}
