//
//  PEPSweepCodeView.h
//  LivePusher
//
//  Created by 李沛倬 on 2019/7/19.
//  Copyright © 2019 pep. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// 修改下方的几个字符串以定制扫描框

/// 扫描框中间上下滚动的扫描线图片名
static NSString * const kImageNameQRCodeSweepLine = @"QRCodeSweepLine";
/// 扫描框左上角图片名
static NSString * const kImageNameQRCodeTopLeft = @"QRCodeTopLeft";
/// 扫描框右上角图片名
static NSString * const kImageNameQRCodeTopRight = @"QRCodeTopRight";
/// 扫描框左下角图片名
static NSString * const kImageNameQRCodeBottomLeft = @"QRCodeBottomLeft";
/// 扫描框右下角图片名
static NSString * const kImageNameQRCodeBottmRight = @"QRCodeBottmRight";
/// 扫描完成后播放的声音文件名（位于NSBundle.mainBundle下）
static NSString * const kSoundNameQRCodeSweepSucceed = @"QRCodeSweepSucceed.wav";


@protocol PEPSweepCodeViewDelegate <NSObject>

- (void)onClickSweepCodeViewLightButton:(BOOL)isLight;

@end

@interface PEPSweepCodeView : UIView

@property (nonatomic, weak) id<PEPSweepCodeViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
