//
//  RemindMeRoot.swift
//  SMile
//
//  Created by Andrea Albrecht on 15.09.15.
//  Copyright (c) 2015 SMile. All rights reserved.
//

import Foundation
class RemindMeRoot {
    //
    var allRemindMes: Set<RemindMe> = []
    
    func RemindMeRoot(){
        allRemindMes = Set()
    }
    
    func setAllRemindMes(newRemindMes:Set<RemindMe>){
        self.allRemindMes = newRemindMes
    }
    
    func getAllRemindMes()->Set<RemindMe>{
        return allRemindMes
    }
}