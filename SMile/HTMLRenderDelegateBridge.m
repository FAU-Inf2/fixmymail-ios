//
//  HTMLRenderDelegateBridge.m
//  SMile
//
//  Created by Jan Weiß on 18.08.15.
//  Copyright (c) 2015 SMile. All rights reserved.
//

#import "HTMLRenderDelegateBridge.h"

@interface HTMLRenderDelegateBridge()

@property (nonatomic, strong) NSMutableSet *supportedImageMimeTypes;
@property (nonatomic, strong) NSMutableSet *supportedImageExtensions;

@end

@implementation HTMLRenderDelegateBridge

- (id)init {
    self = [super init];
    if (self) {
        self.supportedImageMimeTypes = [self setSupportedImageMimeTypes];
        self.supportedImageExtensions = [self setSupportedImageExtensions];
    }
    return self;
}

- (NSMutableSet *)setSupportedImageMimeTypes {
    NSMutableSet *returnSet = [NSMutableSet new];
    [returnSet addObject:@"image/png"];
    [returnSet addObject:@"image/gif"];
    [returnSet addObject:@"image/jpg"];
    [returnSet addObject:@"image/jpeg"];
    return returnSet;
}

- (NSMutableSet *)setSupportedImageExtensions {
    NSMutableSet *returnSet = [NSMutableSet new];
    [returnSet addObject:@"png"];
    [returnSet addObject:@"gif"];
    [returnSet addObject:@"jpg"];
    [returnSet addObject:@"jpeg"];
    return returnSet;
}

- (BOOL) MCOAbstractMessage:(MCOAbstractMessage *)msg canPreviewPart:(MCOAbstractPart *)part {
    
    if ([self.supportedImageMimeTypes containsObject:[[part mimeType] lowercaseString]]) {
        return YES;
    }
    
    NSString * ext = nil;
    if ([part filename] != nil) {
        if ([[part filename] pathExtension] != nil) {
            ext = [[[part filename] pathExtension] lowercaseString];
        }
    }
    if (ext != nil) {
        if ([self.supportedImageExtensions containsObject:ext])
            return YES;
    }
    
    if (![[self delegate] respondsToSelector:@selector(abstractMessage:canPreviewPart:)]) {
        return false;
    }
    return [self.delegate abstractMessage:msg canPreviewPart:part];
}

- (NSDictionary *) MCOAbstractMessage:(MCOAbstractMessage *)msg templateValuesForHeader:(MCOMessageHeader *)header
{
    if (![[self delegate] respondsToSelector:@selector(abstractMessage:templateValuesForHeader:)]) {
        return nil;
    }
    return [[self delegate] abstractMessage:msg templateValuesForHeader:header];
}

- (NSDictionary *) MCOAbstractMessage:(MCOAbstractMessage *)msg templateValuesForPart:(MCOAbstractPart *)part
{
    if (![[self delegate] respondsToSelector:@selector(abstractMessage:templateValuesForPart:)]) {
        return nil;
    }
    return [[self delegate] abstractMessage:msg templateValuesForPart:part];
}

- (NSString *) MCOAbstractMessage:(MCOAbstractMessage *)msg templateForMainHeader:(MCOMessageHeader *)header
{
    if (![[self delegate] respondsToSelector:@selector(abstractMessage:templateForMainHeader:)]) {
        return nil;
    }
    return [[self delegate] abstractMessage:msg templateForMainHeader:header];
}

- (NSString *) MCOAbstractMessage:(MCOAbstractMessage *)msg templateForImage:(MCOAbstractPart *)header
{
    NSString * templateString;
    if ([[self delegate] respondsToSelector:@selector(abstractMessage:templateForImage:)]) {
        templateString = [[self delegate] abstractMessage:msg templateForImage:header];
    }
    else {
        templateString = @"<img src=\"{{URL}}\"/>";
    }
    templateString = [NSString stringWithFormat:@"<div id=\"{{CONTENTID}}\">%@</div>", templateString];
    return templateString;
}

