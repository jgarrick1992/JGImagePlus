//
//  UIImage+Plus.m
//  JGImagePlus
//
//  Created by Ji Fu on 12/30/15.
//  Copyright © 2015 Ji Fu. All rights reserved.
//

#import "GPUImage.h"
#import "UIImage+Plus.h"
#import "UIImageView+WebCache.h"

#import <GLKit/GLKit.h>
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <SDWebImage+ExtensionSupport/SDImageCache.h>
#import <SDWebImage+ExtensionSupport/SDWebImageManager.h>

@implementation UIImage (Size)

// *******************************************
#pragma mark - 图片信息获取
+(CGSize)downloadImageSizeWithURL:(id)imageURL {
    
    NSURL* URL = nil;
    if([imageURL isKindOfClass:[NSURL class]]){
        URL = imageURL;
    }
    if([imageURL isKindOfClass:[NSString class]]){
        URL = [NSURL URLWithString:imageURL];
    }
    if(URL == nil)
        return CGSizeZero;
    
#ifdef dispatch_main_sync_safe
    NSString *key = [[SDWebImageManager sharedManager] cacheKeyForURL:URL];
    UIImage *lastPreviousCachedImage = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:key];
    if (lastPreviousCachedImage) {
        return lastPreviousCachedImage.size;
    }
#endif
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];
    NSString* pathExtendsion = [URL.pathExtension lowercaseString];
    
    CGSize size = CGSizeZero;
    if([pathExtendsion isEqualToString:@"png"]){
        size =  [self downloadPNGImageSizeWithRequest:request];
    }
    else if([pathExtendsion isEqual:@"gif"])
    {
        size =  [self downloadGIFImageSizeWithRequest:request];
    }
    else{
        size = [self downloadJPGImageSizeWithRequest:request];
    }
    if(CGSizeEqualToSize(CGSizeZero, size))
    {
        NSData * data = [NSData dataWithContentsOfURL:URL];
        UIImage* image = [[UIImage alloc] initWithData:data];
        
        if(image)
        {
#ifdef dispatch_main_sync_safe
            [[SDImageCache sharedImageCache] storeImage:image recalculateFromImage:YES imageData:data forKey:URL.absoluteString toDisk:YES];
#endif
            size = image.size;
        }
    }
    
    return size;
}

+ (UIImage *)downloadImageWithURL:(id)imageURL {
    NSURL* URL = nil;
    if([imageURL isKindOfClass:[NSURL class]]){
        URL = imageURL;
    }
    if([imageURL isKindOfClass:[NSString class]]){
        URL = [NSURL URLWithString:imageURL];
    }
    if(URL == nil)
        return nil;
    
    // 是否存在缓存
    NSString *key = [[SDWebImageManager sharedManager] cacheKeyForURL:URL];
    UIImage *lastPreviousCachedImage = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:key];
    if (lastPreviousCachedImage) {
        return lastPreviousCachedImage;
    }
    
    // 下载图片
    NSData * data = [NSData dataWithContentsOfURL:URL];
    UIImage* image = [[UIImage alloc] initWithData:data];
    if(image) {
        return image;
    }else {
        return nil;
    }
}

// *******************************************
#pragma mark - 图片判断
- (BOOL)isImageSameScaleWith:(CGFloat)scale {
    
    CGFloat selfScale = self.size.width / self.size.height;
    CGFloat scaleOfImages = selfScale / scale;
    
    if (scaleOfImages > 1.05 || scaleOfImages < 0.95) {
        return NO;
    } else {
        return YES;
    }
}

