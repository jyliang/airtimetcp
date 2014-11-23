//
//  Packet.m
//  airtimetcp
//
//  Created by Jason Liang on 11/23/14.
//  Copyright (c) 2014 Jason Liang. All rights reserved.
//

#import "Packet.h"

@implementation Packet

- (NSData *)getFilledData:(NSUInteger)i {
    uint16_t space = self.len%4;
    NSMutableData *data = [NSMutableData dataWithData:[self.data subdataWithRange:NSMakeRange(i, self.data.length-i)]];
    for (int s = 0; s < 4 - space; s++) {
        UInt8 filler= 0xab;
        [data appendBytes:&filler length:sizeof(filler)];
    }
    return data;
}

- (BOOL)isValidPacket {
    uint16_t space = self.len%4;
    uint32_t chk = OSReadBigInt32(self.headerData.bytes, 0);
    uint32_t chunk;
    void *bytes = (void*)[self.data bytes];
    for (NSUInteger i = 0; i < self.data.length; i += sizeof(uint32_t)) {
        if (space!= 0 && i > (self.data.length - sizeof(uint32_t))) {
            NSData *data = [self getFilledData:i];
            chunk = OSReadBigInt32([data bytes], 0);
            chk = chk ^ chunk;
        } else {
            chunk = OSReadBigInt32(bytes, i);
            chk = chk ^ chunk;
        }
    }

    return (chk == self.chk);
}

@end
