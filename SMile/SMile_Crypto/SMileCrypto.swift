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
	private let pubKeyBlockStringEnd = "-----END PGP PUBLIC KEY BLOCK-----"
	private let secKeyBlockString = "-----BEGIN PGP PRIVATE KEY BLOCK-----"
	private let secKeyBlockStringEnd = "-----END PGP PRIVATE KEY BLOCK-----"
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
	
	- returns:	The Error or nil if decrypt was successful.
				Decrytped File at URL or nil if error occured.
				If Error is not nil the error may contain the KeyID (error!.userInfo["KeyID"])
	*/
	func decryptFile(encryptedFile: NSURL, passphrase: String, encryptionType: String) -> (error: NSError?, decryptedFile: NSURL?) {
		var error: NSError?
		var decryptedFile: NSURL?
		var encryptedData: NSData?
		
		var copyItem: NSURL = NSURL(fileURLWithPath: self.documentDirectory)
        copyItem = copyItem.URLByAppendingPathComponent(self.fileManager.displayNameAtPath(encryptedFile.path!))
		
		do {
			try self.fileManager.copyItemAtURL(encryptedFile, toURL: copyItem)
		} catch let error1 as NSError {
			error = error1
		}
		if error == nil {
			if encryptionType.lowercaseString == "pgp" || encryptionType.lowercaseString == "gpg" {
				encryptedData = NSData(contentsOfURL: copyItem)
				if encryptedData != nil {
					let decryptedPacket = self.decryptData(encryptedData!, passphrase: passphrase, encryptionType: "PGP")
					if decryptedPacket.error != nil {
						error = decryptedPacket.error
					} else {
						// cut of .asc or .gpg to get the original extention
						// for files not conforming to encrypted filenames like test.pdf.asc we have to implement some magic number checking
						let newFilePath: String = (copyItem.path! as NSString).substringToIndex((copyItem.path! as NSString).length - 4)
						if self.fileManager.createFileAtPath(newFilePath, contents: decryptedPacket.decryptedData, attributes: nil) == true {
							decryptedFile = NSURL(fileURLWithPath: newFilePath)
							
							// everything went ok here!
							
						} else {
							var errorDetail = [String: String]()
							errorDetail[NSLocalizedDescriptionKey] = "File could not be created!"
							error = NSError(domain: "SMileCrypto", code: 108, userInfo: errorDetail)
						}
					}
				} else {
					var errorDetail = [String: String]()
					errorDetail[NSLocalizedDescriptionKey] = "File could not be read!"
					error = NSError(domain: "SMileCrypto", code: 107, userInfo: errorDetail)
				}
			} else if encryptionType.lowercaseString == "smime" || encryptionType.lowercaseString == "s/mime" {
				// TODO
				// Do smime stuff
				var errorDetail = [String: String]()
				errorDetail[NSLocalizedDescriptionKey] = "SMIME not implemented yet!"
				error = NSError(domain: "SMileCrypto", code: 107, userInfo: errorDetail)
			}

			
		}
		return (error, decryptedFile)
	}
	
	/**
		Decrypt Data
	
		- parameter data::	the encrypted data.
		- parameter passphrase::	the passphrase to unlock the private key.
		- parameter encryptionType::	PGP or SMIME
	
		- returns:	The Error or nil if decrypt was successful
					and Decrytped Data or nil if error occured.
					If Error is not nil the error may contain the KeyID (error!.userInfo["KeyID"])
 	*/
	func decryptData(data: NSData, passphrase: String, encryptionType: String) -> (error: NSError?, decryptedData: NSData?) {
		var error: NSError?
		var decryptedData: NSData?
		if encryptionType.lowercaseString == "pgp" || encryptionType.lowercaseString == "gpg" {
			if let decryptKeyID = pgp.getKeyIDFromArmoredPGPMessage(data) {
				var keyInCoreData: Key?
				if self.keysInCoreData != nil {
					for key in self.keysInCoreData! {
						if key.keyID == decryptKeyID {
							keyInCoreData = key
							break
						} else {
							for item in key.subKeys {
								let subkey = item as! SubKey
								if subkey.subKeyID == decryptKeyID {
									keyInCoreData = key
									break
								}
								
							}
						}
					}
				}
				// key found
				if keyInCoreData != nil {
					if let pgpKey = pgp.importPGPKeyFromArmouredFile(keyInCoreData!.keyData) {
						decryptedData = pgp.decryptPGPMessageWithKey(pgpKey, fromArmouredFile: keyInCoreData!.keyData, withPassphrase: passphrase)
						if decryptedData  == nil {
							var errorDetail = [String: String]()
							errorDetail[NSLocalizedDescriptionKey] = "Decrypt failed for key " + keyInCoreData!.keyID
							errorDetail["KeyID"] = keyInCoreData!.keyID
							error = NSError(domain: "SMileCrypto", code: 106, userInfo: errorDetail)
							
						}
						
						
						// everything went ok at this point
						
					} else {
						var errorDetail = [String: String]()
						errorDetail[NSLocalizedDescriptionKey] = "No valid PGPKey returned from SMilePGP Instance!"
						error = NSError(domain: "SMileCrypto", code: 102, userInfo: errorDetail)
					}
					
				} else {
					// no key found
					var errorDetail = [String: String]()
					errorDetail[NSLocalizedDescriptionKey] = "No matching key in CoreData found!"
					error = NSError(domain: "SMileCrypto", code: 100, userInfo: errorDetail)
				}
				
			} else {
				var errorDetail = [String: String]()
				errorDetail[NSLocalizedDescriptionKey] = "KeyID could not be extracted from armored PGP message!"
				error = NSError(domain: "SMileCrypto", code: 105, userInfo: errorDetail)
			}
		} else if encryptionType.lowercaseString == "smime" || encryptionType.lowercaseString == "s/mime" {
			// TODO
			// Do smime stuff
			var errorDetail = [String: String]()
			errorDetail[NSLocalizedDescriptionKey] = "SMIME not implemented yet!"
			error = NSError(domain: "SMileCrypto", code: 107, userInfo: errorDetail)
		}
		
		
		return (error, decryptedData)
	}
	
	// MARK: - Encryption
	/**
	Encrypt File
	
	- parameter file::	the file to be encrypted.
	- parameter keyIdentifier::	the key ID.
	- parameter encryptionType::	PGP or SMIME
	
	- returns: The Error or nil if encrypt was successful
	and encrytped Data or nil if error occured.
	*/
	func encryptFile(file: NSURL, keyIdentifier: String, encryptionType: String) -> (error: NSError?, encryptedFile: NSURL?) {
		var error: NSError?
		var encryptedFile: NSURL?
		
		var copyItem: NSURL = NSURL(fileURLWithPath: self.documentDirectory)
		copyItem = copyItem.URLByAppendingPathComponent(self.fileManager.displayNameAtPath(file.path!))
		
		do {
			try self.fileManager.copyItemAtURL(file, toURL: copyItem)
		} catch let error1 as NSError {
			error = error1
		}
		if error == nil {
			if encryptionType.lowercaseString == "pgp" || encryptionType.lowercaseString == "gpg" {
				if let dataToEncrypt = NSData(contentsOfURL: copyItem) {
					let encryptedPacket = self.encryptData(dataToEncrypt, keyIdentifier: keyIdentifier, encryptionType: encryptionType)
					if encryptedPacket.error != nil {
						error = encryptedPacket.error
					} else {
						// create file
						let newFilePath: String = copyItem.path! + ".asc"
						if self.fileManager.createFileAtPath(newFilePath, contents: encryptedPacket.encryptedData, attributes: nil) == true {
							encryptedFile = NSURL(fileURLWithPath: newFilePath)
						} else {
							var errorDetail = [String: String]()
							errorDetail[NSLocalizedDescriptionKey] = "File creation error!"
							error = NSError(domain: "SMileCrypto", code: 105, userInfo: errorDetail)
						}
					}
				} else {
					// file error
					var errorDetail = [String: String]()
					errorDetail[NSLocalizedDescriptionKey] = "No file found"
					error = NSError(domain: "SMileCrypto", code: 104, userInfo: errorDetail)
				}
				
				
			} else if encryptionType.lowercaseString == "smime" || encryptionType.lowercaseString == "s/mime" {
				// TODO
				// Do smime stuff
				var errorDetail = [String: String]()
				errorDetail[NSLocalizedDescriptionKey] = "SMIME not implemented yet!"
				error = NSError(domain: "SMileCrypto", code: 107, userInfo: errorDetail)
			}
			
			do {
			 try self.fileManager.removeItemAtURL(copyItem)
			} catch let error2 as NSError {
				NSLog("Removing file \(copyItem.path!) did not succeed! Error: \(error2.localizedDescription)")
			}
			
		}
		return (error, encryptedFile)
	}
	
	
	/**
	Encrypt Data
	
	- parameter data::	the data to be encrypted.
	- parameter keyIdentifier::	the key ID.
	- parameter encryptionType::	PGP or SMIME
	
	- returns: The Error or nil if encrypt was successful
			  and encrytped Data or nil if error occured.
	*/
	func encryptData(data: NSData, keyIdentifier: String, encryptionType: String) -> (error: NSError?, encryptedData: NSData?) {
		var error: NSError?
		var encryptedData: NSData?
		if encryptionType.lowercaseString == "pgp" || encryptionType.lowercaseString == "gpg" {
			
			var keyInCoreData: Key?
			if self.keysInCoreData != nil {
				for key in self.keysInCoreData! {
					if key.keyID == keyIdentifier {
						keyInCoreData = key
						break
					} else {
						for item in key.subKeys {
							let subkey = item as! SubKey
							if subkey.subKeyID == keyIdentifier {
								keyInCoreData = key
								break
							}
							
						}
					}
				}
			}
			// key found
			if keyInCoreData != nil {
				if let pgpKey = pgp.importPGPKeyFromArmouredFile(keyInCoreData!.keyData) {
					encryptedData = pgp.buildPGPMessageFromData(data, withKey: pgpKey)
					if encryptedData == nil {
						var errorDetail = [String: String]()
						errorDetail[NSLocalizedDescriptionKey] = "Encryption did not complete properly!"
						error = NSError(domain: "SMileCrypto", code: 101, userInfo: errorDetail)
					}
					// everything went ok at this point
					
				} else {
					var errorDetail = [String: String]()
					errorDetail[NSLocalizedDescriptionKey] = "No valid PGPKey returned from SMilePGP Instance!"
					error = NSError(domain: "SMileCrypto", code: 102, userInfo: errorDetail)
				}
				
			} else {
				// no key found
				var errorDetail = [String: String]()
				errorDetail[NSLocalizedDescriptionKey] = "No matching key in CoreData found!"
				error = NSError(domain: "SMileCrypto", code: 100, userInfo: errorDetail)
			}
			
		} else if encryptionType.lowercaseString == "smime" || encryptionType.lowercaseString == "s/mime" {
			// TODO
			// Do smime stuff
			var errorDetail = [String: String]()
			errorDetail[NSLocalizedDescriptionKey] = "SMIME not implemented yet!"
			error = NSError(domain: "SMileCrypto", code: 107, userInfo: errorDetail)
		}
		
		return (error, encryptedData)
	}
	
	// MARK: - Import Keys
	/**
	Import Key
	
	- parameter keyfile::	the URL of the keyfile to be imported.
	
	- returns: true if import was successful or key already exists in CoreData.
	*/
	func importKey(keyfile: NSURL) -> Bool {
		if let keyData = NSData(contentsOfURL: keyfile) {
			var extractedKeyData: NSData?
			var keyForCoreData: KeyItem?
			
			if let fileContent = try? String(contentsOfFile: keyfile.path!, encoding: NSUTF8StringEncoding) {
				// keyfile is ppg key
				if fileContent.rangeOfString(self.pubKeyBlockString) != nil || fileContent.rangeOfString(self.secKeyBlockString) != nil {
					// file contains pub AND sec keyblock -> cut off public
					if fileContent.rangeOfString(self.pubKeyBlockString) != nil &&
						fileContent.rangeOfString(self.secKeyBlockString) != nil {
							let beginRange = fileContent.rangeOfString(self.secKeyBlockString)
							let endRange = fileContent.rangeOfString(self.secKeyBlockStringEnd)
							if beginRange != nil && endRange != nil {
								let privateKeyBlock = fileContent.substringWithRange(Range<String.Index>(start: beginRange!.startIndex, end: endRange!.endIndex))
								extractedKeyData = privateKeyBlock.dataUsingEncoding(NSUTF8StringEncoding)
							}
					}
					
					if extractedKeyData != nil {
						let importedKey = pgp.importPGPKeyFromArmouredFile(extractedKeyData!)
						if importedKey == nil { return false }
						keyForCoreData = self.getKeyFromPGPKey(importedKey!, keyFileData: extractedKeyData!)
						
					} else {
						let importedKey = pgp.importPGPKeyFromArmouredFile(keyData)
						if importedKey == nil { return false }
						keyForCoreData = self.getKeyFromPGPKey(importedKey!, keyFileData: keyData)
					}
					
					
					
					// check if keyForCoreData already exists in CoreData
					if self.keysInCoreData != nil {
						for key in self.keysInCoreData! {
							if key.keyID == keyForCoreData!.keyID {
								return true
							}
						}
					}
					// keyforCoreData is a new key -> save to core data
					if !self.saveKeyToCoreData(keyForCoreData!) {
						return false
					}
					// update keys from coreData
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
				
				// keyfile is smime file
				if fileContent.rangeOfString(self.smimeFileString) != nil {
					// TODO
					// do smime stuff
					return false
				}
			}
			
		}
		NSLog("Key imported")
		return true
}
	
	// MARK: - Info
	
	/**
	Get the Key a encrypted message was encrypted with.
	
	- parameter encryptedData:	The encrypted message.
	
	- returns: The Key or nil if none found.
	*/
	func getKeyforEncryptedMessage(encryptedData: NSData) -> Key? {
		var keyInCoreData: Key?
		
		if let keyID = pgp.getKeyIDFromArmoredPGPMessage(encryptedData) {
			if self.keysInCoreData != nil {
				for key in self.keysInCoreData! {
					if key.keyID == keyID {
						keyInCoreData = key
						break
					} else {
						for item in key.subKeys {
							let subkey = item as! SubKey
							if subkey.subKeyID == keyID {
								keyInCoreData = key
								break
							}
							
						}
					}
				}
			}
		}
		return keyInCoreData
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
		let userIDextract = self.extractNameAndMailAddressFromUserID(pgpKey.getUserIDs().objectAtIndex(0) as! String)
		newKey.userIDprimary = userIDextract.name
		newKey.emailAddressPrimary = userIDextract.mailAddress
		newKey.keyID = pgpKey.getKeyID()
		newKey.isSecretKey = pgpKey.isPrivate
		newKey.isPublicKey = true
		newKey.keyType = "PGP"
		newKey.created = pgpKey.getCreationDate()
		
		// because the expiration time interval is optional in RFC4880 we will use this magic date to indicate that the key won't expire. :-P
		if Int(pgpKey.getTimeInDaysTillExpiration()) == 0 {
			newKey.validThru = NSDate(dateString: "9999-01-01")
		} else {
			
			if let validDate = calendar.dateByAddingUnit(.Day, value: Int(pgpKey.getTimeInDaysTillExpiration()), toDate: pgpKey.getCreationDate(), options: []) {
				newKey.validThru = validDate
			} else {
				newKey.validThru = pgpKey.getCreationDate()
			}
		}
		
		newKey.keyLength = Int(pgpKey.getKeyLength())
		newKey.algorithm = self.getAlgorithmString(Int(pgpKey.getKeyAlgorithm()))
		newKey.fingerprint = pgpKey.getFingerPrint()
		newKey.trust = TrustType.Unknown.rawValue
		
		var userIDs: [UserIdItem] = [UserIdItem]()
		for var i = 0; i < pgpKey.getUserIDs().count; i++ {
			let userID = UserIdItem()
			let userIDextractSub = self.extractNameAndMailAddressFromUserID(pgpKey.getUserIDs().objectAtIndex(i) as! String)
			userID.name = userIDextractSub.name
			userID.emailAddress = userIDextractSub.mailAddress
			userID.comment = ""
			userIDs.append(userID)
		}
		newKey.userIDs = NSSet(array: userIDs)
		
		var subKeys: [SubKeyItem] = [SubKeyItem]()
		for var i = 0; i < pgpKey.subKeys.count; i++ {
			let subkey = SubKeyItem()
			let pgpsubkey = pgpKey.subKeys.objectAtIndex(i) as! PGPKey
 			subkey.subKeyID = pgpsubkey.getKeyID()
			subkey.length = Int(pgpsubkey.getKeyLength())
			subkey.algorithm = self.getAlgorithmString(Int(pgpsubkey.getKeyAlgorithm()))
			subkey.created = pgpsubkey.getCreationDate()
			if let validDate = calendar.dateByAddingUnit(.Day, value: Int(pgpsubkey.getTimeInDaysTillExpiration()), toDate: NSDate(), options: []) {
				subkey.validThru = validDate
			} else {
				subkey.validThru = pgpsubkey.getCreationDate()
			}
			subKeys.append(subkey)
		}
		
		newKey.subKeys = NSSet(array: subKeys)
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
			
			// subkeys
			var subKeys: [SubKey] = [SubKey]()
			for item in keyToSave.subKeys {
				let subKey = item as! SubKeyItem
				let newSubKeyEntry = NSEntityDescription.insertNewObjectForEntityForName("SubKey", inManagedObjectContext: self.managedObjectContext!) as! SubKey
				newSubKeyEntry.setValue(subKey.subKeyID, forKey: "subKeyID")
				newSubKeyEntry.setValue(subKey.length, forKey: "length")
				newSubKeyEntry.setValue(subKey.algorithm, forKey: "algorithm")
				newSubKeyEntry.setValue(subKey.created, forKey: "created")
				newSubKeyEntry.setValue(subKey.validThru, forKey: "validThru")
				newSubKeyEntry.setValue(newKeyEntry, forKey: "toKey")
				subKeys.append(newSubKeyEntry)
				
			}
			newKeyEntry.setValue(NSSet(array: subKeys), forKey: "subKeys")

			// userIDs
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
	
    func getKeysFromCoreData() -> [Key]? {
        return self.keysInCoreData
    }
    
}
