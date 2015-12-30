//
// Created by Philip Schneider on 07.08.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import "PSTrackViewController.h"
#import "PSTrack.h"
#import "BEMSimpleLineGraphView.h"
#import "PSMapViewController.h"


@interface PSTrackViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic) UITableView *tableView;
@property (nonatomic) PSTrack *track;
@end


@implementation PSTrackViewController

- (instancetype)init
{
    DLogFuncName();
    self = [super init];
    if (self)
    {
        self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        self.tableView.autoresizingMask = self.view.autoresizingMask;
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        [self.view addSubview:self.tableView];
    }
    return self;
}


- (instancetype)initWithTrack:(PSTrack*)track
{
    DLogFuncName();
    self = [self init];
    if (self)
    {
        self.track = track;
        self.title = self.track.filename;
    }
    return self;
}


#pragma mark - Cell


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    DLogFuncName();
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[self.track snapShot] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(headerButtonTapped:) forControlEvents:UIControlEventTouchUpInside];

    return button;

}


- (void)headerButtonTapped:(id)headerButtonTapped
{
    DLogFuncName();
    PSMapViewController *mapViewController = [[PSMapViewController alloc] initWithTrack:self.track];
    [self.navigationController pushViewController:mapViewController animated:YES];
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    DLogFuncName();
    [self.track lineGraphSnapShotImage];
    return self.track.graphView;
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    DLogFuncName();
    return 250.0;
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    DLogFuncName();
    return 200.0;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    DLogFuncName();
    return 6;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    DLogFuncName();
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DLogFuncName();
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellIdentifier" forIndexPath:indexPath];
//    cell.textLabel.text = @"Test";

    UITableViewCell * cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    NSString *text = @"-";
    NSString *value = @"-";
    cell.userInteractionEnabled = NO;
    
    switch (indexPath.row)
    {
        case 0:
            text = [NSString stringWithFormat:@"Length:"];
            value = [self.track distanceInKm];
            break;
        case 1:
            text = [NSString stringWithFormat:@"Duration:"];
            value = [self.track readableTrackDuration];
            break;
        case 2:
            text = [NSString stringWithFormat:@"Up"];
            value = [self.track roundedUp];
            break;
        case 3:
            text = [NSString stringWithFormat:@"Down"];
            value = [self.track roundedDown];
            break;
        case 4:
            text = [NSString stringWithFormat:@"min"];
            value = [NSString stringWithFormat:@"%.0fm", [self.track minElevationData]];
            break;
        case 5:
            text = [NSString stringWithFormat:@"max"];
            value = [NSString stringWithFormat:@"%.0fm", [self.track maxElevationData]];
            break;
    }
    cell.textLabel.text = text;
    cell.detailTextLabel.text = value;
    return cell;
}


#pragma mark - BEMSSimpleLineGraphViewDelegate
//
//- (void)lineGraphDidFinishLoading:(BEMSimpleLineGraphView *)graph
//{
//    DLogFuncName();
//
////    BEMCircle *circleDot = [[BEMCircle alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
//////    circleDot.center = CGPointMake(positionOnXAxis, positionOnYAxis);
////    circleDot.tag = 200+100;
////
////    [graph setUpPopUpLabelAbovePoint:circleDot];
//}

//
//- (NSString *)popUpSuffixForlineGraph:(BEMSimpleLineGraphView *)graph
//{
//    DLogFuncName();
//    return @"";
//}
//
//
//- (BOOL)lineGraph:(BEMSimpleLineGraphView *)graph alwaysDisplayPopUpAtIndex:(CGFloat)index
//{
//    DLogFuncName();
//    return NO;
//}
//
//

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
//    return 5;
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
