//
// Created by Philip Schneider on 10.05.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import <XMLDictionary/XMLDictionary.h>
#import <MapKit/MapKit.h>
#import <Ono/ONOXMLDocument.h>
#import "PSTrack.h"
#import "PSDistanceAnnotation.h"
#import "PSTrackOverlay.h"


@interface PSTrack()
@property (nonatomic) CGFloat totalDown;
@property (nonatomic) NSString *filename;
@property (nonatomic) MKMapPoint *pointArr;
@property (nonatomic) CLLocationCoordinate2D *pointsCoordinate;
@property (nonatomic) int pointArrCount;
@property (nonatomic) NSMutableDictionary *distanceAnnotationsDict;
@property (nonatomic) NSMutableDictionary *tags;
@end


@implementation PSTrack

- (instancetype)initWithFilename:(NSString*)filename
{
    self = [super init];
    if (self)
    {
        self.trackType = PSTrackTypeUnknown;
        self.filename = filename;
        self.color = [UIColor blueColor];
        self.alpha = 1.0;
        self.lineWidth = 2.5;
        self.lineDashPattern = @[@2, @5];

        [self parseElevationFile];
    }
    return self;
}


- (instancetype)initWithFilename:(NSString *)filename trackType:(PSTrackType)trackType
{
    self = [self initWithFilename:filename];
    if (self)
    {
        self.trackType = trackType;
    }
    return self;
}


- (instancetype)initWithXmlData:(ONOXMLElement*)onoxmlElement document:(ONOXMLDocument*)document
{
    DLogFuncName();
    self = [super init];
    if (self)
    {
        __block NSMutableArray *points = [[NSMutableArray alloc] init];
        __block NSMutableDictionary*wayTags = [[NSMutableDictionary alloc] init];
        
        for (ONOXMLElement *child in [onoxmlElement childrenWithTag:@"tag"])
        {
            [wayTags setObject:[child valueForAttribute:@"v"] forKey:[child valueForAttribute:@"k"]];
        }
        
        
        for (ONOXMLElement *child in [onoxmlElement childrenWithTag:@"nd"])
        {
            NSString *nodeId = [child valueForAttribute:@"ref"];
            NSString *xPathString = [NSString stringWithFormat:@"//node[@id=%@]",nodeId];
            [document enumerateElementsWithXPath:xPathString usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop) {
//                NSLog(@"%@", element);
                NSNumber *lat = [element valueForAttribute:@"lat"];
                NSNumber *lon = [element valueForAttribute:@"lon"];
                NSMutableDictionary *pointDict = [[NSMutableDictionary alloc] init];
                [pointDict setObject:lat forKey:@"_lat"];
                [pointDict setObject:lon forKey:@"_lon"];
                [points addObject:pointDict];
            }];
        }


        NSDictionary *dictionary = @{ @"trk" :  @{ @"trkseg" : @{ @"trkpt" : points} } };
        [self parseDictionary:dictionary];
        self.color = [UIColor redColor];
        self.alpha = 0.5;
        self.lineWidth = 2.5;
        self.lineDashPattern = @[@5, @5];
        self.tags = [wayTags copy];
    }
    
    return self;
}


#pragma mark - Informations
- (NSString*)title
{
    NSMutableString *titleString = [[NSMutableString alloc] init];
    for (NSString *key in [self.tags allKeys])
    {
        [titleString appendFormat:@"%@ = %@",key, [self.tags objectForKey:key]];
    }
    return titleString;
}


- (NSString*)roundedUp
{
    DLogFuncName();
    return [NSString stringWithFormat:@"%0.0fm",self.totalUp];
}

- (NSString*)roundedDown
{
    DLogFuncName();
    return [NSString stringWithFormat:@"%0.0fm",self.totalDown];
}


- (NSString*)filepath
{
    return [[NSBundle mainBundle] pathForResource:self.filename ofType:@"gpx"];
}


#pragma mark - Parsing
- (void) parseElevationFile
{
    NSData *data = [NSData dataWithContentsOfFile:[self filepath]];
    if (data)
    {
        NSDictionary *routingDict = [NSDictionary dictionaryWithXMLData:data];
//        NSLog(@"routingDict  %@", routingDict);
        [self parseDictionary:routingDict];
    }
    else
    {
//        NSLog(@"No Data for %@", [self filepath]);
    }
}


