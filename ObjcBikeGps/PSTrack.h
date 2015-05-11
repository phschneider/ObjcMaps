//
// Created by Philip Schneider on 10.05.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PSTrack : NSObject
@property (nonatomic, readonly) NSString *filename;

@property (nonatomic) CGFloat totalUp;
@property (nonatomic) CGFloat totalDown;
@property (nonatomic) CGFloat distance;

- (instancetype)initWithFilename:(NSString *)filename;
- (int)numberOfCoordinates;
- (CLLocationCoordinate2D*)coordinates;
- (NSString *)distanceInKm;
- (MKPolyline *)route;
- (CGFloat)distanceFromLocation:(CLLocation *)location;
- (MKMapPoint)start;
- (MKMapPoint)finish;
- (MKPolylineView *)overlayView;
- (NSArray *)distanceAnnotations;
@end