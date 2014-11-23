//
//  PackageProcessor.h
//  airtimetcp
//
//  Created by Jason Liang on 11/22/14.
//  Copyright (c) 2014 Jason Liang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Packet.h"

@interface PackageProcessor : NSObject

@property (nonatomic, strong) Packet *currentPacket;

- (uint32_t)processNewPacketHeader:(NSData *)data;
- (void)processCurrentPacketWithData:(NSData *)data;
- (void)completeProcessing;

- (void)processPackage:(NSData *)data;

@end
