//
//  JAScanner.m
//  AFNetworking
//
//  Created by Shepherd on 2019/3/5.
//

#import "JAScanner.h"
#import "JAScanExecutor.h"
#import "JAScanView.h"
#import <AVFoundation/AVFoundation.h>
#import <YYCategories/YYCategories.h>

CGFloat visibleHeight = 200;
CGFloat visibleWidth = 200;
CGFloat animationDuration = 1.33;

@interface JAScanner ()

@property (nonatomic,strong) UIView *view;
@property (nonatomic,assign) CGRect visibleArea;

@property (nonatomic,strong) UIImageView *visibleBoundsImageView;
@property (nonatomic,strong) UIImageView *scanningImageView;

@property (nonatomic,strong) JAScanExecutor *executor;
@property (nonatomic,strong) JAScanView *containView;

@end

@implementation JAScanner

+ (instancetype)scanAtView:(UIView *)view {
    return [self scanAtView:view
                visibleArea:CGRectMake((view.width - visibleWidth) * 0.5,(view.height - visibleHeight) * 0.5, visibleWidth, visibleHeight)];
    
}

+ (instancetype)scanAtView:(UIView *)view
               visibleArea:(CGRect)frame {
    
    JAScanner *scanner = [[JAScanner alloc] init];
    scanner.view = view;
    scanner.visibleArea = frame;
    scanner.option = JAScannerOptionQR;
    scanner.executor = [[JAScanExecutor alloc] init];
    scanner.containView = [[JAScanView alloc] initWithFrame:view.bounds visibleArea:frame];
    
    if (scanner.areaImage) {
        scanner.containView.visibleBoundsImageView.image = scanner.areaImage;
    }
    
    if (scanner.scanningImage) {
        scanner.containView.scanningImageView.image = scanner.scanningImage;
    }
    
    [scanner.view addSubview:scanner.containView];
    
    [[NSNotificationCenter defaultCenter] addObserver:scanner selector:@selector(inactiveScan:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:scanner selector:@selector(activeScan:) name:UIApplicationWillEnterForegroundNotification object:nil];
    return scanner;
}

- (void)startWithCompletionHandler:(void (^)(NSString *))completionHandler {
    [self configureScanner];

    typeof(self) weakself = self;
    [self.executor runWithView:self.view
                   visibleArea:self.visibleArea
                     container:self.containView
             completionHandler:^(NSString * _Nonnull result) {
                 weakself.state = JAScannerStateCompleted;
                 completionHandler(result);
             }];    
    [self startAnimation];
    self.state = JAScannerStateScanning;
}

- (void)activeScan:(NSNotification *)sender {
    // current vc
    UIResponder *responder = self.containView.superview.nextResponder;
    BOOL isCurVC = NO;
    while (responder) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            UIViewController *vc = (UIViewController *)responder;
            isCurVC = (vc.isViewLoaded && vc.view.window);
            break;
        }else if (responder == nil) {
            break;
        }
        responder = responder.nextResponder;
    }
    if (isCurVC) {
        self.state = JAScannerStateScanning;
    }
}

- (void)inactiveScan:(NSNotification *)sender {
    self.state = JAScannerStateLeaveScene;
}

- (void)stopRecognize {
    [self.executor stopExecutor];
}

- (void)startAnimation {
    if (self.animateBlock) {
        self.animateBlock();
    }else {
        if ([UIView areAnimationsEnabled]) {
            self.containView.scanningImageView.bottom = self.visibleArea.origin.y;
            [UIView animateWithDuration:animateWithDuration animations:^{
                [UIView setAnimationRepeatCount:MAXFLOAT];
                self.containView.scanningImageView.bottom = self.visibleArea.origin.y + self.visibleArea.size.height;
                self.containView.scanningImageView.alpha = 0.0;
            } completion:^(BOOL finished) {
                self.containView.scanningImageView.alpha = 1.0;
            }];
        }
    }
}

- (void)stopAnimateion {
    [self.containView.scanningImageView.layer removeAllAnimations];
}

- (void)configureScanner {
    if (self.option & JAScannerOptionQR) {
        NSMutableArray *m = [NSMutableArray arrayWithCapacity:self.executor.metaDataObjects.count + 1];
        [m addObject:AVMetadataObjectTypeQRCode];
        self.executor.metaDataObjects = [m copy];
    }
    
    // Other scan && appearance adjust
    
    self.executor.flashLightMode = self.isBulb;
    self.containView.bulbImageView.hidden = self.isHideBulb;
    
    typeof(self) weakself = self;
    [self addObserverBlockForKeyPath:@"state" block:^(id  _Nonnull obj, id  _Nonnull oldVal, id  _Nonnull newVal) {
        if ([newVal integerValue] == JAScannerStateScanning) {
            [weakself.executor startExecutor];
            [weakself startAnimation];
        }else if ([newVal integerValue] == JAScannerStateCompleted) {
            [weakself stopAnimateion];
        }else if ([newVal integerValue] == JAScannerStateLeaveScene) {
            [weakself stopAnimateion];
            [weakself.executor stopExecutor];
        }
    }];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(activeScan:)];
    [self.containView.coverView addGestureRecognizer:tap];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeObserverBlocksForKeyPath:@"state"];
}

@end
