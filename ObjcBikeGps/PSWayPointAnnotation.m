//
// Created by Philip Schneider on 08.08.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import "PSWayPointAnnotation.h"


@implementation PSWayPointAnnotation

- (id) initWithCoordinate:(CLLocationCoordinate2D)coordinate title:(NSString*)title
{
    self = [super init];
    if (self)
    {
        _title = title;
        _coordinate = coordinate;
    }
    return self;
}


@end