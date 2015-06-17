//
//  CostumTableViewCell.swift
//  MailCoreTestSwift
//
//  Created by Martin on 07.05.15.
//  Copyright (c) 2015 Moritz Müller. All rights reserved.
//

import UIKit


protocol TableViewCellDelegate {
    func deleteEmail(mail: Email)
}

class CustomMailTableViewCell: UITableViewCell {
    
    @IBOutlet var mailFrom: UILabel!
    @IBOutlet var mailBody: UILabel!
    @IBOutlet var unseendot: UIImageView!
    var mail: Email!
    var delegate: TableViewCellDelegate?
    var height: CGFloat!
    
    var originalCenter = CGPoint()
    var deleteOnDragRelease = false
    var archiveOnDragRelease = false
    var remindMeOnDragRelease = false
    
    var panGestureRecognizer: UIPanGestureRecognizer!
    var crossLabel: UILabel!
    var checkLabel: UILabel!
    var subviewDeleteSwipeFromRightToLeft = UIView()
    var subviewArchiveSwipeFromLeftToRight = UIView()
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: "panHandler:")
        panGestureRecognizer.delegate = self
        addGestureRecognizer(panGestureRecognizer)
        
        crossLabel = createCueLabel()
        crossLabel.text = "\u{00D7}"
        crossLabel.textAlignment = .Left
        crossLabel.textColor = UIColor.whiteColor()
        checkLabel = createCueLabel()
        checkLabel.text = "\u{2713}"
        checkLabel.textAlignment = .Right
        checkLabel.textColor = UIColor.whiteColor()
        
    }
    
    func createCueLabel() -> UILabel {
        let label = UILabel(frame: CGRect.nullRect)
        label.textColor = UIColor.whiteColor()
        label.font = UIFont.boldSystemFontOfSize(32.0)
        label.backgroundColor = UIColor.clearColor()
        return label
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    //horizontal swipe gesture methods
    func panHandler (recognizer: UIPanGestureRecognizer) {
        //init delete subview on the right
        subviewDeleteSwipeFromRightToLeft.frame = CGRect(x: bounds.size.width, y: 0, width: self.bounds.width, height: height)
        crossLabel.frame = CGRect(x: 10, y: (height/2) - 14, width: 20, height: 22)
        subviewDeleteSwipeFromRightToLeft.addSubview(crossLabel)
        addSubview(subviewDeleteSwipeFromRightToLeft)
        
        //init archive subview on the left
        subviewArchiveSwipeFromLeftToRight.frame = CGRect(x: -bounds.size.width, y: 0, width: self.bounds.width, height: height)
        checkLabel.frame = CGRect(x: bounds.size.width - 50, y: (height/2) - 12, width: 40, height: 22)
        subviewArchiveSwipeFromLeftToRight.addSubview(checkLabel)
        addSubview(subviewArchiveSwipeFromLeftToRight)
        
        if recognizer.state == .Began {
            // when the gesture begins, record the current center location
            originalCenter = center
        }
        
        if recognizer.state == .Changed {
            let translation = recognizer.translationInView(self)
            center = CGPointMake(originalCenter.x + translation.x, originalCenter.y)
            deleteOnDragRelease = frame.origin.x < -frame.size.width / 7.0
            archiveOnDragRelease = frame.origin.x > frame.size.width / 7.0
            remindMeOnDragRelease = frame.origin.x > frame.size.width / 1.5
            
            // indicate when the user has pulled the item far enough to invoke the given action
            subviewDeleteSwipeFromRightToLeft.backgroundColor = deleteOnDragRelease ? UIColor.redColor() : UIColor.grayColor()
            subviewArchiveSwipeFromLeftToRight.backgroundColor = archiveOnDragRelease ? UIColor.greenColor() : UIColor.grayColor()
            
            if remindMeOnDragRelease {
                checkLabel.hidden = true
                subviewArchiveSwipeFromLeftToRight.backgroundColor = UIColor.yellowColor()
            }else {
                checkLabel.hidden = false
            }
        }
        
        if recognizer.state == .Ended {
            let originalFrame = CGRect(x: 0, y: frame.origin.y, width: bounds.size.width, height: bounds.size.height)
            let deleteFrame = CGRect(x: -bounds.size.width, y: frame.origin.y, width: bounds.size.width, height: bounds.size.height)
            let showButtonsFrame = CGRect(x: bounds.size.width, y: frame.origin.y, width: bounds.size.width, height: bounds.size.height)
            
            if !deleteOnDragRelease && !archiveOnDragRelease && !remindMeOnDragRelease {
                //snap back to original location
                UIView.animateWithDuration(0.2, animations: {self.frame = originalFrame})
                return
            }
            
            if deleteOnDragRelease {
                if delegate != nil {
                    //delete this mail
                    UIView.animateWithDuration(0.2, animations: {self.frame = deleteFrame})
                    delegate!.deleteEmail(mail)
                }
            }

            if remindMeOnDragRelease {
                UIView.animateWithDuration(0.2, animations: {self.frame = originalFrame})
                NSLog("REMIND ME")
            } else if archiveOnDragRelease {
                    UIView.animateWithDuration(0.2, animations: {self.frame = originalFrame})
                    NSLog("archive this email")
            }
        }
    }
    
    override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
            let translation = panGestureRecognizer.translationInView(superview!)
            
            if fabs(translation.x) > fabs(translation.y) {
                return true
            }
        }
        return false
    }
}
