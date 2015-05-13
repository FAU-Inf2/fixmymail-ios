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
    optional func toggleLeftPanel()
    optional func collapseSidePanels()
}

class ContentViewController: UIViewController {
    
    var delegate: ContentViewControllerProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func menuTapped(sender: AnyObject) {
       
        delegate?.toggleLeftPanel?()
        
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
