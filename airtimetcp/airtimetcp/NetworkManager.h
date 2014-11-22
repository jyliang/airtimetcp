//
//  NetworkManager.h
//  airtimetcp
//
//  Created by Jason Liang on 11/22/14.
//  Copyright (c) 2014 Jason Liang. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GCDAsyncSocket;

@interface NetworkManager : NSObject

@property (nonatomic, strong) GCDAsyncSocket *asyncSocket;

- (void)connect;

@end
