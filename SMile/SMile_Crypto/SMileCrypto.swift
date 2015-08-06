//
//  SMileCrypto.swift
//  SMile
//
//  Created by Sebastian Thürauf on 30.07.15.
//  Copyright (c) 2015 SMile. All rights reserved.
//

// example for use in other classes:
// var crypt = SMileCrypto()
// var edata: NSData = crypt.encryptString("Hello from swift my little swifty", key: "SMile")
// println("encrytpted: \(edata)")
// var pdata: String = crypt.decryptData(edata, key: "SMile")
// println("decrypted: \(pdata)")


import UIKit

class SMileCrypto: NSObject {
	private var pgp: ObjectivePGP
	private var unnetpgp: UNNetPGP
	private var fileManager: NSFileManager
	private var pubringURL: NSURL
	private var secringURL: NSURL
	
	
	override init() {
		self.pgp = ObjectivePGP()
		self.unnetpgp = UNNetPGP()
		self.fileManager = NSFileManager.defaultManager()
		self.pubringURL = NSUserDefaults.standardUserDefaults().URLForKey("pubring")!
		self.secringURL = NSUserDefaults.standardUserDefaults().URLForKey("secring")!
		
		// pgp settings
		self.pgp.importKeysFromFile(self.pubringURL.path!, allowDuplicates: false)
		self.pgp.importKeysFromFile(self.secringURL.path!, allowDuplicates: false)
		
	}
	
	init(pgp: ObjectivePGP, unnetpgp: UNNetPGP, fileManager: NSFileManager, pubringURL: NSURL, secringURL: NSURL) {
		self.pgp = pgp
		self.unnetpgp = unnetpgp
		self.fileManager = fileManager
		self.pubringURL = pubringURL
		self.secringURL = secringURL
		
		// pgp settings
		self.pgp.importKeysFromFile(self.pubringURL.path!, allowDuplicates: false)
		self.pgp.importKeysFromFile(self.secringURL.path!, allowDuplicates: false)
	}
	
	
	
	func decryptFileWithURL(encrytedFile: NSURL, passphrase: String, encryptionType: String) -> NSURL? {
		// TODO
		return nil
	}
	
	func decryptFile(file: NSData, passphrase: String, encryptionType: String) -> NSData? {
		// TODO
		return nil
	}
	
	
	func encryptFileURL(file: NSURL, keyIdentifier: String, encryptionType: String) -> NSURL? {
		// TODO
		return nil
	}
	
	func encryptFile(file: NSData, keyIdentifier: String, encryptionType: String) -> NSData? {
		// TODO
		return nil
	}
	
	func importKey(keyfile: NSURL) -> Bool {
		var result: Bool = false
		var exportError: NSError?
		if let fileContent = String(contentsOfFile: keyfile.path!, encoding: NSUTF8StringEncoding, error: nil) {
			if fileContent.rangeOfString("-----BEGIN PGP PUBLIC KEY BLOCK-----") != nil
				|| fileContent.rangeOfString("-----BEGIN PGP PRIVATE KEY BLOCK-----") != nil {
				pgp.importKeysFromFile(keyfile.path!, allowDuplicates: false)
				result = pgp.exportKeysOfType(PGPKeyType.Public, toFile: self.pubringURL.path!, error: &exportError)
				result = result && pgp.exportKeysOfType(PGPKeyType.Secret, toFile: self.secringURL.path!, error: &exportError)
				
			} else if fileContent.rangeOfString("pkcs7-mime") != nil {
				// TODO
				// do smime stuff
			}
		}
		if exportError != nil {
			NSLog("Error: \(exportError?.domain)")
		} else {
			NSLog("Import successful")
		}
		return result
	}
	
	
	func encryptString(estring: String, key: String) -> NSData {
		var edata = MyRNEncryptor.encryptData(estring.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true), password: key, error: nil)
		
		return edata
	}
	
	func decryptData(edata: NSData, key: String) -> String {
		
		var pdata = RNDecryptor.decryptData(edata, withPassword: key, error: nil)
		var pstring: String = MyRNEncryptor.stringFromData(pdata)
		return pstring
	}
}
