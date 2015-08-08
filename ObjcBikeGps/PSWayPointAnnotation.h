//
// Created by Philip Schneider on 08.08.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PSWayPointAnnotation : NSObject

@property (nonatomic) NSString *title;
@property (nonatomic) CLLocationCoordinate2D coordinate;

- (id) initWithCoordinate:(CLLocationCoordinate2D)coordinate title:(NSString*)title;

@end