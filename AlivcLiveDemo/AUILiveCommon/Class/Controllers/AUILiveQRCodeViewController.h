//
//  AUILiveSweepCodeViewController.h
//  AlivcLiveCaptureDev
//
//  Created by lyz on 2017/9/28.
//  Copyright © 2017年 Alivc. All rights reserved.
//

#import "AVBaseViewController.h"

@interface AUILiveQRCodeViewController : AVBaseViewController

@property (nonatomic, copy) void(^backValueBlock)(BOOL scaned, NSString *sweepString);

@end
