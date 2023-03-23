//
//  AUIUgsvOpenModuleHelper.m
//  AlivcUgsvDemo
//
//  Created by Bingo on 2022/6/15.
//

#import "AUIUgsvOpenModuleHelper.h"
#import "AUIUgsvPath.h"
#import "AUIUgsvMacro.h"

#import "AUIPhotoPicker.h"
#import "AUIVideoRecorder.h"
#import "AUIVideoCrop.h"
#import "AUIMediaPublisher.h"
#import "NHAVEditor.h"
#import "AlivcUgsvSDKHeader.h"
#ifndef USING_SVIDEO_BASIC
#import "AUIVideoEditor.h"
#import "AUIVideoTemplateListViewController.h"
#endif // USING_SVIDEO_BASIC

#ifdef INCLUDE_QUEEN
@interface AUIUgsvCheckQueenModel : NSObject<QueenMaterialDelegate>

@property (nonatomic, copy) void (^CheckResult)(BOOL completed);
@property (nonatomic, weak) AVProgressHUD *hub;

@end

@implementation AUIUgsvCheckQueenModel

+ (AUIUgsvCheckQueenModel *)sharedInstance {
    static AUIUgsvCheckQueenModel *_instance = nil;
    if (!_instance) {
        _instance = [AUIUgsvCheckQueenModel new];
    }
    return _instance;
}

+ (void)checkWithCurrentView:(UIView *)view completed:(void (^)(BOOL completed))completed {
    [self sharedInstance].CheckResult = completed;
    [[self sharedInstance] startCheckWithCurrentView:view];
}

- (void)startCheckWithCurrentView:(UIView *)view {
    
    BOOL result = [[QueenMaterial sharedInstance] requestMaterial:kQueenMaterialModel];
    if (!result) {
        if (self.CheckResult) {
            self.CheckResult(YES);
        }
    }
    else {
        [self.hub hideAnimated:NO];
        
        AVProgressHUD *loading = [AVProgressHUD ShowHUDAddedTo:view animated:YES];
        loading.labelText = AUIUgsvGetString(@"正在下载美颜模型中，请等待");
        self.hub = loading;
        
        [QueenMaterial sharedInstance].delegate = self;
    }
}

#pragma mark - QueenMaterialDelegate

- (void)queenMaterialOnReady:(kQueenMaterialType)type
{
    // 资源下载成功
    if (type == kQueenMaterialModel) {
        [self.hub hideAnimated:YES];
        self.hub = nil;
        if (self.CheckResult) {
            self.CheckResult(YES);
        }
    }
}

- (void)queenMaterialOnProgress:(kQueenMaterialType)type withCurrentSize:(int)currentSize withTotalSize:(int)totalSize withProgess:(float)progress
{
    // 资源下载进度回调
    if (type == kQueenMaterialModel) {
        NSLog(@"====正在下载资源模型，进度：%f", progress);
    }
}

- (void)queenMaterialOnError:(kQueenMaterialType)type
{
    // 资源下载出错
    if (type == kQueenMaterialModel){
        [self.hub hideAnimated:YES];
        self.hub = nil;
        if (self.CheckResult) {
            self.CheckResult(NO);
        }
    }
}

@end

#endif // INCLUDE_QUEEN

@implementation AUIUgsvPublishParamInfo
+ (AUIUgsvPublishParamInfo *) InfoWithSaveToAlbum:(BOOL)saveToAlbum needToPublish:(BOOL)needToPublish {
    AUIUgsvPublishParamInfo *info = [AUIUgsvPublishParamInfo new];
    info.saveToAlbum = saveToAlbum;
    info.needToPublish = needToPublish;
    return info;
}
- (instancetype)init {
    self = [super init];
    if (self) {
        _saveToAlbum = YES;
        _needToPublish = NO;
    }
    return self;
}
@end


@interface AUIUgsvOpenModuleHelper ()<NHAVEditorProtocol>
@property (nonatomic, strong) NHAVEditor *mediaEditor;
@property (nonatomic, strong) CALayer *watermarkLayer;
@end

@implementation AUIUgsvOpenModuleHelper

