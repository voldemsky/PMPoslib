//
//  TextViewCtrl.m
//  RNlib
//
//  Created by 289124787@qq.com on 2018/7/12.
//  Copyright © 2018年 suixingpay. All rights reserved.
//

#import "TextViewCtrl.h"
#import <React/RCTRootView.h>
@interface TextViewCtrl ()

@end

@implementation TextViewCtrl

- (void)viewDidLoad {
    [super viewDidLoad];
    NSURL *jsCodeLocation = [NSURL
                             URLWithString:@"http://localhost:8081/index.bundle?platform=ios"];
    RCTRootView *rootView =
    [[RCTRootView alloc] initWithBundleURL : jsCodeLocation
                         moduleName        : @"TestMPOSRN"
                         initialProperties : @{
                                               @"routeName": @"root"
                                               }
                         launchOptions     : nil];
    UIViewController *vc = [[UIViewController alloc] init];
    vc.view = rootView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
