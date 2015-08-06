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
	private var documentDirectory: String
	
	
	override init() {
		self.pgp = ObjectivePGP()
		self.unnetpgp = UNNetPGP()
		self.fileManager = NSFileManager.defaultManager()
		self.pubringURL = NSUserDefaults.standardUserDefaults().URLForKey("pubring")!
		self.secringURL = NSUserDefaults.standardUserDefaults().URLForKey("secring")!
		
		// pgp settings
		self.pgp.importKeysFromFile(self.pubringURL.path!, allowDuplicates: false)
		self.pgp.importKeysFromFile(self.secringURL.path!, allowDuplicates: false)
		
		// get documentDirectory
		self.documentDirectory = ""
		let nsDocumentDirectory = NSSearchPathDirectory.DocumentDirectory
		let nsUserDomainMask = NSSearchPathDomainMask.UserDomainMask
		if let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true) {
			if paths.count > 0 {
				if let dirPath = paths[0] as? String {
					self.documentDirectory = dirPath
				}
			}
		}
	
	
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
		
		// get documentDirectory
		self.documentDirectory = ""
		let nsDocumentDirectory = NSSearchPathDirectory.DocumentDirectory
		let nsUserDomainMask = NSSearchPathDomainMask.UserDomainMask
		if let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true) {
			if paths.count > 0 {
				if let dirPath = paths[0] as? String {
					self.documentDirectory = dirPath
				}
			}
		}
	}
	
	
	/**
	Decrypt File
	
	:param: encryptedFile:	the encrypted file at URL.
	:param: passphrase:	the passphrase to unlock the private key.
	:param: encryptionType:	PGP or SMIME
	
	:returns: Decrytped File at URL or nil if error occured.
	*/
	func decryptFile(encryptedFile: NSURL, passphrase: String, encryptionType: String) -> NSURL? {
		var error: NSError?
		var decryptedFile: NSURL?
		var encryptedData: NSData?
		var decryptedData: NSData?
		
	//	var copyItem: NSURL = NSURL(fileURLWithPath: self.documentDirectory.stringByAppendingPathComponent(self.fileManager.displayNameAtPath(encryptedFile.path!)))!
		
	//	self.fileManager.copyItemAtURL(encryptedFile, toURL: copyItem, error: nil)
		
		if encryptionType.lowercaseString == "pgp" || encryptionType.lowercaseString == "gpg" {
			encryptedData = NSData(contentsOfFile: encryptedFile.path!)
			if encryptedData != nil {
				decryptedData = pgp.decryptData(encryptedData!, passphrase: passphrase, error: &error)
				if decryptedData != nil && error == nil {
					// cut of .asc or .gpg to get the original extention
					// for files not conforming to encrypted filenames like test.pdf.asc we have to implement some magic number checking
					var newFilePath: String = (encryptedFile.path! as NSString).substringToIndex((encryptedFile.path! as NSString).length - 4)
					if self.fileManager.createFileAtPath(newFilePath, contents: decryptedData, attributes: nil) == true {
						decryptedFile = NSURL(fileURLWithPath: newFilePath)
					}
				}
			}
		} else if encryptionType.lowercaseString == "smime" || encryptionType.lowercaseString == "s/mime" {
			// TODO
			// Do smime stuff
		}
		
		return decryptedFile
	}
	
	/**
		Decrypt Data
	
		:param: data:	the encrypted data.
		:param: passphrase:	the passphrase to unlock the private key.
		:param: encryptionType:	PGP or SMIME
	
		:returns: Decrytped Data or nil if error occured.
 	*/
	func decryptData(data: NSData, passphrase: String?, encryptionType: String) -> NSData? {
		var error: NSError?
		var decryptedData: NSData?
		decryptedData = pgp.decryptData(data, passphrase: passphrase, error: &error)
		if error != nil {
			NSLog("Error: \(error?.domain)")
		}
		
		return decryptedData
	}
	
	
	func encryptFile(file: NSURL, keyIdentifier: String, encryptionType: String) -> NSURL? {
		// TODO
		return nil
	}
	
	func encryptData(data: NSData, keyIdentifier: String, encryptionType: String) -> NSData? {
		// TODO
		return nil
	}
	
	/**
	Import Key
	
	:param: keyfile:	the URL of the keyfile to be imported.
	
	:returns: true if import was successful.
	*/
	func importKey(keyfile: NSURL) -> Bool {
		var result: Bool = false
		var exportError: NSError?
		if let fileContent = String(contentsOfFile: keyfile.path!, encoding: NSUTF8StringEncoding, error: nil) {
			if fileContent.rangeOfString("-----BEGIN PGP PUBLIC KEY BLOCK-----") != nil
				|| fileContent.rangeOfString("-----BEGIN PGP PRIVATE KEY BLOCK-----") != nil {
				pgp.importKeysFromFile(keyfile.path!, allowDuplicates: false)
				self.printAllPublicKeys()
				self.printAllSecretKeys()
				result = pgp.exportKeysOfType(PGPKeyType.Public, toFile: self.pubringURL.path!, error: &exportError)
				result = pgp.exportKeysOfType(PGPKeyType.Secret, toFile: self.secringURL.path!, error: &exportError)
				
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
	
	// MARK: - DEBUG
	
	func printAllPublicKeys() {
		//println("PublicRingFile: " + self.pubringURL.path!)
		var pubkeys = pgp.getKeysOfType(PGPKeyType.Public) as! [PGPKey]
		if pubkeys.count == 0 {
			println("NO PUBLIC KEYS")
		}
		for key in pubkeys {
			println("PubKey-ID: " + key.keyID.shortKeyString)
		}
	}
	
	func printAllSecretKeys() {
		//println("SecretRingFile: " + self.secringURL.path!)
		var seckeys = pgp.getKeysOfType(PGPKeyType.Secret) as! [PGPKey]
		if seckeys.count == 0 {
			println("NO SECRET KEYS")
		}
		for key in seckeys {
			println("SecKey-ID: " + key.keyID.shortKeyString)
		}
	}
}
