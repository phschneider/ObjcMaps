//
// Created by Philip Schneider on 10.05.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ONOXMLElement;
@class ONOXMLDocument;


typedef NS_ENUM(NSInteger, PSTrackType) {
    PSTrackTypeUnknown,
    PSTrackTypeTrail,
    PSTrackTypeRoundTrip
};


@interface PSTrack : NSObject
@property (nonatomic, readonly) NSString *filename;

@property (nonatomic) CGFloat trackLength;
@property (nonatomic) PSTrackType trackType;
@property (nonatomic) CGFloat totalUp;

@property (nonatomic) UIColor *color;
@property (nonatomic) CGFloat alpha;
@property (nonatomic) CGFloat lineWidth;
@property (nonatomic) NSArray *lineDashPattern;

- (instancetype)initWithFilename:(NSString *)filename;
- (instancetype)initWithFilename:(NSString *)filename trackType:(PSTrackType)trackType;

- (instancetype)initWithXmlData:(ONOXMLElement *)onoxmlElement document:(ONOXMLDocument *)document;

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
- (NSString *)title;

@end