- (void)parseDictionary:(NSDictionary *)routingDict
{
    NSArray *trek = [[[routingDict objectForKey:@"trk"] objectForKey:@"trkseg"] objectForKey:@"trkpt"];

    NSMutableArray *elevatioNData = [[NSMutableArray alloc] initWithCapacity:[trek count]];
    self.distanceAnnotationsDict = [[NSMutableDictionary alloc] initWithCapacity:[trek count]];

    self.pointsCoordinate = (CLLocationCoordinate2D *)malloc(sizeof(CLLocationCoordinate2D) * [trek count]);

    CLLocation* Location1;
    CLLocation *tmpLocation;
    CLLocationDistance distance = 0.0;

    int pointArrCount = 0;  //it's simpler to keep a separate index for pointArr
    CGFloat minHeight = 0.0;
    CGFloat maxHeight = 0.0;

    self.totalDown = 0.0;
    self.totalUp = 0.0;

    CGFloat tmpElevation = 0.0;

    for (NSDictionary * pointDict in trek)
        {

            CGFloat lat = [[pointDict objectForKey:@"_lat"] doubleValue];
            CGFloat lon = [[pointDict objectForKey:@"_lon"] doubleValue];

            CLLocationCoordinate2D workingCoordinate = CLLocationCoordinate2DMake(lat, lon);
            self.pointsCoordinate[pointArrCount] = workingCoordinate;

            CGFloat elevation = [[pointDict objectForKey:@"ele"] doubleValue];
            if (pointArrCount > 0)
            {
                if (elevation < minHeight)
                {
                    minHeight = elevation;
                }
                if (elevation > maxHeight)
                {
                    maxHeight = elevation;
                }

                // Die StartHöhe darf nicht berücksichtigt werden ...
                // Hier sind 234m zuviel berechnet ...
                if (elevation > tmpElevation)
                {
                    self.totalUp += (elevation-tmpElevation);
                }
                else if (elevation < tmpElevation)
                {
                    self.totalDown += (tmpElevation-elevation);
                }
            }
            else
            {
                // Passt!!!
                minHeight = elevation;
                maxHeight = elevation;
            }



            tmpElevation = elevation;
            //            NSLog(@"Coordinate = %f %f  ELEVATION %f TIME %@", workingCoordinate.latitude, workingCoordinate.longitude,[[pointDict objectForKey:@"ele"] doubleValue], [pointDict objectForKey:@"time"]);

            // Distance
            tmpLocation = [[CLLocation alloc] initWithLatitude:lat longitude:lon];
            //            if (pointArrIndex > 0)
            //            {

            // Passt nicht ...
            distance += [tmpLocation distanceFromLocation:Location1];
//            NSLog(@"Distance = %f", trackLength);
            int dist = (distance / 1000);
            if (dist %1 == 0)
            {
                NSString *key = [NSString stringWithFormat:@"%d", dist];
                if (![[self.distanceAnnotationsDict allKeys] containsObject:key])
                {
//                    NSLog(@"ADDED %d", dist);
                    PSDistanceAnnotation *annotation = [[PSDistanceAnnotation alloc] initWithCoordinate:[tmpLocation coordinate] title:key];

                    [self.distanceAnnotationsDict setObject:annotation forKey:key];
                }
            }

            //            }
            Location1 = tmpLocation;
            [elevatioNData addObject:[NSNumber numberWithFloat:tmpElevation]];
            pointArrCount++;
        }

    self.trackLength = (float) distance;
    self.pointArrCount = pointArrCount;
//        [self.graphViewController setData:elevatioNData];
//    NSLog(@"MinHeight = %f", minHeight);
//    NSLog(@"MaxHeight = %f", maxHeight);
//
//    NSLog(@"TotalUp = %f", self.totalUp);
//    NSLog(@"TotalDown = %f", self.totalDown);
//    NSLog(@"Distance = %f", self.trackLength);
}


