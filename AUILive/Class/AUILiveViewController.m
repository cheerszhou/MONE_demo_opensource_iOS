//
//  AUILiveViewController.m
//  AlivcLivePusherDemo
//
//  Created by zzy on 2022/5/31.
//  Copyright © 2022 TripleL. All rights reserved.
//

#import "AUILiveViewController.h"
#import "AUILiveCameraPushModule.h"
#import "AUILiveRecordPushModule.h"
#import "AUILivePlayModule.h"
#import "AUILiveRtsPlayModule.h"
#import "AUILiveLinkMicModule.h"
#import "AUILivePKModule.h"

typedef NS_ENUM(NSUInteger, AUILiveModuleIndex) {
    AUILiveModuleIndexCameraPush = 1,
    AUILiveModuleIndexRecordPush,
    AUILiveModuleIndexPlayPull,
    AUILiveModuleIndexPlayRts,
    AUILiveModuleIndexLinkMic,
    AUILiveModuleIndexLinkPK,
};

@interface AUILiveViewController ()

@end

@implementation AUILiveViewController

- (instancetype)init {
    NSMutableArray *list = [NSMutableArray array];
   
    AVCommonListItem *item1 = [AVCommonListItem new];
    item1.title = AlivcLiveString(@"Camera Push");
    item1.info = AlivcLiveString(@"The demonstration of the camera push");
    item1.icon = AlivcLiveImage(@"zhibo_ic_tuiliu");
    item1.tag = AUILiveModuleIndexCameraPush;
    [list addObject:item1];
   
    if ([AUILiveRecordPushModule checkCanOpen]) {
        AVCommonListItem *item2 = [AVCommonListItem new];
        item2.title = AlivcLiveString(@"Record Push");
        item2.info = AlivcLiveString(@"The demonstration of the record push");
        item2.icon = AlivcLiveImage(@"zhibo_ic_luping");
        item2.tag = AUILiveModuleIndexRecordPush;
        [list addObject:item2];
    }

    AVCommonListItem *item3 = [AVCommonListItem new];
    item3.title = AlivcLiveString(@"Pull Play");
    item3.info = AlivcLiveString(@"The demonstration of the pull play");
    item3.icon = AlivcLiveImage(@"zhibo_ic_laliu");
    item3.tag = AUILiveModuleIndexPlayPull;
    [list addObject:item3];

    if ([AUILiveRtsPlayModule checkCanOpen]) {
        AVCommonListItem *item4 = [AVCommonListItem new];
        item4.title = AlivcLiveString(@"Rts Play");
        item4.info = AlivcLiveString(@"The demonstration of the rts play");
        item4.icon = AlivcLiveImage(@"zhibo_ic_laliu");
        item4.tag = AUILiveModuleIndexPlayRts;
        [list addObject:item4];
    }

    if ([AUILiveLinkMicModule checkCanOpen]) {
        AVCommonListItem *item5 = [AVCommonListItem new];
        item5.title = AlivcLiveString(@"Link Mic");
        item5.info = AlivcLiveString(@"The demonstration of the link mic");
        item5.icon = AlivcLiveImage(@"zhibo_ic_linkmic");
        item5.tag = AUILiveModuleIndexLinkMic;
        [list addObject:item5];
    }

    if ([AUILivePKModule checkCanOpen]) {
        AVCommonListItem *item6 = [AVCommonListItem new];
        item6.title = AlivcLiveString(@"PK");
        item6.info = AlivcLiveString(@"The demonstration of the PK");
        item6.icon = AlivcLiveImage(@"zhibo_ic_pk");
        item6.tag = AUILiveModuleIndexLinkPK;
        [list addObject:item6];
    }

   self = [super initWithItemList:list];
   if (self) {
   }
   return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.hiddenMenuButton = YES;
    self.titleView.text = AlivcLiveString(@"Live Demo");
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    AVCommonListItem *item = [self.itemList objectAtIndex:indexPath.row];
    if (item.tag == AUILiveModuleIndexCameraPush) {
        [self openCameraPush];
    }
    else if (item.tag == AUILiveModuleIndexRecordPush) {
        [self openRecordPush];
    }
    else if (item.tag == AUILiveModuleIndexPlayPull) {
        [self openPlay];
    }
    else if (item.tag == AUILiveModuleIndexPlayRts) {
        [self openRtsPlay];
    }
    else if (item.tag == AUILiveModuleIndexLinkMic) {
        [self openLinkMic];
    }
    else if (item.tag == AUILiveModuleIndexLinkPK) {
        [self openPK];
    }
}

- (void)openCameraPush {
    AUILiveCameraPushModule *module = [[AUILiveCameraPushModule alloc] initWithSourceViewController:self];
    [module open];
}

- (void)openRecordPush {
    AUILiveRecordPushModule *module = [[AUILiveRecordPushModule alloc] initWithSourceViewController:self];
    [module open];
}

- (void)openPlay {
    AUILivePlayModule *module = [[AUILivePlayModule alloc] initWithSourceViewController:self];
    [module open];
}

- (void)openRtsPlay {
    AUILiveRtsPlayModule *module = [[AUILiveRtsPlayModule alloc] initWithSourceViewController:self];
    [module open];
}

- (void)openLinkMic {
    AUILiveLinkMicModule *module = [[AUILiveLinkMicModule alloc] initWithSourceViewController:self];
    [module open];
}

- (void)openPK {
    AUILivePKModule *module = [[AUILivePKModule alloc] initWithSourceViewController:self];
    [module open];
}

@end
