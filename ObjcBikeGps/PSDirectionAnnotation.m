//
// Created by Philip Schneider on 28.12.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import "PSDirectionAnnotation.h"


@implementation PSDirectionAnnotation

- (id) initWithCoordinate:(CLLocationCoordinate2D)coordinate title:(NSString*)title
{
    DLogFuncName();
    self = [super init];
    if (self)
    {
        _title = title;
        _coordinate = coordinate;
    }
    return self;
}

@end