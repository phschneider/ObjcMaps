//
//  PSMapAnnotation.m
//  ObjcBikeGps
//
//  Created by Philip Schneider on 07.02.16.
//  Copyright © 2016 phschneider.net. All rights reserved.
//

#import "PSMapAnnotation.h"

@implementation PSMapAnnotation


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
