//
// Created by Philip Schneider on 10.05.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import <XMLDictionary/XMLDictionary.h>
#import <MapKit/MapKit.h>
#import <Ono/ONOXMLDocument.h>
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "PSTrack.h"
#import "PSDistanceAnnotation.h"
#import "PSTrackOverlay.h"
#import "BEMSimpleLineGraphView.h"
#import "PSWayPointAnnotation.h"
#import "PSDirectionAnnotation.h"
#import "PSPoi.h"
#import "PSPoiStore.h"


@interface PSTrack() <BEMSimpleLineGraphDataSource, BEMSimpleLineGraphDelegate>
@property (nonatomic) CGFloat totalDown;
@property (nonatomic) NSString *filename;
@property (nonatomic) MKMapPoint *pointArr;
@property (nonatomic) CLLocationCoordinate2D *pointsCoordinate;
@property (nonatomic) int pointArrCount;
@property (nonatomic) NSMutableDictionary *distanceAnnotationsDict;
@property (nonatomic) NSMutableDictionary *directionAnnotationsDict;
@property (nonatomic) NSMutableDictionary *annotationsDict;
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
        self.color = [UIColor blackColor];
        self.alpha = 1.0;
        self.lineWidth = 5.5;
        self.lineDashPattern = @[@2, @5];

        [self parseElevationFile];

//#ifdef GENERATE_SNAPSHOTS
//        [self generateSnapShotImage];
//#endif

    }
    return self;
}


- (instancetype)initWithFilename:(NSString *)filename trackType:(PSTrackType)trackType
{
    self = [self initWithFilename:filename];
    if (self)
    {
#ifdef INSELHUEPFEN_MODE
        if ([[filename lowercaseString] rangeOfString:@"inselhuepfen"].location != NSNotFound)
        {
            self.color = [UIColor magentaColor];
            self.lineDashPattern = @[@1,@5];
            self.alpha = 0.5;
        }
        else
        {
            self.color = [UIColor blueColor];
            self.lineDashPattern = @[@5,@5];
            self.alpha = 0.5;
        }
#else
        self.trackType = trackType;
        if (trackType == PSTrackTypeTrail)
        {
            self.color = [UIColor magentaColor];
        }
        else if (trackType == PSTrackTypeUnknown)
        {
            self.color = [UIColor darkGrayColor];
        }
        else if (trackType == PSTrackTypeRoundTrip)
        {
            self.color = [UIColor orangeColor];
        }
        else
        {
            self.color = [UIColor blackColor];
        }

        self.lineDashPattern = nil;
        self.alpha = 0.5;
        
        NSArray *components = [[filename stringByReplacingOccurrencesOfString:@".gpx" withString:@"" ]componentsSeparatedByString:@"_"];
        if ([components count] > 1)
       {
           self.alpha = 0.5;
           if ([components[1] isEqualToString:@"blueColor"])
           {
               self.color = [UIColor blueColor];
           }
           else if ([components[1] isEqualToString:@"greenColor"])
           {
               self.color = [UIColor greenColor];
           }
       }
#endif

    }
    return self;
}


