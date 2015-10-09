//
//  SMileCrypto.swift
//  SMile
//
//  Created by Sebastian Thürauf on 30.07.15.
//  Copyright (c) 2015 SMile. All rights reserved.
//


import UIKit
import CoreData
import Foundation

class SMileCrypto: NSObject {
	
	private let pubKeyBlockString = "-----BEGIN PGP PUBLIC KEY BLOCK-----"
	private let secKeyBlockString = "-----BEGIN PGP PRIVATE KEY BLOCK-----"
	private let smimeFileString = "pkcs7-mime"
	
	private var pgp: SMilePGP
	private var fileManager: NSFileManager
	private var documentDirectory: String
	private var keysInCoreData: [Key]?
	private var managedObjectContext: NSManagedObjectContext?
	
	enum TrustType: Int {
		case Unknown = 1
		case Never = 2
		case Marginally = 3
		case Fully = 4
		case Ultimately = 5
	}
	
	
	
	
	override init() {
		self.pgp = SMilePGP()
		self.fileManager = NSFileManager.defaultManager()
		
		// get documentDirectory
		self.documentDirectory = ""
		let nsDocumentDirectory = NSSearchPathDirectory.DocumentDirectory
		let nsUserDomainMask = NSSearchPathDomainMask.UserDomainMask
        let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
        if paths.count > 0 {
            self.documentDirectory = paths[0]
        }
		
		// fetch keys from coreData
		let appDel: AppDelegate? = UIApplication.sharedApplication().delegate as? AppDelegate
		if let appDelegate = appDel {
			self.managedObjectContext = appDelegate.managedObjectContext!
			let keyFetchRequest = NSFetchRequest(entityName: "Key")
            do {
                self.keysInCoreData = try managedObjectContext!.executeFetchRequest(keyFetchRequest) as? [Key]
            } catch _ {
                self.keysInCoreData = nil
            }
		}
	}
	
	// MARK: - Decryption
	/**
	Decrypt File
	
	- parameter encryptedFile::	the encrypted file at URL.
	- parameter passphrase::	the passphrase to unlock the private key.
	- parameter encryptionType::	PGP or SMIME
	
	- returns: The Error or nil if decrypt was successful.
			  Decrytped File at URL or nil if error occured.
	*/
	func decryptFile(encryptedFile: NSURL, passphrase: String, encryptionType: String) -> (NSError?, NSURL?) {
//		var error: NSError?
//		var decryptedFile: NSURL?
//		var encryptedData: NSData?
//		let decryptedData: NSData?
//		
//		var copyItem: NSURL = NSURL(fileURLWithPath: self.documentDirectory)
//        copyItem = copyItem.URLByAppendingPathComponent(self.fileManager.displayNameAtPath(encryptedFile.path!))
//		
//		do {
//			try self.fileManager.copyItemAtURL(encryptedFile, toURL: copyItem)
//		} catch let error1 as NSError {
//			error = error1
//		}
//		if error == nil {
//			if encryptionType.lowercaseString == "pgp" || encryptionType.lowercaseString == "gpg" {
//				encryptedData = NSData(contentsOfURL: copyItem)
//				if encryptedData != nil {
//	//				decryptedData = self.pgp.decryptData(encryptedData!, passphrase: passphrase, error: &error)
//					if decryptedData != nil && error == nil {
//						// cut of .asc or .gpg to get the original extention
//						// for files not conforming to encrypted filenames like test.pdf.asc we have to implement some magic number checking
//						let newFilePath: String = (copyItem.path! as NSString).substringToIndex((copyItem.path! as NSString).length - 4)
//						if self.fileManager.createFileAtPath(newFilePath, contents: decryptedData, attributes: nil) == true {
//							decryptedFile = NSURL(fileURLWithPath: newFilePath)
//						}
//					}
//				}
//			} else if encryptionType.lowercaseString == "smime" || encryptionType.lowercaseString == "s/mime" {
//				// TODO
//				// Do smime stuff
//			}
//
//			
//		}
//		return (error, decryptedFile)
        return (nil, nil)
	}
	
