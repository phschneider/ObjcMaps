//
// Created by Philip Schneider on 28.12.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PSDirectionAnnotation : NSObject

@property (nonatomic) NSString *title;
@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic) CLLocationDegrees degrees;

- (id) initWithCoordinate:(CLLocationCoordinate2D)coordinate title:(NSString*)title;

@end