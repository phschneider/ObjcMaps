//
// Created by Philip Schneider on 10.05.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ONOXMLElement;
@class ONOXMLDocument;
@class BEMSimpleLineGraphView;

typedef NS_ENUM(NSInteger, PSTrackType) {
    PSTrackTypeUnknown,
    PSTrackTypeTrail,
    PSTrackTypeMTBTrip,
    PSTrackTypeBikeTrip,
    PSTrackTypeRoundTrip,
    PSTrackTypeCustom,
    PSTrackTypeOsm
};


@interface PSTrack : NSObject
@property (nonatomic, readonly) NSString *filename;

@property (nonatomic) CGFloat trackLength;
@property (nonatomic) CGFloat trackDuration;
@property (nonatomic) PSTrackType trackType;
@property (nonatomic) CGFloat totalUp;
@property (nonatomic) NSArray *elevationData;
@property (nonatomic) NSArray *smoothedElevationData;

@property (nonatomic) UIColor *color;
@property (nonatomic) CGFloat alpha;
@property (nonatomic) CGFloat lineWidth;
@property (nonatomic) NSArray *lineDashPattern;
@property (nonatomic) BEMSimpleLineGraphView *graphView;
@property (nonatomic) CGFloat maxElevationData;
@property (nonatomic) CGFloat minElevationData;
@property (nonatomic) CGFloat elevationDiff;
@property (nonatomic) NSArray *wayPoints;
@property (nonatomic) CLLocation *peak;
@property (nonatomic) CLLocation *low;

@property (nonatomic,readonly) NSDictionary *infoTags;

@property (nonatomic) UIImage *lineGraphSnapShotImage;
- (instancetype)initWithFilename:(NSString *)filename;
- (instancetype)initWithFilename:(NSString *)filename trackType:(PSTrackType)trackType;


- (UIImage *)lineGraphSnapShotImageWithWidth:(CGFloat)width;

- (instancetype)initWithXmlData:(ONOXMLElement *)onoxmlElement document:(ONOXMLDocument *)document;

- (int)numberOfCoordinates;
- (CLLocationCoordinate2D*)coordinates;

- (NSArray *)elevationAnnotations;

- (NSString *)distanceInKm;

- (NSString *)readableTrackDuration;

- (MKPolyline *)route;
- (CGFloat)distanceFromLocation:(CLLocation *)location;
- (MKMapPoint)start;
- (MKMapPoint)finish;

- (BOOL)isDownhill;

- (BOOL)isUphill;

- (MKPolylineView *)overlayView;
- (NSArray *)distanceAnnotations;

- (NSArray *)directionAnnotations;

- (UIImage *)snapShot;
- (UIImage *)drawRoute:(MKPolyline *)polyline onSnapshot:(MKMapSnapshot *)snapShot withColor:(UIColor *)lineColor;
- (NSString*)roundedUp;
- (NSString *)roundedDown;
- (NSString *)title;

@end