// *******************************************
#pragma mark - 图片变形
- (UIImage *)imageRotationWithOrientation:(UIImageOrientation)orientation {
    long double rotate = 0.0;
    CGRect rect;
    float translateX = 0;
    float translateY = 0;
    float scaleX = 1.0;
    float scaleY = 1.0;
    
    switch (orientation) {
        case UIImageOrientationLeft:
            rotate = M_PI_2;
            rect = CGRectMake(0, 0, self.size.height, self.size.width);
            translateX = 0;
            translateY = -rect.size.width;
            scaleY = rect.size.width/rect.size.height;
            scaleX = rect.size.height/rect.size.width;
            break;
        case UIImageOrientationRight:
            rotate = 3 * M_PI_2;
            rect = CGRectMake(0, 0, self.size.height, self.size.width);
            translateX = -rect.size.height;
            translateY = 0;
            scaleY = rect.size.width/rect.size.height;
            scaleX = rect.size.height/rect.size.width;
            break;
        case UIImageOrientationDown:
            rotate = M_PI;
            rect = CGRectMake(0, 0, self.size.width, self.size.height);
            translateX = -rect.size.width;
            translateY = -rect.size.height;
            break;
        default:
            rotate = 0.0;
            rect = CGRectMake(0, 0, self.size.width, self.size.height);
            translateX = 0;
            translateY = 0;
            break;
    }
    
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    //做CTM变换
    CGContextTranslateCTM(context, 0.0, rect.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextRotateCTM(context, rotate);
    CGContextTranslateCTM(context, translateX, translateY);
    
    CGContextScaleCTM(context, scaleX, scaleY);
    //绘制图片
    CGContextDrawImage(context, CGRectMake(0, 0, rect.size.width, rect.size.height), self.CGImage);
    
    UIImage *newPic = UIGraphicsGetImageFromCurrentImageContext();
    
    return newPic;
}

- (UIImage *)imageCutWithSubRect:(CGRect)subCGRect {
    
    GPUImageCropFilter *imageFilter = [[GPUImageCropFilter alloc] init];
    imageFilter.cropRegion = subCGRect;
    UIImage *filteredImage = [imageFilter imageByFilteringImage:self];
    
    return filteredImage;
}

- (UIImage *)imageCompressWithMaxDimension:(CGFloat)maxDimension {
    
    CGSize scaledSize =  CGSizeMake(maxDimension, maxDimension);
    CGFloat scaleFactor;
    
    if (self.size.width > self.size.height) {
        scaleFactor       = self.size.height / self.size.width;
        scaledSize.width  = maxDimension;
        scaledSize.height = scaledSize.width * scaleFactor;
    } else {
        scaleFactor       = self.size.width / self.size.height;
        scaledSize.height = maxDimension;
        scaledSize.width  = scaledSize.height * scaleFactor;
    }
    
    UIGraphicsBeginImageContext(scaledSize);
    [self drawInRect: CGRectMake(0, 0, scaledSize.width, scaledSize.height)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return scaledImage;
}

- (UIImage *)imageRotationWithOrientation:(UIImageOrientation)orientation {
    
    CGRect rect;
    long double rotate = 0.0;
    float translateX   = 0;
    float translateY   = 0;
    float scaleX       = 1.0;
    float scaleY       = 1.0;
    
    switch (orientation) {
        case UIImageOrientationLeft:
            rotate     = M_PI_2;
            rect       = CGRectMake(0, 0, self.size.height, self.size.width);
            translateX = 0;
            translateY = -rect.size.width;
            scaleY     = rect.size.width/rect.size.height;
            scaleX     = rect.size.height/rect.size.width;
            break;
        case UIImageOrientationRight:
            rotate     = 3 * M_PI_2;
            rect       = CGRectMake(0, 0, self.size.height, self.size.width);
            translateX = -rect.size.height;
            translateY = 0;
            scaleY     = rect.size.width/rect.size.height;
            scaleX     = rect.size.height/rect.size.width;
            break;
        case UIImageOrientationDown:
            rotate     = M_PI;
            rect       = CGRectMake(0, 0, self.size.width, self.size.height);
            translateX = -rect.size.width;
            translateY = -rect.size.height;
            break;
        default:
            rotate     = 0.0;
            rect       = CGRectMake(0, 0, self.size.width, self.size.height);
            translateX = 0;
            translateY = 0;
            break;
    }
    
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    //做CTM变换
    CGContextTranslateCTM(context, 0.0, rect.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextRotateCTM(context, rotate);
    CGContextTranslateCTM(context, translateX, translateY);
    
    CGContextScaleCTM(context, scaleX, scaleY);
    //绘制图片
    CGContextDrawImage(context, CGRectMake(0, 0, rect.size.width, rect.size.height), self.CGImage);
    
    UIImage *newPic = UIGraphicsGetImageFromCurrentImageContext();
    
    return newPic;
}

+(UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    
    UIGraphicsBeginImageContext( newSize );
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

+(UIImage *)imageWithData2:(NSData *)data scale:(CGFloat)scale {
    
    return [UIImage imageWithCGImage:[UIImage imageWithData:data].CGImage scale:scale orientation:UIImageOrientationUp];
}

+(UIImage *)imageWithImage:(UIImage *)image ratioToSize:(CGSize)newSize {
    
    CGFloat width = image.size.width;
    CGFloat height = image.size.height;
    float verticalRadio = newSize.height/height;
    float horizontalRadio = newSize.width/width;
    float radio = verticalRadio > horizontalRadio ? horizontalRadio : verticalRadio;
    width = width*radio;
    height = height*radio;
    
    return [self imageWithImage:image scaledToSize:CGSizeMake(width,height)];
}

+(UIImage *)imageWithImage:(UIImage *)image ratioCompressToSize:(CGSize)newSize {
    
    CGFloat width = image.size.width;
    CGFloat height = image.size.height;
    if(width < newSize.width && height < newSize.height)
    {
        return image;
    }
    else
    {
        return [self imageWithImage:image ratioToSize:newSize];
    }
}

+(UIImage *)imageWithImage:(UIImage *)image roundRect:(CGSize)size {
    
    // the size of CGContextRef
    int w = size.width;
    int h = size.height;
    
    UIImage *img = image;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, w, h, 8, 4 * w, colorSpace, (uint32_t)kCGImageAlphaPremultipliedFirst);
    CGRect rect = CGRectMake(0, 0, w, h);
    
    CGContextBeginPath(context);
    addRoundedRectToPath(context, rect, 5, 5);
    CGContextClosePath(context);
    CGContextClip(context);
    CGContextDrawImage(context, CGRectMake(0, 0, w, h), img.CGImage);
    CGImageRef imageMasked = CGBitmapContextCreateImage(context);
    UIImage* image2 =  [UIImage imageWithCGImage:imageMasked];
    CGContextRelease(context);
    CGImageRelease(imageMasked);
    CGColorSpaceRelease(colorSpace);
    return image2;
}

// *******************************************
#pragma mark - 图片滤镜
+(UIImage *)imageWithImage:(UIImage *)image darkValue:(float)darkValue
{
    return [UIImage imageWithImage:image pixelOperationBlock:^(UInt8 *redRef, UInt8 *greenRef, UInt8 *blueRef) {
        *redRef = *redRef * darkValue;
        *greenRef = *greenRef * darkValue;
        *blueRef = *blueRef * darkValue;
    }];
}

- (UIImage *)imageFilterWithAdaptiveThreshold:(CGFloat)blurRadiusPixels {
    if (0 == blurRadiusPixels) {
        blurRadiusPixels = 15.0;
    }
    
    GPUImageAdaptiveThresholdFilter *imageFilter = [[GPUImageAdaptiveThresholdFilter alloc] init];
    imageFilter.blurRadiusInPixels               = 15.0;// tag blur
    UIImage *filteredImage                       = [imageFilter imageByFilteringImage:self];
    
    return filteredImage;
}

- (UIImage *)imageFilterWithDenoise {
    
    GPUImageMedianFilter *imageFilter = [[GPUImageMedianFilter alloc] init];
    UIImage *filteredImage            = [imageFilter imageByFilteringImage:self];
    
    return filteredImage;
}

- (UIImage *)imageFilterWithErosion {
    
    GPUImageErosionFilter  *imageFilter = [[GPUImageErosionFilter alloc] init];
    UIImage *filteredImage = [imageFilter imageByFilteringImage:self];
    
    return filteredImage;
}

// *******************************************
#pragma mark - 子图像
+(UIImage *)imageWithImage:(UIImage *)image cutToRect:(CGRect)newRect {
    
    CGImageRef subImageRef = CGImageCreateWithImageInRect(image.CGImage, newRect);
    CGRect smallBounds = CGRectMake(0, 0, CGImageGetWidth(subImageRef), CGImageGetHeight(subImageRef));
    UIGraphicsBeginImageContext(smallBounds.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextDrawImage(context, smallBounds, subImageRef);
    UIImage* smallImage = [UIImage imageWithCGImage:subImageRef];
    UIGraphicsEndImageContext();
    CGImageRelease(subImageRef);
    return smallImage;
}

// *******************************************
#pragma mark - 图片边界识别
+ (CIDetector *)highAccuracyRectangleDetector {
    
    static CIDetector *detector = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
                  {
                      detector = [CIDetector detectorOfType:CIDetectorTypeRectangle context:nil options:@{CIDetectorAccuracy : CIDetectorAccuracyHigh}];
                  });
    return detector;
}

+ (CIDetector *)rectangleDetetor {
    
    static CIDetector *detector = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
                  {
                      detector = [CIDetector detectorOfType:CIDetectorTypeRectangle context:nil options:@{CIDetectorAccuracy : CIDetectorAccuracyLow,CIDetectorTracking : @(YES)}];
                  });
    return detector;
}

+ (CIRectangleFeature *)biggestRectangleInRectangles:(NSArray *)rectangles {
    
    if (![rectangles count]) return nil;
    
    float halfPerimiterValue = 0;
    
    CIRectangleFeature *biggestRectangle = [rectangles firstObject];
    
    for (CIRectangleFeature *rect in rectangles)
    {
        CGPoint p1 = rect.topLeft;
        CGPoint p2 = rect.topRight;
        CGFloat width = hypotf(p1.x - p2.x, p1.y - p2.y);
        
        CGPoint p3 = rect.topLeft;
        CGPoint p4 = rect.bottomLeft;
        CGFloat height = hypotf(p3.x - p4.x, p3.y - p4.y);
        
        CGFloat currentHalfPerimiterValue = height + width;
        
        if (halfPerimiterValue < currentHalfPerimiterValue)
        {
            halfPerimiterValue = currentHalfPerimiterValue;
            biggestRectangle = rect;
        }
    }
    
    return biggestRectangle;
}

+ (CIImage *)drawHighlightOverlayForPoints:(CIImage *)image topLeft:(CGPoint)topLeft topRight:(CGPoint)topRight bottomLeft:(CGPoint)bottomLeft bottomRight:(CGPoint)bottomRight {
    
    CIImage *overlay = [CIImage imageWithColor:[CIColor colorWithRed:1 green:0 blue:0 alpha:0.6]];
    overlay = [overlay imageByCroppingToRect:image.extent];
    overlay = [overlay imageByApplyingFilter:@"CIPerspectiveTransformWithExtent" withInputParameters:@{@"inputExtent":[CIVector vectorWithCGRect:image.extent],@"inputTopLeft":[CIVector vectorWithCGPoint:topLeft],@"inputTopRight":[CIVector vectorWithCGPoint:topRight],@"inputBottomLeft":[CIVector vectorWithCGPoint:bottomLeft],@"inputBottomRight":[CIVector vectorWithCGPoint:bottomRight]}];
    
    return [overlay imageByCompositingOverImage:image];
}

+ (CIImage *)correctPerspectiveForImage:(CIImage *)image withFeatures:(CIRectangleFeature *)rectangleFeature {
    
    NSMutableDictionary *rectangleCoordinates = [NSMutableDictionary new];
    rectangleCoordinates[@"inputTopLeft"] = [CIVector vectorWithCGPoint:rectangleFeature.topLeft];
    rectangleCoordinates[@"inputTopRight"] = [CIVector vectorWithCGPoint:rectangleFeature.topRight];
    rectangleCoordinates[@"inputBottomLeft"] = [CIVector vectorWithCGPoint:rectangleFeature.bottomLeft];
    rectangleCoordinates[@"inputBottomRight"] = [CIVector vectorWithCGPoint:rectangleFeature.bottomRight];
    return [image imageByApplyingFilter:@"CIPerspectiveCorrection" withInputParameters:rectangleCoordinates];
}

+ (void)saveCGImageAsJPEGToFilePath:(CGImageRef)imageRef filePath:(NSString *)filePath {
    
    @autoreleasepool {
        
        CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:filePath];
        CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypeJPEG, 1, NULL);
        CGImageDestinationAddImage(destination, imageRef, nil);
        CGImageDestinationFinalize(destination);
        CFRelease(destination);
    }
}

