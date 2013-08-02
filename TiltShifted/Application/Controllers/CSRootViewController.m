//
//  CSRootViewController.m
//  TiltShifted
//
//  Created by Joseph Lorich on 4/3/13.
//  Copyright (c) 2013 Cloudspace. All rights reserved.
//

#import "CSRootViewController.h"
#import "CSHomeViewController.h"


@interface CSRootViewController ()

@end

@implementation CSRootViewController

/*!
 * Initializes the root view controller
 */
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  
  if (self) {
    //[self.view setBackgroundColor:[UIColor blackColor]];
    
    // Create view controllers
    _viewController_main      = [CSHomeViewController new];
    [self setViewControllers:@[_viewController_main]];

  }
  
  return self;
}


@end