static AliyunVideoCodecType s_convertCodec(AliyunRecorderEncodeMode mode) {
    if (mode == AliyunRecorderEncodeMode_HardCoding) {
        return AliyunVideoCodecHardware;
    }
    return AliyunVideoCodecTypeAuto;
}

#ifndef USING_SVIDEO_BASIC
static AUIVideoOutputParam * s_convertRecordToEdit(AUIRecorderConfig *config) {
    AUIVideoOutputParam *param = [[AUIVideoOutputParam alloc] initWithOutputSize:config.videoConfig.resolution];
    param.fps = config.videoConfig.fps;
    param.gop = config.videoConfig.gop;
    param.bitrate = config.videoConfig.bitrate;
    param.videoQuality = config.videoConfig.videoQuality;
    param.scaleMode = config.videoConfig.scaleMode;
    param.codecType = s_convertCodec(config.videoConfig.encodeMode);
    return param;
}
#endif // USING_SVIDEO_BASIC

+ (void)openRecorder:(UIViewController *)currentVC
              config:(AUIRecorderConfig *)config
           enterEdit:(BOOL)enterEdit
        publishParam:(AUIUgsvPublishParamInfo *)publishParam {
    
    void (^openBlock)(AUIRecorderConfig *, AUIUgsvPublishParamInfo *) = ^(AUIRecorderConfig *config, AUIUgsvPublishParamInfo *publishParam){
        
        if (!enterEdit && !config.mergeOnFinish) {
            publishParam.saveToAlbum = NO;
        }
        
        __weak typeof(currentVC) weakVC = currentVC;
        AUIVideoRecorder *recorder = [[AUIVideoRecorder alloc] initWithConfig:config onCompletion:^(AUIVideoRecorder *recorderSelf,
                                                                                                    NSString *taskPath,
                                                                                                    NSString * _Nullable outputPath,
                                                                                                    NSError * _Nullable error) {
            if (error) {
                NSString *errMsg = [NSString stringWithFormat:@"%@ : %@", AUIUgsvGetString(@"完成录制失败"), error.localizedDescription];
                [AVToastView show:errMsg view:weakVC.view position:AVToastViewPositionTop];
                return;
            }
            
#ifndef USING_SVIDEO_BASIC
            if (enterEdit) {
                AUIVideoEditor *editor = nil;
                if (config.mergeOnFinish) {
                    AUIVideoOutputParam *editParam = s_convertRecordToEdit(config);
                    AliyunClip *clip = [[AliyunClip alloc] initWithVideoPath:outputPath animDuration:0];
                    editor = [[AUIVideoEditor alloc] initWithClips:@[clip] withParam:editParam];
                }
                else {
                    editor = [[AUIVideoEditor alloc] initWithTaskPath:taskPath];
                }
                
                editor.saveToAlbumExportCompleted = publishParam.saveToAlbum;
                editor.needToPublish = publishParam.needToPublish;
                [weakVC.navigationController pushViewController:editor animated:YES];
                return;
            }
#endif // USING_SVIDEO_BASIC
            
            NSCAssert(config.mergeOnFinish, @"不合并结束只能去编辑");
            if (publishParam.saveToAlbum) {
                [AUIPhotoLibraryManager saveVideoWithUrl:[NSURL fileURLWithPath:outputPath] location:nil completion:^(PHAsset * _Nonnull asset, NSError * _Nonnull error) {
                    if (error) {
                        [AVToastView show:AUIUgsvGetString(@"保存相册失败") view:recorderSelf.view position:AVToastViewPositionMid];
                    }
                    else {
                        [AVToastView show:AUIUgsvGetString(@"保存相册成功") view:recorderSelf.view position:AVToastViewPositionMid];
                    }
                }];
            }
            
            if (!publishParam.needToPublish) {
                return;
            }
            
            AUIMediaPublisher *publisher = [[AUIMediaPublisher alloc] initWithVideoFilePath:outputPath withThumbnailImage:nil];
            publisher.onFinish = ^(UIViewController * _Nonnull current, NSError * _Nullable error, id  _Nullable product) {
                if (error) {
                    [AVAlertController showWithTitle:AUIUgsvGetString(@"出错了") message:error.description needCancel:NO onCompleted:^(BOOL isCanced) {
                        [current.navigationController popToViewController:recorderSelf animated:YES];
                    }];
                }
                else {
                    BOOL isPublish = [current isKindOfClass:AUIMediaPublisher.class];
                    [AVAlertController showWithTitle:nil message:isPublish ? AUIUgsvGetString(@"发布成功") : AUIUgsvGetString(@"导出成功") needCancel:NO onCompleted:^(BOOL isCanced) {
                        [current.navigationController popToViewController:recorderSelf animated:YES];
                    }];
                }
            };
            [recorderSelf.navigationController pushViewController:publisher animated:YES];
        }];
        [weakVC.navigationController pushViewController:recorder animated:YES];
    };
    
    
    AUIUgsvPublishParamInfo *thisPublishParam = publishParam;
    if (!thisPublishParam) {
        thisPublishParam = [AUIUgsvPublishParamInfo new];
    }
    AUIRecorderConfig *thisConfig = config;
    if (!thisConfig) {
        thisConfig = [AUIRecorderConfig new];
    }
#ifdef INCLUDE_QUEEN
    [AUIUgsvCheckQueenModel checkWithCurrentView:currentVC.view completed:^(BOOL completed) {
        if (completed) {
            openBlock(thisConfig, thisPublishParam);
        }
        else {
            [AVAlertController show:AUIUgsvGetString(@"美颜模型无法加载，退出") vc:currentVC];
        }
    }];
#else
    openBlock(thisConfig, thisPublishParam);
#endif // INCLUDE_QUEEN
    
}

