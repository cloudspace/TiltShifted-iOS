//
//  CSHomeViewController.m
//  TiltShifted
//
//  Created by Joseph Lorich on 4/4/13.
//  Copyright (c) 2013 Cloudspace. All rights reserved.
//

// Frameworks
#import <Social/Social.h>
#import <Accounts/Accounts.h>
#import <QuartzCore/QuartzCore.h>
#import "GAI.h"
#import "Appirater.h"


// Plugins
#import "MBProgressHUD.h"
#import "GPUImage.h"
#import "UIImage+Normalizer.h"

// Controllers
#import "CSHomeViewController.h"
#import "CSRootViewController.h"
#import "CSOverlayViewController.h"

@interface CSHomeViewController ()

@end

@implementation CSHomeViewController

/*!
 * Set up base properties, load data, add observers
 */
- (void)viewDidLoad
{
  self.hasNavigationBar = NO;
  [super viewDidLoad];
  
  [self.label_instructions setAlpha:0.0f];
  
  NSString *deviceModel = [[UIDevice currentDevice] model];
  
  if ([deviceModel hasPrefix:@"iPhone"] || [deviceModel hasPrefix:@"iPod"])
  {
    // Use iPhone nibs
    [self.imageView_selectedImage setImage:[UIImage imageNamed:@"home.png"]];
  }
  else
  {
    // Use iPad nibs
    [self.imageView_selectedImage setImage:[UIImage imageNamed:@"home_iPad.png"]];
  }
  
  
  // Enable camera button if one is available
  if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
    [self.tabBarItem_camera setEnabled:YES];
  }
  
  #ifndef PRO_VERSION
    // Load ad
    [self requestInterstitialAd];
  #endif
  
  return;
}

/*!
 * Tracks through google analytics
 */
- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  
  id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
  [tracker sendView:@"Home View"];
}

/*!
 * Handles changes on interface rotation
 */
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
  // Handle changes on interface rotation
  [self.overlayViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}


#pragma mark - UI Helpers
/*!
 * Launches an action sheet with sharing options
 */
- (void) requestInterstitialAd
{
  self.interstitialAd = [[GADInterstitial alloc] init];
  self.interstitialAd.delegate = self;
  self.interstitialAd.adUnitID = @"a151f9692d97c6e";
  GADRequest *request = [GADRequest request];
  request.testDevices = @[@"813B1865-D42B-575D-9E94-227837248459"];
  [self.interstitialAd loadRequest:request];
}

/*!
 * Displays an intersitital ad if one is available, then requests a new ad
 */
- (void) displayInterstitialAdIfAvailable
{
  if (_hasBanner)
  {
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
      
      // Present advertisement
      [self.interstitialAd presentFromRootViewController:self];
      
    });
  }
}

/*!
 * Launches an action sheet with sharing options
 */
- (void) share
{
  UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Share via" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:Nil otherButtonTitles:@"Mail", @"Facebook", @"Twitter", nil];
  [actionSheet showInView:self.view];
}

/*!
 * Save to camera roll
 */
- (void) save
{

  [MBProgressHUD showHUDAddedTo:self.view animated:YES];
  
  dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    UIImage *renderedImage = [self renderBlurredImage];
    
    // Save the current photo
    UIImageWriteToSavedPhotosAlbum(renderedImage, nil, nil, nil);
    
    dispatch_async(dispatch_get_main_queue(), ^{
      [MBProgressHUD hideHUDForView:self.view animated:YES];
      
      [[[UIAlertView alloc] initWithTitle:@"Saved!"
                                  message:@"The tilt-shifted photo has been saved to your camera roll."
                                 delegate:self
                        cancelButtonTitle:nil
                        otherButtonTitles:@"Thanks!", nil
        ] show];
      
      // Log share with Google Analytics
      id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
      [tracker sendView:@"Saved to Camera Roll"];
      
      // Mark significant event with Appirater
      [Appirater userDidSignificantEvent:YES];
      
    });
  });

}

/*!
 * Hides the image edit bar if it's visible
 */