// *******************************************
#pragma mark - 图片保存
// 图片保存
- (void)saveImageToPhotos {
    UIImageWriteToSavedPhotosAlbum(self, self, @selector(finishUIImageWriteToSavedPhotosAlbum:didFinishSavingWithError:contextInfo:), NULL);
}

// 指定回调方法
- (void)finishUIImageWriteToSavedPhotosAlbum:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    NSString *msg = nil ;
    if(error != NULL){
        msg = @"保存图片失败" ;
    }else{
        msg = @"保存图片成功" ;
    }
}

// *******************************************
#pragma mark - 图片显示
- (void)imageShowOntheView:(UIViewController *)target {
    UIImageView *captureImageView = [[UIImageView alloc] initWithImage:self];
    captureImageView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.7];
    captureImageView.frame = CGRectOffset(target.view.bounds, 0, -target.view.bounds.size.height);
    captureImageView.alpha = 1.0;
    captureImageView.contentMode = UIViewContentModeScaleAspectFit;
    captureImageView.userInteractionEnabled = YES;
    [target.view addSubview:captureImageView];
    
    UITapGestureRecognizer *dismissTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissPreview:)];
    [captureImageView addGestureRecognizer:dismissTap];
    
    [UIView animateWithDuration:0.7 delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:0.7 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        captureImageView.frame = target.view.bounds;
    } completion:nil];
}

