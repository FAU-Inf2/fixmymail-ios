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
    
    var email:Email?
    @IBOutlet weak var SetTime: UIButton!
    @IBOutlet weak var back: UIButton!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var collectionView: UICollectionView!
    //var mail: Email?
    
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
        //downlaodJsonAndCheckForUpcomingReminds()
        
    }
    
    func downlaodJsonAndCheckForUpcomingReminds(){ // ich gehe davon aus das SmileStorage vorhanden ist weil ich es vorher ja abgeprüft habe und notfalls erstellt habe
        //JsonFile aus Folder SmileStorage auslesen
        var folderStorage: String = "SmileStorage"
        var remind:Email = email!
        var folders = email?.toAccount.folders
        let currentMaxUID = getMaxUID(email!.toAccount, folderStorage)
        fetchEmails(email!.toAccount, folderStorage, MCOIndexSet(range: MCORangeMake(UInt64(currentMaxUID+1), UINT64_MAX-UInt64(currentMaxUID+2))))
        var downloadMailDuration: NSDate? = getDateFromPreferencesDurationString(email!.toAccount.downloadMailDuration)
        for mail in email!.toAccount.emails {
            if mail.folder == folderStorage {
                if let dMD = downloadMailDuration {
                    if ((mail as! Email).mcomessage as! MCOIMAPMessage).header.receivedDate.laterDate(dMD) == dMD {
                        continue
                    }
                }
                remind = mail as! Email
            }
        }
        println(remind.plainText)               // noch rausnehmen
        if remind == email{
            println("something went wrong")
        }
        //RemindMe Datum auslesen und in NSDate umformen
        else{
            if let dataFromString = remind.plainText.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
                let json = JSON(data: dataFromString)
                var key = "remindTime"
                
                for result in json["allRemindMes"].arrayValue {
            
                    let time = result["remindTime"].stringValue
                    let prefix:String = "/Date("
                    let suffix:String = ")/"
                    var time2 = prefix + time + suffix
                    var now = NSDate()
                    //RemindMe Datum mit akutellem Datum vergleichen
                    if let theDate = NSDate(jsonDate: time2)
                    {
                        let compareResult = now.compare(theDate)
                        if compareResult == NSComparisonResult.OrderedDescending {
                            //move email to Inbox
                            var id = json["messageId"].stringValue
                            var upcomingEmail:Email = returnEmailWithSpecificID(email!.toAccount, folder: "RemindMe", id: id) //durch remindMe email (aus Ordner RemindMe mit Messageid id) erstetzen
                            addFlagToEmail(upcomingEmail, MCOMessageFlag.None) //Flag auf unseen setzten bzw. vielleicht auf remind
                            //moveEmailToFolder(upcomingEmail, "INBOX")
                        }
                        else{
                            //Do nothing. Its not time yet
                        }
                    }
                    else //Datum hatte falsches Format - Dürfte nicht passieren
                    {
                        println("wrong format")
                    }
                }
            }
        }
    }
    
    
    //TODO
    func returnEmailWithSpecificID(account: EmailAccount, folder: String, id: String)->Email{
        var email:Email?
        let currentMaxUID = getMaxUID(account, folder)
        var downloadMailDuration: NSDate? = getDateFromPreferencesDurationString(account.downloadMailDuration)
        for mail in account.emails {
            if mail.folder == folder {
                if let dMD = downloadMailDuration {
                    if ((mail as! Email).mcomessage as! MCOIMAPMessage).header.receivedDate.laterDate(dMD) == dMD {
                        continue
                    }
                }
                /*if mail.mcomessage.identifier == id { //schauen ob id der mail die selbe ist wie der der remindEmail
                    email = mail
                }*/
                email = mail as? Email
            }
        }
        return email!
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
        var date = NSDate()
        var components = NSDateComponents()
        components.hour = NSTimeZone.localTimeZone().secondsFromGMT/3600 //zeitzone reinrechnen
        date = NSCalendar.currentCalendar().dateByAddingComponents(components, toDate: date, options: nil)!
        println(date)
        var remindDate:NSDate = NSDate()
        switch (indexPath.row){
        case 0: //Later Today
            components.hour = 4
            remindDate = NSCalendar.currentCalendar().dateByAddingComponents(components, toDate: date, options: nil)!
            RemindEmail(email!,date: remindDate)
        case 1: //This Evening
            components.hour = 20
            remindDate = NSCalendar.currentCalendar().dateBySettingHour(components.hour, minute: 0, second: 0, ofDate: date, options: nil)!
            RemindEmail(email!,date: remindDate)
        case 2: //Tomorrow Morning
            components.hour = 5
            components.day = 1
            remindDate = NSCalendar.currentCalendar().dateByAddingComponents(components, toDate: date, options: nil)!
            remindDate = NSCalendar.currentCalendar().dateBySettingHour(components.hour, minute: 0, second: 0, ofDate: remindDate, options: nil)!
            RemindEmail(email!,date: remindDate)
        case 3: //This Weekend
            var day = NSCalendar.currentCalendar().component(.CalendarUnitWeekday, fromDate: date)
            var friday = 6
            components.day = friday-day
            components.hour = 17
            remindDate = NSCalendar.currentCalendar().dateByAddingComponents(components, toDate: date, options: nil)!
            remindDate = NSCalendar.currentCalendar().dateBySettingHour(components.hour, minute: 0, second: 0, ofDate: remindDate, options: nil)!
            RemindEmail(email!,date: remindDate)
        case 4: //Next Week
            var day = NSCalendar.currentCalendar().component(.CalendarUnitWeekday, fromDate: date)
            var monday = 2
            components.day = abs(day-monday)
            components.hour = 5
            remindDate = NSCalendar.currentCalendar().dateByAddingComponents(components, toDate: date, options: nil)!
            remindDate = NSCalendar.currentCalendar().dateBySettingHour(components.hour, minute: 0, second: 0, ofDate: remindDate, options: nil)!
            RemindEmail(email!,date: remindDate)
        case 5: //In 1 Month
            components.month = 1
            remindDate = NSCalendar.currentCalendar().dateByAddingComponents(components, toDate: date, options: nil)!
            RemindEmail(email!,date: remindDate)
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
        var remindDate = datePicker.date
        println(remindDate)
        RemindEmail(email!,date: remindDate)
    }
    
    func RemindEmail(email: Email, date: NSDate){
        
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
            let from = advance(jsonDate.startIndex, count(prefix))
            let to = advance(jsonDate.endIndex, -count(suffix))
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