//
//  PEPQRCodeViewController.m
//  LivePusher
//
//  Created by 李沛倬 on 2019/7/19.
//  Copyright © 2019 pep. All rights reserved.
//

#import "PEPQRCodeViewController.h"
#import "PEPSweepCodeView.h"

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>


@interface PEPQRCodeViewController ()<AVCaptureMetadataOutputObjectsDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, PEPSweepCodeViewDelegate>
{
    BOOL _navigationBarHidden;
    BOOL _navigationBarTranslucent;
    UIImage * _navigationBarBackgroundImage;
    UIColor * _navigationBarBarTintColor;
    UIColor * _navigationBarTintColor;
    UIColor * _navigationBarTitleColor;
    NSDictionary<NSAttributedStringKey, id> * _navigationBarTitleTextAttributes;
}

@property (nonatomic, strong) PEPSweepCodeView *sweepView;

@property (nonatomic, strong) AVCaptureSession *session;

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@property (nonatomic, strong) UINavigationBar *navigationBar;

@end

@implementation PEPQRCodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    [self setupNavigationItem];
    [self setupSubView];
    
    __weak typeof(self) weakself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakself setupCamera];
    });
    
    [self addNotification];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self configationNavigationBar];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self resetNavigaitonBar];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)addNotification {
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(background) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(foreground) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(didChangeRotate:) name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
}


// MARK: - UI

- (void)configationNavigationBar {
    UINavigationBar *navigationBar = self.navigationController.navigationBar;

    _navigationBarTranslucent = navigationBar.translucent;
    _navigationBarBackgroundImage = [navigationBar backgroundImageForBarMetrics:UIBarMetricsDefault];
    _navigationBarBarTintColor = navigationBar.barTintColor;
    _navigationBarTintColor = navigationBar.tintColor;
    _navigationBarTitleTextAttributes = navigationBar.titleTextAttributes;
    
    navigationBar.translucent = true;
//    [navigationBar setBackgroundImage:[UIImage.alloc init] forBarMetrics:UIBarMetricsDefault];
    navigationBar.barTintColor = UIColor.blackColor;
    navigationBar.tintColor = UIColor.whiteColor;
    navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: UIColor.whiteColor};

}

- (void)resetNavigaitonBar {
    UINavigationBar *navigationBar = self.navigationController.navigationBar;

    navigationBar.translucent = _navigationBarTranslucent;
    navigationBar.barTintColor = _navigationBarBarTintColor;
//    [navigationBar setBackgroundImage:_navigationBarBackgroundImage forBarMetrics:UIBarMetricsDefault];
    navigationBar.tintColor = _navigationBarTintColor;
    navigationBar.titleTextAttributes = _navigationBarTitleTextAttributes;
}


- (void)setupSubView {
//    self.navigationItem.title = @"扫一扫";
    self.view.backgroundColor = UIColor.blackColor;
    
    self.sweepView = [PEPSweepCodeView.alloc initWithFrame:self.view.bounds];
    self.sweepView.delegate = self;
    
    [self.view addSubview:self.sweepView];
}

- (void)setupNavigationItem {
    UIBarButtonItem *photoLibrary = [[UIBarButtonItem alloc] initWithTitle:@"相册" style:UIBarButtonItemStylePlain target:self action:@selector(jumpPickerController)];
    self.navigationController.navigationItem.rightBarButtonItem = photoLibrary;
}


#pragma mark - PEPSweepCodeViewDelegate

- (void)onClickSweepCodeViewLightButton:(BOOL)isLight {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    if ([device hasTorch]) {
        [device lockForConfiguration:nil];
        [device setTorchMode:isLight ? AVCaptureTorchModeOn : AVCaptureTorchModeOff];
        [device unlockForConfiguration];
    }
    
}

- (void)background {
    [self stopCamera];
}

- (void)foreground {
    [self setupCamera];
}


#pragma mark - 从相册中读取照片

- (void)jumpPickerController {
    
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    imagePicker.delegate = self;
    [self presentViewController:imagePicker animated:YES completion:nil];
    
}


#pragma mark - 二维码扫描

- (void)setupCamera {
    if (self.session) { return; }
    
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];  //读取设备授权状态
    if (authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied) {
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"当前没有摄像头权限，请在设置中打开相机权限" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *settingAction = [UIAlertAction actionWithTitle:@"去设置" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            if ([[UIApplication sharedApplication] canOpenURL:url]) {
                [[UIApplication sharedApplication] openURL:url];
            }
        }];
        
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:nil];
        
        [alert addAction:settingAction];
        [alert addAction:cancel];
        
        [self presentViewController:alert animated:true completion:nil];
        return;
    }
    
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    output.rectOfInterest = CGRectMake(0.05, 0.2, 0.7, 0.6);
    
    
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    
    if ([session canSetSessionPreset:AVCaptureSessionPresetHigh]) {
        session.sessionPreset = AVCaptureSessionPresetHigh;
    }
    if ([session canAddInput:input]) {
        [session addInput:input];
    }
    if ([session canAddOutput:output]) {
        [session addOutput:output];
    }
    
    NSArray *metadataObjectTypes = @[AVMetadataObjectTypeQRCode, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code];
    NSMutableArray *availableTypes = [NSMutableArray arrayWithCapacity:metadataObjectTypes.count];
    for (AVMetadataObjectType type in metadataObjectTypes) {
        if ([output.availableMetadataObjectTypes containsObject:type]) {
            [availableTypes addObject:type];
        }
    }
    output.metadataObjectTypes = availableTypes;
    
    AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:session];
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if (orientation == UIInterfaceOrientationLandscapeLeft) {
        previewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
    }else if(orientation == UIInterfaceOrientationLandscapeRight){
        previewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
    }else{
        previewLayer.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    }
    previewLayer.frame = self.view.bounds;
    
    [self.view.layer addSublayer:previewLayer];
    [self.view bringSubviewToFront:self.sweepView];
    
    
    if (session.inputs.count > 0 && availableTypes.count > 0) {
        [session startRunning];
    }
    
    self.session = session;
    self.previewLayer = previewLayer;
}

