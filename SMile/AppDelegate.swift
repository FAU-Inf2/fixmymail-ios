//
//  AppDelegate.swift
//  FixMyMail
//
//  Created by Jan Weiß on 04.05.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit
import CoreData
import AddressBook

var addressBook : ABAddressBookRef?

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        //WARNING: This method is only for adding dummy entries to CoreData!!!*/
        self.registerUserDefaults()
        initCoreDataTestEntries()
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user 
        AccessAddressBook()
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "de.fixMyMail.FixMyMail" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] as! NSURL
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("SMile", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("SMile.sqlite")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        if coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil, error: &error) == nil {
            coordinator = nil
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            abort()
        }
        
        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        //objc_sync_enter(self.managedObjectContext)
        if let moc = self.managedObjectContext {
            var error: NSError? = nil
            if moc.hasChanges && !moc.save(&error) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                NSLog("Unresolved error \(error), \(error!.userInfo)")
                abort()
            }
        }
        //objc_sync_exit(self.managedObjectContext)
    }
    
    //WARNING: This is method is only for adding dummy entries to CoreData!!!
    private func initCoreDataTestEntries() {
        let defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        if(!defaults.boolForKey("TestEntriesInserted")) {
            var gmailAccount = NSEntityDescription.insertNewObjectForEntityForName("EmailAccount", inManagedObjectContext: self.managedObjectContext!) as! EmailAccount
            gmailAccount.username = "fixmymail2015"
            gmailAccount.password = "*"
            gmailAccount.emailAddress = "fixmymail2015@gmail.com"
            gmailAccount.imapHostname = "imap.gmail.com"
            gmailAccount.imapPort = 993
			gmailAccount.authTypeImap = authTypeToString(MCOAuthType.SASLPlain)
			gmailAccount.connectionTypeImap = connectionTypeToString(MCOConnectionType.TLS)
            gmailAccount.smtpHostname = "smtp.gmail.com"
            gmailAccount.smtpPort = 465
			gmailAccount.authTypeSmtp = authTypeToString(MCOAuthType.SASLPlain)
			gmailAccount.connectionTypeSmtp = connectionTypeToString(MCOConnectionType.TLS)
			gmailAccount.realName = "SMile_Gmail"
			gmailAccount.accountName = "Gmail"
			gmailAccount.isActivated = true
			gmailAccount.signature = ""
			let errorLocksmithGmail = Locksmith.deleteDataForUserAccount("fixmymail2015@gmail.com")
			if errorLocksmithGmail == nil {
				NSLog("found old data -> deleted!")
			}
			let GmailSaveRequest = LocksmithRequest(userAccount: "fixmymail2015@gmail.com", requestType: .Create, data: ["Password:": "fixinginMAD2015"])
			GmailSaveRequest.accessible = .AfterFirstUnlockThisDeviceOnly
			let (GmailDictionary, GmailRequestError) = Locksmith.performRequest(GmailSaveRequest)
			if GmailRequestError == nil {
				NSLog("saving data for \(gmailAccount.emailAddress)")
			}
			
			
			
            var gmxAccount = NSEntityDescription.insertNewObjectForEntityForName("EmailAccount", inManagedObjectContext: self.managedObjectContext!) as! EmailAccount
            gmxAccount.username = "fixmymail@gmx.de"
            gmxAccount.password = "*"
            gmxAccount.emailAddress = "fixmymail@gmx.de"
            gmxAccount.imapHostname = "imap.gmx.net"
            gmxAccount.imapPort = 993
			gmxAccount.authTypeImap = authTypeToString(MCOAuthType.SASLPlain)
			gmxAccount.connectionTypeImap = connectionTypeToString(MCOConnectionType.TLS)
            gmxAccount.smtpHostname = "mail.gmx.net"
            gmxAccount.smtpPort = 465
			gmxAccount.authTypeSmtp = authTypeToString(MCOAuthType.SASLPlain)
			gmxAccount.connectionTypeSmtp = connectionTypeToString(MCOConnectionType.TLS)
			gmxAccount.realName = "SMile_GMX"
            gmxAccount.accountName = "GMX"
			gmxAccount.isActivated = true
			gmxAccount.signature = "Sent with GMX!"
			let errorLocksmithGmx = Locksmith.deleteDataForUserAccount("fixmymail@gmx.de")
			if errorLocksmithGmx == nil {
				NSLog("found old data -> deleted!")
			}
			let GmxSaveRequest = LocksmithRequest(userAccount: "fixmymail@gmx.de", requestType: .Create, data: ["Password:": "fixinginMAD2015"])
			GmxSaveRequest.accessible = .AfterFirstUnlockThisDeviceOnly
			let (GmxDictionary, GmxRequestError) = Locksmith.performRequest(GmxSaveRequest)
			if GmxRequestError == nil {
				NSLog("saving data for \(gmxAccount.emailAddress)")
			}
			
			
            var webAccount = NSEntityDescription.insertNewObjectForEntityForName("EmailAccount", inManagedObjectContext: self.managedObjectContext!) as! EmailAccount
            webAccount.username = "fixmymail@web.de"
            webAccount.password = "*"
            webAccount.emailAddress = "fixmymail@web.de"
            webAccount.imapHostname = "imap.web.de"
            webAccount.imapPort = 993
			webAccount.authTypeImap = authTypeToString(MCOAuthType.SASLPlain)
			webAccount.connectionTypeImap = connectionTypeToString(MCOConnectionType.TLS)
            webAccount.smtpHostname = "smtp.web.de"
            webAccount.smtpPort = 587
			webAccount.authTypeSmtp = authTypeToString(MCOAuthType.SASLPlain)
			webAccount.connectionTypeSmtp = connectionTypeToString(MCOConnectionType.StartTLS)
			webAccount.realName = "SMile_WEBDE"
			webAccount.accountName = "WEB.DE"
			webAccount.isActivated = true
			webAccount.signature = "Sent with WEB.DE!"
			let errorLocksmithWeb = Locksmith.deleteDataForUserAccount("fixmymail@web.de")
			if errorLocksmithWeb == nil {
				NSLog("found old data -> deleted!")
			}
			let WebSaveRequest = LocksmithRequest(userAccount: "fixmymail@web.de", requestType: .Create, data: ["Password:": "fixinginMAD2015"])
			WebSaveRequest.accessible = .AfterFirstUnlockThisDeviceOnly
			let (WebDictionary, WebRequestError) = Locksmith.performRequest(WebSaveRequest)
			if WebRequestError == nil {
				println("saving data for \(webAccount.emailAddress)")
			}
			
            var error: NSError?
            self.managedObjectContext!.save(&error)
      
            if error != nil {
                NSLog("%@", error!.description)
            } else {
                defaults.setBool(true, forKey: "TestEntriesInserted")
            }
        }
    }

    //MARK: - AdressBook
    
   func AccessAddressBook() {
        switch ABAddressBookGetAuthorizationStatus(){
        case .Authorized:
            println("Already authorized")
            createAddressBook()
            /* Access the address book */
        case .Denied:
            println("Denied access to address book")
            
        case .NotDetermined:
            createAddressBook()
            if let theBook: ABAddressBookRef = addressBook{
                ABAddressBookRequestAccessWithCompletion(theBook,
                    {(granted: Bool, error: CFError!) in
                        
                        if granted{
                            println("Access granted")
                        } else {
                            println("Access not granted")
                        }
                        
                })
            }
            
        case .Restricted:
            println("Access restricted")
            
        default:
            println("Other Problem")
        }
    }
    
    func createAddressBook(){
        var error: Unmanaged<CFError>?
        addressBook = ABAddressBookCreateWithOptions(nil, &error).takeRetainedValue()
    }
    
    //MARK: - UserDefaults
    
    private func registerUserDefaults() -> Void {
        NSUserDefaults.standardUserDefaults().registerDefaults(["standardAccount" : "",
            "loadPictures" : true, "previewLines" : 1])
    }
}

