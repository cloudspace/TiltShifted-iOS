//
//  CSOverlayViewController.m
//  TiltShifted
//
//  Created by Joseph Lorich on 6/27/13.
//  Copyright (c) 2013 Cloudspace. All rights reserved.
//

#import "CSOverlayViewController.h"
#import "GPUImage.h"
#import "UIImage+Normalizer.h"

@interface CSOverlayViewController ()

@end

@implementation CSOverlayViewController


/*!
 * Creates a blurred draggable overlay view on an imageview
 */
- (id)initWithImageView:(UIImageView*)imageView{
  self = [self init];
  
  if (self)
  {
    CGRect bounds = imageView.bounds;
    
    _topBlurDistance = 1.0f;
    _bottomBlurDistance = 1.0f;
    
    self.image_raw = imageView.image;
    self.imageView_base = imageView;
    
    
    // Get the blurred image
    CGFloat scaleFactor = MIN(bounds.size.height/imageView.image.size.height, bounds.size.width/imageView.image.size.width);
    scaledFrame = CGRectMake(0, 0, imageView.image.size.width * scaleFactor, imageView.image.size.height * scaleFactor);
    scaledFrame.origin.x = bounds.size.width/2.0f - scaledFrame.size.width/2.0f;
    scaledFrame.origin.y = bounds.size.height/2.0f - scaledFrame.size.height/2.0f;
    self.view_top    = [[UIView alloc] initWithFrame:CGRectMake(scaledFrame.origin.x, scaledFrame.origin.y, scaledFrame.size.width, scaledFrame.size.height/3.0f)];
    self.view_bottom = [[UIView alloc] initWithFrame:CGRectMake(scaledFrame.origin.x, scaledFrame.origin.y + scaledFrame.size.height*2.0f/3.0f, scaledFrame.size.width, scaledFrame.size.height/3.0f)];
    
    [self.view_top    setClipsToBounds:YES];
    [self.view_bottom setClipsToBounds:YES];
    
    self.image_blur = [self blurImage:imageView.image];
    self.imageView_top    = [[UIImageView alloc] initWithImage:self.image_blur];
    self.imageView_bottom = [[UIImageView alloc] initWithImage:self.image_blur];
    [self.imageView_top    setContentMode:UIViewContentModeScaleAspectFit];
    [self.imageView_bottom setContentMode:UIViewContentModeScaleAspectFit];

    CGFloat blurAmount = 0.1f * self.image_raw.size.height * (scaledFrame.size.height/self.image_raw.size.height);
    
    // Set top gradient layer
    CAGradientLayer *gl_top = [CAGradientLayer layer];
    gl_top.frame      = self.view_top.bounds;
    gl_top.colors     = [NSArray arrayWithObjects:(id)[UIColor whiteColor].CGColor, (id)[UIColor clearColor].CGColor, nil];
    gl_top.startPoint = CGPointMake(0.0f, 1.0f - blurAmount/self.view_top.frame.size.height);
    gl_top.endPoint   = CGPointMake(0.0f, 1.0f);
    self.view_top.layer.mask = gl_top;
    
    // Set bottom gradient layer
    CAGradientLayer *gl_bottom = [CAGradientLayer layer];
    gl_bottom.frame      = CGRectMake(0, 0, self.view_bottom.frame.size.width, self.view_bottom.frame.size.height);
    gl_bottom.colors     = [NSArray arrayWithObjects:(id)[UIColor clearColor].CGColor, (id)[UIColor whiteColor].CGColor, nil];
    gl_bottom.startPoint = CGPointMake(0.0f, 0.0f);
    gl_bottom.endPoint   = CGPointMake(0.0f, blurAmount/self.view_bottom.frame.size.height);
    self.view_bottom.layer.mask = gl_bottom;
    
    
    // Set blurred image frames
    [self.imageView_top    setFrame:CGRectMake(0, 0, scaledFrame.size.width, scaledFrame.size.height)];
    [self.imageView_bottom    setFrame:CGRectMake(0,-(scaledFrame.size.height-self.view_bottom.frame.size.height),scaledFrame.size.width, scaledFrame.size.height)];

    // Place blurred images in their appropriate views
    [self.view_top    addSubview:self.imageView_top];
    [self.view_bottom addSubview:self.imageView_bottom];

    
    // Handle gestures
    UIPanGestureRecognizer *topPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panTop:)];
    [self.view_top addGestureRecognizer:topPanGestureRecognizer];

    UIPanGestureRecognizer *bottomPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panBottom:)];
    [self.view_bottom addGestureRecognizer:bottomPanGestureRecognizer];
    
    
    // Add blur views to superview
    [self.view addSubview:self.view_top];
    [self.view addSubview:self.view_bottom];
  }
  
  return self;
}

