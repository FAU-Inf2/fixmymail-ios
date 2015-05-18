//
//  ViewController.swift
//  FixMyMail
//
//  Created by Jan Weiß on 04.05.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //WARNING: This is only a sample for fetching CoreData entities and evaluates that the insertion was successful!!!
        //getAndLogCoreDataTestEntries()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //WARNING: This is only a sample for fetching CoreData entities and evaluates that the insertion was successful!!!
    private func getAndLogCoreDataTestEntries() -> Void {
        var managedObjectContext: NSManagedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!
        let fetchRequest: NSFetchRequest = NSFetchRequest(entityName: "EmailAccount")
        var error: NSError?
        var result = managedObjectContext.executeFetchRequest(fetchRequest, error: &error)
        if error != nil {
            NSLog("%@", error!.description)
        } else {
            if let emailAccounts = result {
                for account in emailAccounts {
                    if account is EmailAccount {
                        NSLog("Username: \((account as! EmailAccount).username)")
                        NSLog("Emails: ")
                        var emails: NSSet = (account as! EmailAccount).emails
                        for email in emails {
                            if email is Email {
                                NSLog("Sender: \((email as! Email).sender), Title: \((email as! Email).title), Message: \((email as! Email).message), PGP: \((email as! Email).pgp), SMIME: \((email as! Email).smime)")
                            }
                        }
                    }
                }
            }
        }
    }


}

