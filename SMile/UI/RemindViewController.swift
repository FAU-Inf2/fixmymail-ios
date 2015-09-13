//
//  RemindViewController.swift
//  SMile
//
//  Created by Andrea Albrecht on 08.09.15.
//  Copyright (c) 2015 SMile. All rights reserved.
//

import UIKit

class RemindViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource{
    
    @IBOutlet weak var SetTime: UIButton!
    @IBOutlet weak var back: UIButton!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var collectionView: UICollectionView!
    var mail: Email?
    
    var textData: [String] = ["Later Today","This Evening", "Tomorrow", "This Weekend", "Next Week", "In One Month", "back", "","Pick a Date"]
    var Images:[String] = ["Hourglass-64.png","Waxing Gibbous Filled-64.png","Cup-64.png","Sun-64.png","Toolbox-64.png","Plus 1 Month-64.png","","","Calendar-64.png"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        datePicker.hidden = true
        back.hidden = true
        SetTime.hidden = true
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
        let date = NSDate()
        println(date)
        var remindDate:NSDate
        var components = NSDateComponents()

        switch (indexPath.row){
        case 0: //Later Today
            components.hour = 2
            remindDate = NSCalendar.currentCalendar().dateByAddingComponents(components, toDate: date, options: nil)!
            println("today")
            println(remindDate)
        case 1: //This Evening
            components.hour = 20 //immer 2 stunden mehr, da 2 Studen abegezogen werden
            remindDate = NSCalendar.currentCalendar().dateBySettingHour(components.hour, minute: 0, second: 0, ofDate: date, options: nil)!
            println("thisEvening")
            println(remindDate)
        case 2: //Tomorrow Morning
            components.hour = 5  //immer 2 stunden mehr, da 2 Studen abegezogen werden
            components.day = 1
            remindDate = NSCalendar.currentCalendar().dateByAddingComponents(components, toDate: date, options: nil)!
            remindDate = NSCalendar.currentCalendar().dateBySettingHour(components.hour, minute: 0, second: 0, ofDate: remindDate, options: nil)!
            println("tomorrow")
            println(remindDate)
        case 3: //This Weekend
            var day:UnsafeMutablePointer<Int> = nil
            
            NSCalendar.currentCalendar().getEra(nil, yearForWeekOfYear: nil, weekOfYear: nil, weekday: day, fromDate: date)
            println(day)
        case 4: //Next Week
            NSLog("4")
        case 5: //In 1 Month
            components.month = 1
            remindDate = NSCalendar.currentCalendar().dateByAddingComponents(components, toDate: date, options: nil)!
            println("In 1 Month")
            println(remindDate)
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
        var remindDate = datePicker.date
        println(remindDate)
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