- (void) parseFile
{
    NSData *data = [NSData dataWithContentsOfFile:[self filepath]];
    if (data)
    {
        NSDictionary *routingDict = [NSDictionary dictionaryWithXMLData:data];
        NSArray *trek = [[[routingDict objectForKey:@"trk"] objectForKey:@"trkseg"] objectForKey:@"trkpt"];

        int pointCount = [trek count];

        self.pointArr = malloc(sizeof(CLLocationCoordinate2D) * pointCount);
        CLLocation *Location1;
        CLLocation *tmpLocation;
        CLLocationDistance distance = 0.0;

        int pointArrIndex = 0;  //it's simpler to keep a separate index for pointArr
        CGFloat minHeight = 0.0;
        CGFloat maxHeight = 0.0;

        CGFloat totalUp = 0.0;
        CGFloat totalDown = 0.0;

        CGFloat tmpElevation = 0.0;

        for (NSDictionary *pointDict in trek)
        {
            CLLocationCoordinate2D workingCoordinate;
            CGFloat lat = [[pointDict objectForKey:@"_lat"] doubleValue];
            CGFloat lon = [[pointDict objectForKey:@"_lon"] doubleValue];

            workingCoordinate.latitude = lat;
            workingCoordinate.longitude = lon;

            CGFloat elevation = [[pointDict objectForKey:@"ele"] doubleValue];
            if (pointArrIndex > 0)
            {
                if (elevation < minHeight)
                {
                    minHeight = elevation;
                }
                if (elevation > maxHeight)
                {
                    maxHeight = elevation;
                }

                // Die StartHöhe darf nicht berücksichtigt werden ...
                // Hier sind 234m zuviel berechnet ...
                if (elevation > tmpElevation)
                {
                    totalUp += (elevation - tmpElevation);
                }
                else if (elevation < tmpElevation)
                {
                    totalDown += (tmpElevation - elevation);
                }
            }
            else
            {
                // Passt!!!
                minHeight = elevation;
                maxHeight = elevation;
            }


            tmpElevation = elevation;
//            NSLog(@"Coordinate = %f %f  ELEVATION %f TIME %@", workingCoordinate.latitude, workingCoordinate.longitude,[[pointDict objectForKey:@"ele"] doubleValue], [pointDict objectForKey:@"time"]);

            // Distance
            tmpLocation = [[CLLocation alloc] initWithLatitude:lat longitude:lon];
//            if (pointArrIndex > 0)
//            {

            // Passt nicht ...
            distance += [tmpLocation distanceFromLocation:Location1];
//                NSLog(@"Distance = %f", trackLength);
//            }
            Location1 = tmpLocation;

            MKMapPoint point = MKMapPointForCoordinate(workingCoordinate);
            self.pointArr[pointArrIndex] = point;
            pointArrIndex++;
        }
        self.pointArrCount = pointCount;
    }
}


#pragma mark - Coordinates
- (int) numberOfCoordinates
{
    return self.pointArrCount;

}

- (CLLocationCoordinate2D*)coordinates
{
    return self.pointsCoordinate;
}


- (NSString*)distanceInKm
{
    return [NSString stringWithFormat:@"%0.2fkm",(self.trackLength / 1000.00)];
}


- (MKPolyline *)route
{
//    return [MKPolyline polylineWithPoints:self.pointArr count:self.pointArrCount];

    PSTrackOverlay *trackOverlay =  [PSTrackOverlay polylineWithCoordinates:self.pointsCoordinate count:self.pointArrCount];
    trackOverlay.track = self;
    return trackOverlay;
}


- (CGFloat)distanceFromLocation:(CLLocation *)location
{
    CLLocationCoordinate2D annocoord =  MKCoordinateForMapPoint([self start]);
    CLLocationCoordinate2D usercoord = location.coordinate;

//    NSLog(@"ANNO  = %f, %f", annocoord.latitude, annocoord.longitude);
//    NSLog(@"USER = %f, %f", usercoord.latitude, usercoord.longitude);

    CLLocation *loc = [[CLLocation alloc] initWithLatitude:annocoord.latitude longitude:annocoord.longitude];
    CLLocation *loc2 = [[CLLocation alloc] initWithLatitude:usercoord.latitude longitude:usercoord.longitude];

//    NSLog(@"LOC  = %f, %f", loc.coordinate.latitude,  loc.coordinate.longitude);
//    NSLog(@"LOC2 = %f, %f", loc2.coordinate.latitude, loc2.coordinate.longitude);

    CLLocationDistance dist = [loc distanceFromLocation:loc2];

//    NSLog(@"DIST: %f", dist); // Wrong formatting may show wrong value!
    return dist;
}


- (MKMapPoint)start
{
    return MKMapPointForCoordinate(self.pointsCoordinate[0]);

//    MKMapPoint point = MKMapPointForCoordinate(workingCoordinate);
//
//    return point;
}


- (MKMapPoint)finish
{
    return MKMapPointForCoordinate(self.pointsCoordinate[self.pointArrCount-1]);
}


- (MKPolylineView *) overlayView
{
    MKPolylineView  *routeLineView = [[MKPolylineView alloc] initWithPolyline:[self route]];
    routeLineView.fillColor = [UIColor redColor];
    routeLineView.strokeColor = [UIColor redColor];
    routeLineView.lineWidth = 5;
    return routeLineView;
}


#pragma mark - Annotations
- (NSArray *)distanceAnnotations
{
    return [[self.distanceAnnotationsDict allValues] copy];
}


@end
