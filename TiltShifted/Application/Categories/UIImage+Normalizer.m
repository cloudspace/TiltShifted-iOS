#import "UIImage+Normalizer.h"


@implementation  UIImage (Normalizer)

- (UIImage *)normalizedImage {
  if (self.imageOrientation == UIImageOrientationUp) return self;
  
  UIGraphicsBeginImageContextWithOptions(self.size, NO, self.scale);
  [self drawInRect:(CGRect){0, 0, self.size}];
  UIImage *normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return normalizedImage;
}


@end
