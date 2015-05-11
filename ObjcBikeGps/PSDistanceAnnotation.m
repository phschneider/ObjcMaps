//
//  PSDistanceAnnotation.m
//  ObjcBikeGps
//
//  Created by Philip Schneider on 03.05.15.
//  Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import "PSDistanceAnnotation.h"

@implementation PSDistanceAnnotation

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
