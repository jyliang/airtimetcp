//
//  Packet.h
//  airtimetcp
//
//  Created by Jason Liang on 11/23/14.
//  Copyright (c) 2014 Jason Liang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Packet : NSObject

@property (nonatomic) uint32_t seq;
@property (nonatomic) uint32_t len;
@property (nonatomic) uint32_t chk;

@property (nonatomic, strong) NSData *headerData;
@property (nonatomic, strong) NSData *data;

- (BOOL)isValidPacket;

@end
