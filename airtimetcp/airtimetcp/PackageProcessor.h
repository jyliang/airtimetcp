//
//  PackageProcessor.h
//  airtimetcp
//
//  Created by Jason Liang on 11/22/14.
//  Copyright (c) 2014 Jason Liang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Packet.h"

static NSString * const kProcessedFileName = @"processed";
static NSString * const kFileExtSound = @".raw";
static NSString * const kFileExtZip = @".zip";


@interface PackageProcessor : NSObject

@property (nonatomic, strong) Packet *currentPacket;
@property (nonatomic, strong) NSString *zipPath;

- (uint32_t)processNewPacketHeader:(NSData *)data;
- (void)processCurrentPacketWithData:(NSData *)data;
- (void)completeProcessing;

@end
