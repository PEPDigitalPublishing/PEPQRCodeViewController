//
//  PEPQRCodeViewController.h
//  LivePusher
//
//  Created by 李沛倬 on 2019/7/19.
//  Copyright © 2019 pep. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PEPQRCodeViewController : UIViewController

@property (nonatomic, copy) void(^callbackSweepResult)(NSString *sweepResult);
///  扫描登录用
@property (nonatomic, copy) void(^callbackSweepResultForLogin)(NSString *sweepResult);

@property(nonatomic,assign)BOOL is_result;/**<  第一次扫描数据请求后台结果*/
@end

NS_ASSUME_NONNULL_END
