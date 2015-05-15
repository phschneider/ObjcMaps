//
// Created by Philip Schneider on 10.05.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import "PSTracksViewController.h"
#import "PSTrack.h"
#import "PSTrackStore.h"
#import "PSMapViewController.h"
#import "DZNSegmentedControl.h"


@interface PSTracksViewController ()
@property (nonatomic) UITableView *tableView;
@property (nonatomic) NSArray *tracks;
@property (nonatomic) NSArray *visibleTracks;
@property (nonatomic) MKMapView *mapView;
@property (nonatomic) PSMapViewController *mapViewController;
@property (nonatomic) DZNSegmentedControl *control;
@end


@implementation PSTracksViewController

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.tracks = [[NSArray alloc] init];
        self.visibleTracks = [[NSArray alloc] init];

        self.title = @"Strecken";
        self.tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
        self.tableView.delegate = self;
        self.tableView.dataSource = self;

        [self.view addSubview:self.tableView];


        [[PSTrackStore sharedInstance] addObserver:self forKeyPath:@"tracks" options:NSKeyValueObservingOptionNew context:nil];


        UISegmentedControl *viewSwitcher = [[UISegmentedControl alloc] initWithItems: @[ [UIImage imageNamed:@"854-list-toolbar-selected"],[UIImage imageNamed:@"852-map-toolbar"]]];
        [viewSwitcher setSelectedSegmentIndex:0];
        [viewSwitcher addTarget:self action:@selector(viewSwitched:) forControlEvents:UIControlEventValueChanged];
        self.navigationItem.titleView = viewSwitcher;

        NSArray *items = @[@"All", @"Trails", @"Routes", @"Unknown"];

        self.control = [[DZNSegmentedControl alloc] initWithItems:items];
        self.control.tintColor = [UIColor blueColor];
        self.control.delegate = self;
        self.control.selectedSegmentIndex = 0;

        [self.control setCount:@([self.tracks count]) forSegmentAtIndex:0];
        [self.control setCount:@([[self.tracks filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"trackType = %d",PSTrackTypeTrail]] count]) forSegmentAtIndex:1];
        [self.control setCount:@([[self.tracks filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"trackType = %d",PSTrackTypeRoundTrip]] count]) forSegmentAtIndex:2];
        [self.control setCount:@([[self.tracks filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"trackType = %d",PSTrackTypeUnknown]] count]) forSegmentAtIndex:3];

        [self.control addTarget:self action:@selector(selectedSegment:) forControlEvents:UIControlEventValueChanged];
        self.tableView.tableHeaderView = self.control;
    }
    return self;
}


- (void)selectedSegment:(UISegmentedControl*)segmentedControl
{
    int index = segmentedControl.selectedSegmentIndex;
     switch (index)
     {
         case 0:
             self.visibleTracks = [self.tracks copy];
             break;
         case 1:
             self.visibleTracks = [self.tracks filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"trackType = %d",PSTrackTypeTrail]];
             break;
         case 2:
             self.visibleTracks = [self.tracks filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"trackType = %d",PSTrackTypeRoundTrip]];
             break;
         case 3:
             self.visibleTracks = [self.tracks filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"trackType = %d",PSTrackTypeUnknown]];
             break;
     };

    [self.tableView reloadData];
}


- (UIBarPosition)positionForBar:(id <UIBarPositioning>)bar
{
    return UIBarPositionAny;
}

- (void)viewSwitched:(UISegmentedControl*)segmentedControl
{
    if (segmentedControl.selectedSegmentIndex == 0)
    {
        self.tableView.hidden = NO;

        self.mapView.hidden = YES;
        if (self.mapView)
        {
            [self.mapView removeFromSuperview];
            self.mapViewController = nil;
        }
    }
    else
    {
        self.tableView.hidden = YES;

        self.mapViewController = [[PSMapViewController alloc] initWithTracks:self.visibleTracks];
        self.mapView = self.mapViewController.mapView;
        self.mapView.hidden = NO;
        [self.view addSubview:self.mapView];
    }
}


- (void) observeValueForKeyPath:(NSString *)keyPath
                       ofObject:(id)object
                         change:(NSDictionary *)change
                        context:(void *)context
{
    if ([keyPath isEqualToString:@"tracks"])
    {

        self.tracks = [NSArray arrayWithArray:[change objectForKey:@"new"]];
        self.visibleTracks = [NSArray arrayWithArray:[change objectForKey:@"new"]];

        NSLog(@"Add Entries = %d",[[change objectForKey:@"new"] count]);
//        [self.tracks addObjectsFromArray:[change objectForKey:@"new"]];
        [self.tableView reloadData];

        [self.control setCount:@([self.tracks count]) forSegmentAtIndex:0];
        [self.control setCount:@([[self.tracks filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"trackType = %d",PSTrackTypeTrail]] count]) forSegmentAtIndex:1];
        [self.control setCount:@([[self.tracks filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"trackType = %d",PSTrackTypeRoundTrip]] count]) forSegmentAtIndex:2];
        [self.control setCount:@([[self.tracks filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"trackType = %d",PSTrackTypeUnknown]] count]) forSegmentAtIndex:3];
    }
}



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[self visibleTracks] copy] count];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    UITableViewCell * cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    PSTrack *track = [self.visibleTracks objectAtIndex:indexPath.row];
    cell.textLabel.text = [track filename];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"distace: %@  %@ down: %@", [track distanceInKm], [track roundedUp], [track roundedDown]];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PSTrack *track = [self.visibleTracks objectAtIndex:indexPath.row];

    PSMapViewController *mapViewController = [[PSMapViewController alloc] initWithTrack:track];
    [self.navigationController pushViewController:mapViewController animated:YES];
}


@end