- (NSString *) MCOAbstractMessage:(MCOAbstractMessage *)msg templateForAttachment:(MCOAbstractPart *)part
{
    if (![[self delegate] respondsToSelector:@selector(abstractMessage:templateForAttachment:)]) {
        return NULL;
    }
    NSString * templateString = [[self delegate] abstractMessage:msg templateForAttachment:part];
    templateString = [NSString stringWithFormat:@"<div id=\"{{CONTENTID}}\">%@</div>", templateString];
    return templateString;
}

- (NSString *) MCOAbstractMessage_templateForMessage:(MCOAbstractMessage *)msg
{
    if (![[self delegate] respondsToSelector:@selector(abstractMessageTemplateForMessage:)]) {
        return NULL;
    }
    return [[self delegate] abstractMessageTemplateForMessage:msg];
}

- (NSString *) MCOAbstractMessage:(MCOAbstractMessage *)msg templateForEmbeddedMessage:(MCOAbstractMessagePart *)part
{
    if (![[self delegate] respondsToSelector:@selector(abstractMessage:templateForEmbeddedMessage:)]) {
        return NULL;
    }
    return [[self delegate] abstractMessage:msg templateForEmbeddedMessage:part];
}

- (NSString *) MCOAbstractMessage:(MCOAbstractMessage *)msg templateForEmbeddedMessageHeader:(MCOMessageHeader *)header
{
    if (![[self delegate] respondsToSelector:@selector(abstractMessage:templateForEmbeddedMessageHeader:)]) {
        return NULL;
    }
    return [[self delegate] abstractMessage:msg templateForEmbeddedMessageHeader:header];
}

- (NSString *) MCOAbstractMessage_templateForAttachmentSeparator:(MCOAbstractMessage *)msg
{
    if (![[self delegate] respondsToSelector:@selector(abstractMessageTemplateForAttachmentSeparator:)]) {
        return NULL;
    }
    return [[self delegate] abstractMessageTemplateForAttachmentSeparator:msg];
}

- (NSString *) MCOAbstractMessage:(MCOAbstractMessage *)msg filterHTMLForPart:(NSString *)html
{
    if (![[self delegate] respondsToSelector:@selector(abstractMessage:filterHTMLForPart:)]) {
        return html;
    }
    return [[self delegate] abstractMessage:msg filterHTMLForPart:html];
}

- (NSString *) MCOAbstractMessage:(MCOAbstractMessage *)msg filterHTMLForMessage:(NSString *)html
{
    if (![[self delegate] respondsToSelector:@selector(abstractMessage:filterHTMLForMessage:)]) {
        return html;
    }
    return [[self delegate] abstractMessage:msg filterHTMLForMessage:html];
}

- (NSData *) MCOAbstractMessage:(MCOAbstractMessage *)msg dataForIMAPPart:(MCOIMAPPart *)part folder:(NSString *)folder
{
    return [[self delegate] abstractMessage:msg dataForIMAPPart:part folder:folder];
}

- (void) MCOAbstractMessage:(MCOAbstractMessage *)msg prefetchAttachmentIMAPPart:(MCOIMAPPart *)part folder:(NSString *)folder
{
    if ([self.delegate respondsToSelector:@selector(abstractMessage:prefetchAttachmentIMAPPart:folder:)]) {
        [self.delegate abstractMessage:msg prefetchAttachmentIMAPPart:part folder:folder];
    }
}

- (void) MCOAbstractMessage:(MCOAbstractMessage *)msg prefetchImageIMAPPart:(MCOIMAPPart *)part folder:(NSString *)folder
{
    if ([self.delegate respondsToSelector:@selector(abstractMessage:prefetchImageIMAPPart:folder:)]) {
        [self.delegate abstractMessage:msg prefetchImageIMAPPart:part folder:folder];
    }
}

@end

