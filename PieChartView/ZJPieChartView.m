//
//  ViewController.m
//  Block
//
//  Created by apple on 16/7/14.
//  Copyright © 2016年 apple. All rights reserved.
//

#import "ZJPieChartView.h"
#import "ZJPieChartPartLayer.h"
#import "ZJPieChartRenderData.h"

@interface SRPieChartView ()

@property (strong, nonatomic) NSMutableArray *partDatas;
@property (assign, nonatomic) CGFloat pieChartTotalSum;
@property (strong, nonatomic) NSMutableArray *pieChartRenderDatas;
@property (strong, nonatomic) NSMutableArray *arcLayers;
@property (assign, nonatomic) CGFloat startAngle;

@end

@implementation SRPieChartView

#pragma mark - Init

- (instancetype)init {
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    self.backgroundColor = [UIColor whiteColor];
    self.selectEnable = YES;
    self.selectedPartIndex = -1;
    self.isRingStyle = NO;
    self.showPercentage = NO;
    
    [self addObserver:self forKeyPath:@"bounds" options:NSKeyValueObservingOptionNew context:nil];
}

#pragma mark - Draw PieChartView

- (void)drawRect:(CGRect)rect {
    NSUInteger totalPartsCount = self.pieChartRenderDatas.count;
    if (totalPartsCount == 0) {
        return ;
    }
    
    // remove layer form super layer
    NSMutableArray *subLayers = [[NSMutableArray alloc] initWithArray:self.layer.sublayers];
    for (CALayer *layer in subLayers) {
        [self.arcLayers addObject:layer];
        [layer removeFromSuperlayer];
    }
    
    for (NSUInteger i = 0; i < totalPartsCount; i++) {
        [self drawPartWithIndex:i];
    }
}

- (void)drawPartWithIndex:(NSUInteger)partIndex {
    if (partIndex > self.pieChartRenderDatas.count - 1) {
        return;
    }
    
    ZJPieChartPartLayer *layer = [self arcLayer];
    if ([self.arcLayers containsObject:layer]) {
        [self.arcLayers removeObject:layer];
    }
    layer.data = self.pieChartRenderDatas[partIndex];
    [layer setNeedsDisplay];
    [self.layer addSublayer:layer];
}

- (ZJPieChartPartLayer *)arcLayer {
    if (self.arcLayers.count > 0) {
        return self.arcLayers[0];
    }
    ZJPieChartPartLayer *layer = [ZJPieChartPartLayer layer];
    layer.backgroundColor = [UIColor clearColor].CGColor;
    layer.frame = self.bounds;
    return layer;
}

- (CGFloat)startAngleForPartIndex:(NSUInteger)partIndex {
    if (partIndex > self.pieChartRenderDatas.count - 1) {
        return -1;
    }
    
    if (partIndex == 0) {
        return self.startAngle;
    } else {
        ZJPieChartRenderData *pieChartPartData = self.pieChartRenderDatas[partIndex - 1];
        return pieChartPartData.endAngle;
    }
}

- (CGPoint)pointInCircleForCenter:(CGPoint)center radius:(CGFloat)radius angle:(CGFloat)angle {
    if (radius < 0) {
        return center;
    }
    return CGPointMake(center.x + radius * cosf(angle), center.y + sinf(angle));
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSString*, id> *)change context:(nullable void *)context {
    [self reloadData];
}

#pragma mark - Reload Data

- (void)reloadData {
    if (!self.dataSource) {
        return;
    }
    
    [self.partDatas removeAllObjects];
    [self.pieChartRenderDatas removeAllObjects];
    self.selectedPartIndex = -1;
    self.pieChartTotalSum = 0;
    
    // get all datas
    NSUInteger totalParts = [self.dataSource numberOfPartsInPieChartView];
    for (NSInteger i = 0; i < totalParts; i++) {
        CGFloat data = [self.dataSource pieChartView:self dataAtPartIndex:i];
        [self.partDatas addObject:[NSNumber numberWithFloat:data]];
        self.pieChartTotalSum += data;
    }
    
    // create pie chart part data
    if (totalParts <= 0) {
        return;
    }
    for (int i = 0; i < totalParts; i++) {
        ZJPieChartRenderData *partData = [[ZJPieChartRenderData alloc] init];
        [self.pieChartRenderDatas addObject:partData];
    }
    
    // init pie chart part data
    if ([self.dataSource respondsToSelector:@selector(startAngleForPieChartView)]) {
        self.startAngle = [self.dataSource startAngleForPieChartView];
    } else {
        self.startAngle = (arc4random() % 100) * M_PI * 2.0 / 100;
    }
    for (int i = 0; i < totalParts; i++) {
        ZJPieChartRenderData *partData = [self.pieChartRenderDatas objectAtIndex:i];
        partData.startAngle = [self startAngleForPartIndex:i];
        partData.endAngle = partData.startAngle + ([self.partDatas[i] floatValue] / self.pieChartTotalSum) * M_PI * 2;
        partData.isRingStyle = self.isRingStyle;
        partData.showPercentage = self.showPercentage;
        partData.text = @"";
        if (self.selectEnable && self.selectedPartIndex == i) {
            partData.selected = YES;
        }
        if ([self.dataSource respondsToSelector:@selector(pieChartView:colorAtPartIndex:)]) {
            partData.fillColor = [self.dataSource pieChartView:self colorAtPartIndex:i];
            partData.strokeColor = self.backgroundColor;
        }
        partData.outerRadius = ((self.bounds.size.width > self.bounds.size.height ? self.bounds.size.height : self.bounds.size.width) / 2) * 0.9;
    }
    [self setNeedsDisplay];
}

