//
// Created by Philip Schneider on 10.05.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import "PSTrackList.h"
#import "PSTrack.h"
#import "PSTrackStore.h"
#import "PSMapViewController.h"


@interface PSTrackList ()
@property (nonatomic) UITableView *tableView;
@property (nonatomic) NSMutableArray *tracks;
@end


@implementation PSTrackList

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
    }
    return self;
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
    cell.detailTextLabel.text = [NSString stringWithFormat:@"distace: %@ up: %0.2fm down: %.2fm", [track distanceInKm], [track totalUp], [track totalDown]];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PSTrack *track = [self.tracks objectAtIndex:indexPath.row];

//    PSMapViewController *mapViewController = [[PSMapViewController alloc] initWithTrack:track];
    PSMapViewController *mapViewController = [[PSMapViewController alloc] initWithTracks:self.tracks];
    [self.navigationController pushViewController:mapViewController animated:YES];
}


@end