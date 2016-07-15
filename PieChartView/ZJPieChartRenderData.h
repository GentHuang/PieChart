//
//  ViewController.m
//  Block
//
//  Created by apple on 16/7/14.
//  Copyright © 2016年 apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ZJPieChartRenderData : NSObject

@property (assign, nonatomic) CGFloat startAngle;
@property (assign, nonatomic) CGFloat endAngle;
@property (strong, nonatomic) UIColor *fillColor;
@property (strong, nonatomic) UIColor *strokeColor;
@property (assign, nonatomic) CGFloat innerRadius;
@property (assign, nonatomic) CGFloat outerRadius;
@property (assign, nonatomic) BOOL isRingStyle;
@property (assign, nonatomic, getter=isSelected) BOOL selected;
@property (assign, nonatomic) NSString *text;
@property (assign, nonatomic) BOOL showPercentage;

- (void)resetDefault;

@end
