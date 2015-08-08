//
// Created by Philip Schneider on 10.05.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import <BFNavigationBarDrawer/BFNavigationBarDrawer.h>
#import "PSTracksViewController.h"
#import "PSTrack.h"
#import "PSTrackStore.h"
#import "PSMapViewController.h"
#import "DZNSegmentedControl.h"
#import "BFNavigationBarDrawer.h"
#import "PSTrackViewController.h"


@interface PSTracksViewController ()
@property (nonatomic) UITableView *tableView;
@property (nonatomic) NSArray *tracks;
@property (nonatomic) NSArray *visibleTracks;
@property (nonatomic) PSMapViewController *mapViewController;
@property (nonatomic) DZNSegmentedControl *control;
@property (nonatomic, strong) BFNavigationBarDrawer *filterDrawer;
@property (nonatomic, strong) BFNavigationBarDrawer *sortingDrawer;
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
        self.tableView.autoresizingMask = self.view.autoresizingMask;
        self.tableView.delegate = self;
        self.tableView.dataSource = self;

        [self.view addSubview:self.tableView];

        self.mapViewController = [[PSMapViewController alloc] initWithTracks:self.visibleTracks];

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

        UIBarButtonItem *sortButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(showSortingOptions)];
        self.navigationItem.rightBarButtonItem = sortButton;


        UIBarButtonItem *filterButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"798-filter-toolbar"] style:UIBarButtonItemStylePlain target:self action:@selector(showFilterOptions)];
        self.navigationItem.leftBarButtonItem = filterButton;


        // Init a drawer with default size
        self.filterDrawer = [[BFNavigationBarDrawer alloc] init];

        // Assign the table view as the affected scroll view of the drawer.
        // This will make sure the scroll view is properly scrolled and updated
        // when the drawer is shown.
        self.filterDrawer.scrollView = self.tableView;
        [self.filterDrawer addSubview:self.control];


        self.sortingDrawer = [[BFNavigationBarDrawer alloc] init];

        // Assign the table view as the affected scroll view of the drawer.
        // This will make sure the scroll view is properly scrolled and updated
        // when the drawer is shown.
        self.sortingDrawer.scrollView = self.tableView;

        // Add some buttons to the drawer.
        UIBarButtonItem *button1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(sortByName)];
        UIBarButtonItem *button2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:0];
        UIBarButtonItem *button3 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(sortByDistance)];
        UIBarButtonItem *button4 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:0];
        UIBarButtonItem *button5 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(sortByLength)];
        UIBarButtonItem *button6 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:0];
        UIBarButtonItem *button7 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(sortByUp)];
        UIBarButtonItem *button8 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:0];
        UIBarButtonItem *button9 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(sortByDown)];
        self.sortingDrawer.items = @[button1, button2, button3, button4, button5, button6, button7, button8, button9];
    }
    return self;
}


- (void)sortByName
{
    NSArray *tmpArray = [self.visibleTracks copy];
    self.visibleTracks = [tmpArray sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"filename" ascending:YES]]];
    [self.tableView reloadData];
}


- (void)sortByLength
{
    NSArray *tmpArray = [self.visibleTracks copy];
    self.visibleTracks = [tmpArray sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"trackLength" ascending:YES]]];
    [self.tableView reloadData];
}


- (void)sortByDistance
{
    NSArray *tmpArray = [self.visibleTracks copy];
    self.visibleTracks = [tmpArray sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"trackLength" ascending:YES]]];
    [self.tableView reloadData];
}


- (void)sortByUp
{
    NSArray *tmpArray = [self.visibleTracks copy];
    self.visibleTracks = [tmpArray sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"totalUp" ascending:YES]]];
    [self.tableView reloadData];
}


- (void)sortByDown
{
    NSArray *tmpArray = [self.visibleTracks copy];
    self.visibleTracks = [tmpArray sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"totalDown" ascending:YES]]];
    [self.tableView reloadData];
}


