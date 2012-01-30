//
//  Hemkop.h
//  Program
//
//  Created by Christopher Lindblom on 2011-12-26.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HemkopReciever <NSObject>

- (void) infoUpdated;
- (void) newMessage;
- (void) failedWithMessage:(NSString *) message;

@end

@interface Hemkop : NSObject

@property (strong, nonatomic, readonly) NSString * balance;
@property (strong, nonatomic, readonly) NSString * message;
@property (strong, nonatomic, readonly) NSArray * transactions;
@property (weak, nonatomic) id <HemkopReciever> delegate;

- (void) update:(NSString *)username withPassword:(NSString *)password;

@end