+ (void)openEditor:(UIViewController *)currentVC
             param:(AUIVideoOutputParam *)param
      publishParam:(AUIUgsvPublishParamInfo *)publishParam {
#ifdef USING_SVIDEO_BASIC
    [AVAlertController show:@"当前SDK不支持"];
#else // USING_SVIDEO_BASIC
    if (!publishParam) {
        publishParam = [AUIUgsvPublishParamInfo new];
    }
    
    __weak typeof(currentVC) weakVC = currentVC;
    AUIPhotoPicker *picker = [[AUIPhotoPicker alloc] initWithMaxPickingCount:6 withAllowPickingImage:YES withAllowPickingVideo:YES withTimeRange:CMTimeRangeMake(CMTimeMake(100, 1000), CMTimeMake(3600*1000, 1000))];
    [picker onSelectionCompleted:^(AUIPhotoPicker * _Nonnull sender, NSArray<AUIPhotoPickerResult *> * _Nonnull results) {
        if (results.count > 0) {
            NSMutableArray<AliyunClip *> *clips = [NSMutableArray array];
            [results enumerateObjectsUsingBlock:^(AUIPhotoPickerResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.filePath.length == 0) {
                    return;
                }
                if (obj.model.type == AUIPhotoAssetTypePhoto) {
                    AliyunClip *clip = [[AliyunClip alloc] initWithImagePath:obj.filePath duration:obj.model.assetDuration animDuration:0];
                    [clips addObject:clip];
                }
                else {
                    AliyunClip *clip = [[AliyunClip alloc] initWithVideoPath:obj.filePath animDuration:0];
                    [clips addObject:clip];
                }
            }];
            if (clips.count > 0) {
                [sender dismissViewControllerAnimated:NO completion:^{
                    AUIVideoEditor *editor = [[AUIVideoEditor alloc] initWithClips:clips withParam:param];
                    editor.saveToAlbumExportCompleted = publishParam.saveToAlbum;
                    editor.needToPublish = publishParam.needToPublish;
                    [weakVC.navigationController pushViewController:editor animated:YES];
                    
                }];
            }
            else {
                [AVAlertController show:AUIUgsvGetString(@"选择的视频出错了或无权限") vc:sender];
            }
        }
    } withOutputDir:[AUIUgsvPath cacheDir]];
    [currentVC av_presentFullScreenViewController:picker animated:YES completion:nil];
#endif
}

