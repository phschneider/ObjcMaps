//
// Created by Philip Schneider on 06.02.16.
// Copyright (c) 2016 phschneider.net. All rights reserved.
//

#import "PSPeakLowAnnotation.h"


@implementation PSPeakLowAnnotation

- (id) initWithCoordinate:(CLLocationCoordinate2D)coordinate title:(NSString*)title
{
    DLogFuncName();
    self = [super init];
    if (self)
    {
        _title = title;
        _coordinate = coordinate;
        _isPeak = NO;
    }
    return self;
}

@end