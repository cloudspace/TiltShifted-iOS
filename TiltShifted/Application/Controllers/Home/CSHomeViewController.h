//
//  CSHomeViewController.h
//  TiltShifted
//
//  Created by Joseph Lorich on 4/4/13.
//  Copyright (c) 2013 Cloudspace. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "GADInterstitial.h"

#import "CSBaseViewController.h"

@class CSOverlayViewController;

/**
 * The home view controller for the feed parser
 */
@interface CSHomeViewController : CSBaseViewController<
  UIImagePickerControllerDelegate,
  UINavigationControllerDelegate,
  UITabBarDelegate,
  UIActionSheetDelegate,
  UIAlertViewDelegate,
  MFMailComposeViewControllerDelegate,
  GADInterstitialDelegate
>
{
  BOOL _editBarVisible;
  BOOL _hasBanner;
}


// Properties
@property (nonatomic, strong) UIImagePickerController *imagePicker;
@property (nonatomic, strong) UIPopoverController     *popover;
@property (nonatomic, strong) GADInterstitial         *interstitialAd;

// IBOutlet Properties
@property IBOutlet UIImageView *imageView_selectedImage;

@property IBOutlet UITabBar *tabBar;
@property IBOutlet UITabBarItem *tabBarItem_camera;
@property IBOutlet UITabBarItem *tabBarItem_photos;
@property IBOutlet UITabBarItem *tabBarItem_edit;
@property IBOutlet UITabBarItem *tabBarItem_share;
@property IBOutlet UITabBarItem *tabBarItem_save;

@property IBOutlet UILabel  *label_instructions;

@property IBOutlet UIView   *view_edit;
@property IBOutlet UISlider *slider_contrast;
@property IBOutlet UISlider *slider_saturation;
@property IBOutlet UISlider *slider_brightness;



@property IBOutlet NSLayoutConstraint *view_edit_bottomSpace;

/// The camera overlay view controller
@property CSOverlayViewController *overlayViewController;

- (IBAction) applyFilters;

@end
