//
//  ViewController.swift
//  FixMyMail
//
//  Created by Jan Weiß on 04.05.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit
import CoreData

enum SlideOutState {
    case PanelCollapsed
    case LeftPanelExpanded
}

class ViewController: UIViewController {
    
    var contentVC: ContentViewController!
    var currentState: SlideOutState = .PanelCollapsed
    var sideBarVC: SidebarTableViewController?
    let contentPanelExpandedOffset: CGFloat = UIScreen.mainScreen().bounds.width / 3

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //WARNING: This is only a sample for fetching CoreData entities and evaluates that the insertion was successful!!!
        getAndLogCoreDataTestEntries()
        
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        contentVC = storyBoard.instantiateViewControllerWithIdentifier("ContentViewController") as! ContentViewController
        contentVC.delegate = self
        self.navigationItem.leftBarButtonItem = contentVC.navigationItem.leftBarButtonItem
        view.addSubview(contentVC.view)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //WARNING: This is only a sample for fetching CoreData entities and evaluates that the insertion was successful!!!
    private func getAndLogCoreDataTestEntries() -> Void {
        let managedObjectContext: NSManagedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!
        let fetchRequest: NSFetchRequest = NSFetchRequest(entityName: "EmailAccount")
        var error: NSError?
        let result = managedObjectContext.executeFetchRequest(fetchRequest, error: &error)
        if error != nil {
            NSLog("%@", error!.description)
        } else {
            if let emailAccounts = result {
                for account in emailAccounts {
                    if account is EmailAccount {
                        NSLog("Username: \((account as! EmailAccount).username)")
                        NSLog("Emails: ")
                        let emails: NSSet = (account as! EmailAccount).emails
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

extension ViewController : ContentViewControllerProtocol {
    
    func toggleLeftPanel() {
        let notAlreadyExpanded = (currentState != .LeftPanelExpanded)
        
        if notAlreadyExpanded {
            addLeftPanelViewController()
        }
        
        animateLeftPanel(shouldExpand: notAlreadyExpanded)
    }
    
    func collapseSidePanels() {
        
    }
    
    func addLeftPanelViewController() {
        if (sideBarVC == nil) {
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
            var sidebarVC: SidebarTableViewController = storyBoard.instantiateViewControllerWithIdentifier("SideBarController") as! SidebarTableViewController
            sideBarVC = sidebarVC
//            sideBarVC!.animals = Animal.allCats()
            
            addChildSidePanelController(sideBarVC!)
        }
    }
    
    func addChildSidePanelController(sidePanelController: SidebarTableViewController) {
        view.insertSubview(sidePanelController.view, atIndex: 0)
        
        addChildViewController(sidePanelController)
        sidePanelController.didMoveToParentViewController(self)
    }
    
    func animateLeftPanel(#shouldExpand: Bool) {
        if(shouldExpand) {
            currentState = SlideOutState.LeftPanelExpanded
            
            animateContentPanelXPosition(targetPosition: CGRectGetWidth(contentVC.view.frame) - contentPanelExpandedOffset)
        } else {
            animateContentPanelXPosition(targetPosition: 0) {
                finished in
                self.currentState = SlideOutState.PanelCollapsed
                
                if let sideBarViewController = self.sideBarVC {
                    self.sideBarVC!.view.removeFromSuperview()
                    self.sideBarVC = nil
                }
            }
        }
    }
    
    func animateContentPanelXPosition(#targetPosition: CGFloat, completion: ((Bool) -> Void)! = nil) {
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: { () -> Void in
            self.contentVC.view.frame.origin.x = targetPosition
        }, completion: completion)
    }
    
}
