//
// Created by Philip Schneider on 06.08.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import <Foundation/Foundation.h>

#define MERCATOR_RADIUS 85445659.44705395
#define MAX_GOOGLE_LEVELS 20

@interface MKMapView (PSZoomLevel)

- (int) zoomLevel;

@end