+ (void)openClipper:(UIViewController *)currentVC
              param:(AUIVideoOutputParam *)param
       publishParam:(AUIUgsvPublishParamInfo *)publishParam {
    if (!publishParam) {
        publishParam = [AUIUgsvPublishParamInfo new];
    }
    
    __weak typeof(currentVC) weakVC = currentVC;
    AUIPhotoPicker *picker = [[AUIPhotoPicker alloc] initWithMaxPickingCount:1 withAllowPickingImage:NO withAllowPickingVideo:YES withTimeRange:kCMTimeRangeZero];
    [picker onSelectionCompleted:^(AUIPhotoPicker * _Nonnull sender, NSArray<AUIPhotoPickerResult *> * _Nonnull results) {
        if (results.firstObject && results.firstObject.filePath.length > 0) {
            [sender dismissViewControllerAnimated:NO completion:^{
                [self addwatermarktovideo:results.firstObject.filePath andVideoInfo:results.firstObject];
//                [self addWatermarkWith:results.firstObject];
                AUIVideoCrop *crop = [[AUIVideoCrop alloc] initWithFilePath:results.firstObject.filePath withParam:param];
                crop.saveToAlbumExportCompleted = publishParam.saveToAlbum;
                crop.needToPublish = publishParam.needToPublish;
                [weakVC.navigationController pushViewController:crop animated:YES];
            }];
        }
        else {
            [AVAlertController show:AUIUgsvGetString(@"选择的视频出错了或无权限") vc:sender];
        }
    } withOutputDir:[AUIUgsvPath cacheDir]];
    
    [currentVC av_presentFullScreenViewController:picker animated:YES completion:nil];
}

+ (void)openTemplateList:(UIViewController *)currentVC {
#ifdef USING_SVIDEO_BASIC
    [AVAlertController show:@"当前SDK不支持"];
#else // USING_SVIDEO_BASIC
    if (![AliyunAETemplateManager canSupport]) {
        [AVAlertController show:@"当前机型不支持"];
        return;
    }
    AUIVideoTemplateListViewController *vc = [[AUIVideoTemplateListViewController alloc] init];
    [currentVC.navigationController pushViewController:vc animated:YES];
#endif
}

+ (void)addWatermarkWith:(AUIPhotoPickerResult*)pickerResult {
    AUIUgsvOpenModuleHelper* helper = [[AUIUgsvOpenModuleHelper alloc]init];
    NSURL *sourceURL = [NSURL fileURLWithPath:pickerResult.filePath];
    [helper.mediaEditor setInputVideoURL:sourceURL];
}

