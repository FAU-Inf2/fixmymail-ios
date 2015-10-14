//
//  RemindMe.swift
//  SMile
//
//  Created by Andrea Albrecht on 14.09.15.
//  Copyright (c) 2015 SMile. All rights reserved.
//

import Foundation
import SwiftyJSON
import Locksmith
import CoreData

extension JSON {
    public init(_ jsonArray:[JSON]) {
        self.init(jsonArray.map { $0.object })
    }
}

class RemindMe{
    var jsonstring:String?
    var folderStorage:String?
    var folderRemind:String?
    var lastUpdated:NSDate?
    
//
//Check if Folder RemindMe and SmileStorage exists and if not create them
//
    func checkIfFolderExist(account:EmailAccount) -> Bool {
        var remind:Bool = false
        var storage:Bool = false
        for folder in account.folders{
            let fol: MCOIMAPFolder = (folder as! ImapFolder).mcoimapfolder
            if fol.path.rangeOfString("RemindMe") != nil{
                folderRemind = fol.path
                remind = true
            }
            if fol.path.rangeOfString("SmileStorage") != nil {
                folderStorage = fol.path
                storage = true
            }
        }
        if remind == false || storage == false{
            var imapsession: MCOIMAPSession!
            do{
                imapsession = try getSession(account)
            }catch _ {
                print ( "Error while trying to create RemindMe and SmileStorage Folder")
				return false
            }
            if remind == false{
                let appendMsgOp = imapsession.createFolderOperation("RemindMe")
                appendMsgOp.start({ (error) -> Void in
                    if error != nil {
                        NSLog("%@", error.description)
                    } else {
                        NSLog("Folder created")
                    }
                })
                folderRemind = "RemindMe"
            }
            if storage == false{
                let appendMsgOp = imapsession.createFolderOperation("SmileStorage")
                appendMsgOp.start({ (error) -> Void in
                    if error != nil {
                        NSLog("%@", error.description)
                    } else {
                        NSLog("Folder created")
                    }
                })
                folderStorage = "SmileStorage"
            }
        }
		
		return true
    }
    
    
    
//
//Check if in Folder SmileStorage Json file exists and if not create it
//
    func checkIfJSONEmailExists(toAccount:EmailAccount){
        /*print("exists")
        print(Account.accountName)
        var exists:Bool = false
        let currentMaxUID = getMaxUID(Account, folderToQuery: folderStorage!)
        saveCoreDataChanges()
        updateLocalEmail(Account, folderToQuery: folderStorage!)
        fetchEmails(Account, folderToQuery: folderStorage!, uidRange: MCOIndexSet(range: MCORangeMake(UInt64(currentMaxUID+1), UINT64_MAX-UInt64(currentMaxUID+2))))
        for mail in Account.emails {
            if (mail as! Email).folder == folderStorage {
                exists = true
            }
        }
        print(exists)
        if(exists == false){
            jsonstring = "{\"allRemindMes\":[]}"
            uploadJsonMail(Account)
            print("new")
            saveCoreDataChanges()
        }*/
		do {
			let session = try getSession(toAccount)
			let requestKind:MCOIMAPMessagesRequestKind = ([MCOIMAPMessagesRequestKind.Uid, MCOIMAPMessagesRequestKind.Flags, MCOIMAPMessagesRequestKind.Headers, MCOIMAPMessagesRequestKind.Structure])
			let fetchJsonFile = session.fetchMessagesByNumberOperationWithFolder(self.folderStorage!, requestKind: requestKind, numbers: MCOIndexSet(range: MCORangeMake(1, UINT64_MAX)))
			fetchJsonFile.start({ (error, messages, set) -> Void in
				if messages.count == 0 {
					self.jsonstring = "{\"allRemindMes\":[]}"
					
					let builder = MCOMessageBuilder()
					
					builder.header.subject = "Internal from Smile"
					let now = time_t(NSDate().timeIntervalSince1970)
					builder.header.messageID = "SmileStorage\(now)"
					builder.textBody = self.jsonstring
					let appendOp = session.appendMessageOperationWithFolder(self.folderStorage!, messageData: builder.data(), flags: MCOMessageFlag.Seen)
					appendOp.start({ (error, uid) -> Void in
						if error != nil {
							
						}
					})
				}
			})
		} catch {
			
		}
    }

    
//
//Adds Json Entry for new RemindMe email
//
    func setJSONforUpcomingRemind(email: Email, remindTime: NSDate){
        //Get current JsonMail from SmileStorage Folder
        //saveCoreDataChanges()
        //let currentMaxUID = getMaxUID(email.toAccount, folderToQuery: folderStorage!)
        //var time1 = email.toAccount.emails
        //updateLocalEmail(email.toAccount, folderToQuery: folderStorage!)
        //fetchEmails(email.toAccount, folderToQuery: folderStorage!, uidRange: MCOIndexSet(range: MCORangeMake(UInt64(currentMaxUID+1), UINT64_MAX-UInt64(currentMaxUID+2))))
        //saveCoreDataChanges()
        //var time2 = email.toAccount.emails
            
        /*
            //add new json entry
            var alreadyReminding:Bool = false
            let now = time_t(NSDate().timeIntervalSince1970)
            var header = email.mcomessage.header!
            header = email.mcomessage.header!
            let messageId = header.messageID
            
            let remindTimeTimestamp = time_t(remindTime.timeIntervalSince1970)
            print(remindTimeTimestamp)
            
            let dataFromString = jsonmail!.plainText.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
            if dataFromString != nil {
                var json = JSON(data: dataFromString!)
                var json2 = json["allRemindMes"].arrayValue
                 for result in json["allRemindMes"].arrayValue {
                    if result["messageId"].string! == email.mcomessage.header!.messageID{
                        let newjson = JSON(["folderId": result["folderId"].doubleValue, "id": result["id"].doubleValue, "lastModified": now, "messageId": messageId, "remindInterval": result["remindInterval"].stringValue, "remindTime": remindTimeTimestamp, "seen": NSNull(), "title": email.title, "uid": NSNull(), "reference": NSNull()])
                        json2.removeAtIndex(json["allRemindMes"].arrayValue.indexOf(result)!)
                        json2.append(newjson)
                        json["allRemindMes"] = JSON(json2)
                        print("duplicate found")
                        alreadyReminding = true
                    }
                }
                
                
                if alreadyReminding == false{
                    
                    header.receivedDate = remindTime
                    updateLocalEmail(email.toAccount, folderToQuery: folderRemind!)
                    saveCoreDataChanges()
                    
                    moveEmailToFolder(email, destFolder: folderRemind)
                    //
                    
                    let newjson = JSON(["folderId": NSNull(), "id": NSNull(), "lastModified": now, "messageId": messageId, "remindInterval": NSNull(), "remindTime": remindTimeTimestamp, "seen": NSNull(), "title": email.title, "uid": NSNull(), "reference": NSNull()])
                
                    //Add newjson to json2
                    json2.append(newjson)
                    json["allRemindMes"] = JSON(json2)
                   }
                    jsonstring = json.rawString()!
                    
                
                    //delete old json email
                    deleteEmail(jsonmail!)
                    uploadJsonMail(email.toAccount)
                    saveCoreDataChanges()
                    updateLocalEmail(email.toAccount, folderToQuery: folderStorage!)
                
                
            }
        }*/
		
		do {
			let session = try getSession(email.toAccount)
			let requestKind:MCOIMAPMessagesRequestKind = ([MCOIMAPMessagesRequestKind.Uid, MCOIMAPMessagesRequestKind.Flags, MCOIMAPMessagesRequestKind.Headers, MCOIMAPMessagesRequestKind.Structure])
			let fetchJsonFile = session.fetchMessagesByNumberOperationWithFolder(self.folderStorage!, requestKind: requestKind, numbers: MCOIndexSet(range: MCORangeMake(1, UINT64_MAX)))
			fetchJsonFile.start({ (error, jsonFiles, range) -> Void in
				if error != nil {
					
				}else {
					if jsonFiles.count > 0 {
						var latestJsonFile: MCOIMAPMessage = jsonFiles[0] as! MCOIMAPMessage
						for file in jsonFiles {
							if latestJsonFile.uid < (file as! MCOIMAPMessage).uid {
								latestJsonFile = file as! MCOIMAPMessage;
							}
						}
						//Fetch Data
						let fetchEmailDataOp = session.fetchMessageOperationWithFolder(self.folderStorage!, uid: latestJsonFile.uid)
						
						fetchEmailDataOp.start({(error, data) in
							if error != nil {
								NSLog("Could not recieve mail: %@", error)
							} else {
								let parser: MCOMessageParser! = MCOMessageParser(data: data)
								self.jsonstring = parser.plainTextBodyRendering()
								
								session.storeFlagsOperationWithFolder(self.folderStorage!, uids: MCOIndexSet(index: UInt64(latestJsonFile.uid)), kind: MCOIMAPStoreFlagsRequestKind.Add, flags: MCOMessageFlag.Deleted).start({ (error) -> Void in
									if error != nil {
										print("error")
									} else {
										let expungeFolder = session.expungeOperation(self.folderStorage!)
										expungeFolder.start({ (error) -> Void in })
									}
								})
								
								var alreadyReminding:Bool = false
								let now = time_t(NSDate().timeIntervalSince1970)
								var header = email.mcomessage.header!
								header = email.mcomessage.header!
								let messageId = header.messageID
								
								let remindTimeTimestamp = time_t(remindTime.timeIntervalSince1970)
								print(remindTimeTimestamp)
								let dataFromString = self.jsonstring!.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
								if dataFromString != nil {
									var json = JSON(data: dataFromString!)
									var json2 = json["allRemindMes"].arrayValue
									for result in json["allRemindMes"].arrayValue {
										if result["messageId"].string! == email.mcomessage.header!.messageID{
											let newjson = JSON(["folderId": result["folderId"].doubleValue, "id": result["id"].doubleValue, "lastModified": now, "messageId": messageId, "remindInterval": result["remindInterval"].stringValue, "remindTime": remindTimeTimestamp, "seen": NSNull(), "title": email.title, "uid": NSNull(), "reference": NSNull()])
											json2.removeAtIndex(json["allRemindMes"].arrayValue.indexOf(result)!)
											json2.append(newjson)
											json["allRemindMes"] = JSON(json2)
											print("duplicate found")
											alreadyReminding = true
										}
									}
									
									
									if alreadyReminding == false{
										
										header.receivedDate = remindTime
										
										
										moveEmailToFolder(email, destFolder: self.folderRemind)
										//
										
										let newjson = JSON(["folderId": NSNull(), "id": NSNull(), "lastModified": now, "messageId": messageId, "remindInterval": NSNull(), "remindTime": remindTimeTimestamp, "seen": NSNull(), "title": email.title, "uid": NSNull(), "reference": NSNull()])
										
										//Add newjson to json2
										json2.append(newjson)
										json["allRemindMes"] = JSON(json2)
									}
									self.jsonstring = json.rawString()!
									
									let builder = MCOMessageBuilder()
									
									builder.header.subject = "Internal from Smile"
									builder.header.messageID = "SmileStorage\(now)"
									builder.textBody = self.jsonstring
									let appendOp = session.appendMessageOperationWithFolder(self.folderStorage!, messageData: builder.data(), flags: MCOMessageFlag.Seen)
									appendOp.start({ (error, uid) -> Void in
										if error != nil {
											
										}
									})
								}
							}
						})
					}
				}
			})
		} catch {
			print("getSession() error")
		}
    }
		
//
//upload new jsonmail to folder
//
    func uploadJsonMail(Account:EmailAccount){
        print("json created")
        lastUpdated = NSDate()
		
        var imapSession: MCOIMAPSession!
        do {
            imapSession = try getSession(Account)
        } catch _ {
            print("Error while trying to move email to drafts folder")
            return
        }
        
        let appendMsgOp = imapSession.appendMessageOperationWithFolder(folderStorage, messageData: self.buildEmail(), flags: [MCOMessageFlag.Seen])
        appendMsgOp.start({ (error, uid) -> Void in
            if error != nil {
                NSLog("%@", error.description)
            } else {
                NSLog("Draft saved")
            }
        })
    }
    
    
    
//
// Build email with subject and jsonstring
//
    func buildEmail() -> NSData {
        let builder = MCOMessageBuilder()
        print(jsonstring!)
        
        builder.header.subject = "Internal from Smile"
        builder.textBody = jsonstring
        return builder.data()
    }

    
//
// delete old json
//
    func deleteEmail(mail: Email) {
        
        addFlagToEmail(mail, flag: MCOMessageFlag.Deleted)
        managedObjectContext.deleteObject(mail)
        saveCoreDataChanges()
    }

    
    
//
// download jsonfile from Folder and check if emails are due date
//
    func downlaodJsonAndCheckForUpcomingReminds(toAccount: EmailAccount){ // ich gehe davon aus das SmileStorage vorhanden ist weil ich es vorher ja abgeprüft habe und notfalls erstellt habe
		if self.checkIfFolderExist(toAccount) == false {
			 print("Remind folder could not be created")
			return
		}
		do {
			let session = try getSession(toAccount)
			let requestKind:MCOIMAPMessagesRequestKind = ([MCOIMAPMessagesRequestKind.Uid, MCOIMAPMessagesRequestKind.Flags, MCOIMAPMessagesRequestKind.Headers, MCOIMAPMessagesRequestKind.Structure])
			let fetchJsonFile = session.fetchMessagesByNumberOperationWithFolder(self.folderStorage!, requestKind: requestKind, numbers: MCOIndexSet(range: MCORangeMake(1, UINT64_MAX)))
			fetchJsonFile.start({ (error, jsonFiles, range) -> Void in
				if error != nil {
					
				}else {
					if jsonFiles.count > 0 {
						var latestJsonFile: MCOIMAPMessage = jsonFiles[0] as! MCOIMAPMessage
						for file in jsonFiles {
							if latestJsonFile.uid < (file as! MCOIMAPMessage).uid {
								latestJsonFile = file as! MCOIMAPMessage;
							}
						}
						//Fetch Data
						let fetchEmailDataOp = session.fetchMessageOperationWithFolder(self.folderStorage!, uid: latestJsonFile.uid)
						
						fetchEmailDataOp.start({(error, data) in
							if error != nil {
								NSLog("Could not recieve mail: %@", error)
							} else {
								let parser: MCOMessageParser! = MCOMessageParser(data: data)
								self.jsonstring = parser.plainTextBodyRendering()
								self.performRemindMe(toAccount)
							}
						})
					}
				}
			})
		} catch {
			print("getSession() error")
		}
		//} else { //Fetch new Json
		
		//}
        //updateLocalEmail(toAccount, folderToQuery: folderStorage!)
        //fetchEmails(toAccount, folderToQuery: folderStorage!, uidRange: MCOIndexSet(range: MCORangeMake(UInt64(currentMaxUID+1), UINT64_MAX-UInt64(currentMaxUID+2))))
        
        /*for mail in toAccount.emails {
            if mail.folder == folderStorage {
                jsonmail = mail as? Email
            }
        }
        if(jsonmail == nil){
            print("no JSON")
            return
        }*/
        
		
    }
	
