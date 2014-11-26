//
//  NerworkAccessObject.h
//  VirtualPet
//
//  Created by Ezequiel on 11/26/14.
//  Copyright (c) 2014 Ezequiel. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^Success)(NSURLSessionDataTask*, id);
typedef void (^Failure)(NSURLSessionDataTask*, NSError*);

@interface NetworkAccessObject : NSObject

- (void) doGETPetInfo;
- (void) doPOSTPetLevelUp;

@end