- (void)dismissPreview:(UITapGestureRecognizer *)dismissTap {
    [UIView animateWithDuration:0.7 delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:1.0 options:UIViewAnimationOptionAllowUserInteraction animations:^ {
    }completion:^(BOOL finished){
        [dismissTap.view removeFromSuperview];
    }];
}

// *********************************************************************************************************************
#pragma mark - Private
//讨厌警告
-(id)diskImageDataBySearchingAllPathsForKey:(id)key{return nil;}

// PNG
+(CGSize)downloadPNGImageSizeWithRequest:(NSMutableURLRequest*)request
{
    [request setValue:@"bytes=16-23" forHTTPHeaderField:@"Range"];
    NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    if(data.length == 8)
    {
        int w1 = 0, w2 = 0, w3 = 0, w4 = 0;
        [data getBytes:&w1 range:NSMakeRange(0, 1)];
        [data getBytes:&w2 range:NSMakeRange(1, 1)];
        [data getBytes:&w3 range:NSMakeRange(2, 1)];
        [data getBytes:&w4 range:NSMakeRange(3, 1)];
        int w = (w1 << 24) + (w2 << 16) + (w3 << 8) + w4;
        int h1 = 0, h2 = 0, h3 = 0, h4 = 0;
        [data getBytes:&h1 range:NSMakeRange(4, 1)];
        [data getBytes:&h2 range:NSMakeRange(5, 1)];
        [data getBytes:&h3 range:NSMakeRange(6, 1)];
        [data getBytes:&h4 range:NSMakeRange(7, 1)];
        int h = (h1 << 24) + (h2 << 16) + (h3 << 8) + h4;
        return CGSizeMake(w, h);
    }
    return CGSizeZero;
}

