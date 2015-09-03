//
//  EmailAccount_Support.swift
//  FixMyMail
//
//  Created by Sebastian Thürauf on 06.06.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//


import Foundation


func authTypeToString(authtype: MCOAuthType) -> String {
	switch authtype {
	case MCOAuthType.SASLCRAMMD5:	return "CRAM-MD5"
	case MCOAuthType.SASLPlain:		return "Plain"
	case MCOAuthType.SASLGSSAPI:	return "GSSAPI"
	case MCOAuthType.SASLDIGESTMD5:	return "DIGEST-MD5"
	case MCOAuthType.SASLLogin:		return "Login"
	case MCOAuthType.SASLSRP:		return "Secure Remote Password"
	case MCOAuthType.SASLNTLM:		return "NTLM Authentication"
	case MCOAuthType.SASLKerberosV4:return "Kerberos 4"
	case MCOAuthType.XOAuth2:		return "OAuth2"
	case MCOAuthType.XOAuth2Outlook:return "OAuth2 on Outlook.com"
	default: return "None"
	}
}

func StringToAuthType(authtype: String) -> MCOAuthType {
	switch authtype {
	case "CRAM-MD5":				return MCOAuthType.SASLCRAMMD5
	case "Plain":					return MCOAuthType.SASLPlain
	case "GSSAPI":					return MCOAuthType.SASLGSSAPI
	case "DIGEST-MD5":				return MCOAuthType.SASLDIGESTMD5
	case "Login":					return MCOAuthType.SASLLogin
	case "Secure Remote Password":	return MCOAuthType.SASLSRP
	case "NTLM Authentication":		return MCOAuthType.SASLNTLM
	case "Kerberos 4":				return MCOAuthType.SASLKerberosV4
	case "OAuth2":					return MCOAuthType.XOAuth2
	case "OAuth2 on Outlook.com":	return MCOAuthType.XOAuth2Outlook
	default: return MCOAuthType.SASLNone
	}
}


func connectionTypeToString(connectionType: MCOConnectionType) -> String {
	switch connectionType {
	case MCOConnectionType.TLS:		return "TLS"
	case MCOConnectionType.StartTLS:return "STARTTLS"
	default: return "Clear-Text"
	}
}

func StringToConnectionType(connectionType: String) -> MCOConnectionType {
	switch connectionType {
	case "TLS": 		return MCOConnectionType.TLS
	case "STARTTLS": 	return MCOConnectionType.StartTLS
	default: return MCOConnectionType.Clear
	}
}

/**
Date until mails should be downloaded

:param: duration:	the textual expression from EmailAccount.downloadMailDuration

:returns: The Date or nil for no selection.
*/
func getDateFromPreferencesDurationString(duration: String) -> NSDate? {
	var calendar = NSCalendar.currentCalendar()
	var date: NSDate?
	switch duration {
	case "One week":
		date = calendar.dateByAddingUnit(NSCalendarUnit.CalendarUnitDay, value: -7, toDate: NSDate(), options: nil)
	case "One month":
		date = calendar.dateByAddingUnit(NSCalendarUnit.CalendarUnitMonth, value: -1, toDate: NSDate(), options: nil)
	case "Six months":
		date = calendar.dateByAddingUnit(NSCalendarUnit.CalendarUnitMonth, value: -6, toDate: NSDate(), options: nil)
	case "One year":
		date = calendar.dateByAddingUnit(NSCalendarUnit.CalendarUnitYear, value: -1, toDate: NSDate(), options: nil)
	//"Ever"
	default: date = nil
	}
	return date
}