- (void)hideEditBar
{
  if (_editBarVisible)
  {
    [UIView animateWithDuration:0.5f animations:^{
      [self.view_edit_bottomSpace setConstant:-(self.view_edit.frame.size.height - self.tabBar.frame.size.height)];
      [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
      _editBarVisible = NO;
    }];
  }
}

/*!
 * Shows the image edit bar if it's hidden
 */
- (void)showEditBar
{
  if (!_editBarVisible)
  {
    [self.tabBar setSelectedItem:self.tabBarItem_edit];
    [UIView animateWithDuration:0.5f animations:^{
      [self.view_edit_bottomSpace setConstant:self.tabBar.frame.size.height];
      [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
      _editBarVisible = YES;
    }];
  }
}


#pragma mark - UIImage Rendering, Filtering, Gradients, and Masking
/*!
 * Renders a gradient as a UIImage
 */
- (UIImage *)renderGradientImageWithSize:(CGSize)size startPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint startColor:(UIColor *)startColor endColor:(UIColor*)endColor
{
  UIGraphicsBeginImageContext(size);
  
  CAGradientLayer *glayer_top = [[CAGradientLayer alloc] init];
  [glayer_top setFrame:CGRectMake(0,0,size.width,size.height)];

  glayer_top.startPoint = startPoint;
  glayer_top.endPoint   = endPoint;
  glayer_top.colors =  [NSArray arrayWithObjects:(id)startColor.CGColor, endColor.CGColor, nil];
  
  [glayer_top setNeedsDisplay];
  [glayer_top renderInContext:UIGraphicsGetCurrentContext()];
  
  UIImage *renderedTopGradient = UIGraphicsGetImageFromCurrentImageContext();

  UIGraphicsEndImageContext();
  
  return renderedTopGradient;
}

/*!
 * Applies a mask to a UIImage
 */
- (UIImage *)applyMask:(UIImage*)mask toImage:(UIImage*)image
{
  
  // Apply top mask
  CGImageRef originalMask = mask.CGImage;
  CGImageRef cgmask = CGImageMaskCreate(CGImageGetWidth(originalMask),
                                      CGImageGetHeight(originalMask),
                                      CGImageGetBitsPerComponent(originalMask),
                                      CGImageGetBitsPerPixel(originalMask),
                                      CGImageGetBytesPerRow(originalMask),
                                      CGImageGetDataProvider(originalMask), nil, YES);
  
  CGImageRef maskedImageRef = CGImageCreateWithMask(image.CGImage, cgmask);
  
  UIImage *maskedImage = [UIImage imageWithCGImage:maskedImageRef scale:image.scale orientation:image.imageOrientation];
  
  CGImageRelease(cgmask);
  CGImageRelease(maskedImageRef);
  
  return maskedImage;
}

/*!
 * Returns a rendered full-resolution blurred image
 */
- (UIImage *) renderBlurredImage
{
  CGRect overlayTopFrame = self.overlayViewController.view_top.frame;
  CGRect overlayBottomFrame = self.overlayViewController.view_bottom.frame;
 
  
  CGSize imageSize = self.overlayViewController.image_blur.size;

  CGFloat scale      = ((CGFloat)imageSize.width)/((CGFloat)overlayTopFrame.size.width);
  CGRect topFrame    = CGRectMake(0, 0, overlayTopFrame.size.width*scale, overlayTopFrame.size.height*scale);
  CGRect bottomFrame = CGRectMake(0, imageSize.height - overlayBottomFrame.size.height*scale, overlayBottomFrame.size.width*scale, overlayBottomFrame.size.height*scale);
  
  
  // Render Top Gradient
  UIImage *maskTop = [self renderGradientImageWithSize:topFrame.size
                                            startPoint:((CAGradientLayer*)self.overlayViewController.view_top.layer.mask).startPoint
                                              endPoint:((CAGradientLayer*)self.overlayViewController.view_top.layer.mask).endPoint
                                            startColor:[UIColor clearColor]
                                              endColor:[UIColor whiteColor]
                      ];
  
  
  // Render bottom Gradient
  UIImage *maskBottom = [self renderGradientImageWithSize:bottomFrame.size
                                               startPoint:((CAGradientLayer*)self.overlayViewController.view_bottom.layer.mask).startPoint
                                                 endPoint:((CAGradientLayer*)self.overlayViewController.view_bottom.layer.mask).endPoint
                                               startColor:[UIColor whiteColor]
                                                 endColor:[UIColor clearColor]
  ];
  
  
  // Crop top and bottom images appropriately
  CGImageRef topImageRef    = CGImageCreateWithImageInRect([self.overlayViewController.imageView_top.image    CGImage], topFrame);
  CGImageRef bottomImageRef = CGImageCreateWithImageInRect([self.overlayViewController.imageView_bottom.image CGImage], bottomFrame);
  
  // Apply masks to top and bottom images
  UIImage *topImage    = [self applyMask:maskTop    toImage:[UIImage imageWithCGImage:topImageRef]];
  UIImage *bottomImage = [self applyMask:maskBottom toImage:[UIImage imageWithCGImage:bottomImageRef]];

  // Release refs
  CGImageRelease(topImageRef);
  CGImageRelease(bottomImageRef);
  
  // Build overall view to render offscreen
  UIView *hiddenView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, imageSize.width, imageSize.height)];

  UIImageView *hiddenBaseImageView = [[UIImageView alloc] initWithImage:self.imageView_selectedImage.image];
  [hiddenBaseImageView setFrame:CGRectMake(0, 0, imageSize.width, imageSize.height)];

  [hiddenView setFrame:CGRectMake(0, 0, imageSize.width, imageSize.height)];
  [hiddenView addSubview:hiddenBaseImageView];
  
  UIImageView *hiddenTopImageview    = [[UIImageView alloc] initWithImage:topImage];
  UIImageView *hiddenBottomImageview = [[UIImageView alloc] initWithImage:bottomImage];
  
  
  [hiddenView       insertSubview:hiddenTopImageview    aboveSubview:hiddenBaseImageView];
  [hiddenTopImageview    setFrame:topFrame];
  
  [hiddenView       insertSubview:hiddenBottomImageview aboveSubview:hiddenBaseImageView];
  [hiddenBottomImageview setFrame:bottomFrame];
  

  // Render the offscreen view as an image and return
  UIGraphicsBeginImageContext(hiddenView.frame.size);
  [hiddenView.layer renderInContext:UIGraphicsGetCurrentContext()];
  
  UIImage *renderedImage = UIGraphicsGetImageFromCurrentImageContext();
  
  UIGraphicsEndImageContext();
  
  return renderedImage;
}

