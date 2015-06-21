//
//  MCOIMAPFolderWrapper.m
//  FixMyMail
//
//  Created by Jan Weiß on 17.06.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

#import "MCOIMAPFolderWrapper.h"

@interface MCOIMAPFolderWrapper () <NSCoding>

@end

@implementation MCOIMAPFolderWrapper

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    
    [self setPath:[aDecoder decodeObjectForKey:@"path"]];
    [self setDelimiter:[aDecoder decodeIntForKey:@"delimiter"]];
    [self setFlags:(MCOIMAPFolderFlag)[aDecoder decodeIntForKey:@"flags"]];
    
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.path forKey:@"path"];
    [aCoder encodeInt:self.delimiter forKey:@"delimiter"];
    [aCoder encodeInt:self.flags forKey:@"flags"];
}

@end