/*!
 * Lays out the overlay views on device rotation
 */
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
  // Animate size adjustments for blurred views
  [UIView animateWithDuration:duration
                        delay:0
                      options: UIViewAnimationOptionCurveEaseInOut
                   animations:^{
                     
                     
                     
                     float width  = UIInterfaceOrientationIsPortrait(toInterfaceOrientation) ? [UIScreen mainScreen].bounds.size.width  : [UIScreen mainScreen].bounds.size.height;
                     float height = UIInterfaceOrientationIsPortrait(toInterfaceOrientation) ? self.imageView_base.bounds.size.height  - ([[UIScreen mainScreen] bounds].size.width - self.imageView_base.bounds.size.width): self.imageView_base.bounds.size.width  - ([[UIScreen mainScreen] bounds].size.height - self.imageView_base.bounds.size.height);
                     
                     UIImageView *imageView = self.imageView_base;
                     CGRect bounds = CGRectMake(0, 0, width, height);
                     
                     // Get the blurred image
                     CGFloat scaleFactor = MIN(height/imageView.image.size.height,width/imageView.image.size.width);
                     scaledFrame = CGRectMake(0, 0, imageView.image.size.width * scaleFactor, imageView.image.size.height * scaleFactor);
                     scaledFrame.origin.x = bounds.size.width/2 - scaledFrame.size.width/2;
                     scaledFrame.origin.y = bounds.size.height/2 - scaledFrame.size.height/2;
                     
                     [self.view_top         setFrame:CGRectMake(scaledFrame.origin.x, scaledFrame.origin.y, scaledFrame.size.width, scaledFrame.size.height/3)];
                     [self.imageView_top    setFrame:CGRectMake(0, 0, scaledFrame.size.width, scaledFrame.size.height)];
                     [self.view_top.layer.mask setFrame:CGRectMake(0, 0, self.view_top.frame.size.width, self.view_top.frame.size.height)];
                     
                     [self.view_bottom      setFrame:CGRectMake(scaledFrame.origin.x, scaledFrame.origin.y + scaledFrame.size.height*2/3, scaledFrame.size.width, scaledFrame.size.height/3)];
                     [self.imageView_bottom setFrame:CGRectMake(0, self.view_bottom.frame.size.height - scaledFrame.size.height, scaledFrame.size.width, scaledFrame.size.height)];
                     [self.view_bottom.layer.mask setFrame:CGRectMake(0, 0, self.view_bottom.frame.size.width, self.view_bottom.frame.size.height)];
                   }
                   completion:^(BOOL finished){
                     
                   }];
  
}


#pragma mark - Image Blurring Methods
/*!
 * Applies 2 passes of a 1.5px blur
 */
- (UIImage *) blurImage:(UIImage*)image
{
  NSInteger passes = MAX(image.size.width, image.size.height)/1000+1;
  NSLog(@"Blurring image with %d passes", passes);
  return [self blurImage:image passes:passes];
}

/*!
 * Applies a blur to the image for the number of passes given and returns it
 */
- (UIImage *) blurImage:(UIImage*)image passes:(NSInteger)passes
{
  
  UIImage *blurredImage = image;
  
  
  for (NSInteger i = 0; i < passes; i++)
  {
    GPUImageGaussianBlurFilter *blurFilter = [[GPUImageGaussianBlurFilter alloc] init];
    blurFilter.blurSize = 3;
    blurredImage = [blurFilter imageByFilteringImage:blurredImage];
  }
  
  return blurredImage;
}


