//
//  JAScanView.h
//  AFNetworking
//
//  Created by Shepherd on 2019/3/6.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

UIKIT_EXTERN NSString *JAScanBundlePath;
UIKIT_EXTERN NSString *JAScanBorderPath;
UIKIT_EXTERN NSString *JAScanLinePath;

@interface JAScanView : UIView

@property (nonatomic,strong) UIImageView *visibleBoundsImageView;
@property (nonatomic,strong) UIImageView *scanningImageView;
@property (nonatomic,strong) UIView *coverView;
@property (nonatomic,strong) UIImageView *bulbImageView;

@property (nonatomic,copy) void (^bulbBlock)(id sender);

- (instancetype)initWithFrame:(CGRect)frame
                  visibleArea:(CGRect)visibleArea;

@end

NS_ASSUME_NONNULL_END
