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
#import "BEMSimpleLineGraphView.h"


@interface PSTrack() <BEMSimpleLineGraphDataSource, BEMSimpleLineGraphDelegate>
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
        self.color = [UIColor blackColor];
        self.alpha = 1.0;
        self.lineWidth = 2.5;
        self.lineDashPattern = @[@2, @5];

        [self parseElevationFile];
        [self generateSnapShotImage];
    }
    return self;
}


- (instancetype)initWithFilename:(NSString *)filename trackType:(PSTrackType)trackType
{
    self = [self initWithFilename:filename];
    if (self)
    {
        self.trackType = trackType;
        if (trackType == PSTrackTypeTrail)
        {
            self.color = [UIColor magentaColor];
            self.lineDashPattern = nil;
            self.alpha = .5;
        }
        else if (trackType == PSTrackTypeUnknown)
        {
            self.color = [UIColor blueColor];
            self.lineDashPattern = nil;
            self.alpha = .5;
        }
        else if (trackType == PSTrackTypeRoundTrip)
        {
            self.color = [UIColor yellowColor];
            self.lineDashPattern = nil;
            self.alpha = .75;
        }
        else
        {
            self.color = [UIColor blackColor];
            self.lineDashPattern = nil;
            self.alpha = 0.5;
        }


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
    NSMutableArray *smoothedElevatioNData = [[NSMutableArray alloc] initWithCapacity:[trek count]];
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
                // Der 0.km wird ignoriert ...
                if (![[self.distanceAnnotationsDict allKeys] containsObject:key] && dist != 0)
                {
//                    NSLog(@"ADDED %d", dist);
                    PSDistanceAnnotation *annotation = [[PSDistanceAnnotation alloc] initWithCoordinate:[tmpLocation coordinate] title:key];

                    [self.distanceAnnotationsDict setObject:annotation forKey:key];
                    [smoothedElevatioNData addObject:[NSNumber numberWithFloat:tmpElevation]];
                }
            }

            //            }
            Location1 = tmpLocation;
            [elevatioNData addObject:[NSNumber numberWithFloat:tmpElevation]];
            pointArrCount++;
        }

    self.trackLength = (float) distance;
    self.pointArrCount = pointArrCount;
    
    self.elevationData = elevatioNData;
    self.smoothedElevationData = smoothedElevatioNData;
    NSLog(@"elevationData = %d", [self.elevationData count]);
    NSLog(@"smoothedElevationData = %d", [self.smoothedElevationData count]);
    self.maxElevationData = [[self.elevationData valueForKeyPath:@"@max.intValue"] floatValue];
    self.minElevationData = [[self.elevationData valueForKeyPath:@"@min.intValue"] floatValue];
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


- (MKCoordinateRegion) region
{
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
                NSLog(@"Do nothing");
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
                NSLog(@"Do nothing");
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
