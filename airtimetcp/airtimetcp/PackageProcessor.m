//
//  PackageProcessor.m
//  airtimetcp
//
//  Created by Jason Liang on 11/22/14.
//  Copyright (c) 2014 Jason Liang. All rights reserved.
//

#import "PackageProcessor.h"

@interface PackageProcessor ()

@property (nonatomic, strong) NSMutableDictionary *packages;

@end

@implementation PackageProcessor

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.packages = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (uint32_t)processNewPacketHeader:(NSData *)data {
    NSLog(@"header %@", data);
    void *bytes = [data bytes];
    uint32_t seq = OSReadBigInt32(bytes, 0);
    uint32_t chk = OSReadBigInt32(bytes, 4);
    uint32_t len = OSReadBigInt32(bytes, 8);
    self.currentPacket = [[Packet alloc] init];
    self.currentPacket.seq = seq;
    self.currentPacket.chk = chk;
    self.currentPacket.len = len;
    self.currentPacket.headerData = data;
    return len;
}

- (void)processCurrentPacketWithData:(NSData *)data {
    NSLog(@"data %@", data);
    self.currentPacket.data = data;
    if ([self.currentPacket isValidPacket]) {
        [self.packages setObject:self.currentPacket forKey:[NSNumber numberWithUnsignedInt:self.currentPacket.seq]];
    }
    self.currentPacket = nil;
}

- (void)completeProcessing {
    NSLog(@"Complete processing");
    NSMutableData *data = [[NSMutableData alloc] init];
    NSArray *sortedKeys = [self.packages.allKeys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSNumber *num1 = obj1;
        NSNumber *num2 = obj2;
        return [num1 compare:num2];
    }];
    for (NSNumber *key in sortedKeys) {
        Packet *packet = self.packages[key];
        [data appendData:packet.data];
    }
    [self saveDataToDisk:data];
}

- (void)saveDataToDisk:(NSData *)data {
    NSString *filename = @"processed.dat";
    NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
    NSString *documentsDirectory = [pathArray objectAtIndex:0];
    NSString *soundPath = [documentsDirectory stringByAppendingPathComponent:filename];

    [data writeToFile:soundPath atomically:YES];

}

- (void)processPackage:(NSData *)data {
    void *bytes = [data bytes];
    NSMutableArray *ary = [NSMutableArray array];
    NSUInteger offset = 0;
    while (offset < [data length]) {
        NSUInteger seq = OSReadBigInt32(bytes, offset);
        NSUInteger chk = OSReadBigInt32(bytes, offset+4);
        NSUInteger len = OSReadBigInt32(bytes, offset+8);

        NSUInteger start = offset+12;
        NSUInteger end = offset+12+len;

        offset = end;

        NSData *subData = [data subdataWithRange:NSMakeRange(start, len)];

        self.packages[[NSNumber numberWithUnsignedInteger:seq]] = subData;

//        for (NSUInteger i = start; i < end; i += sizeof(int32_t)) {
//            int32_t elem = OSReadLittleInt32(bytes, i);
//            [ary addObject:[NSNumber numberWithInt:elem]];
//        }
    }

    NSLog(@"%@",self.packages);

}

@end
