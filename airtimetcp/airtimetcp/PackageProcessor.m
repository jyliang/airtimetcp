//
//  PackageProcessor.m
//  airtimetcp
//
//  Created by Jason Liang on 11/22/14.
//  Copyright (c) 2014 Jason Liang. All rights reserved.
//

#import "PackageProcessor.h"
#import "SSZipArchive.h"

@interface PackageProcessor ()

@property (nonatomic, strong) NSMutableDictionary *packages;
@property (nonatomic, strong) NSMutableDictionary *invalidPackages;

@end

@implementation PackageProcessor

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.packages = [[NSMutableDictionary alloc] init];
        self.invalidPackages = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (uint32_t)processNewPacketHeader:(NSData *)data {
    void *bytes = (void *)[data bytes];
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
    self.currentPacket.data = data;
    if ([self.currentPacket isValidPacket]) {
        [self.packages setObject:self.currentPacket forKey:[NSNumber numberWithUnsignedInt:self.currentPacket.seq]];
    } else {
        [self.invalidPackages setObject:self.currentPacket forKey:[NSNumber numberWithUnsignedInt:self.currentPacket.seq]];
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
    NSString *filename = kProcessedFileName;
    [self saveDataToDisk:data withFileName:filename];
}

- (void)saveDataToDisk:(NSData *)data withFileName:(NSString *)filename{
    NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
    NSString *documentsDirectory = [pathArray objectAtIndex:0];
    NSString *soundPath = [documentsDirectory stringByAppendingPathComponent:[filename stringByAppendingString:kFileExtSound]];
    [data writeToFile:soundPath atomically:YES];

    NSString *zipPath = [documentsDirectory stringByAppendingPathComponent:[filename stringByAppendingString:kFileExtZip]];
    self.zipPath = zipPath;
    NSArray *inputPaths = @[soundPath];
    [SSZipArchive createZipFileAtPath:zipPath withFilesAtPaths:inputPaths];
}

@end