	/**
		Decrypt Data
	
		- parameter data::	the encrypted data.
		- parameter passphrase::	the passphrase to unlock the private key.
		- parameter encryptionType::	PGP or SMIME
	
		- returns: The Error or nil if decrypt was successful
				  and Decrytped Data or nil if error occured.
 	*/
	func decryptData(data: NSData, passphrase: String, encryptionType: String) -> (NSError?, NSData?) {
//		let error: NSError?
//		let decryptedData: NSData?
//		if encryptionType.lowercaseString == "pgp" || encryptionType.lowercaseString == "gpg" {
////			decryptedData = self.pgp.decryptData(data, passphrase: passphrase, error: &error)
//			
//		} else if encryptionType.lowercaseString == "smime" || encryptionType.lowercaseString == "s/mime" {
//			// TODO
//			// Do smime stuff
//		}
//		
//		
////		return (error, decryptedData)
        return (nil, nil)
	}
	
	// MARK: - Encryption
	/**
	Encrypt File
	
	- parameter file::	the file to be encrypted.
	- parameter keyIdentifier::	the key ID full or short.
	- parameter encryptionType::	PGP or SMIME
	
	- returns: The Error or nil if encrypt was successful
	and encrytped Data or nil if error occured.
	*/
	func encryptFile(file: NSURL, keyIdentifier: String, encryptionType: String) -> (NSError?, NSURL?) {
//		let error: NSError?
//		let encryptedFile: NSURL?
//		var encryptedData: NSData?
//		var dataToEncrypt: NSData?
/*
		var copyItem: NSURL = NSURL(fileURLWithPath: self.documentDirectory.stringByAppendingPathComponent(self.fileManager.displayNameAtPath(file.path!)))!
		self.fileManager.copyItemAtURL(file, toURL: copyItem, error: &error)
		if error == nil {
			if encryptionType.lowercaseString == "pgp" || encryptionType.lowercaseString == "gpg" {
				dataToEncrypt = NSData(contentsOfURL: copyItem)
				if dataToEncrypt != nil {
					var keyToEncrypt: PGPKey = self.pgp.getKeyForIdentifier(keyIdentifier, type: PGPKeyType.Public)
					encryptedData = self.pgp.encryptData(dataToEncrypt!, usingPublicKey: keyToEncrypt, armored: true, error: &error)
					if encryptedData != nil && error == nil {
						var newFilePath: String = copyItem.path! + ".asc"
						if self.fileManager.createFileAtPath(newFilePath, contents: encryptedData!, attributes: nil) == true {
							encryptedFile = NSURL(fileURLWithPath: newFilePath)
							self.fileManager.removeItemAtURL(copyItem, error: nil)
						}
					}
				}
				
				
			} else if encryptionType.lowercaseString == "smime" || encryptionType.lowercaseString == "s/mime" {
				// TODO
				// Do smime stuff
			}
		}
*/
//		return (error, encryptedFile)
        return (nil, nil)
	}
	
	
	/**
	Encrypt Data
	
	- parameter data::	the data to be encrypted.
	- parameter keyIdentifier::	the key ID full or short.
	- parameter encryptionType::	PGP or SMIME
	
	- returns: The Error or nil if encrypt was successful
			  and encrytped Data or nil if error occured.
	*/
	func encryptData(data: NSData, keyIdentifier: String, encryptionType: String) -> (NSError?, NSData?) {
//		let error: NSError?
//		let encryptedData: NSData?
/*		if encryptionType.lowercaseString == "pgp" || encryptionType.lowercaseString == "gpg" {
			var keyToEncrypt: PGPKey = self.pgp.getKeyForIdentifier(keyIdentifier, type: PGPKeyType.Public)
						
			encryptedData = self.pgp.encryptData(data, usingPublicKey: keyToEncrypt, armored: true, error: &error)
			
		} else if encryptionType.lowercaseString == "smime" || encryptionType.lowercaseString == "s/mime" {
			// TODO
			// Do smime stuff
		}
		
*/
//		return (error, encryptedData)
        return (nil, nil)
	}
	