- (void)stopCamera {
    
    [self.session stopRunning];
    self.session = nil;
    
    [self.previewLayer removeFromSuperlayer];
}
-(void)stopScan{
    [self.session stopRunning];
}
-(void)startScan{
    if (self.session.inputs.count > 0 ) {
        [self.session startRunning];
    }
}
-(void)setIs_result:(BOOL)is_result{
    _is_result = is_result;
    if (!is_result) {
//        [self showPrompt];
        [self startScan];
        
    }
}
-(void)showPrompt{
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"提示" message:@"二维码验证失败，请重新扫描" preferredStyle:UIAlertControllerStyleAlert];
     __weak typeof(self) weakself = self;
    UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakself startScan];
    }];
    [alertVC addAction:confirm];
    [self presentViewController:alertVC animated:YES completion:nil];
}
#pragma mark - - - 二维码扫描代理方法

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    
    if (metadataObjects.count > 0) {
        AVMetadataMachineReadableCodeObject *metadataObj = metadataObjects[0];
        
        NSLog(@"扫描的数据:%@", metadataObj);
        
        //判断回传的数据类型
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            if (self.callbackSweepResultForLogin) {
                //扫描登录逻辑
                [self playSound];
                [self stopScan];
                NSString *sweepCodeString;
                if (metadataObj.stringValue) {
                    sweepCodeString = metadataObj.stringValue;
                }
                if (self.callbackSweepResultForLogin) {
                    self.callbackSweepResultForLogin(sweepCodeString);
                }
            }else{
                // 二维码
                [self playSound];
                
                [self stopCamera];
                
                NSString *sweepCodeString;
                if (metadataObj.stringValue) {
                    sweepCodeString = metadataObj.stringValue;
                }
                
                [self.navigationController popViewControllerAnimated:YES];

                if (self.callbackSweepResult) {
                    self.callbackSweepResult(sweepCodeString);
                }
            }
            
            
        }
    }
}

#pragma mark - 音效

void soundCompleteCallBack(SystemSoundID soundID, void *clientData) {
    
    NSLog(@"音效播放完成");
}


- (void)playSound {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:kSoundNameQRCodeSweepSucceed ofType:nil];
    NSURL *fileUrl = [NSURL URLWithString:filePath];
    
//    if (fileUrl == nil) {
//        AudioServicesPlayAlertSound(1200);
//    } else {
        SystemSoundID soundID = 6;
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)(fileUrl), &soundID);
        AudioServicesAddSystemSoundCompletion(soundID, NULL, NULL, soundCompleteCallBack, NULL);
        AudioServicesPlaySystemSound(soundID);
//    }
    
}



#pragma mark - 从相册中识别二维码, 并进行界面跳转

- (void)scanQRCodeFromPhotosInTheAlbum:(UIImage *)image {
    
    // CIDetector(CIDetector可用于人脸识别)进行图片解析，从而使我们可以便捷的从相册中获取到二维码
    // 声明一个CIDetector，并设定识别类型 CIDetectorTypeQRCode
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy : CIDetectorAccuracyHigh}];
    
    // 取得识别结果
    NSArray<CIFeature *> *features = [detector featuresInImage:[CIImage imageWithCGImage:image.CGImage]];
    
    NSString *scannedResult = @"";
    for (CIQRCodeFeature *feature in features) {
        scannedResult = [NSString stringWithFormat:@"%@\n%@", scannedResult, feature.messageString];
    }
    
    NSLog(@"result:%@", scannedResult);

    [self playSound];
    [self stopCamera];
    
    [self.navigationController popViewControllerAnimated:YES];
    
    if (self.callbackSweepResult) {
        self.callbackSweepResult(scannedResult);
    }
    
}

// MARK: - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    
    NSLog(@"info - - - %@", info);
    
    [self dismissViewControllerAnimated:YES completion:^{
        [self scanQRCodeFromPhotosInTheAlbum:[info objectForKey:UIImagePickerControllerOriginalImage]];
    }];
}
/* !!!: 改动处 */
- (void)didChangeRotate:(NSNotification*)notice {
    if ([[UIDevice currentDevice] orientation] == UIInterfaceOrientationLandscapeRight) {
        
        self.previewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
        
    } else if([[UIDevice currentDevice] orientation] == UIInterfaceOrientationLandscapeLeft) {
        
        self.previewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
        
    }
}

// MARK: - Interface Orientation

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    if([[UIDevice currentDevice].model containsString:@"iPad"]) {
        return UIInterfaceOrientationLandscapeRight;
    }else{
        return UIInterfaceOrientationPortrait;
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if([[UIDevice currentDevice].model containsString:@"iPad"]) {
           return UIInterfaceOrientationMaskLandscape;
       }else{
           return UIInterfaceOrientationMaskPortrait;
       }
}

- (BOOL)shouldAutorotate {
    if([[UIDevice currentDevice].model containsString:@"iPad"]) {
           return YES;
       }else{
           return NO;
       }
}



@end