+ (void)addwatermarktovideo:(NSString*)videoPath andVideoInfo:(AUIPhotoPickerResult*)videoInfo {
    //1.拿到资源
    
    NSDictionary *opts = [NSDictionary dictionaryWithObject:@(YES) forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    //视频资源NSURL *sourceURL = [NSURL fileURLWithPath:pickerResult.filePath];
    AVURLAsset * videoAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:videoPath] options:opts];
    AVAssetTrack *videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    //2.创建视频合成文件
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    
    //3.视频轨道插入素材
    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
    
    CMTime startTime = kCMTimeZero;
    CMTime endTime = CMTimeMakeWithSeconds(videoInfo.model.assetDuration, 300);
    CMTime start = CMTimeMake(0, 1000);
    CMTime duration = videoAssetTrack.timeRange.duration;
    [videoTrack insertTimeRange:CMTimeRangeFromTimeToTime(start, duration)
                        ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
                         atTime:kCMTimeZero error:nil];
    
    //4.音频轨道
    AVMutableCompositionTrack * audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    //音频采集通道
    AVAssetTrack * audioAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    [audioTrack insertTimeRange:CMTimeRangeFromTimeToTime(startTime, endTime) ofTrack:audioAssetTrack atTime:kCMTimeZero error:nil];
    
    //5.合成视频
    //一个指令，决定一个timeRange内每个轨道的状态，包含多个layerInstruction
    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruction.timeRange = CMTimeRangeFromTimeToTime(kCMTimeZero, videoTrack.timeRange.duration);
    //在一个指令的时间范围内，某个轨道的状态
    AVMutableVideoCompositionLayerInstruction *videolayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    
    BOOL isVideoAssetPortrait_  = NO;
    CGAffineTransform videoTransform = videoAssetTrack.preferredTransform;
    if (videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0) {
        //        videoAssetOrientation_ = UIImageOrientationRight;
        isVideoAssetPortrait_ = YES;
    }
    if (videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0) {
        //        videoAssetOrientation_ =  UIImageOrientationLeft;
        isVideoAssetPortrait_ = YES;
    }
    //调整视频方向
    [videolayerInstruction setTransform:videoAssetTrack.preferredTransform atTime:kCMTimeZero];
    [videolayerInstruction setOpacity:0.0 atTime:endTime];
    mainInstruction.layerInstructions = [NSArray arrayWithObjects:videolayerInstruction,nil];
    
    //6.AVMutableVideoComposition：管理所有视频轨道，可以决定最终视频的尺寸，裁剪需要在这里进行
    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
    
    CGSize naturalSize;
    if(isVideoAssetPortrait_){
        naturalSize = CGSizeMake(videoAssetTrack.naturalSize.height, videoAssetTrack.naturalSize.width);
    } else {
        naturalSize = videoAssetTrack.naturalSize;
    }
    
    float renderWidth, renderHeight;
    renderWidth = naturalSize.width;
    renderHeight = naturalSize.height;
    mainCompositionInst.renderSize = CGSizeMake(renderWidth, renderHeight);
    mainCompositionInst.renderSize = CGSizeMake(renderWidth, renderHeight);
    mainCompositionInst.instructions = [NSArray arrayWithObject:mainInstruction];
    mainCompositionInst.frameDuration = CMTimeMake(1, 25);
    
    //7.添加水印
    //水印
     CALayer *imgLayer = [CALayer layer];
     imgLayer.contents = (id)AUIUgsvGetImage(@"ic_ugsv_clipper").CGImage;
    CGSize imgSize = AUIUgsvGetImage(@"ic_ugsv_clipper").size;
     imgLayer.bounds = CGRectMake(0,0, imgSize.width, imgSize.height);
     imgLayer.position = CGPointMake(naturalSize.width/2.0, naturalSize.height/2.0);
//    imgLayer.position = CGPointMake(40, naturalSize.height - imgSize.height);
     
    
     // 2 - The usual overlay
//     CALayer *overlayLayer = [CALayer layer];
////     [overlayLayer addSublayer:subtitle1Text];
//     [overlayLayer addSublayer:imgLayer];
//     overlayLayer.frame = CGRectMake(0, 0, naturalSize.width, naturalSize.height);
//     [overlayLayer setMasksToBounds:YES];
     
     CALayer *parentLayer = [CALayer layer];
     CALayer *videoLayer = [CALayer layer];
     parentLayer.frame = CGRectMake(0, 0, naturalSize.width, naturalSize.height);
     videoLayer.frame = CGRectMake(0, 0, naturalSize.width, naturalSize.height);
     [parentLayer addSublayer:videoLayer];
     [parentLayer addSublayer:imgLayer];
