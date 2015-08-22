//
//  HTMLRenderDelegateBridge.h
//  SMile
//
//  Created by Jan Weiß on 18.08.15.
//  Copyright (c) 2015 SMile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MailCore/MailCore.h>

@protocol HTMLRenderBridgeDelegate;

@interface HTMLRenderDelegateBridge : NSObject <MCOHTMLRendererDelegate>

@property (nonatomic, weak) id<HTMLRenderBridgeDelegate> delegate;

@end

@protocol HTMLRenderBridgeDelegate <NSObject>

@optional
- (BOOL) abstractMessage:(MCOAbstractMessage *)message canPreviewPart:(MCOAbstractPart *)part;
- (NSDictionary *) abstractMessage:(MCOAbstractMessage *)message templateValuesForHeader:(MCOMessageHeader *)header;
- (NSDictionary *) abstractMessage:(MCOAbstractMessage *)msg templateValuesForPart:(MCOAbstractPart *)part;
- (NSString *) abstractMessage:(MCOAbstractMessage *)msg templateForMainHeader:(MCOMessageHeader *)header;
- (NSString *) abstractMessage:(MCOAbstractMessage *)msg templateForImage:(MCOAbstractPart *)header;
- (NSString *) abstractMessage:(MCOAbstractMessage *)msg templateForAttachment:(MCOAbstractPart *)part;
- (NSString *) abstractMessageTemplateForMessage:(MCOAbstractMessage *)msg;
- (NSString *) abstractMessage:(MCOAbstractMessage *)msg templateForEmbeddedMessage:(MCOAbstractMessagePart *)part;
- (NSString *) abstractMessage:(MCOAbstractMessage *)msg templateForEmbeddedMessageHeader:(MCOMessageHeader *)header;
- (NSString *) abstractMessageTemplateForAttachmentSeparator:(MCOAbstractMessage *)msg;
- (NSString *) abstractMessage:(MCOAbstractMessage *)msg filterHTMLForPart:(NSString *)html;
- (NSString *) abstractMessage:(MCOAbstractMessage *)msg filterHTMLForMessage:(NSString *)html;
- (NSData *) abstractMessage:(MCOAbstractMessage *)msg dataForIMAPPart:(MCOIMAPPart *)part folder:(NSString *)folder;
- (void) abstractMessage:(MCOAbstractMessage *)msg prefetchAttachmentIMAPPart:(MCOIMAPPart *)part folder:(NSString *)folder;
- (void) abstractMessage:(MCOAbstractMessage *)msg prefetchImageIMAPPart:(MCOIMAPPart *)part folder:(NSString *)folder;

@end

