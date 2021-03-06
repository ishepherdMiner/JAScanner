//
//  ViewController.m
//  JAScannerRunner
//
//  Created by Shepherd on 2019/3/7.
//  Copyright © 2019 Shepherd. All rights reserved.
//

#import "ViewController.h"
#import <JAScanner/JAScanner.h>

@interface ViewController ()

@property (nonatomic,strong) JAScanner *scanner;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    JAScanner *scanner = [JAScanner scanAtView:self.view];
    [scanner startWithCompletionHandler:^(NSString * _Nonnull result) {
        NSLog(@"%@",result);
    }];    
    self.scanner = scanner;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.scanner.state = JAScannerStateLeaveScene;
}


@end
