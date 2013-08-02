//
//  CSRootViewController.h
//  TiltShifted
//
//  Created by Joseph Lorich on 4/3/13.
//  Copyright (c) 2013 Cloudspace. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * A root view controller
 */
@interface CSRootViewController : UINavigationController

{
  
}

#pragma mark - Properties

/// The main controller that sits at the top of the app
@property (nonatomic, retain) UIViewController *viewController_main;



#pragma mark - Methods


@end
