//
// Created by Philip Schneider on 10.05.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import "PSTracksViewController.h"
#import "PSTrack.h"
#import "PSTrackStore.h"
#import "PSMapViewController.h"


@interface PSTracksViewController ()
@property (nonatomic) UITableView *tableView;
@property (nonatomic) NSMutableArray *tracks;
@property (nonatomic) MKMapView *mapView;
@property (nonatomic) PSMapViewController *mapViewController;
@end


@implementation PSTracksViewController

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.tracks = [[NSMutableArray alloc] init];

        self.title = @"Strecken";
        self.tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
        self.tableView.delegate = self;
        self.tableView.dataSource = self;

        [self.view addSubview:self.tableView];


        [[PSTrackStore sharedInstance] addObserver:self forKeyPath:@"tracks" options:NSKeyValueObservingOptionNew context:nil];


        UISegmentedControl *viewSwitcher = [[UISegmentedControl alloc] initWithItems: @[ [UIImage imageNamed:@"854-list-toolbar-selected"],[UIImage imageNamed:@"852-map-toolbar"]]];
        [viewSwitcher setSelectedSegmentIndex:0];
        [viewSwitcher addTarget:self action:@selector(viewSwitched:) forControlEvents:UIControlEventValueChanged];
        viewSwitcher.segmentedControlStyle = UISegmentedControlStyleBordered;
        self.navigationItem.titleView = viewSwitcher;
    }
    return self;
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

        self.mapViewController = [[PSMapViewController alloc] initWithTracks:self.tracks];
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

        self.tracks = [NSMutableArray arrayWithArray:[change objectForKey:@"new"]];
        NSLog(@"Add Entries = %d",[[change objectForKey:@"new"] count]);
//        [self.tracks addObjectsFromArray:[change objectForKey:@"new"]];
        [self.tableView reloadData];
    }
}



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self tracks] count];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    UITableViewCell * cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    PSTrack *track = [self.tracks objectAtIndex:indexPath.row];
    cell.textLabel.text = [track filename];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"distace: %@  %@ down: %@", [track distanceInKm], [track roundedUp], [track roundedDown]];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PSTrack *track = [self.tracks objectAtIndex:indexPath.row];

    PSMapViewController *mapViewController = [[PSMapViewController alloc] initWithTrack:track];
    [self.navigationController pushViewController:mapViewController animated:YES];
}


@end