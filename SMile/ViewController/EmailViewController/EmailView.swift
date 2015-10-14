//
//  EmailView.swift
//  SMile
//
//  Created by Jan Weiß on 17.08.15.
//  Copyright (c) 2015 SMile. All rights reserved.
//

import UIKit
import Locksmith

protocol EmailViewDelegate: NSObjectProtocol {
    func handleMailtoWithRecipients(recipients: [String], andSubject subject: String, andHTMLString html: String) -> Void
    func presentAttachmentVC(attachmentVC: AttachmentsViewController) -> Void
    func askPassphraseForKey(key: Key) -> String?
    func presentInformationAlertController(alertController: UIAlertController) -> Void
}

class EmailView: UIView, UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource, HTMLRenderBridgeDelegate, UIWebViewDelegate {
    
    var embededHeaderView: UITableView!
    var calculationView: UIView!
    var webView: UIWebView!
    var message: MCOIMAPMessage
    var email: Email
    var folder: String!
    var loadingSpinner: UIActivityIndicatorView!
    var messageHeaderInfo = [String: String]()
    var cellSenderHeight: CGFloat!
    var cellSubjectHeight: CGFloat!
    var cellAttachmentHeight: CGFloat!
    var messageContent: String = ""
    var htmlRenderBridge = HTMLRenderDelegateBridge()
    var imapPartCache = [String: NSData]()
    var ccStringHeight: CGFloat!
    var toStringHeight: CGFloat!
    var fromStringHeight: CGFloat!
    var emailViewDelegate: EmailViewDelegate?
    var plainHTMLContent: String!
    var attachmentVC: AttachmentsViewController!
    private let smileCrypto = SMileCrypto()
    private var keyPassphrases = [Key : String]()
    private var accessoryButton: UIButton?
    private var decrypted: Bool = false
    
    
    init(frame: CGRect, message: MCOIMAPMessage, email: Email) {
        self.email = email
        self.message = message
        super.init(frame: frame)
        
        self.htmlRenderBridge.delegate = self
        
        self.webView = UIWebView(frame: frame)
        self.webView.scalesPageToFit = true
        self.webView.delegate = self
        self.addSubview(self.webView)
        
        let spinnerSize = self.frame.width / 4
        self.loadingSpinner = UIActivityIndicatorView()
        self.loadingSpinner.frame.size = CGSizeMake(spinnerSize, spinnerSize)
        self.loadingSpinner.center = CGPointMake(self.frame.width/2, self.frame.height/2)
        self.loadingSpinner.hidden = true
        self.webView.addSubview(self.loadingSpinner)
        self.webView.bringSubviewToFront(self.loadingSpinner)
        self.sendSubviewToBack(self.webView)
        
        self.bringSubviewToFront(self.webView.scrollView)
        self.messageHeaderInfo = self.getHeaderInformationFromMCOAbstractMessage(self.message)
        
        
        
        self.createHeaderView()
        self.layoutWebViewSubviews()
        
        self.webView.scrollView.addObserver(self, forKeyPath: "contentOffset", options: NSKeyValueObservingOptions.Initial, context: nil)
        
        self.preFetchAttachments()
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            self.loadingSpinner.startAnimating()
            self.loadingSpinner.hidden = false
            self.loadHTMLView()
        })
    }

    
    required init?(coder aDecoder: NSCoder) {
        self.email = aDecoder.decodeObjectForKey("Email") as! Email
        self.message = aDecoder.decodeObjectForKey("MCOIMAPMessage") as! MCOIMAPMessage
        super.init(coder: aDecoder)
        
    }
    
    private func createAndFillAttachmentVC(messageParser: MCOMessageParser) -> String? {
        var retString: String? = nil
        self.attachmentVC = AttachmentsViewController(nibName: "AttachmentsViewController", bundle: nil)
        self.attachmentVC.isViewAttachment = true
        let parser = MCOMessageParser(data: messageParser.data())
        let attachments: [MCOAttachment] = parser.attachments() as! [MCOAttachment]
        for attachment in attachments {
            if attachment.mimeType == "application/pgp-encrypted" {
                continue
            } else {
                let attachmentString =  String(data: attachment.data, encoding: NSUTF8StringEncoding)
                if attachmentString?.containsString("-----BEGIN PGP MESSAGE-----") == true {
                    let htmlContent = self.getDecryptedHTMLContent(attachment.data)
                    if htmlContent != nil {
                        retString = htmlContent
                    }
                    
                } else {
                    if attachment.inlineAttachment {
                        continue
                    }
                    var filename: String
                    var mimeType: String
                    if attachment.filename == nil {
                        filename = "noname"
                    } else {
                        filename = attachment.filename
                    }
                    if attachment.mimeType == nil {
                        mimeType = ""
                    } else {
                        mimeType = attachment.mimeType
                    }
                    self.attachmentVC.attachFile(filename, data: attachment.data, mimetype: mimeType)
                }
            }
        }
        return retString
    }
    
    
    private func createHeaderView() -> Void {
        let boldFont = UIFont.boldSystemFontOfSize(20.0)
        let standardFont = UIFont.systemFontOfSize(17.0)
        let width: CGFloat = CGFloat(self.frame.size.width - 8.0 - 8.0)
        
        self.ccStringHeight = self.messageHeaderInfo["cc"] != nil ? self.messageHeaderInfo["cc"]!.heightForWith(width, usingFont: standardFont) : 0.0
        self.toStringHeight = self.messageHeaderInfo["to"] != nil ? self.heightForView(self.messageHeaderInfo["to"]!, font: standardFont, width: width): 0.0
        self.fromStringHeight = self.messageHeaderInfo["from"]!.heightForWith(width, usingFont: boldFont)
        self.cellSenderHeight = 8.0 + 2.0 + 2.0 + 8.0 + self.ccStringHeight + self.toStringHeight + self.fromStringHeight
        if self.message.attachments().count > 0 {
            self.cellAttachmentHeight = 44.0
        } else {
            self.cellAttachmentHeight = 0.0
        }
        
        let subjectStringHeight: CGFloat = self.messageHeaderInfo["subject"] != nil ? self.messageHeaderInfo["subject"]!.heightForWith(width, usingFont: boldFont) : "".heightForWith(width, usingFont: boldFont)
        let dateStringHeight: CGFloat = self.messageHeaderInfo["date"]!.heightForWith(width, usingFont: standardFont)
        self.cellSubjectHeight = 8.0 + 8.0 + subjectStringHeight + dateStringHeight
        
        self.embededHeaderView = UITableView(frame: CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.cellSenderHeight + self.cellSubjectHeight + self.cellAttachmentHeight))
        self.embededHeaderView.dataSource = self
        self.embededHeaderView.delegate = self
        self.embededHeaderView.registerNib(UINib(nibName: "SenderInfoTableViewCell", bundle: nil), forCellReuseIdentifier: "senderInfoCell")
        self.embededHeaderView.registerNib(UINib(nibName: "SubjectInfoTableViewCell", bundle: nil), forCellReuseIdentifier: "subjectInfoCell")
        self.embededHeaderView.registerNib(UINib(nibName: "AttachmentViewCell", bundle: nil), forCellReuseIdentifier: "AttachmentViewCell")
        self.embededHeaderView.scrollEnabled = false
        self.webView.scrollView.addSubview(self.embededHeaderView)
        self.webView.scrollView.bringSubviewToFront(self.embededHeaderView)
        
        self.calculationView = UIView(frame: self.embededHeaderView.frame)
        self.calculationView.backgroundColor = UIColor.clearColor()
        self.addSubview(self.calculationView)
        self.sendSubviewToBack(self.calculationView)
    }
    
    
    private func layoutWebViewSubviews() {
        super.layoutSubviews()
        
        for view in self.webView.scrollView.subviews {
            let subview = view
            if subview.isEqual(self.embededHeaderView) {
                continue
            }
            var newFrame = subview.frame
            newFrame.origin.y = CGRectGetHeight(self.embededHeaderView.frame)
            subview.frame = newFrame
        }
    }
    
    
    deinit {
        self.webView.scrollView.removeObserver(self, forKeyPath: "contentOffset")
    }
    
    //MARK: - UIWebviewDelegate
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
        if navigationType == UIWebViewNavigationType.LinkClicked {
            if request.URL?.scheme == "mailto" {
                if self.emailViewDelegate != nil && self.emailViewDelegate!.respondsToSelector("handleMailtoWithRecipients:andSubject:andHTMLString:") {
                    self.emailViewDelegate!.handleMailtoWithRecipients([request.URL?.resourceSpecifier ?? ""], andSubject: (self.embededHeaderView.cellForRowAtIndexPath(NSIndexPath(forItem: 1, inSection: 0)) as! SubjectInfoTableViewCell).subjectLabel.text ?? "",andHTMLString: EmailCache.sharedInstance.getHTMLStringWithUniqueEmailID("\(self.message.uid)")?.cachedHTML ?? "")
                }
            } else if UIApplication.sharedApplication().canOpenURL(request.URL!) {
                UIApplication.sharedApplication().openURL(request.URL!)
            }
            return false
        }
        
        return true
    }
    
    //MARK: - Key-Value-Observing
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        var newFrame: CGRect = self.calculationView.frame
        newFrame.origin.y = -CGRectGetMinY(self.webView.convertRect(self.embededHeaderView.frame, toView: self.webView.scrollView))
        self.calculationView.frame = newFrame
        
        var newEmbededFrame: CGRect = self.embededHeaderView.frame
        newEmbededFrame.size = self.calculationView.frame.size
        newEmbededFrame.origin.x = self.webView.scrollView.contentOffset.x
        self.embededHeaderView.frame = newEmbededFrame
    }
    
    //MARK: - TableView functions
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.message.attachments().count > 0 {
            return 3
        } else {
            return 2
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return self.cellSenderHeight
        } else if indexPath.row == 1 {
            return self.cellSubjectHeight
        } else {
            return 44.0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let senderInfoCell: SenderInfoTableViewCell = tableView.dequeueReusableCellWithIdentifier("senderInfoCell", forIndexPath: indexPath) as! SenderInfoTableViewCell
            
            senderInfoCell.fromLabel.text = self.messageHeaderInfo["from"]
            
            let ccLabelString: String? = self.messageHeaderInfo["cc"] != nil ? self.messageHeaderInfo["cc"]! : nil
            if ccLabelString == nil {
                senderInfoCell.ccLabel.frame.size = CGSizeZero
                senderInfoCell.ccLabel.text = ""
            } else {
                senderInfoCell.ccLabel.frame.size = CGSizeMake(senderInfoCell.ccLabel.frame.size.width, self.ccStringHeight)
                senderInfoCell.ccLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
                senderInfoCell.ccLabel.text = ccLabelString!
            }
            
            let toLabelString = self.messageHeaderInfo["to"] != nil ? self.messageHeaderInfo["to"]! : "To:"
            senderInfoCell.toLabel.frame.size = CGSizeMake(senderInfoCell.toLabel.frame.size.width, self.toStringHeight)
            senderInfoCell.toLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
            senderInfoCell.toLabel.text = toLabelString
            
            senderInfoCell.accessoryType = .None
            senderInfoCell.selectionStyle = UITableViewCellSelectionStyle.None
            return senderInfoCell
        } else if indexPath.row == 1 {
            
            self.message.header.extraHeaderValueForName("")
            
            let subjectInfoCell: SubjectInfoTableViewCell = tableView.dequeueReusableCellWithIdentifier("subjectInfoCell", forIndexPath: indexPath) as! SubjectInfoTableViewCell
            
            let subjectLabelString = self.messageHeaderInfo["subject"] != nil ? self.messageHeaderInfo["subject"]! : ""
            subjectInfoCell.subjectLabel.text = subjectLabelString
            
            subjectInfoCell.dateLabel.text = self.messageHeaderInfo["date"]
            
            if self.accessoryButton != nil {
                subjectInfoCell.accessoryView = self.accessoryButton!
            }
            subjectInfoCell.selectionStyle = UITableViewCellSelectionStyle.None
            return subjectInfoCell
        } else {
            let attachmentCell: AttachmentViewCell = tableView.dequeueReusableCellWithIdentifier("AttachmentViewCell", forIndexPath: indexPath) as! AttachmentViewCell
            attachmentCell.imageViewPreview.image = UIImage(named: "attachment_icon@2x.png")!
            attachmentCell.imageViewPreview.image = UIImage(CGImage: attachmentCell.imageViewPreview.image!.CGImage!, scale: 1, orientation: UIImageOrientation.Up)
            attachmentCell.labelFilesAttached.text = "\t \(self.message.attachments().count) files attached"
            attachmentCell.labelFilesAttached.textColor = UIColor.grayColor()
            
            attachmentCell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            attachmentCell.selectionStyle = UITableViewCellSelectionStyle.Default
            return attachmentCell
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == 2 {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            if (self.emailViewDelegate?.respondsToSelector("presentAttachmentVC:") != nil) {
                self.emailViewDelegate?.presentAttachmentVC(self.attachmentVC)
            }
        }
    }
    
    //MARK: - MailCore Message Helper
    
    private func getHeaderInformationFromMCOAbstractMessage(message: MCOAbstractMessage) -> [String: String] {
        var returnDict = [String: String]()
        let header : MCOMessageHeader = message.header
        
        if header.from != nil {
            let fromString: String? = (header.from.displayName != nil) ? header.from.displayName : header.from.mailbox
            if fromString != nil {
                returnDict["from"] = "From: \(fromString!)"
            } else {
                returnDict["from"] = "From: -"
            }
        } else {
            returnDict["from"] = "From: -"
        }
        
        let toString: String? = self.addressStringFromArray(header.to)
        if let to = toString {
            returnDict["to"] = "To: \(to)"
        } else {
            returnDict["to"] = "To: -"
        }
        
        let ccString: String? = self.addressStringFromArray(header.cc)
        if let cc = ccString {
            returnDict["cc"] = "CC: \(cc)"
        } else {
            returnDict["cc"] = ccString
        }
        
        let subjectString: String? = header.subject != "" ? header.subject : nil
        returnDict["subject"] = subjectString
        
        let dateString = NSDateFormatter.localizedStringFromDate(header.date, dateStyle: .MediumStyle, timeStyle: .MediumStyle)
        returnDict["date"] = dateString
        
        return returnDict
    }
    
    private func heightForView(text:String, font: UIFont, width: CGFloat) -> CGFloat{
        let label:UILabel = UILabel(frame: CGRectMake(0, 0, width, CGFloat.max))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.ByWordWrapping
        label.font = font
        label.text = text
        
        label.sizeToFit()
        return label.frame.height
    }
    
    private func addressStringFromArray(array :[AnyObject]?) -> String? {
        if array == nil || array!.count == 0 {
            return nil
        }
        
        let addArray = NSMutableArray()
        for element in array! {
            if element is MCOAddress {
                let address = element as! MCOAddress
                if address.displayName != "" && address.displayName != nil {
                    addArray.addObject(address.displayName)
                } else {
                    addArray.addObject(address.mailbox)
                }
            }
        }
        
        return addArray.componentsJoinedByString(", ")
    }
    
    private func loadHTMLView() -> Void {
        let htmlContent = EmailCache.sharedInstance.getHTMLStringWithUniqueEmailID("\(self.message.uid)")
        if htmlContent != nil {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.webView.loadHTMLString(htmlContent!.cachedHTML, baseURL: nil)
                if htmlContent!.wasDecrypted == true {
                    self.setIconForDecrypt()
                }
                self.loadingSpinner.hidden = true
                self.loadingSpinner.stopAnimating()
            })
        } else {
            var htmlContent: String?
            if self.email.plainText.containsString("-----BEGIN PGP MESSAGE-----") {
                htmlContent = self.getDecryptedHTMLContent(self.email.plainText.dataUsingEncoding(NSUTF8StringEncoding)!)
            } else {
                let messageParser: MCOMessageParser = MCOMessageParser(data: self.email.data)
                htmlContent = messageParser.htmlRenderingWithDelegate(self.htmlRenderBridge) as String?
                let returnString = self.createAndFillAttachmentVC(messageParser)
                if returnString != nil {
                    htmlContent = returnString
                }
            }
                
            if htmlContent == nil {
                self.messageContent = ""
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.webView.loadHTMLString("", baseURL: nil)
                    self.loadingSpinner.hidden = true
                    self.loadingSpinner.stopAnimating()
                })
                return
            }
            
            self.parseForPresentationWithHTMLContent(htmlContent!)
        }
    }
    
    private func parseForPresentationWithHTMLContent(htmlContent: String) -> Void {
        self.plainHTMLContent = htmlContent
        
        var htmlString = String()
        let jsURL = NSBundle.mainBundle().URLForResource("MCOMessageViewScript", withExtension: "js")
        
        htmlString += "<html><head><script src=\"\(jsURL!.absoluteString)\"></script><style type='text/css'>body{ font-family: 'Helvetica Neue', Helvetica, Arial; margin:0; padding:30px;font-size: 50.0px;}\\hr {border: 0; height: 1px; background-color: #bdc3c7;}\\.show { display: none;}.hide:target + .show { display: inline;} .hide:target { display: none;} .content { display: none;} .hide:target ~ .content { display:inline;}\\</style></head><body><div style=\"font-family: Helvetica;font-size: 50.0px;\">\(htmlContent)</div></body><iframe src='x-mailcore-msgviewloaded:' style='width: 0px; height: 0px; border: none;'></iframe></html>"
        
        //TODO: Comment in
//        EmailCache.sharedInstance.emailContentCache["\(self.message.uid)"] = MailContent(cachedHTML: htmlString, wasDecrypted: decrypted)
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.webView.loadHTMLString(htmlString, baseURL: nil)
            self.loadingSpinner.hidden = true
            self.loadingSpinner.stopAnimating()
            if self.decrypted == true {
                self.setIconForDecrypt()
            }
        })
    }
    
    private func getDataOfIMAPPart(imapPart: MCOIMAPPart, withMessage message: MCOAbstractMessage, andwithFolder folder: String) -> NSData {
        var returnData: NSData!
        let partId = imapPart.uniqueID
        if EmailCache.sharedInstance.getIMAPPartDataWithUniquePartID("\(self.message.uid).\(partId)") != nil {
            return EmailCache.sharedInstance.getIMAPPartDataWithUniquePartID("\(self.message.uid).\(partId)")!
        }
        
        let fetchContentOperation: MCOIMAPFetchContentOperation = try! getSession(self.email.toAccount).fetchMessageAttachmentOperationWithFolder(folder, number: self.message.uid, partID: imapPart.partID, encoding: imapPart.encoding)
        fetchContentOperation.progress = { (current, maximum) -> Void in
            print("progress content: \(current)/\(maximum)")
        }
        
        self.loadingSpinner.startAnimating()
        self.loadingSpinner.hidden = false
        
        dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
            fetchContentOperation.start({ (error, data) -> Void in
                if error != nil {
                    print(error)
                } else {
                    EmailCache.sharedInstance.imapPartCache["\(self.message.uid).\(imapPart.partID)"] = data
                    returnData = data
                }
            })
        })
        
        self.loadingSpinner.stopAnimating()
        self.loadingSpinner.hidden = true
        
        return returnData
    }
    
    private func preFetchAttachments() -> Void {
        if self.message.attachments().count > 0 {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true;
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            dispatch_apply(self.message.attachments().count, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { (i) -> Void in
                let part: MCOIMAPPart = self.message.attachments()[i] as! MCOIMAPPart
                let partFetchOp: MCOIMAPFetchContentOperation = try! getSession(self.email.toAccount).fetchMessageAttachmentOperationWithFolder(self.email.folder, number: self.message.uid, partID: part.partID, encoding: part.encoding)
                partFetchOp.start({ (error, data) -> Void in
                    if i == (self.message.attachments().count - 1) {
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    }
                    if error != nil {
                        print(error)
                    } else {
                        EmailCache.sharedInstance.imapPartCache["\(self.message.uid).\(part.partID)"] = data
                    }
                })
            })
        })
    }
    
    //MARK: - HTMLRenderBridgeDelegate
    
    func abstractMessage(message: MCOAbstractMessage!, canPreviewPart part: MCOAbstractPart!) -> Bool {
        return false
    }
    
    func abstractMessage(msg: MCOAbstractMessage!, templateForMainHeader header: MCOMessageHeader!) -> String! {
        return ""
    }
    
    func abstractMessage(msg: MCOAbstractMessage!, templateForImage header: MCOAbstractPart!) -> String! {
        return ""
    }
    
    func abstractMessage(msg: MCOAbstractMessage!, templateForAttachment part: MCOAbstractPart!) -> String! {
        return ""
    }
    
    func abstractMessageTemplateForMessage(msg: MCOAbstractMessage!) -> String! {
        return "{{BODY}}"
    }
    
    func abstractMessageTemplateForAttachmentSeparator(msg: MCOAbstractMessage!) -> String! {
        return ""
    }
    
    func abstractMessage(msg: MCOAbstractMessage!, dataForIMAPPart part: MCOIMAPPart!, folder: String!) -> NSData! {
        return self.getDataOfIMAPPart(part, withMessage: msg, andwithFolder: folder)
    }
    
    func abstractMessage(msg: MCOAbstractMessage!, prefetchAttachmentIMAPPart part: MCOIMAPPart!, folder: String!) {
        
    }
    
    func abstractMessage(msg: MCOAbstractMessage!, prefetchImageIMAPPart part: MCOIMAPPart!, folder: String!) {
        
    }
    
    //MARK: - Decrypt Helper Operations
    
    private func askPassphraseForKey(key: Key) -> String? {
        if self.keyPassphrases[key] != nil {
            return self.keyPassphrases[key]
        } else {
            if (self.emailViewDelegate?.respondsToSelector("askPassphraseForKey:") != nil) {
                let passphrase = self.emailViewDelegate?.askPassphraseForKey(key)
                if passphrase != nil {
                    self.keyPassphrases[key] = passphrase!
                }
                return passphrase
            }
        }
        return nil
    }
    
    private func setIconForDecrypt() -> Void {
        let buttonImage: UIImage = UIImage(named: "Lock_black@2x.png")!
        let button: UIButton = UIButton(type: UIButtonType.Custom)
        button.frame = CGRectMake(0, 0, 22, 28)
        button.setBackgroundImage(buttonImage, forState: UIControlState.Normal)
        button.backgroundColor = UIColor.clearColor()
        button.addTarget(self, action: nil, forControlEvents: UIControlEvents.TouchUpInside)
        
        self.accessoryButton = button
        self.embededHeaderView.reloadData()
    }
    
    private func getDecryptedHTMLContent(data: NSData) -> String? {
        var htmlContent: String?
        if let key = self.smileCrypto.getKeyforEncryptedMessage(data) {
            var passphrase: String?
            if (Locksmith.loadDataForUserAccount(key.keyID) != nil && Locksmith.loadDataForUserAccount(key.keyID)!["PassPhrase"] != nil) {
                passphrase = Locksmith.loadDataForUserAccount(key.keyID)!["PassPhrase"] as! String?
            } else {
                passphrase = self.askPassphraseForKey(key)
            }
            if passphrase != nil {
                self.setIconForDecrypt()
                let decrpytedValues = self.smileCrypto.decryptData(data, passphrase: passphrase!, encryptionType: "PGP")
                if decrpytedValues.error == nil {
                    self.decrypted = true
                    if decrpytedValues.decryptedData != nil {
                        let messageParser: MCOMessageParser = MCOMessageParser(data: decrpytedValues.decryptedData!)
                        htmlContent = messageParser.htmlRenderingWithDelegate(self.htmlRenderBridge) as String?
                        self.createAndFillAttachmentVC(messageParser)
                    }
                } else {
                    print(decrpytedValues.error?.description)
                }
            }
        } else {
            let alert = UIAlertController(title: "Information", message: "There is no key to decrypt this message", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler: nil))
            if (self.emailViewDelegate?.respondsToSelector("presentInformationAlertController:") != nil) {
                self.emailViewDelegate?.presentInformationAlertController(alert)
            }
            htmlContent = email.plainText
            self.createAndFillAttachmentVC(MCOMessageParser(data: email.data))
        }
        
        return htmlContent
    }
    
}

extension String {
    
    func heightForWith(width: CGFloat, usingFont font : UIFont) -> CGFloat {
        let context: NSStringDrawingContext = NSStringDrawingContext()
        let labelSize = CGSizeMake(width, CGFloat(FLT_MAX))
        let rect: CGRect = self.boundingRectWithSize(labelSize, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: context)
        return rect.size.height
    }
    
}