- (void)showSortingOptions
{
    if ([self.filterDrawer isVisible])
    {
        [self showFilterOptions];
    }

    if (![self.sortingDrawer isVisible])
    {
        [self.sortingDrawer showFromNavigationBar:self.navigationController.navigationBar animated:YES];
    }
    else
    {
        [self.sortingDrawer hideAnimated:YES];
    }
}


- (void)showFilterOptions
{
    if ([self.sortingDrawer isVisible])
    {
        [self showSortingOptions];
    }

    if (![self.filterDrawer isVisible])
    {
        [self.filterDrawer showFromNavigationBar:self.navigationController.navigationBar animated:YES];
        [self.control layoutSubviews];
    }
    else
    {
        [self.filterDrawer hideAnimated:YES];
    }
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

    [self.mapViewController clearMap];

    //    NSArray *clearableAnnotations = [self.mapView overlaysInLevel:MKOverlayLevelAboveRoads];

//    [self.mapViewController.mapView removeOverlays:self.mapViewController.mapView.overlays];
    [self.mapViewController setTracks:self.visibleTracks];
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
//        // Assign the table view as the affected scroll view of the drawer.
//        // This will make sure the scroll view is properly scrolled and updated
//        // when the drawer is shown.
//        self.filterDrawer.scrollView = self.tableView;

        self.navigationItem.rightBarButtonItem.enabled = YES;
        self.tableView.hidden = NO;
        self.mapViewController.view.hidden = YES;
    }
    else
    {
        if ([self.sortingDrawer isVisible])
        {
            [self showSortingOptions];
        }

        self.navigationItem.rightBarButtonItem.enabled = NO;
        self.tableView.hidden = YES;
        self.mapViewController.view.hidden = NO;

        [self.mapViewController clearMap];
        [self.mapViewController setTracks:self.visibleTracks];
//        [self.mapViewController.mapView layoutSubviews];
        if (self.mapViewController.view.superview == nil)
        {
//            [self.mapViewController willMoveToParentViewController:self];
            [self addChildViewController:self.mapViewController];
            // Ruft ein viewWillAppear auf ...
            [self.view addSubview:self.mapViewController.view];

        }
        [self.mapViewController didMoveToParentViewController:self];
    }
}


- (void) observeValueForKeyPath:(NSString *)keyPath
                       ofObject:(id)object
                         change:(NSDictionary *)change
                        context:(void *)context
{
    if ([keyPath isEqualToString:@"tracks"])
    {
        dispatch_async(dispatch_get_main_queue(),^{
            self.tracks = [NSArray arrayWithArray:[change objectForKey:@"new"]];
            self.visibleTracks = [NSArray arrayWithArray:[change objectForKey:@"new"]];

            [self.tableView reloadData];

            [self.control setCount:@([self.tracks count]) forSegmentAtIndex:0];
            [self.control setCount:@([[self.tracks filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"trackType = %d",PSTrackTypeTrail]] count]) forSegmentAtIndex:1];
            [self.control setCount:@([[self.tracks filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"trackType = %d",PSTrackTypeRoundTrip]] count]) forSegmentAtIndex:2];
            [self.control setCount:@([[self.tracks filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"trackType = %d",PSTrackTypeUnknown]] count]) forSegmentAtIndex:3];
        });
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
    [track snapShot];
    cell.textLabel.text = [track filename];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ \t\t\tup: %@\tdown: %@ (%d)", [track distanceInKm], [track roundedUp], [track roundedDown], [[track elevationData] count] ];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.sortingDrawer isVisible])
    {
        [self.filterDrawer hideAnimated:YES];
    }

    if ([self.filterDrawer isVisible])
    {
        [self.filterDrawer hideAnimated:YES];
    }

    PSTrack *track = [self.visibleTracks objectAtIndex:indexPath.row];

//    PSMapViewController *mapViewController = [[PSMapViewController alloc] initWithTrack:track];
    PSTrackViewController *trackViewController = [[PSTrackViewController alloc] initWithTrack:track];
    [self.navigationController pushViewController:trackViewController animated:YES];
}


- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

@end