//
//    //第二个水印,并加入动画
//    CALayer *coverImgLayer = [CALayer layer];
//    coverImgLayer.contents = (id)AUIUgsvGetImage(@"ic_ugsv_more").CGImage;
////    [coverImgLayer setContentsGravity:@"resizeAspect"];
//    coverImgLayer.bounds =  CGRectMake(50, 200,210, 50);
//    coverImgLayer.position = CGPointMake(naturalSize.width/4.0, naturalSize.height/4.0);
//    [parentLayer addSublayer:coverImgLayer];
//
//     //设置封面
//     CABasicAnimation *anima = [CABasicAnimation animationWithKeyPath:@"opacity"];
//     anima.fromValue = [NSNumber numberWithFloat:1.0f];
//     anima.toValue = [NSNumber numberWithFloat:0.0f];
//     anima.repeatCount = 0;
//     anima.duration = 5.0f;  //5s之后消失
//     [anima setRemovedOnCompletion:NO];
//     [anima setFillMode:kCAFillModeForwards];
//     anima.beginTime = AVCoreAnimationBeginTimeAtZero;
//     [coverImgLayer addAnimation:anima forKey:@"opacityAniamtion"];
     //主要是下面这个方法
    mainCompositionInst.animationTool = [AVVideoCompositionCoreAnimationTool
                                  videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    
    //8.获取文件路径导出视频
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *myPathDocs =  [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4",@"wartermark"]];
    unlink([myPathDocs UTF8String]);
    NSURL* videoUrl = [NSURL fileURLWithPath:myPathDocs];
    AVAssetExportSession* exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition
                                                presetName:AVAssetExportPresetHighestQuality];
    exporter.outputURL=videoUrl;
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    exporter.shouldOptimizeForNetworkUse = YES;
    exporter.videoComposition = mainCompositionInst;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            //这里是输出视频之后的操作，做你想做的
            [self exportDidFinish:exporter];
        });
    }];
}
+ (void)exportDidFinish:(AVAssetExportSession*)session {
    if (session.status == AVAssetExportSessionStatusCompleted) {
        NSURL *outputURL = session.outputURL;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            __block PHObjectPlaceholder *placeholder;
            if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(outputURL.path)) {
                NSError *error;
                [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
                    PHAssetChangeRequest* createAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:outputURL];
                    placeholder = [createAssetRequest placeholderForCreatedAsset];
                } error:&error];
                if (error) {
                    
                    [AVToastView show:[NSString stringWithFormat:@"%@",error] view:[UIApplication sharedApplication].keyWindow position:AVToastViewPositionMid];
                }
                else{
                    [AVToastView show:@"视频已经保存到相册" view:[UIApplication sharedApplication].keyWindow position:AVToastViewPositionMid];
                }
            }else {
                [AVToastView show:@"视频保存相册失败，请设置软件读取相册权限" view:[UIApplication sharedApplication].keyWindow position:AVToastViewPositionMid];
            }
        });
    }
}


+ (void)openPickerToPublish:(UIViewController *)currentVC {
    __weak typeof(currentVC) weakVC = currentVC;
    AUIPhotoPicker *picker = [[AUIPhotoPicker alloc] initWithMaxPickingCount:1 withAllowPickingImage:NO withAllowPickingVideo:YES withTimeRange:kCMTimeRangeZero];
    [picker onSelectionCompleted:^(AUIPhotoPicker * _Nonnull sender, NSArray<AUIPhotoPickerResult *> * _Nonnull results) {
        if (results.firstObject) {
            [sender dismissViewControllerAnimated:NO completion:^{
                [self openPublisher:weakVC result:results.firstObject];
            }];
        }
    } withOutputDir:[AUIUgsvPath cacheDir]];
    
    [currentVC av_presentFullScreenViewController:picker animated:YES completion:nil];
}

+ (void)openPublisher:(UIViewController *)currentVC result:(AUIPhotoPickerResult *)result  {
    __weak typeof(currentVC) weakVC = currentVC;
    AUIMediaPublisher *publisher = [[AUIMediaPublisher alloc] initWithVideoFilePath:result.filePath withThumbnailImage:result.model.thumbnailImage];
    publisher.onFinish = ^(UIViewController * _Nonnull current, NSError * _Nullable error, id  _Nullable product) {
        if (error) {
            [AVAlertController showWithTitle:AUIUgsvGetString(@"出错了") message:error.description needCancel:NO onCompleted:^(BOOL isCanced) {
                [current.navigationController popToViewController:weakVC animated:YES];
            }];
        }
        else {
            [AVAlertController showWithTitle:nil message:AUIUgsvGetString(@"发布成功了") needCancel:NO onCompleted:^(BOOL isCanced) {
                [current.navigationController popToViewController:weakVC animated:YES];
            }];
        }
    };
    [currentVC.navigationController pushViewController:publisher animated:YES];
}

#pragma mark - lazy

- (NHAVEditor *)mediaEditor {
  if (!_mediaEditor) {
    _mediaEditor = [[NHAVEditor alloc] init];
    _mediaEditor.delegate = self;
  }
  return _mediaEditor;
}

@end

