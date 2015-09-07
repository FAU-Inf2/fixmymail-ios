//
//  ContentViewController.swift
//  FixMyMail
//
//  Created by Jan Weiß on 12.05.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit

@objc
protocol ContentViewControllerProtocol {
    func toggleLeftPanel()
}

class ContentViewController: UIViewController {
    
    weak var delegate: ContentViewControllerProtocol?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var navigationBar: UINavigationBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.frame.width, 55))
        navigationBar.barTintColor = UIColor.lightTextColor()
        
        
        self.view.addSubview(navigationBar)
        
        var menuItem: UIBarButtonItem = UIBarButtonItem(title: "Menu", style: .Plain, target: self, action: "menuTapped:")
        var flexSpaceItem: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        
        var navItem: UINavigationItem = UINavigationItem(title: "")
        navItem.leftBarButtonItems = [flexSpaceItem, menuItem, flexSpaceItem]
        
        navigationBar.pushNavigationItem(navItem, animated: true)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func menuTapped(sender: AnyObject) {
       
        delegate?.toggleLeftPanel()
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
