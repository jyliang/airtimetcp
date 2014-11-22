//
//  NetworkManager.m
//  airtimetcp
//
//  Created by Jason Liang on 11/22/14.
//  Copyright (c) 2014 Jason Liang. All rights reserved.
//

#import "NetworkManager.h"
#import "GCDAsyncSocket.h"

typedef enum {
    kConnectStart,
    kConnectHandShake,
    kConnectIdentify,
    kConnectHandShakeSuccess
} ConnectStage;

static NSString * const kHost = @"challenge2.airtime.com";
static uint16_t const kPort = 2323;
static NSString * const kEmail = @"liangjyjason@live.com";

@interface NetworkManager () <GCDAsyncSocketDelegate>

@property BOOL connected;
@property ConnectStage stage;

@end

@implementation NetworkManager

- (instancetype)init
{
    self = [super init];
    if (self) {
    self.asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return self;
}

- (void)connect {
    NSError *error;
    self.stage = kConnectStart;
    [self.asyncSocket connectToHost:kHost onPort:kPort error:&error];
}

#pragma mark -
- (void)readHandShake {
//    NSString *str = @"\n";
//    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
//    NSData *crData = [GCDAsyncSocket CRData];
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
//    [self.asyncSocket readDataToData:[GCDAsyncSocket LFData] withTimeout:-1.0 tag:kConnectHandShakeSuccess];
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    self.connected = YES;
    NSLog(@"did connect to host");
    [self readHandShake];
}

- (void)socketDidCloseReadStream:(GCDAsyncSocket *)sock {
    NSLog(@"closed read stream");
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    NSLog(@"did disconnect socket");
}

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    NSLog(@"did accept new socket");
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    if (tag == kConnectHandShake) {
        [self processHandShake:data];
    } else if (tag == kConnectHandShakeSuccess) {
        NSLog(@"connection success, begin decoding");
    } else {

    }
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    if (tag == kConnectIdentify) {
        [self.asyncSocket readDataToData:[GCDAsyncSocket LFData] withTimeout:-1.0 tag:kConnectHandShakeSuccess];
//        [self.asyncSocket readDataWithTimeout:30.0 tag:0];
    }
}

@end