// GIF
+(CGSize)downloadGIFImageSizeWithRequest:(NSMutableURLRequest*)request
{
    [request setValue:@"bytes=6-9" forHTTPHeaderField:@"Range"];
    NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    if(data.length == 4)
    {
        short w1 = 0, w2 = 0;
        [data getBytes:&w1 range:NSMakeRange(0, 1)];
        [data getBytes:&w2 range:NSMakeRange(1, 1)];
        short w = w1 + (w2 << 8);
        short h1 = 0, h2 = 0;
        [data getBytes:&h1 range:NSMakeRange(2, 1)];
        [data getBytes:&h2 range:NSMakeRange(3, 1)];
        short h = h1 + (h2 << 8);
        return CGSizeMake(w, h);
    }
    return CGSizeZero;
}

static inline CGSize jpgImageSizeWithExactData(NSData *data)
{
    short w1 = 0, w2 = 0;
    [data getBytes:&w1 range:NSMakeRange(2, 1)];
    [data getBytes:&w2 range:NSMakeRange(3, 1)];
    short w = (w1 << 8) + w2;
    
    short h1 = 0, h2 = 0;
    [data getBytes:&h1 range:NSMakeRange(0, 1)];
    [data getBytes:&h2 range:NSMakeRange(1, 1)];
    short h = (h1 << 8) + h2;
    
    return CGSizeMake(w, h);
}

