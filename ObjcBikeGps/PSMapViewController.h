//
// Created by Philip Schneider on 10.05.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PSTrack;


@interface PSMapViewController : UIViewController  <MKMapViewDelegate, CLLocationManagerDelegate>

@property (nonatomic) MKMapView *mapView;
@property (nonatomic) NSArray *tracks;

- (instancetype)initWithTrack:(PSTrack *)track;
- (instancetype)initWithTracks:(NSArray *)tracks;

- (void)clearMap;
@end