/*!
 * Applies the contrast, saturation, and brightness filters.
 */
- (IBAction) applyFilters
{
  NSLog(@"Applying Filters");
  [MBProgressHUD showHUDAddedTo:self.view animated:YES];
  
  [self.slider_brightness setEnabled:NO];
  [self.slider_contrast   setEnabled:NO];
  [self.slider_saturation setEnabled:NO];
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    UIImage *rawImage = self.overlayViewController.image_raw;
    UIImage *blurredImage = self.overlayViewController.image_blur;
    
    GPUImageContrastFilter   *cfilter1 = [[GPUImageContrastFilter alloc] init];
    [cfilter1 setContrast:self.slider_contrast.value];
    rawImage = [cfilter1 imageByFilteringImage:rawImage];
    
    GPUImageContrastFilter   *cfilter2 = [[GPUImageContrastFilter alloc] init];
    [cfilter2 setContrast:self.slider_contrast.value];
    blurredImage = [cfilter2 imageByFilteringImage:blurredImage];
    
    GPUImageSaturationFilter *sfilter1 = [[GPUImageSaturationFilter alloc] init];
    [sfilter1 setSaturation:self.slider_saturation.value];
    rawImage = [sfilter1 imageByFilteringImage:rawImage];

    GPUImageSaturationFilter *sfilter2 = [[GPUImageSaturationFilter alloc] init];
    [sfilter2 setSaturation:self.slider_saturation.value];
    blurredImage = [sfilter2 imageByFilteringImage:blurredImage];
    
    GPUImageBrightnessFilter *bfilter1 = [[GPUImageBrightnessFilter alloc] init];
    [bfilter1 setBrightness:self.slider_brightness.value];
    rawImage = [bfilter1 imageByFilteringImage:rawImage];

    GPUImageBrightnessFilter *bfilter2 = [[GPUImageBrightnessFilter alloc] init];
    [bfilter2 setBrightness:self.slider_brightness.value];
    blurredImage = [bfilter2 imageByFilteringImage:blurredImage];
    
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.overlayViewController.imageView_top    setImage:blurredImage];
      [self.overlayViewController.imageView_bottom setImage:blurredImage];
      [self.overlayViewController.imageView_base   setImage:rawImage];
      
      [self.slider_brightness setEnabled:YES];
      [self.slider_contrast   setEnabled:YES];
      [self.slider_saturation setEnabled:YES];

      [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    });
  });
}


