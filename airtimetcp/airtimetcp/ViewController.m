//
//  ViewController.m
//  airtimetcp
//
//  Created by Jason Liang on 11/22/14.
//  Copyright (c) 2014 Jason Liang. All rights reserved.
//

#import "ViewController.h"
#import "NetworkManager.h"
#import <MessageUI/MessageUI.h>

@interface ViewController () <NetworkManagerDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) NetworkManager *networkManager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.networkManager = [[NetworkManager alloc] init];
    self.networkManager.delegate = self;
    [self.networkManager connect];

}

#pragma mark - NetworkManagerDelegate

- (void)updateStatusTo:(NSString *)statusText {
    self.statusLabel.text = statusText;
}

#pragma mark - 
- (void)showEmail:(NSString*)file {

    NSString *emailTitle = @"Raw Sound PCM file";
    NSString *messageBody = @"Decode with 16-bitPCM at 8000Hz";
    NSArray *toRecipents = @[];

    MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
    mc.mailComposeDelegate = self;
    [mc setSubject:emailTitle];
    [mc setMessageBody:messageBody isHTML:NO];
    [mc setToRecipients:toRecipents];

    // Determine the file name and extension
    NSArray *filepart = [file componentsSeparatedByString:@"."];
    NSString *filename = [[[filepart objectAtIndex:0] componentsSeparatedByString:@"/"] lastObject];
    NSString *extension = [filepart objectAtIndex:1];

    // Get the resource path and read the file using NSData
    NSData *fileData = [NSData dataWithContentsOfFile:file];

    // Determine the MIME type
    NSString *mimeType;
    if ([extension isEqualToString:@"zip"]) {
        mimeType = @"application/zip";
    }

    // Add attachment
    [mc addAttachmentData:fileData mimeType:mimeType fileName:filename];

    // Present mail view controller on screen
    [self presentViewController:mc animated:YES completion:NULL];

}

#pragma mark - MFMailComposeViewControllerDelegate

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail sent");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail sent failure: %@", [error localizedDescription]);
            break;
        default:
            break;
    }

    // Close the Mail Interface
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
