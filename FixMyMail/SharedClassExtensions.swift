//
//  SharedClassExtensions.swift
//  FixMyMail
//
//  Created by Sebastian Thürauf on 16.05.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit

// for convenient creation of NSDate Objects: expl: NSDate(dateString:"2014-06-06")
// let currentDate = NSDate()
extension NSDate
{
	convenience
	init(dateString:String) {
		let dateStringFormatter = NSDateFormatter()
		dateStringFormatter.dateFormat = "yyyy-MM-dd"
		dateStringFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
		let d = dateStringFormatter.dateFromString(dateString)
		self.init(timeInterval:0, sinceDate:d!)
	}
	
	func hour() -> Int
	{
		//Get Hour
		let calendar = NSCalendar.currentCalendar()
		let components = calendar.components(.CalendarUnitHour, fromDate: self)
		let hour = components.hour
		
		//Return Hour
		return hour
	}
	
	
	func minute() -> Int
	{
		//Get Minute
		let calendar = NSCalendar.currentCalendar()
		let components = calendar.components(.CalendarUnitMinute, fromDate: self)
		let minute = components.minute
		
		//Return Minute
		return minute
	}
	
	func toShortTimeString() -> String
	{
		//Get Short Time String
		let formatter = NSDateFormatter()
		formatter.timeStyle = .ShortStyle
		let timeString = formatter.stringFromDate(self)
		
		//Return Short Time String
		return timeString
	}
	
	
	
}


class SharedClassExtensions: NSObject {
}