#pragma mark - UITabBar delegate methods
/*!
 * Handle tab bar press
 */
- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
  [self hideEditBar];
  
  // We're just using the tab bar as a menu so deselect the items after a press
  [self.tabBar setSelectedItem:nil];
  
  if (item == self.tabBarItem_camera)
  {
    // Take a new photo
    self.imagePicker = [[UIImagePickerController alloc] init];
    self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.imagePicker.delegate = self;
    
    [self presentViewController:self.imagePicker animated:YES completion:nil];
    
  }
  else if (item == self.tabBarItem_photos)
  {
    // Select an existing photo
    self.imagePicker = [[UIImagePickerController alloc] init];
    self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    self.imagePicker.delegate = self;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
      // Handle iPad popover view
      self.popover = [[UIPopoverController alloc] initWithContentViewController:self.imagePicker];
      
      CGRect photoItemFrame;
      
      NSUInteger currentTabIndex = 0;
      NSUInteger index = 0;
      
      for (UIView* subView in tabBar.subviews)
      {
        if ([subView isKindOfClass:NSClassFromString(@"UITabBarButton")])
        {
          if (currentTabIndex == index)
          {
            photoItemFrame = subView.frame;
            break;
          }
          else
          {
            currentTabIndex++;
          }
        }
      }
      
      CGRect convertedRect = [self.view convertRect:photoItemFrame fromView:self.tabBar];
      
      
      [self.popover presentPopoverFromRect:convertedRect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
      
    } else {
      // Present standard photo chooser
      [self presentViewController:self.imagePicker animated:YES completion:nil];
    }
    
    
  }
  else if (item == self.tabBarItem_edit)
  {
    if (!_editBarVisible)
    {
      [self showEditBar];
    }
    
  }
  else if (item == self.tabBarItem_save)
  {
    [self save];
  }
  else if (item == self.tabBarItem_share)
  {
    // Share the current photo
    [self share];
  }
  

}


#pragma mark - UIImagePickerController delegate methods
/*!
 * Dismisses the image picker controller on cancel
 */
- (void)imagePickerControllerDidCancel:(UIImagePickerController *) Picker {
  [Picker dismissViewControllerAnimated:YES completion:nil];
}

/*!
 * Handle image selection
 */
