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

class ContainerViewController: UIViewController {
    
    var contentVC: UIViewController!
    var subNavController: UINavigationController!
    var currentState: SlideOutState = .PanelCollapsed {
        didSet {
            let shouldShowShadow = currentState != .PanelCollapsed
            showShadowForContentViewController(shouldShowShadow)
        }
    }
    var sideBarVC: SidebarTableViewController?
    let contentPanelExpandedOffset: CGFloat = UIScreen.mainScreen().bounds.width / 3
    var leftSwipeGesture: UISwipeGestureRecognizer!
    var rightSwipeGesture: UISwipeGestureRecognizer!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        
        self.contentVC = MailTableViewController(nibName: "MailTableViewController", bundle: NSBundle.mainBundle())
        self.contentVC.setValue(self, forKey: "delegate")
        self.contentVC.view.frame = self.view.frame
        self.subNavController = UINavigationController(rootViewController: contentVC)
        //(self.contentVC as! MailTableViewController).rootView = self
        var window: UIWindow = UIApplication.sharedApplication().windows[0] as! UIWindow
        window.addSubview(self.subNavController.view)
        window.makeKeyAndVisible()
        self.view.addSubview(self.subNavController.view)
        //(self.contentVC as! MailTableViewController).subNavController = self.subNavController
        
        self.leftSwipeGesture = UISwipeGestureRecognizer(target: self, action: "swipeForSidebar:")
        self.leftSwipeGesture.direction = .Left
        self.view.addGestureRecognizer(self.leftSwipeGesture)
        
        self.rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: "swipeForSidebar:")
        self.rightSwipeGesture.direction = .Right
        self.view.addGestureRecognizer(self.rightSwipeGesture)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func swipeForSidebar(sender: UISwipeGestureRecognizer) {
        if(sender.isEqual(leftSwipeGesture) && self.currentState == SlideOutState.LeftPanelExpanded) {
            self.toggleLeftPanel()
        }
        if(sender.isEqual(rightSwipeGesture) && self.currentState == SlideOutState.PanelCollapsed) {
            self.toggleLeftPanel()
        }
    }

}

extension ContainerViewController : ContentViewControllerProtocol {
    
    func toggleLeftPanel() {
        let notAlreadyExpanded = (currentState != .LeftPanelExpanded)
        
        if notAlreadyExpanded {
            addLeftPanelViewController()
        }
        
        animateLeftPanel(shouldExpand: notAlreadyExpanded)
    }
    
    func addLeftPanelViewController() {
        if (self.sideBarVC == nil) {
            var sidebarVC : SidebarTableViewController = SidebarTableViewController(nibName: "SidebarTableViewController", bundle: NSBundle.mainBundle())
            self.sideBarVC = sidebarVC
            self.sideBarVC?.delegate = self
            self.sideBarVC?.view.frame = CGRectMake(self.sideBarVC!.view.frame.origin.x, self.sideBarVC!.view.frame.origin.y, self.sideBarVC!.view.frame.width, self.view.frame.height)
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
            self.subNavController.view.frame.origin.x = targetPosition
            //self.contentVC.view.frame.origin.x = targetPosition
            
        }, completion: completion)
    }
    
    func showShadowForContentViewController(shouldShowShadow: Bool) {
        if (shouldShowShadow) {
            self.contentVC.view.layer.shadowOpacity = 0.8
        } else {
            self.contentVC.view.layer.shadowOpacity = 0.0
        }
    }
    
}

extension ContainerViewController: SideBarProtocol {
    func cellSelected(actionItem: ActionItem) {
        var managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext as NSManagedObjectContext!
        
        NSLog("\(self.contentVC.parentViewController)")
        self.toggleLeftPanel()
        
        var shouldChangeVC = false
        switch actionItem.viewController {
        case "EmailAll":
            contentVC = MailTableViewController(nibName: "MailTableViewController", bundle: NSBundle.mainBundle())
            shouldChangeVC = true
            
            //set all Accounts active
            let fetchRequest: NSFetchRequest = NSFetchRequest(entityName: "EmailAccount")
            var error: NSError?
            var result = managedObjectContext.executeFetchRequest(fetchRequest, error: &error)
            if error != nil {
                NSLog("%@", error!.description)
            } else {
                if let emailAccounts = result {
                    for account in emailAccounts {
                        (account as! EmailAccount).active = true
                    }
                }
            }
            managedObjectContext.save(&error)
            if error != nil {
                NSLog("%@", error!.description)
            }

        case "EmailSpecific":
            contentVC = MailTableViewController(nibName: "MailTableViewController", bundle: NSBundle.mainBundle())
            shouldChangeVC = true
            
            //Do something to load correct mails
            let fetchRequest: NSFetchRequest = NSFetchRequest(entityName: "EmailAccount")
            var error: NSError?
            var result = managedObjectContext.executeFetchRequest(fetchRequest, error: &error)
            if error != nil {
                NSLog("%@", error!.description)
            } else {
                if let emailAccounts = result {
                    for account in emailAccounts {
                        (account as! EmailAccount).active = false
                        if (account as! EmailAccount).emailAddress == actionItem.emailAddress {
                            (account as! EmailAccount).active = true
                        }
                    }
                }
            }
            managedObjectContext.save(&error)
            if error != nil {
                NSLog("%@", error!.description)
            }
            
        //case "TODO":
            //Insert TODO VC here!
        case "KeyChain":
            if contentVC is KeyChainListTableViewController == false {
                contentVC = KeyChainListTableViewController(nibName: "KeyChainListTableViewController", bundle: NSBundle.mainBundle())
                shouldChangeVC = true
            }
        case "Preferences":
            //Insert Preferences VC here!
			if contentVC is PreferenceTableViewController == false {
				contentVC = PreferenceTableViewController(nibName: "PreferenceTableViewController", bundle: NSBundle.mainBundle())
				shouldChangeVC = true
			}
        default:
            break
        }
        if shouldChangeVC == true {
            self.contentVC.setValue(self, forKey: "delegate")
            self.contentVC.view.frame = self.view.frame
            self.subNavController.pushViewController(contentVC, animated: false)
        }
    }
    
}
