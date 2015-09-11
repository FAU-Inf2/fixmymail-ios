//
//  RemindViewController.swift
//  SMile
//
//  Created by Andrea Albrecht on 08.09.15.
//  Copyright (c) 2015 SMile. All rights reserved.
//

import UIKit

class RemindViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource{

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var collectionView: UICollectionView!
    var mail: Email?
    
    var textData: [String] = ["Later Today","This Evening", "Tomorrow", "This Weekend", "Next Week", "In One Month", "back", "","Pick a Date"]
    var Images:[String] = ["Hourglass-64.png","Waxing Gibbous Filled-64.png","Cup-64.png","Sun-64.png","Toolbox-64.png","Plus 1 Month-64.png","","","Calendar-64.png"]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.collectionView.registerNib(UINib(nibName: "RemindCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "RemindCell")
        
        self.collectionView.backgroundColor = UIColor.clearColor()
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Dark)
        let effectView = UIVisualEffectView(effect: blurEffect)
        effectView.frame = self.imageView.frame
        self.imageView.addSubview(effectView)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 9
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("RemindCell", forIndexPath: indexPath) as! RemindCollectionViewCell
        cell.labels.text = textData[indexPath.row]
        cell.labels.textColor = UIColor.whiteColor()
        //cell.labels.textAlignment = .Center
        cell.images.image = UIImage(named: Images[indexPath.row])
        
        //cell.images.layer.cornerRadius = cell.images.frame.size.width / 3
        //cell.images.layer.borderWidth = 4.0
        cell.images.layer.borderColor = UIColor.whiteColor().CGColor
        cell.images.clipsToBounds = true
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        return CGSize(width: collectionView.frame.size.width/3, height: collectionView.frame.size.width/3)
        
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath){
        let components = NSDateComponents()
        let date = NSDate()
        //noch nicht die richtige Date funktion gefunden
        switch (indexPath.row){
        case 0: //Later Today
            components.hour = components.hour+2
        case 1: //This Evening
            components.hour = 18
            components.minute = 00
            components.second = 00
        case 2: //Tomorrow Morning
            components.day = components.day+1
            components.hour = 4
            components.minute = 00
            components.second = 00
        case 3: //This Weekend
            NSLog("4")
        case 4: //Next Week
            NSLog("4")
        case 5: //In 1 Month
            NSLog("5")
        case 8: //Pick a Date
            NSLog("8")
        default:
            NSLog("other")
        }
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
