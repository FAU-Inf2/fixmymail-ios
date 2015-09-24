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

- parameter duration::	the textual expression from EmailAccount.downloadMailDuration

- returns: The Date or nil for no selection.
*/
func getDateFromPreferencesDurationString(duration: String) -> NSDate? {
	let calendar = NSCalendar.currentCalendar()
	var date: NSDate?
	switch duration {
	case "One week":
		date = calendar.dateByAddingUnit(NSCalendarUnit.Day, value: -7, toDate: NSDate(), options: [])
	case "One month":
		date = calendar.dateByAddingUnit(NSCalendarUnit.Month, value: -1, toDate: NSDate(), options: [])
	case "Six months":
		date = calendar.dateByAddingUnit(NSCalendarUnit.Month, value: -6, toDate: NSDate(), options: [])
	case "One year":
		date = calendar.dateByAddingUnit(NSCalendarUnit.Year, value: -1, toDate: NSDate(), options: [])
	//"Ever"
	default: date = nil
	}
	return date
}

/**
Mail provider specific session settings

- parameter emailAddress::	The mail address

- returns: SessionPreferenceObject with the session settings for the provider, default settings if provider not known or nil if not a mail address.
*/
func getSessionPreferences(emailAddress: String) -> SessionPreferenceObject? {
	var sessionPreferences: SessionPreferenceObject?
	
	switch emailAddress {
	case let s where s.rangeOfString("@gmail.com") != nil:
		sessionPreferences = SessionPreferenceObject(imapHostname: "imap.gmail.com", imapPort: 993, imapAuthType: MCOAuthType.SASLPlain, imapConType: MCOConnectionType.TLS, smtpHostname: "smtp.gmail.com", smtpPort: 465, smtpAuthType: MCOAuthType.SASLPlain, smtpConType: MCOConnectionType.TLS)
		
	case let s where s.rangeOfString("@googlemail.com") != nil:
		sessionPreferences = SessionPreferenceObject(imapHostname: "imap.gmail.com", imapPort: 993, imapAuthType: MCOAuthType.SASLPlain, imapConType: MCOConnectionType.TLS, smtpHostname: "smtp.gmail.com", smtpPort: 465, smtpAuthType: MCOAuthType.SASLPlain, smtpConType: MCOConnectionType.TLS)
		
	case let s where s.rangeOfString("@outlook") != nil:
		sessionPreferences = SessionPreferenceObject(imapHostname: "imap-mail.outlook.com", imapPort: 993, imapAuthType: MCOAuthType.SASLPlain, imapConType: MCOConnectionType.TLS, smtpHostname: "smtp-mail.outlook.com", smtpPort: 587, smtpAuthType: MCOAuthType.SASLPlain, smtpConType: MCOConnectionType.StartTLS)
		
	case let s where s.rangeOfString("@yahoo") != nil:
		sessionPreferences = SessionPreferenceObject(imapHostname: "imap.mail.yahoo.com", imapPort: 993, imapAuthType: MCOAuthType.SASLPlain, imapConType: MCOConnectionType.TLS, smtpHostname: "smtp.mail.yahoo.com", smtpPort: 465, smtpAuthType: MCOAuthType.SASLPlain, smtpConType: MCOConnectionType.TLS)
		
	case let s where s.rangeOfString("@web.de") != nil:
		sessionPreferences = SessionPreferenceObject(imapHostname: "imap.web.de", imapPort: 993, imapAuthType: MCOAuthType.SASLPlain, imapConType: MCOConnectionType.TLS, smtpHostname: "smtp.web.de", smtpPort: 587, smtpAuthType: MCOAuthType.SASLPlain, smtpConType: MCOConnectionType.StartTLS)
		
	case let s where s.rangeOfString("@gmx") != nil:
		sessionPreferences = SessionPreferenceObject(imapHostname: "imap.gmx.de", imapPort: 993, imapAuthType: MCOAuthType.SASLPlain, imapConType: MCOConnectionType.TLS, smtpHostname: "mail.gmx.net", smtpPort: 465, smtpAuthType: MCOAuthType.SASLPlain, smtpConType: MCOConnectionType.TLS)
		
	case let s where s.rangeOfString("@me.com") != nil:
		sessionPreferences = SessionPreferenceObject(imapHostname: "imap.mail.me.com", imapPort: 993, imapAuthType: MCOAuthType.SASLPlain, imapConType: MCOConnectionType.TLS, smtpHostname: "smtp.mail.me.com", smtpPort: 587, smtpAuthType: MCOAuthType.SASLPlain, smtpConType: MCOConnectionType.StartTLS)
		
	case let s where s.rangeOfString("@icloud.com") != nil:
		sessionPreferences = SessionPreferenceObject(imapHostname: "imap.mail.me.com", imapPort: 993, imapAuthType: MCOAuthType.SASLPlain, imapConType: MCOConnectionType.TLS, smtpHostname: "smtp.mail.me.com", smtpPort: 587, smtpAuthType: MCOAuthType.SASLPlain, smtpConType: MCOConnectionType.StartTLS)
		
	case let s where s.rangeOfString("@fau.de") != nil:
		sessionPreferences = SessionPreferenceObject(imapHostname: "faumail.uni-erlangen.de", imapPort: 993, imapAuthType: MCOAuthType.SASLPlain, imapConType: MCOConnectionType.TLS, smtpHostname: "smtp-auth.uni-erlangen.de", smtpPort: 587, smtpAuthType: MCOAuthType.SASLPlain, smtpConType: MCOConnectionType.TLS)
		
	case let s where s.rangeOfString("@studium.fau.de") != nil:
		sessionPreferences = SessionPreferenceObject(imapHostname: "faumail.uni-erlangen.de", imapPort: 993, imapAuthType: MCOAuthType.SASLPlain, imapConType: MCOConnectionType.TLS, smtpHostname: "smtp-auth.uni-erlangen.de", smtpPort: 587, smtpAuthType: MCOAuthType.SASLPlain, smtpConType: MCOConnectionType.TLS)
		
	default:
		if let _ = emailAddress.rangeOfString("@") where emailAddress.rangeOfString("@") != nil {
			let serverAddress = emailAddress.substringFromIndex(emailAddress.rangeOfString("@")!.endIndex)
			sessionPreferences = SessionPreferenceObject(imapHostname: "imap." + serverAddress, imapPort: 993, imapAuthType: MCOAuthType.SASLPlain, imapConType: MCOConnectionType.TLS, smtpHostname: "smtp." + serverAddress, smtpPort: 587, smtpAuthType: MCOAuthType.SASLPlain, smtpConType: MCOConnectionType.TLS)
		}
		
	}
	
	return sessionPreferences
}





