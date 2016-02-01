//
//  UIImage+Plus.h
//  JGImagePlus
//
//  Created by Ji Fu on 12/30/15.
//  Copyright © 2015 Ji Fu. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "UIImage+Plus.h"

@interface UIImage (Size)

// *********************************************************************************************************************
#pragma mark - Class Extend
// *******************************************
#pragma mark - 图片信息获取
/**
 *   获取网络图片的Size, 先通过文件头来获取图片大小
 *   如果失败 会下载完整的图片Data 来计算大小 所以最好别放在主线程
 *   如果你有使用SDWebImage就会先看下 SDWebImage有缓存过改图片没有
 *   支持文件头大小的格式 : png、gif、jpg
 *
 *  @param imageURL url
 *
 *  @return CGsize
 */
+ (CGSize)downloadImageSizeWithURL:(id)imageURL;
/**
 *  获取图片
 *
 *  @param imageURL url
 *
 *  @return image
 */
+ (UIImage *)downloadImageWithURL:(id)imageURL;

// *******************************************
#pragma mark - 图片变形
/**
 *  指定大小缩放
 *
 *  @param image   UIImage
 *  @param newSize 固定大小
 *
 *  @return UIImage
 */
+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;

/**
 *  指定大小缩放
 *
 *  @param image   NSData
 *  @param newSize 固定大小
 *
 *  @return UIImage
 */
+(UIImage *)imageWithData2:(NSData *)data scale:(CGFloat)scale;

/**
 *  等比例缩放
 *
 *  @param image   UIImage
 *  @param newSize 指定大小
 *
 *  @return UIImage
 */
+ (UIImage*)imageWithImage:(UIImage *)image ratioToSize:(CGSize)newSize;

/**
 *  最短边缩放
 *
 *  @param image   UIImage
 *  @param newSize 固定大小
 *
 *  @return UIImage
 */
+ (UIImage*)imageWithImage:(UIImage *)image ratioCompressToSize:(CGSize)newSize;

/**
 *  图像添加圆角
 *
 *  @param image UIImage
 *  @param size  圆角大小
 *
 *  @return UIImage
 */
+ (UIImage*)imageWithImage:(UIImage*)image roundRect:(CGSize)size;

// *******************************************
#pragma mark - 图片滤镜
/**
 *  调整图像色值 ( 0.0 - 1.0 )
 *
 *  @param image     UIImage
 *  @param darkValue 色值
 *
 *  @return UIimage
 */
+ (UIImage*)imageWithImage:(UIImage*)image darkValue:(float)darkValue;

// *******************************************
#pragma mark - 子图像
/**
 *  图像部分剪切
 *
 *  @param image   UIImage
 *  @param newRect 子图像大小
 *
 *  @return UIImage
 */
+ (UIImage*)imageWithImage:(UIImage*)image cutToRect:(CGRect)newRect;

//+ (UIImage *)middleStretchableImageWithKey:(NSString *)key;
//+ (UIImage*)imageContentFileWithName:(NSString*)imageName ofType:(NSString*)type;
//+ (UIImage *)imageWithData2:(NSData *)data scale:(CGFloat)scale;

// *******************************************
#pragma mark - 图片边界识别
/**
 *  边界识别类型 - 高质量
 *
 *  @return HighAccuracy
 */
+ (CIDetector *)highAccuracyRectangleDetector;

/**
 *  边界识别类型 - Normal
 *
 *  @return Normal
 */
+ (CIDetector *)rectangleDetetor;

/**
 *  边界特征
 *
 *  @param rectangles 定点特征
 *
 *  @return 边界特征
 */
+ (CIRectangleFeature *)biggestRectangleInRectangles:(NSArray *)rectangles;

/**
 *  边界内区域标识
 *
 *  @param image       image
 *  @param topLeft     边界左顶点
 *  @param topRight    边界右顶点
 *  @param bottomLeft  边界左脚点
 *  @param bottomRight 边界右脚点
 *
 *  @return 标识后的图片
 */
+ (CIImage *)drawHighlightOverlayForPoints:(CIImage *)image topLeft:(CGPoint)topLeft topRight:(CGPoint)topRight bottomLeft:(CGPoint)bottomLeft bottomRight:(CGPoint)bottomRight;

/**
 *  边界内区域截取
 *
 *  @param image            image
 *  @param rectangleFeature 顶点特征
 *
 *  @return 截取后图片
 */
+ (CIImage *)correctPerspectiveForImage:(CIImage *)image withFeatures:(CIRectangleFeature *)rectangleFeature;

/**
 *  CGImageRef保存
 *
 *  @param imageRef CGImageRef
 *  @param filePath Sandbox保存位置
 */
+ (void)saveCGImageAsJPEGToFilePath:(CGImageRef)imageRef filePath:(NSString *)filePath;

// *******************************************
#pragma mark - 图片保存
/**
 *  保存当前图片到相册
 */
- (void)saveImageToPhotos;

/**
 *  回调方法
 *
 *  @param image       image
 *  @param error       error
 *  @param contextInfo centextInfo
 */
- (void)finishUIImageWriteToSavedPhotosAlbum:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo;

@end

