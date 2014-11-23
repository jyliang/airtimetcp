//
//  NetworkManager.m
//  airtimetcp
//
//  Created by Jason Liang on 11/22/14.
//  Copyright (c) 2014 Jason Liang. All rights reserved.
//

#import "NetworkManager.h"
#import "GCDAsyncSocket.h"
#import "PackageProcessor.h"

typedef enum {
    kConnectStart,
    kConnectHandShake,
    kConnectIdentify,
    kConnectHandShakeSuccess,
    kConnectPacket,
    kConnectPacketData
} ConnectStage;

static NSString * const kHost = @"challenge2.airtime.com";
static uint16_t const kPort = 2323;
static NSString * const kEmail = @"liangjyjason@gmail.com";
static UInt16 const kHeaderLength = 12;



@interface NetworkManager () <GCDAsyncSocketDelegate>

@property BOOL connected;
@property ConnectStage stage;
@property (nonatomic, strong) PackageProcessor *processor;
@property (nonatomic) NSUInteger packetCount;

@end

@implementation NetworkManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        self.processor = [[PackageProcessor alloc] init];
    }
    return self;
}
- (void)connect {
    NSError *error;
    self.stage = kConnectStart;
    [self.asyncSocket connectToHost:kHost onPort:kPort error:&error];

    if (error) {
        [self.delegate updateStatusTo:[error localizedDescription]];
    }
}

#pragma mark -
- (void)readHandShake {
    [self.asyncSocket readDataToData:[GCDAsyncSocket LFData] withTimeout:-1.0 tag:kConnectHandShake];
}

- (void)processHandShake:(NSData *)data {
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"%@", string);
    NSArray *comp = [string componentsSeparatedByString:@":"];
    if (comp.count == 2 && [comp[0] isEqualToString:@"WHORU"]) {
        NSString *challengeNumber = [comp[1] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        [self sendIdentificationWithChallengeNumber:challengeNumber];
    }
}

- (void)sendIdentificationWithChallengeNumber:(NSString *)challengeNumber {
    NSString *responseString = [NSString stringWithFormat:@"IAM:%@:%@:at\n", challengeNumber, kEmail];
    NSLog(@"sending identification packet '%@'", responseString);
    NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
    [self.asyncSocket writeData:responseData withTimeout:-1.0 tag:kConnectIdentify];
}

- (void)processHandShakeSuccess:(NSData *)data {
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSArray *comp = [string componentsSeparatedByString:@":"];
    if (comp.count == 2 && [comp[0] isEqualToString:@"SUCCESS"]) {
        NSLog(@"%@", string);
        self.stage = kConnectHandShakeSuccess;
        [self readPacketHeader];
    } else {
        [self.delegate updateStatusTo:@"Hand Shake Failed"];
    }
}

- (void)readPacketHeader {
    [self.asyncSocket readDataToLength:kHeaderLength withTimeout:-1.0 tag:kConnectPacket];
}

- (void)processPacketHeader:(NSData *)data {
    self.packetCount ++;
    [self.delegate updateStatusTo:[NSString stringWithFormat:@"Processing packet #%luu",(unsigned long) self.packetCount]];
    uint32_t length = [self.processor processNewPacketHeader:data];
    [self.asyncSocket readDataToLength:length withTimeout:-1.0 tag:kConnectPacketData];
}

- (void)processPacketData:(NSData *)data {
    [self.processor processCurrentPacketWithData:data];
    [self readPacketHeader];
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    self.connected = YES;
    NSLog(@"did connect to host : %@", host);
    [self readHandShake];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    NSLog(@"did disconnect socket");
    if (self.stage == kConnectHandShakeSuccess) {
        [self.delegate updateStatusTo:@"Processing data..."];
        [self.processor completeProcessing];
        [self.delegate updateStatusTo:@"File ready for email transmission."];
        [self.delegate showEmail:self.processor.zipPath];
    } else {
        [self.delegate updateStatusTo:@"Unexpected socket error"];
    }
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    if (tag == kConnectHandShake) {
        [self processHandShake:data];
    } else if (tag == kConnectHandShakeSuccess) {
        [self processHandShakeSuccess:data];
    } else if (tag == kConnectPacket){
        [self processPacketHeader:data];
    } else if (tag == kConnectPacketData) {
        [self processPacketData:data];
    }
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    if (tag == kConnectIdentify) {
        [self.asyncSocket readDataToData:[GCDAsyncSocket LFData] withTimeout:-1.0 tag:kConnectHandShakeSuccess];
    }
}

@end
