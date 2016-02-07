//
// Created by Philip Schneider on 10.05.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WYPopoverController.h"

@class PSTrack;
@class PSMapLocationManager;


@interface PSMapViewController : UIViewController  <MKMapViewDelegate, WYPopoverControllerDelegate>

@property (nonatomic) NSArray *tracks;
@property (nonatomic) MKMapView *mapView;

- (instancetype)initWithTrack:(PSTrack *)track;
- (instancetype)initWithTracks:(NSArray *)tracks;

- (void)switchUserTracking;
- (void)clearMap;

@end