	// MARK: - Import Keys
	/**
	Import Key
	
	- parameter keyfile::	the URL of the keyfile to be imported.
	
	- returns: true if import was successful or key already exists in CoreData.
	*/
	func importKey(keyfile: NSURL) -> Bool {
		if let keyData = NSData(contentsOfURL: keyfile) {
			
			if let fileContent = try? String(contentsOfFile: keyfile.path!, encoding: NSUTF8StringEncoding) {
				// keyfile is ppg key
				if fileContent.rangeOfString(self.pubKeyBlockString) != nil || fileContent.rangeOfString(self.secKeyBlockString) != nil {
					let importedKey = pgp.importPGPKeyFromArmouredFile(keyData)
					let keyForCoreData = self.getKeyFromPGPKey(importedKey, keyFileData: keyData)
					
					// check if keyForCoreData already exists in CoreData
					if self.keysInCoreData != nil {
						for key in self.keysInCoreData! {
							if key.keyID == keyForCoreData.keyID {
								return true
							}
						}
					}
					// keyforCoreData is a new key -> save to core data
					if !self.saveKeyToCoreData(keyForCoreData) {
						return false
					}
				}
				
				// keyfile is smime file
				if fileContent.rangeOfString(self.smimeFileString) != nil {
					// TODO
					// do smime stuff
				}
			}
			
		}
		self.printAllPublicKeys()
		self.printAllSecretKeys()
		NSLog("Key imported")
		return true
}
	
	// MARK: - DEBUG
	
	/**
	Print all public keys from core data
	*/
	func printAllPublicKeys() {
		var pubKeyStrings: [String] = [String]()
		if self.keysInCoreData != nil {
			for key in self.keysInCoreData! {
				if key.isPublicKey {
					pubKeyStrings.append(key.keyID)
				}
			}
		}
		print("Public Keys: " + (pubKeyStrings).joinWithSeparator(","))
	}
	
	/**
	Print all secret keys from core data
	*/
	func printAllSecretKeys() {
		var secKeyStrings: [String] = [String]()
		if self.keysInCoreData != nil {
			for key in self.keysInCoreData! {
				if key.isSecretKey {
					secKeyStrings.append(key.keyID)
				}
			}
		}
		print("Public Keys: " + (secKeyStrings).joinWithSeparator(","))
	}
	
	func printPGPKeyFull(key: Key) -> Void {
		print("UserIDprimary: " + key.userIDprimary)
		print("emailAddressPrimary: " + key.emailAddressPrimary)
		print("keyID: " + key.keyID)
		print("isSecretKey: \(key.isSecretKey)")
		print("isPublicKey: \(key.isPublicKey)")
		print("keyType: " + key.keyType)
		print("created: \(key.created)")
		print("validThru: \(key.validThru)")
		print("keyLength: \(key.keyLength)")
		print("algorithm: " + key.algorithm)
		print("fingerprint: " + key.fingerprint)
		print("trust: \(key.trust)")
		var userIDs: [String] = [String]()
		for someUserID in key.userIDs{
			let userID = someUserID as! UserID
			userIDs.append(userID.name)
		}
		print("UserIDs: " + userIDs.joinWithSeparator(","))
		var subKeys: [String] = [String]()
		for SomeSubKey in key.subKeys {
			let subkey = SomeSubKey as! SubKey
			subKeys.append(subkey.subKeyID)
		}
		print("SubKeys: " + subKeys.joinWithSeparator(","))
		print("keyData: " + String(NSString(data: key.keyData, encoding: NSUTF8StringEncoding)!))
	}
	

	// MARK: - CoreData
	func getKeyFromPGPKey(pgpKey: PGPKey, keyFileData: NSData) -> KeyItem {
		let calendar = NSCalendar.currentCalendar()
		let newKey = KeyItem()
		let userIDextract = self.extractNameAndMailAddressFromUserID(pgpKey.getUserID())
		newKey.userIDprimary = userIDextract.name
		newKey.emailAddressPrimary = userIDextract.mailAddress
		newKey.keyID = pgpKey.getKeyID()
		newKey.isSecretKey = pgpKey.isPrivate
		newKey.isPublicKey = true
		newKey.keyType = "PGP"
		newKey.created = pgpKey.getCreationDate()
		
		if let validDate = calendar.dateByAddingUnit(.Day, value: Int(pgpKey.getTimeInDaysTillExpiration()), toDate: NSDate(), options: []) {
			newKey.validThru = validDate
		} else {
			newKey.validThru = pgpKey.getCreationDate()
		}
		
		newKey.keyLength = 2048
		newKey.algorithm = self.getAlgorithmString(Int(pgpKey.getKeyAlgorithm()))
		newKey.fingerprint = pgpKey.getKeyID()
		newKey.trust = TrustType.Unknown.rawValue
		
		var userIDs: [UserIdItem] = [UserIdItem]()
	//	for var i = 0; i < pgpKey.users.count; i++ {
			let userID = UserIdItem()
			userID.name = userIDextract.name
			userID.emailAddress = userIDextract.mailAddress
			userID.comment = ""
			userIDs.append(userID)
	//	}
		newKey.userIDs = NSSet(array: userIDs)
		newKey.subKeys = NSSet()
		newKey.keyData = keyFileData
		
		return newKey
	}

	
	private func getAlgorithmString(value: Int) -> String {
		switch value {
			case 1: return "RSA"
			case 2: return "RSA Encryption only"
			case 3: return "RSA Sign only"
			case 16: return "Elgamal"
			case 17: return "DSA"
			case 18: return "Elliptic"
			case 19: return "ECDSA"
			case 20: return "Elgamal EncryptorSign"
			case 21: return "Diffie Hellman"
			default: return "Private"
		}
	}
	
