//
// Created by Philip Schneider on 06.08.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import "MKMapView+PSZoomLevel.h"


@implementation MKMapView (PSZoomLevel)

- (int)zoomLevel
{
        CLLocationDegrees longitudeDelta = self.region.span.longitudeDelta;
    CGFloat mapWidthInPixels = self.bounds.size.width;
    double zoomScale = longitudeDelta * MERCATOR_RADIUS * M_PI / (180.0 * mapWidthInPixels);
    double zoomer = MAX_GOOGLE_LEVELS - log2( zoomScale );
    if ( zoomer < 0 ) zoomer = 0;


    return round(zoomer+2);
}



@end