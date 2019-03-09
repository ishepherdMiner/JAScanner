//
//  JAScanView.m
//  AFNetworking
//
//  Created by Shepherd on 2019/3/6.
//

#import "JAScanView.h"
#import <YYCategories/YYCategories.h>

NSString *JAScanBundlePath = @"Frameworks/JAScanner.framework/Scanner";
NSString *JAScanBorderPath = @"qrcode_border";
NSString *JAScanLinePath = @"qrcode_scanline_qrcode";
NSString *JAScanBulbPath = @"bulb";

@implementation JAScanView

- (instancetype)initWithFrame:(CGRect)frame
                  visibleArea:(CGRect)visibleArea {
    if (self = [super initWithFrame:frame]) {        
        NSString *bundlePath = [[NSBundle mainBundle] pathForResource:JAScanBundlePath ofType:@"bundle"];
        NSBundle *extBundle = [NSBundle bundleWithPath:bundlePath];
        NSString *borderPath = [extBundle pathForResource:[JAScanBorderPath stringByAppendingString:@"@2x"] ofType:@"png"];
        
        UIImage *borderImage;
        if ([JAScanBorderPath isEqualToString:@"qrcode_border"]) {
            borderImage = [[UIImage imageWithContentsOfFile:borderPath] resizableImageWithCapInsets:UIEdgeInsetsMake(25, 25, 25.5, 25.5) resizingMode:UIImageResizingModeTile];
        }
        self.visibleBoundsImageView = [[UIImageView alloc] initWithImage:borderImage];
        self.visibleBoundsImageView.frame = visibleArea;
        
        NSString *scanLinePath = [extBundle pathForResource:[NSString stringWithFormat:@"%@@%@x",JAScanLinePath,@(UIScreen.mainScreen.scale).stringValue] ofType:@"png"];
        UIImage *scanningImage = [UIImage imageWithContentsOfFile:scanLinePath];
        self.scanningImageView = [[UIImageView alloc] initWithImage:scanningImage];
        self.scanningImageView.frame = visibleArea;
        
        self.coverView = [[UIView alloc] initWithFrame:frame];
        self.coverView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        
        NSString *bulbPath = [extBundle pathForResource:[NSString stringWithFormat:@"%@@2x",JAScanBulbPath] ofType:@"png"];
        UIImage *bulbImage = [UIImage imageNamed:bulbPath];
        self.bulbImageView = [[UIImageView alloc] initWithImage:bulbImage];
        self.bulbImageView.alpha = 0;
        self.bulbImageView.size = CGSizeMake(self.bulbImageView.size.width, self.bulbImageView.size.height);
        self.bulbImageView.centerX = self.visibleBoundsImageView.centerX;
        self.bulbImageView.bottom = self.visibleBoundsImageView.bottom + 50 + self.bulbImageView.height * 0.5;
        
        typeof(self) weakself = self;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithActionBlock:^(id  _Nonnull sender) {
            if (weakself.bulbBlock) {
                weakself.bulbBlock(sender);
            }
        }];
        self.bulbImageView.userInteractionEnabled = YES;
        [self.bulbImageView addGestureRecognizer:tap];
        
        [self addSubview:self.visibleBoundsImageView];
        [self addSubview:self.scanningImageView];
        [self addSubview:self.coverView];
        [self addSubview:self.bulbImageView];
    }
    
    return self;
}

@end