#pragma mark - UIPanGestureRecognizerDelegate Methods
/*!
 * Handles panning on the top blurred view
 */
- (void)panTop:(UIPanGestureRecognizer*)pan
{
  CGPoint center = [pan locationInView:self.view.superview];

  if (pan.state == UIGestureRecognizerStateBegan)
  {
    lastStartingCenter = center;
  }
  
  CGRect frame = self.view_top.frame;
  
  CGFloat newHeight = self.view_top.frame.size.height + (center.y - lastStartingCenter.y);
  CGFloat newBlurDistance = _topBlurDistance + ((center.x - lastStartingCenter.x)/self.imageView_base.frame.size.width);
  
  if (newHeight < scaledFrame.size.height*.65 && newHeight > scaledFrame.size.height*.05)
  {
    frame.size.height = newHeight;
    [self.view_top setFrame:frame];
    
    CGFloat blurAmount = .1 * self.image_raw.size.height * (scaledFrame.size.height/self.image_raw.size.height);
    CGFloat blurCoefficient = 1/self.view_top.frame.size.height;
    
    if (newBlurDistance <= 1 && newBlurDistance > .15)
    {
      _topBlurDistance = newBlurDistance;
    }
    
    // Set top gradient layer
    CAGradientLayer *gl_top = [CAGradientLayer layer];
    gl_top.frame      = self.view_top.bounds;
    gl_top.colors     = [NSArray arrayWithObjects:(id)[UIColor whiteColor].CGColor, (id)[UIColor clearColor].CGColor, nil];
    gl_top.startPoint = CGPointMake(0.0f, (1.0f - blurAmount*blurCoefficient)*_topBlurDistance);
    gl_top.endPoint   = CGPointMake(0.0f, 1.0f);
    self.view_top.layer.mask = gl_top;


  }
  
  lastStartingCenter = center;
}

/*!
 * Handles panning on the bottom blurred view
 */
- (void)panBottom:(UIPanGestureRecognizer*)pan
{
  CGPoint center = [pan locationInView:self.view.superview];
  
  if (pan.state == UIGestureRecognizerStateBegan)
  {
    lastStartingCenter = center;
  }
  
  CGRect frame = self.view_bottom.frame;
  
  CGFloat newHeight = self.view_bottom.frame.size.height - (center.y - lastStartingCenter.y);
  CGFloat newBlurDistance = _bottomBlurDistance + ((center.x - lastStartingCenter.x)/self.imageView_base.frame.size.width);
  
  if (newHeight < scaledFrame.size.height*.65 && newHeight > scaledFrame.size.height*.05 + 44 )
  {
    // Move view down
    frame.origin.y += frame.size.height - newHeight;

    // Adjust height
    frame.size.height = newHeight;
    
    // Set frame

    [self.view_bottom setFrame:frame];
    [self.imageView_bottom setFrame:CGRectMake(0, frame.size.height - self.imageView_bottom.frame.size.height, self.imageView_bottom.frame.size.width, self.imageView_bottom.frame.size.height)];

    
    if (newBlurDistance <= 1 && newBlurDistance > .15)
    {
      _bottomBlurDistance = newBlurDistance;
    }
    
    
    CGFloat blurAmount = 0.1f * self.image_raw.size.height * (scaledFrame.size.height/self.image_raw.size.height)*(1/_bottomBlurDistance);
    
    CAGradientLayer *gl_bottom = [CAGradientLayer layer];
    gl_bottom.frame      = CGRectMake(0, 0, frame.size.width, frame.size.height);
    gl_bottom.colors     = [NSArray arrayWithObjects:(id)[UIColor clearColor].CGColor, (id)[UIColor whiteColor].CGColor, nil];
    gl_bottom.startPoint = CGPointMake(0.0f, 0.0f);
    gl_bottom.endPoint   = CGPointMake(0.0f, blurAmount/self.view_bottom.frame.size.height);
    self.view_bottom.layer.mask = gl_bottom;

  }

  lastStartingCenter = center;
}


@end
