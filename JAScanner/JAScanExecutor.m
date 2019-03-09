//
//  JAScanExecutor.m
//  AFNetworking
//
//  Created by Shepherd on 2019/3/5.
//

#import "JAScanExecutor.h"
#import <AVFoundation/AVFoundation.h>
#import "JAScanView.h"
#import <YYCategories/YYCategories.h>

static const char *kScanQRCodeQueueName = "ScanQRCodeQueue";
static const char *kVideoOutputQueueName = "VideoOutputQueue";

@interface JAScanExecutor () <
AVCaptureVideoDataOutputSampleBufferDelegate,
AVCaptureMetadataOutputObjectsDelegate
>

@property (nonatomic,strong) AVCaptureSession *captureSession;
@property (nonatomic,strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic,strong) AVCaptureMetadataOutput *captureMetadataOutput;
@property (nonatomic,weak) AVCaptureVideoDataOutput *captureVideoDataOutput;
@property (nonatomic,weak) AVCaptureDevice *captureDevice;
@property (nonatomic,weak) JAScanView *scanView;

@property (nonatomic,assign) BOOL lockBulb;

/** Recognize callback */
@property (nonatomic,copy) void (^completionHandler)(NSString *qrString);
@end

@implementation JAScanExecutor

- (void)runWithView:(UIView *)view visibleArea:(CGRect)frame container:(JAScanView *)container completionHandler:(void (^)(NSString *))completionHandler {
    self.completionHandler = completionHandler;
    [self setupWithView:view visibleArea:frame container:container];
}

- (void)startExecutor {
    if (!self.captureSession.isRunning) {
        [self.captureSession startRunning];
    }
}

- (void)stopExecutor {
    if (self.captureSession.isRunning) {
        [self.captureSession stopRunning];
    }
}

- (void)setupWithView:(UIView *)view visibleArea:(CGRect)frame container:(JAScanView *)container{
    [self startExecutor];
    self.videoPreviewLayer.frame = view.layer.bounds;
    [view.layer addSublayer:self.videoPreviewLayer];
    
    // [view.layer addSublayer:container.visibleBoundsImageView.layer];
    // [view.layer addSublayer:container.scanningImageView.layer];
    // [view.layer addSublayer:container.coverView.layer];
    [view.layer addSublayer:container.layer];
    self.scanView = container;
    typeof(self) weakself = self;
    self.scanView.bulbBlock = ^(id  _Nonnull sender) {
        weakself.flashLightMode = !weakself.flashLightMode;
    };
    [self createMaskWithCoverView:container.coverView visibleArea:frame];
    [self setLimitBoundsWithView:view visibleArea:frame];
}

- (void)createMaskWithCoverView:(UIView *)coverView
                    visibleArea:(CGRect)frame{
    // 贝塞尔曲线 画一个带有圆角的矩形
    UIBezierPath *bpath = [UIBezierPath bezierPathWithRect:UIScreen.mainScreen.bounds];
    // 贝塞尔曲线 画一个矩形
    // [bpath appendPath:[UIBezierPath bezierPathWithArcCenter:scanner.appearance.coverView.center radius:150 startAngle:0 endAngle:2*M_PI clockwise:NO]];
    [bpath appendPath:[[UIBezierPath bezierPathWithRect:frame] bezierPathByReversingPath]];
    // [bpath appendPath:[UIBezierPath bezierPathWithArcCenter:CGPointMake(coverView.centerX,frame.origin.y + frame.size.height + 50) radius:30 startAngle:0 endAngle:2*M_PI clockwise:NO]];
    
    // 创建一个CAShapeLayer 图层
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.path = bpath.CGPath;
    
    // 添加图层蒙板
    coverView.layer.mask = shapeLayer;
}

- (void)setLimitBoundsWithView:(UIView *)view visibleArea:(CGRect)frame {
    // 1.获取屏幕的frame
    // CGRect viewRect = self.view.frame;
    CGRect viewRect = view.frame;
    // 2.获取扫描容器的frame
    // CGRect containerRect = self.containLayerView.frame;
    CGRect containerRect = frame;
    
    CGFloat x = containerRect.origin.y / viewRect.size.height;
    CGFloat y = containerRect.origin.x / viewRect.size.width;
    CGFloat width = containerRect.size.height / viewRect.size.height;
    CGFloat height = containerRect.size.width / viewRect.size.width;
    
    // rectOfInterest控制扫描的边界
    _captureMetadataOutput.rectOfInterest = CGRectMake(x, y, width, height);
}

