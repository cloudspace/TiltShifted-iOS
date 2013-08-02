//
//  CSOverlayViewController.h
//  TiltShifted
//
//  Created by Joseph Lorich on 6/27/13.
//  Copyright (c) 2013 Cloudspace. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * The camera overlay view controller
 */
@interface CSOverlayViewController : UIViewController <
  UIGestureRecognizerDelegate
>
{
  CGPoint lastStartingCenter;
  CGRect scaledFrame;
  CGFloat _blurSize;
  CGFloat _topFocusLevel;
  CGFloat _bottomFocusLevel;
  CGFloat _focusFallOffRate;
  CGFloat _topBlurDistance;
  CGFloat _bottomBlurDistance;
}


@property UIView *view_top;
@property UIView *view_bottom;
@property UIImage *image_raw;
@property UIImage *image_blur;
@property UIImageView *imageView_base;
@property UIImageView *imageView_top;
@property UIImageView *imageView_bottom;

- (id)initWithImageView:(UIImageView*)imageView;

@end