+ (CGSize)jpgImageSizeWithHeaderData:(NSData *)data {
#ifdef DEBUG
    // @"bytes=0-209"
    assert([data length] == 210);
#endif
    short word = 0x0;
    [data getBytes:&word range:NSMakeRange(0x15, 0x1)];
    if (word == 0xdb) {
        [data getBytes:&word range:NSMakeRange(0x5a, 0x1)];
        if (word == 0xdb) {
            // 两个DQT字段
            NSData *exactData = [data subdataWithRange:NSMakeRange(0xa3, 0x4)];
            return jpgImageSizeWithExactData(exactData);
        } else {
            // 一个DQT字段
            NSData *exactData = [data subdataWithRange:NSMakeRange(0x5e, 0x4)];
            return jpgImageSizeWithExactData(exactData);
        }
    } else {
        return CGSizeZero;
    }
}

// JPG
+(CGSize)downloadJPGImageSizeWithRequest:(NSMutableURLRequest*)request
{
    [request setValue:@"bytes=0-209" forHTTPHeaderField:@"Range"];
    NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    //
    //    return [self jpgImageSizeWithHeaderData: data];
    if ([data length] <= 0x58) {
        return CGSizeZero;
    }
    
    if ([data length] < 210) {// 肯定只有一个DQT字段
        short w1 = 0, w2 = 0;
        [data getBytes:&w1 range:NSMakeRange(0x60, 0x1)];
        [data getBytes:&w2 range:NSMakeRange(0x61, 0x1)];
        short w = (w1 << 8) + w2;
        short h1 = 0, h2 = 0;
        [data getBytes:&h1 range:NSMakeRange(0x5e, 0x1)];
        [data getBytes:&h2 range:NSMakeRange(0x5f, 0x1)];
        short h = (h1 << 8) + h2;
        return CGSizeMake(w, h);
    } else {
        short word = 0x0;
        [data getBytes:&word range:NSMakeRange(0x15, 0x1)];
        if (word == 0xdb) {
            [data getBytes:&word range:NSMakeRange(0x5a, 0x1)];
            if (word == 0xdb) {// 两个DQT字段
                short w1 = 0, w2 = 0;
                [data getBytes:&w1 range:NSMakeRange(0xa5, 0x1)];
                [data getBytes:&w2 range:NSMakeRange(0xa6, 0x1)];
                short w = (w1 << 8) + w2;
                short h1 = 0, h2 = 0;
                [data getBytes:&h1 range:NSMakeRange(0xa3, 0x1)];
                [data getBytes:&h2 range:NSMakeRange(0xa4, 0x1)];
                short h = (h1 << 8) + h2;
                return CGSizeMake(w, h);
            } else {// 一个DQT字段
                short w1 = 0, w2 = 0;
                [data getBytes:&w1 range:NSMakeRange(0x60, 0x1)];
                [data getBytes:&w2 range:NSMakeRange(0x61, 0x1)];
                short w = (w1 << 8) + w2;
                short h1 = 0, h2 = 0;
                [data getBytes:&h1 range:NSMakeRange(0x5e, 0x1)];
                [data getBytes:&h2 range:NSMakeRange(0x5f, 0x1)];
                short h = (h1 << 8) + h2;
                return CGSizeMake(w, h);
            }
        } else {
            return CGSizeZero;
        }
    }
}