	func performRemindMe (toAccount: EmailAccount) {
		var somethingChanged:Bool = false
		//RemindMe auslesen
		if let dataFromString = jsonstring!.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
			var json = JSON(data: dataFromString)
			var cleanarray:[JSON] = []
			var now = NSDate()
			let components = NSDateComponents()
			components.hour = NSTimeZone.localTimeZone().secondsFromGMT/3600 //zeitzone reinrechnen
			now = NSCalendar.currentCalendar().dateByAddingComponents(components, toDate: now, options: [])!
			for result in json["allRemindMes"].arrayValue {
				
				//RemindMe Datum mit aktuellem Datum vergleichen
				let time = result["remindTime"].doubleValue
				var theDate =  NSDate(timeIntervalSince1970: time)
				
				
				if theDate.year()>10000{
					let time = result["remindTime"].stringValue
					let prefix:String = "/Date("
					let suffix:String = ")/"
					let time2 = prefix + time + suffix
					theDate = NSDate(jsonDate: time2)!
				}
				print(result["title"].stringValue)
				print(theDate)
				let compareResult = now.compare(theDate)
				if compareResult == NSComparisonResult.OrderedDescending {
					//move email to Inbox
					print("push email")
					
					let id = result["messageId"].stringValue
					/*if let upcomingEmail = returnEmailWithSpecificID(toAccount, folder: folderRemind!, id: id){
						print("file found")
						removeFlagFromEmail(upcomingEmail, flag: MCOMessageFlag.Seen)//Flag auf unseen setzten bzw. vielleicht auf remind
						addFlagToEmail(upcomingEmail, flag: MCOMessageFlag.Flagged)
						let inboxfolder = "INBOX"
						moveEmailToFolder(upcomingEmail, destFolder: inboxfolder)
						
					}*/
					
					do {
						let session = try getSession(toAccount)
						let requestKind:MCOIMAPMessagesRequestKind = ([MCOIMAPMessagesRequestKind.Uid, MCOIMAPMessagesRequestKind.Flags, MCOIMAPMessagesRequestKind.Headers, MCOIMAPMessagesRequestKind.Structure])
						session.fetchMessagesByNumberOperationWithFolder(folderRemind!, requestKind: requestKind, numbers: MCOIndexSet(range: MCORangeMake(1, UINT64_MAX))).start({ (error, messages, set) -> Void in
							if error != nil {
								
							} else {
								for message in messages {
									if (message as! MCOIMAPMessage).header.messageID == id {
										session.storeFlagsOperationWithFolder(self.folderRemind!, uids: MCOIndexSet(index: UInt64((message as! MCOIMAPMessage).uid)), kind: MCOIMAPStoreFlagsRequestKind.Add, flags: MCOMessageFlag.Deleted).start({ (error) -> Void in
											if error != nil {
												print("error")
											} else {
												let op = session.copyMessagesOperationWithFolder(self.folderRemind!, uids: MCOIndexSet(index: UInt64((message as! MCOIMAPMessage).uid)), destFolder: "INBOX")
												op.start({(error, uidMapping) -> Void in
													if let error = error {
														NSLog("error in moveEmailToFolder in copyMessageOp: \(error.userInfo)")
													} else {
														session.storeFlagsOperationWithFolder(self.folderRemind!, uids: MCOIndexSet(index: UInt64((message as! MCOIMAPMessage).uid)), kind: MCOIMAPStoreFlagsRequestKind.Add, flags: MCOMessageFlag.Deleted).start({ (error) -> Void in
															if error != nil {
																print("error")
															} else {
																let expungeFolder = session.expungeOperation(self.folderRemind!)
																expungeFolder.start({ (error) -> Void in })
															}
														})
													}
												})
											}
										})
										break
									}
								}
								if(somethingChanged == true){
									json["allRemindMes"] = JSON(cleanarray)
									self.jsonstring = json.rawString()!
									let builder = MCOMessageBuilder()
									
									builder.header.subject = "Internal from Smile"
									builder.header.messageID = "SmileStorage\(now)"
									builder.textBody = self.jsonstring
									let appendOp = session.appendMessageOperationWithFolder(self.folderStorage!, messageData: builder.data(), flags: MCOMessageFlag.Seen)
									appendOp.start({ (error, uid) -> Void in
										if error != nil {
											
										}
									})
									//deleteEmail(jsonmail!)
									//self.uploadJsonMail(toAccount)
									//saveCoreDataChanges()
									//updateLocalEmail(toAccount, folderToQuery: folderStorage!)
								}
							}
						})
					} catch {
						
					}
				}
			}
		}
	}
	
    /*func returnEmailWithSpecificID(account: EmailAccount, folder: String, id: String)->Email?{
        //let currentMaxUID = getMaxUID(account, folderToQuery: folder)
        //fetchEmails(account, folderToQuery: folder, uidRange: MCOIndexSet(range: MCORangeMake(UInt64(currentMaxUID+1), UINT64_MAX-UInt64(currentMaxUID+2))))
		do {
			let session = try getSession(account)
			let requestKind:MCOIMAPMessagesRequestKind = ([MCOIMAPMessagesRequestKind.Uid, MCOIMAPMessagesRequestKind.Flags, MCOIMAPMessagesRequestKind.Headers, MCOIMAPMessagesRequestKind.Structure])
			session.fetchMessagesByNumberOperationWithFolder(folder, requestKind: requestKind, numbers: MCOIndexSet(range: MCORangeMake(1, UINT64_MAX))).start({ (error, messages, set) -> Void in
				if error != nil {
					
				} else {
					for message in messages {
						if (message as! MCOIMAPMessage).header.messageID == id {
							
						}
					}
				}
			})
		} catch {
			return nil
		}
    }*/
	
	func getEmailFromAccount(account: EmailAccount, uid: UInt32) -> Email? {
		for email in account.emails {
			if (email as! Email).mcomessage.uid == uid {
				return email as? Email
			}
		}
		return nil
	}

}