- (void)imagePickerController:(UIImagePickerController *) Picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
  
  [MBProgressHUD showHUDAddedTo:self.view animated:YES];
  
  id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
  [tracker sendView:@"Modify Blurs View"];
  
  [self hideEditBar];
  
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad && self.popover != nil) {
    // Handle iPad popover closing
    dispatch_async(dispatch_get_main_queue(), ^{
      
      [self.popover dismissPopoverAnimated:YES];
      self.imageView_selectedImage.image = [(UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage] normalizedImage];
      [self.overlayViewController.view removeFromSuperview];
    });
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

                     
      // Create new overlays
      self.overlayViewController = [[CSOverlayViewController alloc] initWithImageView:self.imageView_selectedImage];
      
      dispatch_async(dispatch_get_main_queue(), ^{
        [self.overlayViewController.view setFrame:[[[[UIApplication sharedApplication] windows] lastObject] bounds]];
        
        [self.view insertSubview:self.overlayViewController.view aboveSubview:self.imageView_selectedImage];
        
        // Enable edit, share, and save tab bar items
        [self.tabBarItem_edit  setEnabled:YES];
        [self.tabBarItem_save  setEnabled:YES];
        [self.tabBarItem_share setEnabled:YES];

        // Reset slider values
        self.slider_contrast.value   = 1;
        self.slider_saturation.value = 1;
        self.slider_brightness.value = 0;
        
        [self.imageView_selectedImage setNeedsDisplay];
        [MBProgressHUD hideHUDForView:self.view animated:YES];
      });
    });
  } else {
    // Dismiss picker
    [Picker dismissViewControllerAnimated:YES completion:^{

      // Set image
      self.imageView_selectedImage.image = [(UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage] normalizedImage];      
      
      // Remove existing overlays
      if (self.overlayViewController)
      {
        [self.overlayViewController.view removeFromSuperview];
      }
      
      // Create new overlays
      self.overlayViewController = [[CSOverlayViewController alloc] initWithImageView:self.imageView_selectedImage];
      
      [self.overlayViewController.view setFrame:[[[[UIApplication sharedApplication] windows] lastObject] bounds]];
      
      [self.view insertSubview:self.overlayViewController.view aboveSubview:self.imageView_selectedImage];
      
      // Enable edit, share, and save tab bar items
      [self.tabBarItem_edit  setEnabled:YES];
      [self.tabBarItem_save setEnabled:YES];
      [self.tabBarItem_share setEnabled:YES];
      
      // Reset slider values
      self.slider_contrast.value   = 1;
      self.slider_saturation.value = 1;
      self.slider_brightness.value = 0;
      
      [MBProgressHUD hideHUDForView:self.view animated:YES];
      
      [UIView animateWithDuration:0.25 animations:^{
        [self.label_instructions setAlpha:1.0f];
      }];
      
      double delayInSeconds = 4.0;
      dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
      dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [UIView animateWithDuration:0.25 animations:^{
          [self.label_instructions setAlpha:0.0f];
        }];
      });
    }];
  }
  
}


