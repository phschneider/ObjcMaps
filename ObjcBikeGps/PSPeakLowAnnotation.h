//
// Created by Philip Schneider on 06.02.16.
// Copyright (c) 2016 phschneider.net. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PSPeakLowAnnotation : NSObject

@property (nonatomic) NSString *title;
@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic) BOOL isPeak;

- (id) initWithCoordinate:(CLLocationCoordinate2D)coordinate title:(NSString*)title;

@end