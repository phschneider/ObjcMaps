//
// Created by Philip Schneider on 03.10.14.
// Copyright (c) 2014 phschneider.net. All rights reserved.
//


#import "PSGraphViewController.h"


@interface PSGraphViewController ()

@property(nonatomic, strong) BEMSimpleLineGraphView *graphView;
@property(nonatomic, strong) NSArray *data;
@property(nonatomic, strong) UITableView *tableView;
@end


@implementation PSGraphViewController

- (instancetype) init
{
    DLogFuncName();
    self = [super init];
    if (self)
    {
        self.graphView = [[BEMSimpleLineGraphView alloc] initWithFrame:CGRectZero];
//        self.graphView.autoresizingMask = self.view.autoresizingMask;
        self.graphView.dataSource = self;
        self.graphView.delegate = self;
        self.graphView.enableYAxisLabel = YES;
        self.graphView.enablePopUpReport = YES;
        self.graphView.enableTouchReport = YES;
//        self.graphView.alwaysDisplayPopUpLabels = YES;
        self.view.backgroundColor = [UIColor blueColor];
        [self.view addSubview:self.graphView ];
        
//        self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
//        self.tableView.dataSource = self;
//        self.tableView.delegate = self;
//        [self.view addSubview:self.tableView];
    }
    return self;
}


- (void)viewDidLoad
{
    DLogFuncName();
    [super viewDidLoad];
}


- (void) viewWillAppear:(BOOL)animated
{
    DLogFuncName();
    [super viewWillAppear:animated];
    self.graphView.frame = self.view.bounds;
}


- (void) viewDidAppear:(BOOL)animated
{
    DLogFuncName();
    [super viewDidAppear:animated];
    

}


- (void) setData:(NSArray *)data
{
    DLogFuncName();
    _data = data;
    [self.graphView reloadGraph];
}


#pragma mark - BEMSSimpleLineGraphView DataSource
- (NSInteger)numberOfPointsInLineGraph:(BEMSimpleLineGraphView *)graph
{
    DLogFuncName();
    // Anzahl elemente im Array!?

    return [self.data count];
}


- (CGFloat)lineGraph:(BEMSimpleLineGraphView *)graph valueForPointAtIndex:(NSInteger)index
{
    DLogFuncName();
    CGFloat value = [[self.data objectAtIndex:index] floatValue];
//    NSLog(@"Value at %d = %f",index, value);
    return value;
}


- (NSString *)lineGraph:(BEMSimpleLineGraphView *)graph labelOnXAxisForIndex:(NSInteger)index
{
    DLogFuncName();
    return @"";
}


#pragma mark - BEMSSimpleLineGraphViewDelegate

- (void)lineGraphDidBeginLoading:(BEMSimpleLineGraphView *)graph
{
    DLogFuncName();
}


- (void)lineGraphDidFinishLoading:(BEMSimpleLineGraphView *)graph
{
    DLogFuncName();
    
//    BEMCircle *circleDot = [[BEMCircle alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
////    circleDot.center = CGPointMake(positionOnXAxis, positionOnYAxis);
//    circleDot.tag = 200+100;
//    
//    [graph setUpPopUpLabelAbovePoint:circleDot];
}

//
//- (NSString *)popUpSuffixForlineGraph:(BEMSimpleLineGraphView *)graph
//{
//    DLogFuncName();
//    return @"";
//}


- (BOOL)lineGraph:(BEMSimpleLineGraphView *)graph alwaysDisplayPopUpAtIndex:(CGFloat)index
{
    DLogFuncName();
    return NO;
}


- (CGFloat)maxValueForLineGraph:(BEMSimpleLineGraphView *)graph
{
    DLogFuncName();
    return [[self.data valueForKeyPath:@"@max.intValue"] intValue];
}


- (CGFloat)minValueForLineGraph:(BEMSimpleLineGraphView *)graph
{
    DLogFuncName();
    return [[self.data valueForKeyPath:@"@min.intValue"] intValue];
}


//- (void)lineGraph:(BEMSimpleLineGraphView *)graph didTouchGraphWithClosestIndex:(NSInteger)index
//{
//    DLogFuncName();
//}
//
//
//- (void)lineGraph:(BEMSimpleLineGraphView *)graph didReleaseTouchFromGraphWithClosestIndex:(CGFloat)index
//{
//    DLogFuncName();
//}
//
//
//- (NSInteger)numberOfGapsBetweenLabelsOnLineGraph:(BEMSimpleLineGraphView *)graph
//{
//    DLogFuncName();
//    return 0;
//}
//
//
//- (NSInteger)numberOfYAxisLabelsOnLineGraph:(BEMSimpleLineGraphView *)graph
//{
//    DLogFuncName();
//    return 0;
//}
//
//
//- (int)numberOfPointsInGraph
//{
//    DLogFuncName();
//    return 0;
//}
//
//
//- (float)valueForIndex:(NSInteger)index
//{
//    DLogFuncName();
//    return 0;
//}
//
//
//- (void)didTouchGraphWithClosestIndex:(int)index
//{
//    DLogFuncName();
//}
//
//
//- (void)didReleaseGraphWithClosestIndex:(float)index
//{
//    DLogFuncName();
//}
//
//
//- (int)numberOfGapsBetweenLabels
//{
//    DLogFuncName();
//    return 0;
//}
//
//
//- (NSString *)labelOnXAxisForIndex:(NSInteger)index
//{
//    DLogFuncName();
//    return nil;
//}


@end