	private func saveKeyToCoreData(keyToSave: KeyItem) -> Bool {
		if self.managedObjectContext != nil {
			let newKeyEntry = NSEntityDescription.insertNewObjectForEntityForName("Key", inManagedObjectContext: self.managedObjectContext!) as! Key
			
			newKeyEntry.setValue(keyToSave.userIDprimary, forKey: "userIDprimary")
			newKeyEntry.setValue(keyToSave.emailAddressPrimary, forKey: "emailAddressPrimary")
			newKeyEntry.setValue(keyToSave.keyID, forKey: "keyID")
			newKeyEntry.setValue(keyToSave.isSecretKey, forKey: "isSecretKey")
			newKeyEntry.setValue(keyToSave.isPublicKey, forKey: "isPublicKey")
			newKeyEntry.setValue(keyToSave.keyType, forKey: "keyType")
			newKeyEntry.setValue(keyToSave.created, forKey: "created")
			newKeyEntry.setValue(keyToSave.validThru, forKey: "validThru")
			newKeyEntry.setValue(keyToSave.keyLength, forKey: "keyLength")
			newKeyEntry.setValue(keyToSave.algorithm, forKey: "algorithm")
			newKeyEntry.setValue(keyToSave.fingerprint, forKey: "fingerprint")
			newKeyEntry.setValue(keyToSave.trust, forKey: "trust")
			newKeyEntry.setValue(keyToSave.keyData, forKey: "keyData")
			newKeyEntry.setValue(keyToSave.subKeys, forKey: "subKeys")

			var userIDs: [UserID] = [UserID]()
			for item in keyToSave.userIDs {
				let userID = item as! UserIdItem
				let newUserIDEntry = NSEntityDescription.insertNewObjectForEntityForName("UserID", inManagedObjectContext: self.managedObjectContext!) as! UserID
				
				newUserIDEntry.setValue(userID.name, forKey: "name")
				newUserIDEntry.setValue(userID.emailAddress, forKey: "emailAddress")
				newUserIDEntry.setValue(userID.comment, forKey: "comment")
				newUserIDEntry.setValue(newKeyEntry, forKey: "toKey")
				userIDs.append(newUserIDEntry)
			}
			newKeyEntry.setValue(NSSet(array: userIDs), forKey: "userIDs")
			
			// all set up -> save to core data
			do {
				
				try self.managedObjectContext!.save()
				
			} catch let error as NSError {
				NSLog("Error saving to CoreData: \(error), \(error.userInfo)")
				return false
			}
		}
		
        return true
	}

	// MARK: - Utility
	/**
	Get name and address from userID String
	
	- parameter userID::	The userID String (PGPUser.userID).
	
	- returns: (name, address) or (String(), String()).
	*/
	private func extractNameAndMailAddressFromUserID(userID: String) -> (name: String, mailAddress: String) {
		let nameRange: Range? = userID.rangeOfString("<")
		let addressRange: Range? = userID.rangeOfString(">")
		var name: String = ""
		var address: String = ""
		if nameRange != nil {
			name = userID.substringToIndex(nameRange!.startIndex)
		}
		if addressRange != nil {
			address = userID.substringWithRange(Range<String.Index>(start: nameRange!.endIndex, end: addressRange!.startIndex))
		}
		
		return (name, address)
	}
	

}