//添加圆角
static void addRoundedRectToPath(CGContextRef context, CGRect rect, float ovalWidth, float ovalHeight) {
    
    float fw,fh;
    if (ovalWidth == 0 || ovalHeight == 0) {
        CGContextAddRect(context, rect);
        return;
    }
    
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, CGRectGetMinX(rect), CGRectGetMinY(rect));
    CGContextScaleCTM(context, ovalWidth, ovalHeight);
    fw = CGRectGetWidth(rect) / ovalWidth;
    fh = CGRectGetHeight(rect) / ovalHeight;
    
    CGContextMoveToPoint(context, fw, fh/2);  // Start at lower right corner
    CGContextAddArcToPoint(context, fw, fh, fw/2, fh, 1);  // Top right corner
    CGContextAddArcToPoint(context, 0, fh, 0, fh/2, 1); // Top left corner
    CGContextAddArcToPoint(context, 0, 0, fw/2, 0, 1); // Lower left corner
    CGContextAddArcToPoint(context, fw, 0, fw, fh/2, 1); // Back to lower right
    
    CGContextClosePath(context);
    CGContextRestoreGState(context);
}

+(UIImage *)imageWithImage:(UIImage *)image pixelOperationBlock:(void(^)(UInt8 *redRef, UInt8 *greenRef, UInt8 *blueRef))block {
    if(block == nil)
        return image;
    
    CGImageRef  imageRef = image.CGImage;
    if(imageRef == NULL)
        return nil;
    
    size_t width  = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    
    // ピクセルを構成するRGB各要素が何ビットで構成されている
    size_t bitsPerComponent = CGImageGetBitsPerComponent(imageRef);
    
    // ピクセル全体は何ビットで構成されているか
    size_t bitsPerPixel = CGImageGetBitsPerPixel(imageRef);
    
    // 画像の横1ライン分のデータが、何バイトで構成されているか
    size_t bytesPerRow = CGImageGetBytesPerRow(imageRef);
    
    // 画像の色空間
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(imageRef);
    
    // 画像のBitmap情報
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    
    // 画像がピクセル間の補完をしているか
    bool shouldInterpolate = CGImageGetShouldInterpolate(imageRef);
    
    // 表示装置によって補正をしているか
    CGColorRenderingIntent intent = CGImageGetRenderingIntent(imageRef);
    
    // 画像のデータプロバイダを取得する
    CGDataProviderRef dataProvider = CGImageGetDataProvider(imageRef);
    
    // データプロバイダから画像のbitmap生データ取得
    CFDataRef   data = CGDataProviderCopyData(dataProvider);
    UInt8* buffer = (UInt8*)CFDataGetBytePtr(data);
    
    // 1ピクセルずつ画像を処理
    NSUInteger  x, y;
    for (y = 0; y < height; y++) {
        for (x = 0; x < width; x++) {
            UInt8*  tmp;
            tmp = buffer + y * bytesPerRow + x * 4; // RGBAの4つ値をもっているので、1ピクセルごとに*4してずらす
            
            // RGB値を取得
            UInt8 red,green,blue;
            red = *(tmp + 0);
            green = *(tmp + 1);
            blue = *(tmp + 2);
            
            block(&red,&green,&blue);
            
            *(tmp + 0) = red;
            *(tmp + 1) = green;
            *(tmp + 2) = blue;
        }
    }
    
    // 効果を与えたデータ生成
    CFDataRef   effectedData;
    effectedData = CFDataCreate(NULL, buffer, CFDataGetLength(data));
    
    // 効果を与えたデータプロバイダを生成
    CGDataProviderRef   effectedDataProvider;
    effectedDataProvider = CGDataProviderCreateWithCFData(effectedData);
    
    // 画像を生成
    CGImageRef  effectedCgImage;
    UIImage*    effectedImage;
    effectedCgImage = CGImageCreate(
                                    width, height,
                                    bitsPerComponent, bitsPerPixel, bytesPerRow,
                                    colorSpace, bitmapInfo, effectedDataProvider,
                                    NULL, shouldInterpolate, intent);
    effectedImage = [UIImage imageWithCGImage:effectedCgImage];
    
    // データの解放
    CGImageRelease(effectedCgImage);
    CFRelease(effectedDataProvider);
    CFRelease(effectedData);
    CFRelease(data);
    
    return effectedImage;
}

@end
