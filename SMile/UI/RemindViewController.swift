//
//  RemindViewController.swift
//  SMile
//
//  Created by Andrea Albrecht on 08.09.15.
//  Copyright (c) 2015 SMile. All rights reserved.
//

import UIKit
import CoreData


class RemindViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource{
    var remind:RemindMe?
    var email:Email?
    @IBOutlet weak var SetTime: UIButton!
    @IBOutlet weak var back: UIButton!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var collectionView: UICollectionView!
    //var mail: Email?
    
    var textData: [String] = ["Later Today","This Evening", "Tomorrow", "This Weekend", "Next Week", "In One Month", "back", "","Pick a Date"]
    var Images:[String] = ["Hourglass-64.png","Waxing Gibbous Filled-64.png","Cup-64.png","Sun-64.png","Toolbox-64.png","Plus 1 Month-64.png","Undo Filled-64.png","","Calendar-64.png"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        remind = RemindMe()
        datePicker.hidden = true
        back.hidden = true
        SetTime.hidden = true
        self.collectionView.registerNib(UINib(nibName: "RemindCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "RemindCell")
        
        self.collectionView.backgroundColor = UIColor.clearColor()
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Dark)
        let effectView = UIVisualEffectView(effect: blurEffect)
        self.collectionView.frame = UIScreen.mainScreen().bounds
        effectView.frame = UIScreen.mainScreen().bounds
        self.imageView.addSubview(effectView)
        //downlaodJsonAndCheckForUpcomingReminds()
        remind?.downlaodJsonAndCheckForUpcomingReminds((email?.toAccount)!)
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
        
        return CGSize(width: collectionView.frame.size.width/3, height: collectionView.frame.size.height/3)
        
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath){
        var date = NSDate()
        let components = NSDateComponents()
        components.hour = NSTimeZone.localTimeZone().secondsFromGMT/3600 //zeitzone reinrechnen
        date = NSCalendar.currentCalendar().dateByAddingComponents(components, toDate: date, options: [])!
        print(date)
        var remindDate:NSDate = NSDate()
        switch (indexPath.row){
        case 0: //Later Today
            components.hour = 2
            remindDate = NSCalendar.currentCalendar().dateByAddingComponents(components, toDate: date, options: [])!
            remind!.setJSONforUpcomingRemind(email!,remindTime: remindDate)
        case 1: //This Evening
            components.hour = 20
            remindDate = NSCalendar.currentCalendar().dateBySettingHour(components.hour, minute: 0, second: 0, ofDate: date, options: [])!
            remind!.setJSONforUpcomingRemind(email!,remindTime: remindDate)
        case 2: //Tomorrow Morning
            components.day = 1
            remindDate = NSCalendar.currentCalendar().dateByAddingComponents(components, toDate: date, options: [])!
            components.hour = 5
            remindDate = NSCalendar.currentCalendar().dateBySettingHour(components.hour, minute: 0, second: 0, ofDate: remindDate, options: [])!
           remind!.setJSONforUpcomingRemind(email!,remindTime: remindDate)
        case 3: //This Weekend
            let day = NSCalendar.currentCalendar().component(.Weekday, fromDate: date)
            let friday = 6
            components.day = friday-day
            if (components.day<0 ){
                components.day = components.day+7
            }
            remindDate = NSCalendar.currentCalendar().dateByAddingComponents(components, toDate: date, options: [])!
            components.hour = 17
            remindDate = NSCalendar.currentCalendar().dateBySettingHour(components.hour, minute: 0, second: 0, ofDate: remindDate, options: [])!
            remind!.setJSONforUpcomingRemind(email!,remindTime: remindDate)
        case 4: //Next Week
            let day = NSCalendar.currentCalendar().component(.Weekday, fromDate: date)
            let monday = 2
            components.day = monday-day
            if (components.day<0 ){
                components.day = components.day+7
            }
            remindDate = NSCalendar.currentCalendar().dateByAddingComponents(components, toDate: date, options: [])!
            components.hour = 5
            remindDate = NSCalendar.currentCalendar().dateBySettingHour(components.hour, minute: 0, second: 0, ofDate: remindDate, options: [])!
            remind!.setJSONforUpcomingRemind(email!,remindTime: remindDate)
        case 5: //In 1 Month
            components.month = 1
            remindDate = NSCalendar.currentCalendar().dateByAddingComponents(components, toDate: date, options: [])!
            remind!.setJSONforUpcomingRemind(email!,remindTime: remindDate)
        case 8: //Pick a Date
            collectionView.hidden  = true
            back.hidden = false
            SetTime.hidden = false
            datePicker.hidden = false
            datePicker.datePickerMode = UIDatePickerMode.DateAndTime
            datePicker.minimumDate = date
            datePicker.date = date
        default:
            NSLog("other")
            break
        }
    }
    
    @IBAction func Back(sender: AnyObject) {
        collectionView.hidden=false
        datePicker.hidden = true
        back.hidden = true
        SetTime.hidden = true
    }
    
    @IBAction func SetTime(sender: AnyObject) {
        collectionView.hidden=false
        datePicker.hidden = true
        back.hidden = true
        SetTime.hidden = true
        let remindDate = datePicker.date
        remind!.setJSONforUpcomingRemind(email!,remindTime: remindDate)
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
extension NSDate {
    convenience init?(jsonDate: String) {
        let prefix = "/Date("
        let suffix = ")/"
        // Check for correct format:
        if jsonDate.hasPrefix(prefix) && jsonDate.hasSuffix(suffix) {
            // Extract the number as a string:
            let from = jsonDate.startIndex.advancedBy(prefix.characters.count)
            let to = jsonDate.endIndex.advancedBy(-suffix.characters.count)
            let dateString = jsonDate[from ..< to]
            // Convert to double and from milliseconds to seconds:
            let timeStamp = (dateString as NSString).doubleValue / 1000.0
            // Create NSDate with this UNIX timestamp
            self.init(timeIntervalSince1970: timeStamp)
        } else {
            // Wrong format, return nil. (The compiler requires us to
            // to an initialization first.)
            self.init(timeIntervalSince1970: 0)
            return nil
        }    }
}