//
//  ViewController.m
//  airtimetcp
//
//  Created by Jason Liang on 11/22/14.
//  Copyright (c) 2014 Jason Liang. All rights reserved.
//

#import "ViewController.h"
#import "NetworkManager.h"

@interface ViewController ()

@property (nonatomic, strong) NetworkManager *networkManager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.networkManager = [[NetworkManager alloc] init];
    [self.networkManager processFirstThenConnectIfNeeded];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