#pragma mark - LazyLoad
- (AVCaptureSession *)captureSession {
    if (!_captureSession) {
        NSError * error;
        _captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        // 初始化输入流
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:_captureDevice error:&error];
        if (input == nil) { return nil; }
#if DEBUG
        if (error) { NSLog(@"%@",error); }
#endif
        // 创建会话
        _captureSession = [[AVCaptureSession alloc] init];
        // 添加输入流
        [_captureSession addInput:input];
        // 初始化 & 添加输出流
        [_captureSession addOutput:self.captureMetadataOutput];
        // 用于检测环境光强度
        AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
        [_captureSession addOutput:output];
        dispatch_queue_t dispatchOutputQueue = dispatch_queue_create(kVideoOutputQueueName, NULL);
        [output setSampleBufferDelegate:self queue:dispatchOutputQueue];
        _captureVideoDataOutput = output;
        
        // 创建dispatch queue.
        dispatch_queue_t dispatchQueue;
        dispatchQueue = dispatch_queue_create(kScanQRCodeQueueName, NULL);
        [_captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
        // 设置元数据类型 AVMetadataObjectTypeQRCode
        // [_captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];
        if (self.metaDataObjects.count <= 0) {
            self.metaDataObjects = @[AVMetadataObjectTypeQRCode];
        }
        [_captureMetadataOutput setMetadataObjectTypes:self.metaDataObjects];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(subjectAreaDidChange:)
                                                     name:AVCaptureDeviceSubjectAreaDidChangeNotification
                                                   object:_captureDevice];
        
        // 创建输出对象
        _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
        [_videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    }
    return _captureSession;
}

- (AVCaptureMetadataOutput *)captureMetadataOutput {
    if (!_captureMetadataOutput) {
        _captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
    }
    return _captureMetadataOutput;
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects
       fromConnection:(AVCaptureConnection *)connection {
    
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
        NSString *result;
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            result = metadataObj.stringValue;
            dispatch_async(dispatch_get_main_queue(), ^{
                if (result) {
                    [self stopExecutor];
                    // 扫描到内容,关闭手电筒
                    self.flashLightMode = NO;
                    self.completionHandler(result);                    
                }
            });
        }
    }
}

-  (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    CFDictionaryRef metadataDict = CMCopyDictionaryOfAttachments(NULL,sampleBuffer, kCMAttachmentMode_ShouldPropagate);
    NSDictionary *metadata = [[NSMutableDictionary alloc] initWithDictionary:(__bridge NSDictionary*)metadataDict];
    CFRelease(metadataDict);
    NSDictionary *exifMetadata = [[metadata objectForKey:(NSString *)kCGImagePropertyExifDictionary] mutableCopy];
    float brightnessValue = [[exifMetadata objectForKey:(NSString *)kCGImagePropertyExifBrightnessValue] floatValue];
    
    // AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    BOOL result = [self.captureDevice hasTorch];
    // 在光线弱的情况打开闪光灯
    //    if ((brightnessValue < -0.2) && result && self.captureDevice.torchMode == AVCaptureTorchModeOff) {
    //        self.flashLightMode = YES;
    //        [UIView animateWithDuration:1.33 animations:^{
    //            self.scanView.bulbImageView.alpha = 1.0;
    //        }];
    //    }
    if ((brightnessValue < -0.2) && result && self.captureDevice.torchMode == AVCaptureTorchModeOff) {        
        [UIView animateWithDuration:1.33 animations:^{
            self.scanView.bulbImageView.alpha = 1.0;
        }];
    }
}

- (void)setFlashLightMode:(BOOL)flashLightMode {
    _flashLightMode = flashLightMode;
    if (flashLightMode == AVCaptureFlashModeOn) {
        if ([self.captureDevice isTorchModeSupported:AVCaptureTorchModeOff]) {
            [self.captureDevice lockForConfiguration:nil];
            [self.captureDevice setTorchMode: AVCaptureTorchModeOn];
            [self.captureDevice unlockForConfiguration];
        }
    }else{
        if ([self.captureDevice isTorchModeSupported:AVCaptureTorchModeOn]) {
            [self.captureDevice lockForConfiguration:nil];
            [self.captureDevice setTorchMode: AVCaptureTorchModeOff];
            [self.captureDevice unlockForConfiguration];
        }
    }
}

- (void)subjectAreaDidChange:(NSNotification *)notification{
    // 先进行判断是否支持控制对焦
    if (_captureDevice.isFocusPointOfInterestSupported &&[_captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        NSError *error = nil;
        // 对cameraDevice进行操作前，需要先锁定，防止其他线程访问，
        [_captureDevice lockForConfiguration:&error];
        [_captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
        // [self focusAtPoint:self.scanView.center];
        [_captureDevice setFocusPointOfInterest:self.scanView.center];
        //操作完成后，记得进行unlock。
        [_captureDevice unlockForConfiguration];
    }
}

@end