#pragma mark - UIActionSheet Delegates
/*!
 * Handle sharing action sheet button click events
 */
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
  
  switch(buttonIndex)
  {
    case 0: // Mail
    {
      [MBProgressHUD showHUDAddedTo:self.view animated:YES];
      
      dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *renderedImage = [self renderBlurredImage];
        
        MFMailComposeViewController *mailController = [[MFMailComposeViewController alloc] init];
        mailController.mailComposeDelegate = self;
        NSData *imageData = UIImageJPEGRepresentation(renderedImage, 1.0f);
        
        [mailController setSubject:@"Tilt Shifted Image"];
        [mailController addAttachmentData:imageData mimeType:@"image/jpeg" fileName:@"tiltShiftedImage.jpg"];
        [mailController setMessageBody:@"Created with Tilt Shifted for iOS by Cloudspace" isHTML:YES];
      
        dispatch_async(dispatch_get_main_queue(), ^{
          [MBProgressHUD hideHUDForView:self.view animated:YES];
          [self presentViewController:mailController animated:YES completion:nil];
        });
      });
      
      break;
    }
    case 1: // Facebook
    {
      [MBProgressHUD showHUDAddedTo:self.view animated:YES];
      
      if([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook])
      {
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
          SLComposeViewController *fbController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
          
          SLComposeViewControllerCompletionHandler __block completionHandler=^(SLComposeViewControllerResult result){
            
            [fbController dismissViewControllerAnimated:YES completion:nil];
            
            switch(result){
              case SLComposeViewControllerResultCancelled:
              default:
              {
                NSLog(@"Cancelled.....");
                
              }
                break;
              case SLComposeViewControllerResultDone:
              {
                // Log share with Google Analytics
                id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
                [tracker sendView:@"Shared via Facebook"];
                
                // Mark significant event with Appirater
                [Appirater userDidSignificantEvent:YES];
                
                [[[UIAlertView alloc] initWithTitle:@"Posted!"
                                            message:@"Your tilt-shifted image has successfully been posted to Facebook."
                                           delegate:self
                                  cancelButtonTitle:nil
                                  otherButtonTitles:@"Thanks!", nil
                ] show];
              }
              break;
            }};

          [fbController addImage:[self renderBlurredImage]];

          [fbController setInitialText:@"Created with Tilt Shifted for iOS by Cloudspace!"];
          [fbController setCompletionHandler:completionHandler];
          
          dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            [self presentViewController:fbController animated:YES completion:nil];
          });
        });
      }
      else
      {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [[[UIAlertView alloc] initWithTitle:@"Oops!"
                                    message:@"It looks like Facebook integration isn't set up on this device.  You can enable it in your device settings."
                                   delegate:nil
                          cancelButtonTitle:nil
                          otherButtonTitles:@"Okay!", nil
        ] show];
      }
      
      break;
    }
    case 2: // Twitter
    {
      [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            
      if([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
      {
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
          SLComposeViewController *twitterController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
          
          SLComposeViewControllerCompletionHandler __block completionHandler=^(SLComposeViewControllerResult result){
            
            [twitterController dismissViewControllerAnimated:YES completion:nil];
            
            switch(result){
              case SLComposeViewControllerResultCancelled:
              default:
              {
                NSLog(@"Tweet Cancelled");
                
              }
                break;
              case SLComposeViewControllerResultDone:
              {
                // Log share with Google Analytics
                id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
                [tracker sendView:@"Shared via Twitter"];
                
                // Mark significant event with Appirater
                [Appirater userDidSignificantEvent:YES];
                
                [[[UIAlertView alloc] initWithTitle:@"Posted!"
                                            message:@"Your tilt-shifted image has successfully been posted to twitter."
                                           delegate:self
                                  cancelButtonTitle:nil
                                  otherButtonTitles:@"Thanks!", nil
                ] show];
              }
                break;
            }};
          

          [twitterController addImage:[self renderBlurredImage]];
          [twitterController setInitialText:@"Created with #TiltShifted for iOS by @Cloudspace!"];
          [twitterController setCompletionHandler:completionHandler];
          
          dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            [self presentViewController:twitterController animated:YES completion:nil];
          });
        });
      }
      else
      {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [[[UIAlertView alloc] initWithTitle:@"Oops!"
                                    message:@"It looks like Twitter integration isn't set up on this device.  You can enable it in your device settings."
                                   delegate:nil
                          cancelButtonTitle:nil
                          otherButtonTitles:@"Okay!", nil
        ] show];
      }
      break;
    }
  }
}


#pragma mark - MFMailComposeViewControllerDelegate Methods
/*!
 * Dismisses the mail view on completion
 */
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
  [self dismissViewControllerAnimated:YES completion:nil];

  if (result == MFMailComposeResultSent || result == MFMailComposeResultSaved)
  {
    // Log share with Google Analytics
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker sendView:@"Shared via Mail"];
    
    // Mark significant event with Appirater
    [Appirater userDidSignificantEvent:YES];
    
    // Present advertisement
    [self displayInterstitialAdIfAvailable];
    
  }
}


#pragma mark - UIAlertViewDelegate Methods
/*!
 * Show ads after alerts with registered delegates
 */
- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
  #ifndef PRO_VERSION
    [self displayInterstitialAdIfAvailable];
  #endif
}


#pragma mark - ADInterstitialAdDelegate Methods
/*!
 * Sets if a banner is available
 */
- (void)interstitialDidReceiveAd:(GADInterstitial *)ad
{
  _hasBanner = YES;
}


/*!
 * Sets if a banner is not available
 */
- (void)interstitial:(GADInterstitial *)ad didFailToReceiveAdWithError:(GADRequestError *)error
{
  _hasBanner = NO;
  [self requestInterstitialAd];
}

/*!
 * Requests a new banner to present on dismissal
 
 */
- (void)interstitialWillDismissScreen:(GADInterstitial *)ad
{
  [self requestInterstitialAd];
}


@end
