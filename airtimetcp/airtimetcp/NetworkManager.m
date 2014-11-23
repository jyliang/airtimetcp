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
    kConnectPacketData,
    kConnectDump
} ConnectStage;

static NSString * const kHost = @"challenge2.airtime.com";
static uint16_t const kPort = 2323;
static NSString * const kEmail = @"liangjyjason@gmail.com";
static UInt16 const kHeaderLength = 12;

static NSString * const kRawDataFileName = @"raw.dat";
static NSString * const kProcessedFileName = @"processed.dat";

@interface NetworkManager () <GCDAsyncSocketDelegate>

@property BOOL connected;
@property ConnectStage stage;
@property (nonatomic, strong) PackageProcessor *processor;

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

- (void)processFirstThenConnectIfNeeded {
    [self connect];
//    return;
//    NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
//    NSString *documentsDirectory = [pathArray objectAtIndex:0];
//    NSString *path = [documentsDirectory stringByAppendingPathComponent:kRawDataFileName];
//    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
//        PackageProcessor *processor = [[PackageProcessor alloc] init];
//        [processor processPackage:[[NSFileManager defaultManager] contentsAtPath:path]];
//    } else {
//        [self connect];
//    }
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
}

- (void)readPacketHeader {
    [self.asyncSocket readDataToLength:kHeaderLength withTimeout:-1.0 tag:kConnectPacket];
}

- (void)processPacketHeader:(NSData *)data {
//    void *bytes = [data bytes];
//    uint32_t seq = OSReadBigInt32(bytes, 0);
//    uint32_t chk = OSReadBigInt32(bytes, 4);
//    uint32_t length = OSReadBigInt32(bytes, 8);
    uint32_t length = [self.processor processNewPacketHeader:data];
    [self.asyncSocket readDataToLength:length withTimeout:-1.0 tag:kConnectPacketData];

}

- (void)processPacketData:(NSData *)data {
//    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

//    NSLog(@"string %@", string);


//    if ([[NSFileManager defaultManager] fileExistsAtPath:soundPath])
//    {
//        NSURL *soundURL = [NSURL fileURLWithPath:soundPath isDirectory:NO];
//    }
//    [self.asyncSocket disconnect];
    [self.processor processCurrentPacketWithData:data];
    [self readPacketHeader];
}

- (void)readDumpData {
    [self.asyncSocket readDataWithTimeout:-1.0 tag:kConnectDump];
//    [self.asyncSocket readDataToData:[GCDAsyncSocket ZeroData] withTimeout:-1.0 tag:kConnectDump];
}

- (void)processDumpData:(NSData *)data {

    NSString *filename = kRawDataFileName;
    NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
    NSString *documentsDirectory = [pathArray objectAtIndex:0];
    NSString *soundPath = [documentsDirectory stringByAppendingPathComponent:filename];

    [data writeToFile:soundPath atomically:YES];

    PackageProcessor *processor = [[PackageProcessor alloc] init];
    [processor processPackage:data];
//    [self.asyncSocket disconnect];
}

- (BOOL)isValidData:(NSData *)data {
    return NO;
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
    if (self.stage == kConnectHandShakeSuccess) {
        [self.processor completeProcessing];
    }
}

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    NSLog(@"did accept new socket");
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    if (tag == kConnectHandShake) {
        [self processHandShake:data];
    } else if (tag == kConnectHandShakeSuccess) {
        NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"message %@", message);
        NSLog(@"connection success, begin decoding");
        self.stage = kConnectHandShakeSuccess;
        [self readPacketHeader];
//        [self readDumpData];

    } else if (tag == kConnectPacket){
//        void *bytes = [data bytes];
//        int32_t elem = OSReadLittleInt32(bytes, i);
//        unsigned char aBuffer[4];
//        [data getBytes:aBuffer range:NSMakeRange(8, 4)];
//        NSLog(@"%d", aBuffer[0]);
//        int length = [[NSNumber numberWithUnsignedChar:aBuffer] intValue];

//        NSData *data = ...; // Initialized earlier
//        NSLog(@"%@", data);
//        unsigned int *values = [data bytes], cnt = [data length]/sizeof(unsigned int);
//        for (int i = 0; i < cnt; ++i)
//            NSLog(@"%u\n", values[i]);
        [self processPacketHeader:data];
    } else if (tag == kConnectPacketData) {
        [self processPacketData:data];
    } else if (tag == kConnectDump) {
        [self processDumpData:data];
    }
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    if (tag == kConnectIdentify) {
        [self.asyncSocket readDataToData:[GCDAsyncSocket LFData] withTimeout:-1.0 tag:kConnectHandShakeSuccess];
//        [self.asyncSocket readDataToLength:kHeaderLength withTimeout:-1.0 tag:kConnectPacket];
//        [self.asyncSocket readDataToData:[GCDAsyncSocket ZeroData] withTimeout:-1.0 tag:kConnectDump];
    }
}

@end
