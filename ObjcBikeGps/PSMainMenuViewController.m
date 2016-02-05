//
// Created by Philip Schneider on 19.11.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PSMainMenuViewController.h"
#import "CNPGridMenu.h"
#import "PSMapViewController.h"
#import "PSTracksViewController.h"


@implementation PSMainMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    CNPGridMenuItem *tracks = [[CNPGridMenuItem alloc] init];
        tracks.icon = [UIImage imageNamed:@"LaterToday"];
        tracks.title = @"Tracks";

        CNPGridMenuItem *map = [[CNPGridMenuItem alloc] init];
        map.icon = [UIImage imageNamed:@"ThisEvening"];
        map.title = @"Map";

        CNPGridMenu *gridMenu = [[CNPGridMenu alloc] initWithMenuItems:@[tracks,map]];
        gridMenu.delegate = self;
    [gridMenu.view willMoveToSuperview:self.view];
    [self.view addSubview:gridMenu.view];
    [gridMenu.view didMoveToSuperview];
}



- (void)gridMenu:(CNPGridMenu *)menu didTapOnItem:(CNPGridMenuItem *)item {

    if ([[item.title lowercaseString] isEqualToString:@"map"])
    {
        PSMapViewController *mapViewController = [[PSMapViewController alloc] init];
        [self.navigationController pushViewController:mapViewController animated:YES];
    }

//    if ([[item.title lowercaseString] isEqualToString:@"tracks"])
//    {
//        PSTracksViewController *tracksViewController= [[PSTracksViewController alloc] init];
//        [self.navigationController pushViewController:tracksViewController animated:YES];
//    }

}


@end