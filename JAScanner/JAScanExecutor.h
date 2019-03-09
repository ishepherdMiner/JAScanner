//
//  JAScanExecutor.h
//  AFNetworking
//
//  Created by Shepherd on 2019/3/5.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class JAScanView;

@interface JAScanExecutor : NSObject

@property (nonatomic,assign) BOOL flashLightMode;

/** Recognize types */
@property (nonatomic,copy) NSArray *metaDataObjects;

- (void)runWithView:(UIView *)view
        visibleArea:(CGRect)frame
         container:(JAScanView *)container
  completionHandler:(void (^)(NSString *result))completionHandler;

- (void)startExecutor;
- (void)stopExecutor;

@end

NS_ASSUME_NONNULL_END