#pragma mark - Select 

// TODO: 添加 touchMove等函数
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (!self.selectEnable) {
        return;
    }
    UITouch *touch = touches.anyObject;
    CGPoint touchPoint = [touch locationInView:self];
    NSInteger index = [self indexOfPartCotainsPoint:touchPoint];
    if (index >= 0) {
        self.selectedPartIndex = index;
    }
}

- (NSInteger)indexOfPartCotainsPoint:(CGPoint)point {
    CGPoint center = CGPointMake(self.bounds.size.width * 0.5, self.bounds.size.height * 0.5);
    CGFloat direction = sqrt(powf(point.x - center.x, 2) + powf(point.y - center.y, 2));
    CGPoint vector1 = CGPointMake(point.x - center.x, point.y - center.y);
    CGPoint vector2 = CGPointMake(1, 0);
    CGFloat arc = acos((vector1.x * vector2.x + vector1.y * vector2.y)
                       / (sqrt(vector1.x * vector1.x + vector1.y * vector1.y)
                          * sqrt(vector2.x * vector2.x + vector2.y * vector2.y)));
    // 当算出两个向量的夹角，还要判断第一第四象限的。因为原点在左上角，所以是小于0
    if (vector1.y < 0) {
        arc = M_PI * 2 - arc;
    }
    
    if (arc < self.startAngle) {
        arc += M_PI * 2;
    }
    
    for (NSUInteger i = 0; i < self.pieChartRenderDatas.count; i++) {
        ZJPieChartRenderData *pieChartPartData = self.pieChartRenderDatas[i];
        if (pieChartPartData.isRingStyle) {
            if (arc > pieChartPartData.startAngle && pieChartPartData.endAngle > arc && direction < pieChartPartData.outerRadius && direction > pieChartPartData.innerRadius) {
                return i;
            }
        } else {
            if (arc > pieChartPartData.startAngle && pieChartPartData.endAngle > arc && direction < pieChartPartData.outerRadius) {
                return i;
            }
        }
        
    }
    return -1;
}

- (void)disSelectPartIndex:(NSUInteger)partIndex {
    if (self.pieChartRenderDatas.count == 0 || partIndex == -1) {
        return;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(pieChartView:willSelectedPartAtIndex:)]) {
        [self.delegate pieChartView:self willSelectedPartAtIndex:partIndex];
    }
    
    ZJPieChartRenderData *willDisSelectedData = self.pieChartRenderDatas[partIndex];
    willDisSelectedData.selected = NO;
    
    for (ZJPieChartPartLayer *layer in self.layer.sublayers) {
        if ([layer.data isEqual:willDisSelectedData]) {
            layer.zPosition = 1;
            [layer setNeedsDisplay];
        }
    }
}

- (void)selectPartIndex:(NSInteger)partIndex {
    if (self.pieChartRenderDatas.count == 0 || partIndex == -1) {
        return;
    }
    ZJPieChartRenderData *willSelectedData = self.pieChartRenderDatas[partIndex];
    willSelectedData.selected = YES;
    
    for (ZJPieChartPartLayer *layer in self.layer.sublayers) {
        if ([layer.data isEqual:willSelectedData]) {
            layer.zPosition = -1;
            [layer setNeedsDisplay];
        }
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(pieChartView:didSelectedPartAtIndex:)]) {
        [self.delegate pieChartView:self didSelectedPartAtIndex:partIndex];
    }
}

#pragma mark - Getters && Setters

- (NSMutableArray *)arcLayers {
    if (_arcLayers) {
        _arcLayers = [[NSMutableArray alloc] init];
    }
    return _arcLayers;
}

- (void)setSelectEnable:(BOOL)selectEnable {
    _selectEnable = selectEnable;
    if (!selectEnable) {
        self.selectedPartIndex = -1;
    }
}

- (void)setSelectedPartIndex:(NSInteger)selectedPartIndex {
    if (_selectedPartIndex != selectedPartIndex) {
        [self disSelectPartIndex:_selectedPartIndex];
        _selectedPartIndex = selectedPartIndex;
        [self selectPartIndex:selectedPartIndex];
    } else {
        _selectedPartIndex = -1;
        [self disSelectPartIndex:selectedPartIndex];
    }
}

- (void)setShowPercentage:(BOOL)showPercentage {
    if (_showPercentage != showPercentage) {
        for (ZJPieChartRenderData *pieChartPartData in self.pieChartRenderDatas) {
            pieChartPartData.showPercentage = showPercentage;
        }
        _showPercentage = showPercentage;
        for (ZJPieChartPartLayer *layer in self.layer.sublayers) {
            [layer setNeedsDisplay];
        }
    }
}

- (NSMutableArray *)pieChartRenderDatas {
    if (!_pieChartRenderDatas) {
        _pieChartRenderDatas = [[NSMutableArray alloc] init];
    }
    return _pieChartRenderDatas;
}

- (NSMutableArray *)partDatas {
    if (!_partDatas) {
        _partDatas = [[NSMutableArray alloc] init];
    }
    return _partDatas;
}

@end
