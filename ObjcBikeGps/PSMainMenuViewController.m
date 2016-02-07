//
// Created by Philip Schneider on 19.11.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PSMainMenuViewController.h"
#import "PSMapViewController.h"
#import "PSTracksViewController.h"
#import "PSGridButton.h"
#import "PSTrackStore.h"


@implementation PSMainMenuViewController

- (instancetype)init
{
    DLogFuncName();
    self = [super init];

    if (self)
    {
        self.edgesForExtendedLayout = UIRectEdgeBottom;
        self.extendedLayoutIncludesOpaqueBars = NO;
    }
    return self;
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    DLogFuncName();

    CGFloat padding = 25;

    PSGridButton *mapsButton = [PSGridButton buttonWithType:UIButtonTypeRoundedRect];
    mapsButton.backgroundColor = [UIColor whiteColor];
    [mapsButton setTitle:@"Maps" forState:UIControlStateNormal];
    [mapsButton addTarget:self action:@selector(showMaps) forControlEvents:UIControlEventTouchUpInside];
    CGRect frame = CGRectZero;
    frame.origin.x = 50;
    frame.origin.y = 50;
    frame.size.width = ceil((self.view.frame.size.width - (2*frame.origin.x) - padding) / 2);
    frame.size.height = frame.size.width;
    mapsButton.frame = frame;
    mapsButton.layer.borderColor = [[UIColor darkGrayColor] CGColor];
    mapsButton.layer.borderWidth = 1.0;
    mapsButton.layer.cornerRadius = 5.0;
    [self.view addSubview:mapsButton];

    PSGridButton *tracksButton = [PSGridButton buttonWithType:UIButtonTypeRoundedRect];
    tracksButton.backgroundColor = [UIColor whiteColor];
    [tracksButton setTitle:@"Tracks" forState:UIControlStateNormal];
    [tracksButton addTarget:self action:@selector(showTracks) forControlEvents:UIControlEventTouchUpInside];
    frame.origin.x += padding + frame.size.width;
    tracksButton.frame = frame;
    tracksButton.layer.borderColor = [[UIColor darkGrayColor] CGColor];
    tracksButton.layer.borderWidth = 1.0;
    tracksButton.layer.cornerRadius = 5.0;

    [self.view addSubview:tracksButton];

    PSGridButton *trailsButton = [PSGridButton buttonWithType:UIButtonTypeRoundedRect];
    trailsButton.backgroundColor = [UIColor whiteColor];
    [trailsButton setTitle:@"Trails" forState:UIControlStateNormal];
    [trailsButton addTarget:self action:@selector(showTrails) forControlEvents:UIControlEventTouchUpInside];
    frame = mapsButton.frame;
    frame.origin.y += padding + frame.size.width;
    trailsButton.frame = frame;
    trailsButton.layer.borderColor = [[UIColor darkGrayColor] CGColor];
    trailsButton.layer.borderWidth = 1.0;
    trailsButton.layer.cornerRadius = 5.0;

    [self.view addSubview:trailsButton];
}


- (void)showMaps
{
    DLogFuncName();

    PSMapViewController *mapViewController = [[PSMapViewController alloc] init];
    [self.navigationController pushViewController:mapViewController animated:YES];
}


- (void)showTracks
{
    DLogFuncName();

    PSTracksViewController *tracksViewController = [[PSTracksViewController alloc] initWithTitle:@"Touren" tracks:[[PSTrackStore sharedInstance] routes]];
    [self.navigationController pushViewController:tracksViewController animated:YES];
}


- (void)showTrails
{
    DLogFuncName();

    PSTracksViewController *tracksViewController = [[PSTracksViewController alloc] initWithTitle:@"Trails" tracks:[[PSTrackStore sharedInstance] trails]];
    [self.navigationController pushViewController:tracksViewController animated:YES];
}


@end