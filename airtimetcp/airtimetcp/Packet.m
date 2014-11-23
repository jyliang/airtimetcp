//
//  Packet.m
//  airtimetcp
//
//  Created by Jason Liang on 11/23/14.
//  Copyright (c) 2014 Jason Liang. All rights reserved.
//

#import "Packet.h"

@implementation Packet

- (BOOL)isValidPacket {
    uint16_t space = self.len%4;

    uint32_t chk = OSReadBigInt32(self.headerData.bytes, 0);
    uint32_t chunk;
    void *bytes = (void*)[self.data bytes];
    for (NSUInteger i = 0; i < self.data.length; i += sizeof(int32_t)) {
        if (i+sizeof(int32_t) > self.data.length) {
            NSLog(@"last bit");
            NSMutableData *data = [NSMutableData dataWithData:[self.data subdataWithRange:NSMakeRange(i, self.data.length-i)]];
           NSLog(@"last bit data %@", data);
            for (int s = 0; s < 4 - space; s++) {
                UInt8 filler= 0xab;
                [data appendBytes:&filler length:sizeof(filler)];
            }
           NSLog(@"last bit filled data %@", data);
            chunk = OSReadBigInt32([data bytes], 0);
            chk = chk ^ chunk;
        } else {
            chunk = OSReadBigInt32(bytes, i);
            chk = chk ^ chunk;
        }
    }

    if (chk == self.chk) {
        NSLog(@"very valid packet");
        return YES;
    } else {
        NSLog(@"invalid packet");
        return NO;
    }

    return YES;
}

@end
