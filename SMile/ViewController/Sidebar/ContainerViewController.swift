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
    weak var sideBarVC: SidebarTableViewController?
    let contentPanelExpandedOffset: CGFloat = UIScreen.mainScreen().bounds.width / 3
    var leftSwipeGesture: UISwipeGestureRecognizer!
    var rightSwipeGesture: UISwipeGestureRecognizer!
    var tapGesture: UITapGestureRecognizer!
    var lastSelectedMailAccountName: String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        
        self.contentVC = MailTableViewController(nibName: "MailTableViewController", bundle: NSBundle.mainBundle())
        self.contentVC.setValue(self, forKey: "delegate")
        self.contentVC.view.frame = UIApplication.sharedApplication().delegate!.window!!.frame
        self.subNavController = UINavigationController(rootViewController: contentVC)
        //(self.contentVC as! MailTableViewController).rootView = self
        let window: UIWindow = UIApplication.sharedApplication().windows[0] 
        window.addSubview(self.subNavController.view)
        window.makeKeyAndVisible()
        self.view.addSubview(self.subNavController.view)
        //(self.contentVC as! MailTableViewController).subNavController = self.subNavController
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
            let sidebarVC : SidebarTableViewController = SidebarTableViewController(nibName: "SidebarTableViewController", bundle: NSBundle.mainBundle())
            self.sideBarVC = sidebarVC
            self.sideBarVC?.currAccountName = self.lastSelectedMailAccountName
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
    
    func animateLeftPanel(shouldExpand shouldExpand: Bool) {
        if(shouldExpand) {
            for view in self.subNavController!.view!.subviews {
                if let v: UIView = view {
                    v.userInteractionEnabled = false
                }
            }
            self.tapGesture = UITapGestureRecognizer(target: self, action: "tapToToggle:")
            self.subNavController!.view!.addGestureRecognizer(self.tapGesture)
            currentState = SlideOutState.LeftPanelExpanded
            
            animateContentPanelXPosition(targetPosition: CGRectGetWidth(UIApplication.sharedApplication().delegate!.window!!.frame) - contentPanelExpandedOffset)
        } else {
            for view in self.subNavController!.view!.subviews {
                if let v: UIView = view {
                    v.userInteractionEnabled = true
                }
            }
            self.subNavController!.view!.removeGestureRecognizer(self.tapGesture)
            animateContentPanelXPosition(targetPosition: 0) {
                finished in
                self.currentState = SlideOutState.PanelCollapsed
                
                if self.sideBarVC != nil {
                    self.sideBarVC!.view.removeFromSuperview()
                    self.sideBarVC = nil
                }
            }
        }
    }
    
    func animateContentPanelXPosition(targetPosition targetPosition: CGFloat, completion: ((Bool) -> Void)! = nil) {
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: { () -> Void in
            self.subNavController.view.frame.origin.x = targetPosition
            //self.contentVC.view.frame.origin.x = targetPosition
            
            }, completion: completion)
    }
    
    func showShadowForContentViewController(shouldShowShadow: Bool) {
        if (shouldShowShadow) {
            self.subNavController!.view.layer.shadowOpacity = 0.8
        } else {
            self.subNavController!.view.layer.shadowOpacity = 0.0
        }
    }
    
}

extension ContainerViewController: SideBarProtocol {
    func cellSelected(actionItem: ActionItem) {
        let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext as NSManagedObjectContext!
        
        NSLog("\(self.contentVC.parentViewController)")
        self.toggleLeftPanel()
        
        var shouldChangeVC = false
        self.lastSelectedMailAccountName = actionItem.cellName != "All" ? actionItem.emailAccount?.accountName : nil
        switch actionItem.viewController {
        case "EmailAll":
            shouldChangeVC = true
            contentVC = MailTableViewController(nibName: "MailTableViewController", bundle: NSBundle.mainBundle())
            
            var allAccounts: [EmailAccount] = [EmailAccount]()
            let fetchRequest: NSFetchRequest = NSFetchRequest(entityName: "EmailAccount")
            var error: NSError?
            var result: [AnyObject]?
            do {
                result = try managedObjectContext.executeFetchRequest(fetchRequest)
            } catch let error1 as NSError {
                error = error1
                result = nil
            }
            if error != nil {
                NSLog("%@", error!.description)
            } else {
                if let emailAccounts = result {
                    for account in emailAccounts {
                        (account as! EmailAccount).recentlyUsed = true
                        allAccounts.append(account as! EmailAccount)
                    }
                }
            }
            do {
                try managedObjectContext.save()
            } catch let error1 as NSError {
                error = error1
            }
            if error != nil {
                NSLog("%@", error!.description)
            }
            
            contentVC.setValue(allAccounts, forKey: "accounts")
            contentVC.setValue("INBOX", forKey: "folderToQuery")
            
        case "EmailSpecific":
            shouldChangeVC = true
            
            contentVC = MailTableViewController(nibName: "MailTableViewController", bundle: NSBundle.mainBundle())
            
            if actionItem.emailFolder != nil {
                contentVC.setValue(actionItem.emailFolder!.path, forKey: "folderToQuery")
            }
            
            let fetchRequest: NSFetchRequest = NSFetchRequest(entityName: "EmailAccount")
            var error: NSError?
            var result: [AnyObject]?
            do {
                result = try managedObjectContext.executeFetchRequest(fetchRequest)
            } catch let error1 as NSError {
                error = error1
                result = nil
            }
            if error != nil {
                NSLog("%@", error!.description)
            } else {
                if let emailAccounts = result {
                    for account in emailAccounts {
                        (account as! EmailAccount).recentlyUsed = false
                        if (account as! EmailAccount).emailAddress == actionItem.emailAddress {
                            (account as! EmailAccount).recentlyUsed = true
                            
                            var specificAccount: [EmailAccount] = [EmailAccount]()
                            specificAccount.append(account as! EmailAccount)
                            contentVC.setValue(specificAccount, forKey: "accounts")
                        }
                    }
                }
            }
            do {
                try managedObjectContext.save()
            } catch let error1 as NSError {
                error = error1
            }
            if error != nil {
                print("%@", error!.description)
            }
        case "KeyChain":
            if contentVC is KeyChainListTableViewController == false {
                contentVC = KeyChainListTableViewController(nibName: "KeyChainListTableViewController", bundle: NSBundle.mainBundle())//self.keyChainVC
                shouldChangeVC = true
            }
        case "Preferences":
            if contentVC is PreferenceTableViewController == false {
                contentVC = PreferenceTableViewController(nibName: "PreferenceTableViewController", bundle: NSBundle.mainBundle())//self.preferencesVC
                shouldChangeVC = true
            }
        default:
            break
        }
        if shouldChangeVC == true {
            self.contentVC.setValue(self, forKey: "delegate")
            self.contentVC.view.frame = self.view.frame
            self.subNavController.setViewControllers([contentVC], animated: false)
        }
    }
    
    func tapToToggle(sender: AnyObject) -> Void {
        self.toggleLeftPanel()
    }
    
    func navigationStackContainsTargetViewController(viewController: UIViewController) -> Bool {
        let vcs = self.subNavController.viewControllers
        for var i = 0; i < vcs.count; i++ {
            let vc = vcs[i] 
            if vc is MailTableViewController && viewController is MailTableViewController ||
                vc is PreferenceTableViewController && viewController is PreferenceTableViewController ||
                vc is KeyChainListTableViewController && viewController is KeyChainListTableViewController {
                    return true
            }
        }
        return false
    }
    
}
