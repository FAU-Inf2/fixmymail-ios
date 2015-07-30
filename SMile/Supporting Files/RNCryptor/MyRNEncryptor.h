//
//  MyRNEncryptor.m
//  SMile
//
//  Created by Sebastian Thürauf on 30.07.15.
//  Copyright (c) 2015 SMile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RNEncryptor.h"

@interface MyRNEncryptor : RNEncryptor

+ (NSData *)encryptData:(NSData *)data password:(NSString *)password error:(NSError **)error;
+ (NSString *)stringFromData:(NSData *)data;

@end
