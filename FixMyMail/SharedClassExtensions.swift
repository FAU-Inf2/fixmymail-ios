//
//  SharedClassExtensions.swift
//  FixMyMail
//
//  Created by Sebastian Thürauf on 16.05.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit

// http://www.codingexplorer.com/swiftly-getting-human-readable-date-nsdateformatter/
// for convenient creation of NSDate Objects: expl: NSDate(dateString:"2014-06-06")
// let currentDate = NSDate()
extension NSDate: Comparable
{
	convenience
	init(dateString:String) {
		let dateStringFormatter = NSDateFormatter()
		dateStringFormatter.dateFormat = "yyyy-MM-dd"
		dateStringFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
		let d = dateStringFormatter.dateFromString(dateString)
		self.init(timeInterval:0, sinceDate:d!)
	}
		
	func year() -> Int
	{
		//Get Year
		let calendar = NSCalendar.currentCalendar()
		let components = calendar.components(.CalendarUnitYear, fromDate: self)
		let year = components.year
		
		//Return Year
		return year
	}
	
	
	func month() -> Int
	{
		//Get Month
		let calendar = NSCalendar.currentCalendar()
		let components = calendar.components(.CalendarUnitMonth, fromDate: self)
		let month = components.month
		
		//Return Month
		return month
	}
	
	func day() -> Int
	{
		//Get Day
		let calendar = NSCalendar.currentCalendar()
		let components = calendar.components(.CalendarUnitDay, fromDate: self)
		let day = components.day
		
		//Return Day
		return day
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
	
	func toLongDateString() -> String
	{
	//Get Long Date String
	let formatter = NSDateFormatter()
	formatter.dateStyle = .LongStyle
	let dateString = formatter.stringFromDate(self)
	
	//Return Long Date String
	return dateString
	}
	
	func toShortDateString() -> String
	{
		//Get Short Date String
		let formatter = NSDateFormatter()
		formatter.dateStyle = .ShortStyle
		let dateString = formatter.stringFromDate(self)
		
		//Return Short Date String
		return dateString
	}
	
	// EU date string
	func toEuropeanShortDateString() -> String
	{
		//Get Short Date String
		let dateStringFormatter = NSDateFormatter()
		dateStringFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
		dateStringFormatter.dateFormat = "yyyy-MM-dd HH:mm"
		let dateString = dateStringFormatter.stringFromDate(self)
		
		//Return Short Date String
		return dateString
	}
	
}

public func ==(lhs: NSDate, rhs: NSDate) -> Bool {
	return lhs === rhs || lhs.compare(rhs) == .OrderedSame
}
public func <(lhs: NSDate, rhs: NSDate) -> Bool {
	return lhs.compare(rhs) == .OrderedAscending
}


class SharedClassExtensions: NSObject {
}
