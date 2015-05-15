//
// Created by Philip Schneider on 10.05.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PSTrackType) {
    PSTrackTypeUnknown,
    PSTrackTypeTrail,
    PSTrackTypeRoundTrip
};


@interface PSTrack : NSObject
@property (nonatomic, readonly) NSString *filename;

@property (nonatomic) CGFloat distance;
@property (nonatomic) PSTrackType trackType;

- (instancetype)initWithFilename:(NSString *)filename;
- (instancetype)initWithFilename:(NSString *)filename trackType:(PSTrackType)trackType;

- (int)numberOfCoordinates;
- (CLLocationCoordinate2D*)coordinates;
- (NSString *)distanceInKm;
- (MKPolyline *)route;
- (CGFloat)distanceFromLocation:(CLLocation *)location;
- (MKMapPoint)start;
- (MKMapPoint)finish;
- (MKPolylineView *)overlayView;
- (NSArray *)distanceAnnotations;

- (NSString*)roundedUp;
- (NSString *)roundedDown;
@end