- (instancetype)initWithXmlData:(ONOXMLElement*)onoxmlElement document:(ONOXMLDocument*)document
{
    DLogFuncName();
    self = [super init];
    if (self)
    {

#ifdef DEBUG
        NSLog(@"XML-Document = \n %@",[onoxmlElement childrenWithTag:@"tag"]);
#endif

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
        self.color = [UIColor orangeColor];
        self.alpha = 0.5;
        self.lineWidth = 2.5;
        self.lineDashPattern = @[@5, @5];
        self.tags = [wayTags copy];
        self.trackType = PSTrackTypeOsm;
        
//        if ([[wayTags allKeys] containsObject:@"tracktype"])
//        {
//            NSLog(@"TrackType = %@", [wayTags objectForKey:@"tracktype"]);
//        }
//        
//        if ([[wayTags allKeys] containsObject:@"surface"])
//        {
//            NSLog(@"surface = %@", [wayTags objectForKey:@"surface"]);
//        }
        
        if ([[wayTags allKeys] containsObject:@"mtb:scale"])
        {
            self.alpha = 0.75;
            self.lineWidth = 3.5;
//            NSLog(@"mtb:scale = %@", [wayTags objectForKey:@"mtb:scale"]);
            NSNumber *mtbScale = [wayTags objectForKey:@"mtb:scale"];
            switch ([mtbScale integerValue]) {
                case 0:
                    self.color = [UIColor brownColor];
                    break;
                case 1:
                    self.color = [UIColor greenColor];
                    break;
                case 2:
                    self.color = [UIColor blueColor];
                    break;
                case 4:
                    self.color = [UIColor redColor];
                    break;
                case 5:
                    self.color = [UIColor blackColor];
                    break;
                default:
                    break;
            }
        }
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
    NSMutableArray *smoothedElevatioNData = [[NSMutableArray alloc] initWithCapacity:[trek count]];
    NSMutableArray *wayPoints = [[NSMutableArray alloc] initWithCapacity:[trek count]];
    self.distanceAnnotationsDict = [[NSMutableDictionary alloc] initWithCapacity:[trek count]];
    self.directionAnnotationsDict = [[NSMutableDictionary alloc] initWithCapacity:[trek count]];
    self.annotationsDict = [[NSMutableDictionary alloc] initWithCapacity:[trek count]];

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

            // Distance
            if (elevation)
            {
                tmpLocation = [[CLLocation alloc] initWithCoordinate:workingCoordinate altitude:elevation horizontalAccuracy:5.0 verticalAccuracy:5.0 timestamp:[NSDate date]];
            }
            else
            {
                tmpLocation = [[CLLocation alloc] initWithLatitude:lat longitude:lon];
            }
            // NSLog(@"tmpLocation Alt = %f, low.alt = %f peak.alt = %f", tmpLocation.altitude, self.low.altitude, self.peak.altitude);
            if (!self.low || tmpLocation.altitude < self.low.altitude)
            {
                self.low = [tmpLocation copy];
            }
            if (!self.peak || tmpLocation.altitude > self.peak.altitude)
            {
                self.peak = [tmpLocation copy];
            }


        // Passt nicht ...
            distance += [tmpLocation distanceFromLocation:Location1];
//            NSLog(@"Distance = %f", trackLength);
            int dist = (distance / DISTANCE_ANNOTATIONS_STEP_SIZE);
            NSString *annotationsKey = [NSString stringWithFormat:@"%d", pointArrCount];
            NSString *distanceKey = [NSString stringWithFormat:@"%d", dist];
            BOOL addDistanceAnnotation = (dist %1 == 0);
            if (addDistanceAnnotation)
            {

                // Der 0.km wird ignoriert ...
                if (![[self.distanceAnnotationsDict allKeys] containsObject:distanceKey] && dist != 0)
                {
//                    NSLog(@"ADDED %d", dist);
                    PSDistanceAnnotation *annotation = [[PSDistanceAnnotation alloc] initWithCoordinate:[tmpLocation coordinate] title:distanceKey];

                    [self.distanceAnnotationsDict setObject:annotation forKey:distanceKey];
                    [self.annotationsDict setObject:annotation forKey:annotationsKey];
                }
            }

            int elevationDistance = (distance / SMOOTHED_ELEVATION_STEP_SIZE);
            BOOL addElevationAnnotation = (elevationDistance %1 == 0);
            if (addElevationAnnotation)
            {
                [smoothedElevatioNData addObject:[NSNumber numberWithFloat:tmpElevation]];
            }


            int directionDist = (distance / DIRECTION_ANNOTATIONS_STEP_SIZE);
            NSString *directionsKey = [NSString stringWithFormat:@"%d", directionDist];
            BOOL addDirectionsAnnotation = ((directionDist %1 == 0) && ![[self.annotationsDict allKeys] containsObject:annotationsKey]);
            if (addDirectionsAnnotation)
            {

                if (![[self.directionAnnotationsDict allKeys] containsObject:directionsKey] && directionDist != 0)
                {
                    if ([trek count] > pointArrCount+1)
                    {
                        NSDictionary * directionPointDict = [trek objectAtIndex:pointArrCount+1];
                        PSDirectionAnnotation *dirAnnotation = [[PSDirectionAnnotation alloc] initWithCoordinate:[tmpLocation coordinate] title:directionsKey];

                        CGFloat directionLat = [[directionPointDict objectForKey:@"_lat"] doubleValue];
                        CGFloat directionLon = [[directionPointDict objectForKey:@"_lon"] doubleValue];
                        CLLocation *directionLocation = [[CLLocation alloc] initWithLatitude:directionLat longitude:directionLon];

                        CLLocationCoordinate2D coord1 = tmpLocation.coordinate;
                        CLLocationCoordinate2D coord2 = directionLocation.coordinate;

                        CLLocationDegrees deltaLong = coord2.longitude - coord1.longitude;
                        CLLocationDegrees yComponent = sin(deltaLong) * cos(coord2.latitude);
                        CLLocationDegrees xComponent = (cos(coord1.latitude) * sin(coord2.latitude)) - (sin(coord1.latitude) * cos(coord2.latitude) * cos(deltaLong));

                        CLLocationDegrees radians = atan2(yComponent, xComponent);
                        CLLocationDegrees degrees = RADIANS_TO_DEGREES(radians) + 360;

                        dirAnnotation.degrees = fmod(degrees, 360);

                        [self.directionAnnotationsDict setObject:dirAnnotation forKey:directionsKey];
                        [self.annotationsDict setObject:dirAnnotation forKey:annotationsKey];
                    }
                }
            }
            //            }
            Location1 = tmpLocation;
            [elevatioNData addObject:[NSNumber numberWithFloat:tmpElevation]];
            #ifdef SHOW_TRACK_WAYPOINTS
                [wayPoints addObject:[[PSWayPointAnnotation alloc] initWithCoordinate:[tmpLocation coordinate] title:[NSString stringWithFormat:@"%d",pointArrCount]]];
            #endif
            pointArrCount++;
        }

    self.trackLength = (float) distance;
    self.trackDuration = ((float)distance/DEFAULT_SPEED_IN_KM);
    self.pointArrCount = pointArrCount;
    
    self.elevationData = elevatioNData;
    self.smoothedElevationData = smoothedElevatioNData;
    self.wayPoints = wayPoints;
//    NSLog(@"elevationData = %d", [self.elevationData count]);
//    NSLog(@"smoothedElevationData = %d", [self.smoothedElevationData count]);
    self.maxElevationData = [[self.elevationData valueForKeyPath:@"@max.intValue"] floatValue];
    self.minElevationData = [[self.elevationData valueForKeyPath:@"@min.intValue"] floatValue];
    self.elevationDiff = MAX(self.maxElevationData,self.minElevationData) - MIN(self.maxElevationData,self.minElevationData);
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


- (CLLocationDistance)distanceFromCoordinate:(CLLocationCoordinate2D)from toCoordinate:(CLLocationCoordinate2D)to
{
    CLLocation *fromLocation = [[CLLocation alloc] initWithLatitude:from.latitude longitude:from.longitude];
    CLLocation *toLocation = [[CLLocation alloc] initWithLatitude:to.latitude longitude:to.longitude];
    CLLocationDistance distance = [toLocation distanceFromLocation:fromLocation];
    return distance;
}

- (NSArray*)elevationAnnotations
{
    NSMutableArray *coordinates = [[NSMutableArray alloc] init];
    for (int i = 0; i < self.pointArrCount; i++)
    {
        CLLocationCoordinate2D workingCoordinate = self.pointsCoordinate[i];
        double distance = DBL_MAX;
        [coordinates insertObject:[NSNull null] atIndex:i];
        
        for (PSPoi *poi in [[PSPoiStore sharedInstance] poiList])
        {
            NSLog(@"Next Poi");
            CLLocationDistance currentDistance = [self distanceFromCoordinate:poi.coordinate toCoordinate:workingCoordinate];
            NSLog(@"Distance = %f",currentDistance);
            if (currentDistance < distance && currentDistance < 500.0)
            {
                // Jetzt müssen wir prüfen ob der Poi bereits im Array enthalten ist
                // Ist es bereits enthalten (so haben wir auch dessen index) mit dem wird die coordinate bekommen
                // Mit der coordinate müssen wir prüfen, welches der nähere Pounkt zum Poi ist...
                NSUInteger oldIndex = [coordinates indexOfObject:poi];
                if (oldIndex != NSNotFound)
                {
                    CLLocationDistance oldDistance = [self distanceFromCoordinate:self.pointsCoordinate[oldIndex] toCoordinate:poi.coordinate];
                    if (oldDistance < currentDistance)
                    {
                        // DO Nothing
                        NSLog(@"Use old distance");
                    }
                    else
                    {
                        // Lösche weiter entfernten Eintrag
                        NSLog(@"Use NEW distance");
                        [coordinates replaceObjectAtIndex:oldIndex withObject:[NSNull null]];
                        
                        //Füge den neuen Eintrag hinzu
                        if ([coordinates count] > i)
                        {
                            [coordinates replaceObjectAtIndex:i withObject:poi];
                        }
                        else
                        {
                            [coordinates insertObject:poi atIndex:i];
                        }
                    }
                }
                else
                {
                    //Füge den neuen Eintrag hinzu
                    NSLog(@"INsert");
                    if ([coordinates count] > i)
                    {
                        [coordinates replaceObjectAtIndex:i withObject:poi];
                    }
                    else
                    {
                        [coordinates insertObject:poi atIndex:i];
                    }
                }
                distance = currentDistance;
            }
        }
    }
    
    return coordinates;
}

#pragma mark -
- (NSString*)distanceInKm
{
    return [NSString stringWithFormat:@"%0.2fkm",(self.trackLength / 1000.00)];
}


- (NSString*)readableTrackDuration
{
    DLogFuncName();

    if (self.trackDuration < 1.0)
    {
        return [NSString stringWithFormat:@"%.2fm",(self.trackDuration * 60)];
    }
    else
    {
        return [NSString stringWithFormat:@"%.2fh",self.trackDuration];
    }
}


- (BOOL)isDownhill
{
    DLogFuncName();
    CGFloat diff = self.totalDown - self.totalUp;
    // Nur wenn die Differenz mehr wie 10 % der Höhenmeter ausmacht, geht es wirklich bergab
    return (diff > ([self totalDown] / 10));
}


- (BOOL)isUphill
{
    DLogFuncName();
    CGFloat diff = self.totalDown  - self.totalDown;
    // Nur wenn die Differenz mehr wie 10 % der Höhenmeter ausmacht, geht es wirklich bergauf
    return (diff > ([self totalDown] / 10));
}


#pragma mark - Map-Stuff
- (MKCoordinateRegion) region
{
    DLogFuncName();
    CLLocationCoordinate2D topLeftCoord;
    topLeftCoord.latitude = -90;
    topLeftCoord.longitude = 180;

    CLLocationCoordinate2D bottomRightCoord;
    bottomRightCoord.latitude = 90;
    bottomRightCoord.longitude = -180;

    for(int i=0; i < [self numberOfCoordinates]; i++)
    {
        CLLocationCoordinate2D coordinate = [self coordinates][i];

        topLeftCoord.longitude = fmin(topLeftCoord.longitude, coordinate.longitude);
        topLeftCoord.latitude = fmax(topLeftCoord.latitude, coordinate.latitude);

        bottomRightCoord.longitude = fmax(bottomRightCoord.longitude,coordinate.longitude);
        bottomRightCoord.latitude = fmin(bottomRightCoord.latitude, coordinate.latitude);
    }

    MKCoordinateRegion region;
    region.center.latitude = topLeftCoord.latitude - (topLeftCoord.latitude - bottomRightCoord.latitude) * 0.5;
    region.center.longitude = topLeftCoord.longitude + (bottomRightCoord.longitude - topLeftCoord.longitude) * 0.5;
    region.span.latitudeDelta = fabs(topLeftCoord.latitude - bottomRightCoord.latitude) * 1.1; // Add a little extra space on the sides
    region.span.longitudeDelta = fabs(bottomRightCoord.longitude - topLeftCoord.longitude) * 1.1; // Add a little extra space on the sides

    return region;
}


- (MKPolyline *)route
{
//    return [MKPolyline polylineWithPoints:self.pointArr count:self.pointArrCount];
    NSAssert(self.pointsCoordinate,@"No coordinates for route");
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


- (NSArray *)directionAnnotations
{
    return [[self.directionAnnotationsDict allValues] copy];
}

#pragma mark - Image
- (UIImage *)snapShot
{
    UIImage *image = [UIImage imageWithContentsOfFile:[self snapShotFilename]];
    if (image)
    {
        return image;
    }

    if (!image)
    {
        [self generateSnapShotImage];

    }
    return nil;
}


- (void)generateSnapShotImage
{
    DLogFuncName();
    
    MKMapSnapshotOptions *options = [[MKMapSnapshotOptions alloc] init];
    options.region = self.region;
    options.scale = [UIScreen mainScreen].scale;
    options.size = CGSizeMake([[UIScreen mainScreen] bounds].size.width, 250);

    MKMapSnapshotter *snapshotter = [[MKMapSnapshotter alloc] initWithOptions:options];

    [snapshotter startWithCompletionHandler:^(MKMapSnapshot *snapshot, NSError *error) {

            UIImage *image = [self drawRoute:[self route] andAnnotations:self.distanceAnnotations onSnapshot:snapshot withColor:[UIColor redColor]];
            NSData *data = UIImagePNGRepresentation(image);

            [[NSFileManager defaultManager] createDirectoryAtPath:[[self snapShotFilename] stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
            [data writeToFile:[self snapShotFilename] atomically:YES];
        }];
}


- (UIImage *)drawRoute:(MKPolyline *)polyline onSnapshot:(MKMapSnapshot *)snapShot withColor:(UIColor *)lineColor {

    UIGraphicsBeginImageContext(snapShot.image.size);
    CGRect rectForImage = CGRectMake(0, 0, snapShot.image.size.width, snapShot.image.size.height);

// Draw map
    [snapShot.image drawInRect:rectForImage];

// Get points in the snapshot from the snapshot
    int lastPointIndex;
    int firstPointIndex = 0;
    BOOL isfirstPoint = NO;
    NSMutableArray *pointsToDraw = [NSMutableArray array];
    for (int i = 0; i < polyline.pointCount; i++){
        MKMapPoint point = polyline.points[i];
        CLLocationCoordinate2D pointCoord = MKCoordinateForMapPoint(point);
        CGPoint pointInSnapshot = [snapShot pointForCoordinate:pointCoord];
        if (CGRectContainsPoint(rectForImage, pointInSnapshot)) {
            [pointsToDraw addObject:[NSValue valueWithCGPoint:pointInSnapshot]];
            lastPointIndex = i;
            if (i == 0)
                firstPointIndex = YES;
            if (!isfirstPoint) {
                isfirstPoint = YES;
                firstPointIndex = i;
            }
        }
    }

// Adding the first point on the outside too so we have a nice path
    if (lastPointIndex+1 <= polyline.pointCount)
    {
        MKMapPoint point = polyline.points[lastPointIndex+1];
        CLLocationCoordinate2D pointCoord = MKCoordinateForMapPoint(point);
        CGPoint pointInSnapshot = [snapShot pointForCoordinate:pointCoord];
        [pointsToDraw addObject:[NSValue valueWithCGPoint:pointInSnapshot]];
    }
// Adding the point before the first point in the map as well (if needed) to have nice path

    if (firstPointIndex != 0) {
        MKMapPoint point = polyline.points[firstPointIndex-1];
        CLLocationCoordinate2D pointCoord = MKCoordinateForMapPoint(point);
        CGPoint pointInSnapshot = [snapShot pointForCoordinate:pointCoord];
        [pointsToDraw insertObject:[NSValue valueWithCGPoint:pointInSnapshot] atIndex:0];
    }

// Draw that points
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 3.0);

    for (NSValue *point in pointsToDraw){
        CGPoint pointToDraw = [point CGPointValue];
        if (!isnan(pointToDraw.x) && !isnan(pointToDraw.y))
        {
            if ([pointsToDraw indexOfObject:point] == 0)
            {
                CGContextMoveToPoint(context, pointToDraw.x, pointToDraw.y);
            }
            else if ([pointsToDraw indexOfObject:point] == ([pointsToDraw count]-1))
            {
//                NSLog(@"Do nothing");
            }
            else
            {
                CGContextAddLineToPoint(context, pointToDraw.x, pointToDraw.y);
            }
        }
    }
    CGContextSetStrokeColorWithColor(context, [lineColor CGColor]);
    CGContextStrokePath(context);

    UIImage *resultingImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resultingImage;
}


- (UIImage *)drawAnnotations:(NSArray*)annotations onSnapshot:(MKMapSnapshot *)snapShot withColor:(UIColor *)lineColor
{


    UIImage *image = snapShot.image;

    CGRect finalImageRect = CGRectMake(0, 0, image.size.width, image.size.height);

            // Get a standard annotation view pin. Clearly, Apple assumes that we'll only want to draw standard annotation pins!

            MKAnnotationView *pin = [[MKPinAnnotationView alloc] initWithAnnotation:nil reuseIdentifier:@""];
            UIImage *pinImage = pin.image;

            // ok, let's start to create our final image

            UIGraphicsBeginImageContextWithOptions(image.size, YES, image.scale);

            // first, draw the image from the snapshotter

            [image drawAtPoint:CGPointMake(0, 0)];

            // now, let's iterate through the annotations and draw them, too

            for (id<MKAnnotation>annotation in self.distanceAnnotations)
            {
                CGPoint point = [snapShot pointForCoordinate:annotation.coordinate];
                if (CGRectContainsPoint(finalImageRect, point)) // this is too conservative, but you get the idea
                {
                    CGPoint pinCenterOffset = pin.centerOffset;
                    point.x -= pin.bounds.size.width / 2.0;
                    point.y -= pin.bounds.size.height / 2.0;
                    point.x += pinCenterOffset.x;
                    point.y += pinCenterOffset.y;

                    [pinImage drawAtPoint:point];
                }
            }

            // grab the final image

            UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();

    return finalImage;
}


- (UIImage *)drawRoute:(MKPolyline *)polyline andAnnotations:(NSArray*)annotations onSnapshot:(MKMapSnapshot *)snapShot withColor:(UIColor *)lineColor {

    UIGraphicsBeginImageContext(snapShot.image.size);
    CGRect rectForImage = CGRectMake(0, 0, snapShot.image.size.width, snapShot.image.size.height);

// Draw map
    [snapShot.image drawInRect:rectForImage];

// Get points in the snapshot from the snapshot
    int lastPointIndex;
    int firstPointIndex = 0;
    BOOL isfirstPoint = NO;
    NSMutableArray *pointsToDraw = [NSMutableArray array];
    for (int i = 0; i < polyline.pointCount; i++){
        MKMapPoint point = polyline.points[i];
        CLLocationCoordinate2D pointCoord = MKCoordinateForMapPoint(point);
        CGPoint pointInSnapshot = [snapShot pointForCoordinate:pointCoord];
        if (CGRectContainsPoint(rectForImage, pointInSnapshot)) {
            [pointsToDraw addObject:[NSValue valueWithCGPoint:pointInSnapshot]];
            lastPointIndex = i;
            if (i == 0)
                firstPointIndex = YES;
            if (!isfirstPoint) {
                isfirstPoint = YES;
                firstPointIndex = i;
            }
        }
    }

// Adding the first point on the outside too so we have a nice path
    if (lastPointIndex+1 <= polyline.pointCount)
    {
        MKMapPoint point = polyline.points[lastPointIndex+1];
        CLLocationCoordinate2D pointCoord = MKCoordinateForMapPoint(point);
        CGPoint pointInSnapshot = [snapShot pointForCoordinate:pointCoord];
        [pointsToDraw addObject:[NSValue valueWithCGPoint:pointInSnapshot]];
    }
// Adding the point before the first point in the map as well (if needed) to have nice path

    if (firstPointIndex != 0) {
        MKMapPoint point = polyline.points[firstPointIndex-1];
        CLLocationCoordinate2D pointCoord = MKCoordinateForMapPoint(point);
        CGPoint pointInSnapshot = [snapShot pointForCoordinate:pointCoord];
        [pointsToDraw insertObject:[NSValue valueWithCGPoint:pointInSnapshot] atIndex:0];
    }

// Draw that points
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 3.0);

    for (NSValue *point in pointsToDraw){
        CGPoint pointToDraw = [point CGPointValue];
        if (!isnan(pointToDraw.x) && !isnan(pointToDraw.y))
        {
            if ([pointsToDraw indexOfObject:point] == 0)
            {
                CGContextMoveToPoint(context, pointToDraw.x, pointToDraw.y);
            }
            else if ([pointsToDraw indexOfObject:point] == ([pointsToDraw count]-1))
            {
//                NSLog(@"Do nothing");
            }
            else
            {
                CGContextAddLineToPoint(context, pointToDraw.x, pointToDraw.y);
            }
        }
    }
    CGContextSetStrokeColorWithColor(context, [lineColor CGColor]);
    CGContextStrokePath(context);

    UIImage *resultingImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    CGRect finalImageRect = CGRectMake(0, 0, resultingImage.size.width, resultingImage.size.height);

    // Get a standard annotation view pin. Clearly, Apple assumes that we'll only want to draw standard annotation pins!

    MKAnnotationView *pin = [[MKPinAnnotationView alloc] initWithAnnotation:nil reuseIdentifier:@""];
    UIImage *pinImage = pin.image;

    // ok, let's start to create our final image

    UIGraphicsBeginImageContextWithOptions(resultingImage.size, YES, resultingImage.scale);

    // first, draw the image from the snapshotter

    [resultingImage drawAtPoint:CGPointMake(0, 0)];

    // now, let's iterate through the annotations and draw them, too

    for (id<MKAnnotation>annotation in self.distanceAnnotations)
    {
        CGPoint point = [snapShot pointForCoordinate:annotation.coordinate];
        if (CGRectContainsPoint(finalImageRect, point)) // this is too conservative, but you get the idea
        {
            CGPoint pinCenterOffset = pin.centerOffset;
            point.x -= pin.bounds.size.width / 2.0;
            point.y -= pin.bounds.size.height / 2.0;
            point.x += pinCenterOffset.x;
            point.y += pinCenterOffset.y;

            [pinImage drawAtPoint:point];
        }
    }

    // grab the final image

    UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();


    return finalImage;
}



- (NSString*)snapShotFilename
{
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    NSString *databasePath = [[NSString alloc] initWithString: [docsDir stringByAppendingPathComponent: [NSString stringWithFormat:@"tracks/%@-snapshot.png",self.filename]]];

    return databasePath;
}


- (UIImage *)lineGraphSnapShotImage
{
    DLogFuncName();
    if (!_lineGraphSnapShotImage)
    {
        [self createLineGraphSnapShotImage];
    }

    return _lineGraphSnapShotImage;
}


- (UIImage *)lineGraphSnapShotImageWithWidth:(CGFloat)width
{
    DLogFuncName();
    if (!_lineGraphSnapShotImage)
    {
        [self createLineGraphSnapShotImageWithWidth:width];
    }
    
    return _lineGraphSnapShotImage;
}



- (void) createLineGraphSnapShotImage
{
    DLogFuncName();
        self.graphView = [[BEMSimpleLineGraphView alloc] initWithFrame:CGRectMake(0,0,320,200)];
        self.graphView.dataSource = self;
        self.graphView.delegate = self;
        self.graphView.enableYAxisLabel = YES;
        self.graphView.enablePopUpReport = NO;
        self.graphView.enableTouchReport = NO;
    self.graphView.animationGraphStyle = BEMLineAnimationNone;

    self.graphView.enableReferenceAxisFrame = YES;
                                self.graphView.enableReferenceAxisLines = YES;

    self.graphView.backgroundColor = [UIColor clearColor];
    self.graphView.tintColor = [UIColor clearColor];
    self.graphView.colorTop = [UIColor whiteColor];
    self.graphView.colorLine = [UIColor blackColor];
//    self.graphView.colorBottom = [UIColor redColor];

//    self.lineGraphSnapShotImage = [self.graphView graphSnapshotImage];

}


- (void) createLineGraphSnapShotImageWithWidth:(CGFloat)width
{
    DLogFuncName();
    self.graphView = [[BEMSimpleLineGraphView alloc] initWithFrame:CGRectMake(0,0,width,200)];
    self.graphView.dataSource = self;
    self.graphView.delegate = self;
    self.graphView.enableYAxisLabel = YES;
    self.graphView.enablePopUpReport = NO;
    self.graphView.enableTouchReport = NO;
    self.graphView.animationGraphStyle = BEMLineAnimationNone;
    
    self.graphView.enableReferenceAxisFrame = YES;
    self.graphView.enableReferenceAxisLines = YES;
    
    self.graphView.backgroundColor = [UIColor clearColor];
    self.graphView.tintColor = [UIColor clearColor];
    self.graphView.colorTop = [UIColor whiteColor];
    self.graphView.colorLine = [UIColor blackColor];
    //    self.graphView.colorBottom = [UIColor redColor];
    
    //    self.lineGraphSnapShotImage = [self.graphView graphSnapshotImage];
    
}

#pragma mark - BEMSSimpleLineGraphView DataSource
- (NSInteger)numberOfPointsInLineGraph:(BEMSimpleLineGraphView *)graph
{
    DLogFuncName();
    // Anzahl elemente im Array!?

    return [[self elementsForElevationGraph] count];
}


- (void)lineGraphDidBeginLoading:(BEMSimpleLineGraphView *)graph
{
    DLogFuncName();
}


- (void)lineGraphDidFinishLoading:(BEMSimpleLineGraphView *)graph
{
    DLogFuncName();
    self.lineGraphSnapShotImage = [self.graphView graphSnapshotImage];
}


- (CGFloat)lineGraph:(BEMSimpleLineGraphView *)graph valueForPointAtIndex:(NSInteger)index
{
    DLogFuncName();
    CGFloat value = [[[self elementsForElevationGraph] objectAtIndex:index] floatValue];
//    NSLog(@"Value at %d = %f",index, value);
    return value;
}


- (NSString *)lineGraph:(BEMSimpleLineGraphView *)graph labelOnXAxisForIndex:(NSInteger)index
{
    DLogFuncName();
    if (index == 0)
    {
        return @"";
    }
    if ( (index % 5) == 0 )
    {
        return [NSString stringWithFormat:@"%d", index];
    }
    return @"";
}


- (NSDictionary*)infoTags
{
    return [self.tags copy];
}


- (CGFloat)maxValueForLineGraph:(BEMSimpleLineGraphView *)graph
{
    DLogFuncName();
    return self.maxElevationData;
}


- (CGFloat)minValueForLineGraph:(BEMSimpleLineGraphView *)graph
{
    DLogFuncName();
    return self.minElevationData;
}


- (void)lineGraphDidFinishDrawing:(BEMSimpleLineGraphView *)graph {
    DLogFuncName();
    // Update any interface elements that rely on a full rendered graph
    self.lineGraphSnapShotImage = [self.graphView graphSnapshotImage];
}


- (NSArray*)elementsForElevationGraph
{
    return self.smoothedElevationData;
}

@end
