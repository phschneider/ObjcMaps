//
// Created by Philip Schneider on 10.05.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PSTrack;


@interface PSMapViewController : UIViewController  <MKMapViewDelegate, CLLocationManagerDelegate>
- (instancetype)initWithTrack:(PSTrack *)track;
- (instancetype)initWithTracks:(NSArray *)tracks;
@end