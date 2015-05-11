//
//  PSViewController.m
//  ObjcBikeGps
//
//  Created by Philip Schneider on 02.10.14.
//  Copyright (c) 2014 phschneider.net. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "PSViewController.h"
//#import "Ono.h"
#import "XMLDictionary.h"
#import "PSGraphViewController.h"
#import "PSGraphViewController.h"
#import "PSDistanceAnnotation.h"

@interface PSViewController ()

@property(nonatomic, strong) MKMapView *mapView;
@property(nonatomic, strong) CLLocationManager *locationManager;
@property(nonatomic, strong) UILabel *locationLabel;
@property(nonatomic, strong) UILabel *speedLabel;
@property(nonatomic, strong) UILabel *altLabel;
@property(nonatomic, strong) UILabel *distanceLabel;

@property(nonatomic, strong) MKPolyline *routeLine;
@property(nonatomic, strong) MKPolylineView *routeLineView;
@property(nonatomic, strong) PSGraphViewController *graphViewController;
@end

@implementation PSViewController

- (instancetype) init
{
    DLogFuncName();
    self = [super init];
    if (self)
    {

        self.graphViewController = [[PSGraphViewController alloc] init];

        self.mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
        self.mapView.autoresizingMask =  self.view.autoresizingMask;
        self.mapView.showsUserLocation = YES;
        self.mapView.delegate = self;
        self.mapView.userTrackingMode = MKUserTrackingModeFollowWithHeading;
        [self.view addSubview:self.mapView];

        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        [self.locationManager startUpdatingLocation];
        [self.locationManager startUpdatingHeading];


        
        self.locationLabel = [self createAndReturnDefaultLabel];
        [self.view addSubview:self.locationLabel];

        self.speedLabel = [self createAndReturnDefaultLabel];
        [self.view addSubview:self.speedLabel];

        self.altLabel = [self createAndReturnDefaultLabel];
        [self.view addSubview:self.altLabel];
            
        self.distanceLabel = [self createAndReturnDefaultLabel];
        [self.view addSubview:self.distanceLabel];


    }
    return self;
}


- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    static NSString *annotaionIdentifier=@"annotationIdentifier";
//    MKPinAnnotationView *annotationView=(MKPinAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:annotaionIdentifier ];
//    if (annotationView==nil) {
//        
        MKAnnotationView *annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@""];
        annotationView.canShowCallout = YES;
        
        
        UILabel *label = [[UILabel alloc] initWithFrame:annotationView.frame];
        
        CGRect frame = CGRectZero;
//        BOOL adjustFrameFromImage = ([settings changeBackgroundSizeAutomatically] && [settings showsCustomImage]);
//        if (adjustFrameFromImage)
//        {
//            frame.size = CGSizeMake(annotationImage.size.width/2,annotationImage.size.width/2);
//            frame.origin.y = ceil(annotationImage.size.width/10);
//        }
//        else
//        {
            frame.size = CGSizeMake(12.0,12.0);
            //                else
            //                {
            //                    frame.origin.y = ceil([settings.backgroundSize floatValue]/0.5);
            //                }
//        }
    
        label.frame = frame;
        label.textAlignment = NSTextAlignmentCenter;
//        if ([annotation isKindOfClass:[PSMapAtmoPublicDeviceDict class] ])
//        {
//            label.text = [(PSMapAtmoPublicDeviceDict *) annotation displayTitle];
//        }
//        else
//        {
            label.text = annotation.title;
//        }
        label.backgroundColor = [UIColor blackColor];
        label.adjustsFontSizeToFitWidth = YES;
        label.font = [UIFont systemFontOfSize:10.0];
        label.clipsToBounds = YES;
        label.textColor = [UIColor whiteColor];
        label.layer.cornerRadius = frame.size.width/2;
        
            // Centriere das Label in der Annotation
            label.center = annotationView.center;
            label.center = CGPointMake(label.center.x, label.center.y + 5);
        
        [annotationView addSubview:label];
//        aView=[[MKPinAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:annotaionIdentifier];
//        aView.pinColor = MKPinAnnotationColorRed;
//        aView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
//        //        aView.image=[UIImage imageNamed:@"arrow"];
//        aView.animatesDrop=TRUE;
//        aView.canShowCallout = YES;
//        aView.calloutOffset = CGPointMake(-5, 5);
//    }
    
    return annotationView;
}


- (UILabel *)createAndReturnDefaultLabel
{
    UILabel * label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.adjustsFontSizeToFitWidth = YES;
    label.backgroundColor = [UIColor blackColor];
    label.textColor = [UIColor whiteColor];
    label.shadowColor = [UIColor blackColor];
    label.shadowOffset = CGSizeMake(2, 2);
    return label;
}


- (void) viewDidAppear:(BOOL)animated
{
    DLogFuncName();
    [super viewDidAppear:animated];
    
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self addMapOverlay];
    });
//    return;
    
   
    [self.graphViewController willMoveToParentViewController:self];
    CGRect frame = self.view.bounds;
    frame.origin.y = frame.size.height - 100;
    frame.size.height = 100;
    self.graphViewController.view.frame = frame;
    [self.view addSubview:self.graphViewController.view];
    [self.graphViewController didMoveToParentViewController:self];
    
    [self parseElevationData];
}


- (NSString*) filepath
{
    return [[NSBundle mainBundle] pathForResource:@"N´rideHom-3" ofType:@"gpx"];
}

- (void) parseElevationData
{
    DLogFuncName();
    

    NSData *data = [NSData dataWithContentsOfFile:[self filepath]];
    if (data)
    {
        NSDictionary *routingDict = [NSDictionary dictionaryWithXMLData:data];
        NSLog(@"routingDict  %@", routingDict);
        NSArray *trek = [[[routingDict objectForKey:@"trk"] objectForKey:@"trkseg"] objectForKey:@"trkpt"];
        
        NSMutableArray *elevatioNData = [[NSMutableArray alloc] initWithCapacity:[trek count]];
        NSMutableDictionary *annotations = [[NSMutableDictionary alloc] initWithCapacity:[trek count]];
        
        CLLocationCoordinate2D *pointsCoordinate = (CLLocationCoordinate2D *)malloc(sizeof(CLLocationCoordinate2D) * [trek count]);
        
        
//        [self.mapView addOverlay:polyline];
        CLLocation* Location1;
        CLLocation *tmpLocation;
        CLLocationDistance distance = 0.0;
        
        int pointArrIndex = 0;  //it's simpler to keep a separate index for pointArr
        CGFloat minHeight = 0.0;
        CGFloat maxHeight = 0.0;
        
        CGFloat totalUp = 0.0;
        CGFloat totalDown = 0.0;
        
        CGFloat tmpElevation = 0.0;
        
        for (NSDictionary * pointDict in trek)
        {

            CGFloat lat = [[pointDict objectForKey:@"_lat"] doubleValue];
            CGFloat lon = [[pointDict objectForKey:@"_lon"] doubleValue];

            CLLocationCoordinate2D workingCoordinate = CLLocationCoordinate2DMake(lat, lon);
            pointsCoordinate[pointArrIndex] = workingCoordinate;
            
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
                    totalUp += (elevation-tmpElevation);
                }
                else if (elevation < tmpElevation)
                {
                    totalDown += (tmpElevation-elevation);
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
            NSLog(@"Distance = %f", distance);
            int dist = (distance / 1000);
            if (dist %1 == 0)
            {
                NSString *key = [NSString stringWithFormat:@"%d", dist];
                if (![[annotations allKeys] containsObject:key])
                {
                    NSLog(@"ADDED %d", dist);
                    PSDistanceAnnotation *annotation = [[PSDistanceAnnotation alloc] initWithCoordinate:[tmpLocation coordinate] title:key];
                
                    [annotations setObject:annotation forKey:key];
                }
            }

            //            }
            Location1 = tmpLocation;
            [elevatioNData addObject:[NSNumber numberWithFloat:tmpElevation]];
        }
 
//        [self.graphViewController setData:elevatioNData];
        
        self.routeLine = [MKPolyline polylineWithCoordinates:pointsCoordinate count:pointArrIndex];
        free(pointsCoordinate);
        
        [self.mapView addOverlay:self.routeLine];
        [self.mapView setVisibleMapRect:[self.routeLine boundingMapRect]]; //If you want the route to be visible
        
        [self.mapView addAnnotations:[[annotations allValues] copy]];
        
        CLLocationCoordinate2D ground = CLLocationCoordinate2DMake(tmpLocation.coordinate.latitude, tmpLocation.coordinate.longitude);
        CLLocationCoordinate2D eye = CLLocationCoordinate2DMake(tmpLocation.coordinate.latitude, tmpLocation.coordinate.longitude+.020);
        MKMapCamera *mapCamera = [MKMapCamera cameraLookingAtCenterCoordinate:ground
                                                            fromEyeCoordinate:eye
                                                                  eyeAltitude:700];
        
        [UIView animateWithDuration:25.0 animations:^{
            
            
            
            self.mapView.camera = mapCamera;
            
        }];
        
        NSLog(@"MinHeight = %f", minHeight);
        NSLog(@"MaxHeight = %f", maxHeight);
        
        NSLog(@"TotalUp = %f", totalUp);
        NSLog(@"TotalDown = %f", totalDown);
    }
    else
    {
        NSLog(@"No Data for %@", [self filepath]);
    }
    
   
}


-(MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay
{
    if(overlay == self.routeLine)
    {
        if(nil == self.routeLineView)
        {
            self.routeLineView = [[MKPolylineView alloc] initWithPolyline:self.routeLine];
            self.routeLineView.fillColor = [UIColor redColor];
            self.routeLineView.strokeColor = [UIColor redColor];
            self.routeLineView.lineWidth = 5;
            
        }
        
        return self.routeLineView;
    }
    
    return nil;
}


-  (void) addMapOverlay
{
    DLogFuncName();
    
    // Statusabfrage:
    // http://wiki.openstreetmap.org/wiki/Slippy_Map
    // http://tile.openstreetmap.org/7/63/42.png/status
    // Tile is clean. Last rendered at Sun Nov 09 16:07:18 2014. Last accessed at Sun Nov 09 16:07:19 2014. Stored in file:///srv/tile.openstreetmap.org/tiles/default/7/0/0/0/50/136.meta
    // (Dates might not be accurate. Rendering time might be reset to an old date for tile expiry. Access times might not be updated on all file systems)
    
    //http://lhb.baireuther.de/qlandkartegt/
    
//    http://wiki.openstreetmap.org/wiki/OpenLayers/FasterTiles
//    Layer.TMS("Name", ['http://tile1.tile.openstreetmap.org/tiles/', 'http://tile2.tile.openstreetmap.org/tiles/'], {'layername':'mapnik'})
    
    // Compare Maps
    // http://wiki.openstreetmap.org/wiki/Tileserver
    
    // Hike & Bike
//    NSString *template = @"http://toolserver.org/tiles/hikebike/${z}/${x}/${y}.png";
    // NSString *template = @" http://{a,b,c}.tiles.wmflabs.org/hikebike/{z}/{x}/{y}.png
//    NSString *template = @"http://a.tiles.wmflabs.org/hikebike/{z}/{x}/{y}.png";
    
    // Fahrradrouten
//    NSString *template = @"http://tile.lonvia.de/cycling/{z}/{x}/{y}.png";
    
    // Wanderruten
//    NSString *template = @"http://tile.lonvia.de/hiking/{z}/{x}/{y}.png";
    
    
    // Hillshading
    NSString *hillShadingTemplate = @"http://toolserver.org/~cmarqu/hill/{z}/{x}/{y}.png";
    
    // Landshading ...
    NSString *landShadingTemplate = @"http://tiles.openpistemap.org/landshaded/{z}/{x}/{y}.png";
    
//     NSString *template = @"http://www.wanderreitkarte.de/topo/{z}/{x}/{y}.png";
    //OpenCycleMap:
//    NSString *template = @"http://b.tile.opencyclemap.org/cycle/{z}/{x}/{y}.png";
    //MapQuest:
    
//    NSString *template = @"http://otile3.mqcdn.com/tiles/1.0.0/osm/{z}/{x}/{y}.jpg";

    // OpenStreetMap
//    NSString *template = @"http://tile.openstreetmap.org/{z}/{x}/{y}.png";
    
    MKTileOverlay *hillShadingOverlay = [[MKTileOverlay alloc] initWithURLTemplate:hillShadingTemplate];
    hillShadingOverlay.canReplaceMapContent = NO;
    [self.mapView addOverlay:hillShadingOverlay level:MKOverlayLevelAboveLabels];

    MKTileOverlay *landShadingOverlay = [[MKTileOverlay alloc] initWithURLTemplate:landShadingTemplate];
    landShadingOverlay.canReplaceMapContent = NO;
    [self.mapView addOverlay:landShadingOverlay level:MKOverlayLevelAboveLabels];

    //OpenPisteMap
//    NSString *template = @"http://tiles.openpistemap.org/nocontours/{z}/{x}/{y}.png";
    
    // OpenPTMap - Public Transport Map
    // http://wiki.openstreetmap.org/wiki/Openptmap
//    NSString *template = @"http://openptmap.org/tiles/{z}/{x}/{y}.png";
//    MKTileOverlay *overlay = [[MKTileOverlay alloc] initWithURLTemplate:template];
//    overlay.canReplaceMapContent = NO;
//    [self.mapView addOverlay:overlay level:MKOverlayLevelAboveLabels];

    
    
    
//    NSString *template = @"http://tile.öpnvkarte.de/{z}/{x}/{y}.png";
//    NSString *template = @"http://www.openstreetmap.org/#map=10/{z}/{x}/{y}";
//    MKTileOverlay *overlay = [[MKTileOverlay alloc] initWithURLTemplate:template];
//    overlay.canReplaceMapContent = YES;
//    [self.mapView addOverlay:overlay level:MKOverlayLevelAboveLabels];
    

    // MemoMap
//    NSString *template = @"http://tile.memomaps.de/tilegen/{z}/{x}/{y}.png";
//    MKTileOverlay *overlay = [[MKTileOverlay alloc] initWithURLTemplate:template];
//    overlay.canReplaceMapContent = YES;
//    [self.mapView addOverlay:overlay level:MKOverlayLevelAboveLabels];

    // OpenTopoMap
//    // http://wiki.openstreetmap.org/wiki/OpenTopoMap
//    NSString *template = @"http://a.tile.opentopomap.org/{z}/{x}/{y}.png";
//    MKTileOverlay *overlay = [[MKTileOverlay alloc] initWithURLTemplate:template];
//    overlay.canReplaceMapContent = YES;
//    [self.mapView addOverlay:overlay level:MKOverlayLevelAboveLabels];

    
//    return;
    
    NSData *data = [NSData dataWithContentsOfFile:[self filepath]];
    if (data)
    {
        NSDictionary *routingDict = [NSDictionary dictionaryWithXMLData:data];
//         NSLog(@"routingDict  %@", routingDict);
        
        
        NSArray *trek = [[[routingDict objectForKey:@"trk"] objectForKey:@"trkseg"] objectForKey:@"trkpt"];
        
        int pointCount = [trek count] ;
        
        MKMapPoint *pointArr = malloc(sizeof(CLLocationCoordinate2D)
                                      * pointCount);
        CLLocation* Location1;
        CLLocation *tmpLocation;
        CLLocationDistance distance = 0.0;
        
        int pointArrIndex = 0;  //it's simpler to keep a separate index for pointArr
        CGFloat minHeight = 0.0;
        CGFloat maxHeight = 0.0;

        CGFloat totalUp = 0.0;
        CGFloat totalDown = 0.0;
        
        CGFloat tmpElevation = 0.0;
        
        for (NSDictionary * pointDict in trek)
        {
            CLLocationCoordinate2D workingCoordinate;
            CGFloat lat = [[pointDict objectForKey:@"_lat"] doubleValue];
            CGFloat lon = [[pointDict objectForKey:@"_lon"] doubleValue];
            
            workingCoordinate.latitude=lat;
            workingCoordinate.longitude=lon;
            
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
                    totalUp += (elevation-tmpElevation);
                }
                else if (elevation < tmpElevation)
                {
                    totalDown += (tmpElevation-elevation);
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
//                NSLog(@"Distance = %f", distance);
//            }
            Location1 = tmpLocation;
            
            MKMapPoint point = MKMapPointForCoordinate(workingCoordinate);
            pointArr[pointArrIndex] = point;
            pointArrIndex++;         
        }
        
        
        // create the polyline based on the array of points.
        MKPolyline *routeLine = [MKPolyline polylineWithPoints:pointArr count:pointArrIndex];
        [self.mapView addOverlay:routeLine];
        free(pointArr);

        [self setDistance:distance];
        NSLog(@"MinHeight = %f", minHeight);
        NSLog(@"MaxHeight = %f", maxHeight);
        
        NSLog(@"TotalUp = %f", totalUp);
        NSLog(@"TotalDown = %f", totalDown);
    }
    else
    {
        NSLog(@"No Data for %@", [self filepath]);
    }

    
  }


- (void)didReceiveMemoryWarning
{
    DLogFuncName();
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - CoreLocation

-(float) angleToRadians:(float) a
{
    DLogFuncName();
    return ((a/180)*M_PI);
}


- (float) getHeadingForDirectionFromCoordinate:(CLLocationCoordinate2D)fromLoc toCoordinate:(CLLocationCoordinate2D)toLoc
{
    DLogFuncName();
    
    float fLat = [self angleToRadians:fromLoc.latitude];
    float fLng = [self angleToRadians:fromLoc.longitude];
    float tLat = [self angleToRadians:toLoc.latitude];
    float tLng = [self angleToRadians:toLoc.longitude];
    
    return atan2(sin(tLng-fLng)*cos(tLat), cos(fLat)*sin(tLat)-sin(fLat)*cos(tLat)*cos(tLng-fLng));
}
//
//-(void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
//    CLLocationCoordinate2D here =  newLocation.coordinate;
//    
//    [self calculateUserAngle:here];
//}
//
//- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
//    compass.transform = CGAffineTransformMakeRotation(newHeading.magneticHeading * M_PI / 180);
//    needle.transform = CGAffineTransformMakeRotation((degrees - newHeading.magneticHeading) * M_PI / 180);
//}
//
//-(void) calculateUserAngle:(CLLocationCoordinate2D)user {
//    locLat = [[targetLocationDictionary objectForKey:@"latitude"] floatValue];
//    locLon = [[targetLocationDictionary objectForKey:@"longitude"] floatValue];
//    
//    NSLog(@"%f ; %f", locLat, locLon);
//    
//    float pLat;
//    float pLon;
//    
//    if(locLat > user.latitude && locLon > user.longitude) {
//        // north east
//        
//        pLat = user.latitude;
//        pLon = locLon;
//        
//        degrees = 0;
//    }
//    else if(locLat > user.latitude && locLon < user.longitude) {
//        // south east
//        
//        pLat = locLat;
//        pLon = user.longitude;
//        
//        degrees = 45;
//    }
//    else if(locLat < user.latitude && locLon < user.longitude) {
//        // south west
//        
//        pLat = locLat;
//        pLon = user.latitude;
//        
//        degrees = 180;
//    }
//    else if(locLat < user.latitude && locLon > user.longitude) {
//        // north west
//        
//        pLat = locLat;
//        pLon = user.longitude;
//        
//        degrees = 225;
//    }
//    
//    // Vector QP (from user to point)
//    float vQPlat = pLat - user.latitude;
//    float vQPlon = pLon - user.longitude;
//    
//    // Vector QL (from user to location)
//    float vQLlat = locLat - user.latitude;
//    float vQLlon = locLon - user.longitude;
//    
//    // degrees between QP and QL
//    float cosDegrees = (vQPlat * vQLlat + vQPlon * vQLlon) / sqrt((vQPlat*vQPlat + vQPlon*vQPlon) * (vQLlat*vQLlat + vQLlon*vQLlon));
//    degrees = degrees + acos(cosDegrees);
//}


#pragma mark - CLLocationManager
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    DLogFuncName();

}


- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    DLogFuncName();
    NSLog(@"Locations = %@",locations);
    
    CLLocation *location = [locations firstObject];
    
    MKCoordinateRegion region;
    region.center = self.mapView.userLocation.coordinate;
    
    MKCoordinateSpan span;
    span.latitudeDelta  = location.horizontalAccuracy/10000000; // Change these values to change the zoom
    span.longitudeDelta = location.horizontalAccuracy/10000000;
    region.span = span;
    
    NSLog(@"RegionSpane = %f %f", span.latitudeDelta, span.longitudeDelta);
    
    CGRect frame = self.view.bounds;
    frame.origin.y = 20;
    frame.size.height = 20;
    self.locationLabel.frame = frame;
    self.locationLabel.text = [NSString stringWithFormat:@"%@", [location debugDescription]];


    frame = self.view.bounds;
    frame.origin.y =+ 20;
    frame.size.height = 20;
    frame.size.width = ceil (frame.size.width / 2);
    self.speedLabel.frame = frame;
    
    float speedInKmH = location.speed * 3.6;
    self.speedLabel.text = [NSString stringWithFormat:@"%2.2f km/h", speedInKmH];


    frame.origin.x = frame.size.width;
    self.altLabel.frame = frame;
    self.altLabel.text = [NSString stringWithFormat:@"%.2f", location.altitude];

    return;
    
    [self.mapView setRegion:region animated:YES];

}


- (void) setDistance:(CLLocationDistance)distance
{
    DLogFuncName();
    
    NSLog(@"Distance = %f",distance);
    
    CGRect frame = self.view.bounds;
    frame.origin.y += 40;
    frame.size.height = 20;
    frame.size.width = ceil (frame.size.width / 2);
    frame.origin.y += 20;

    self.distanceLabel.frame = frame;
    self.distanceLabel.text = [NSString stringWithFormat:@"%.2fkm", (distance/1000)];
}


- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    DLogFuncName();
    return;
    
    
//    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(newLocation.coordinate, 2000, 2000);
//    [self.mapView setRegion:region animated:YES];
//    
//    // set position of "beam" to position of blue dot
//    self.headingAngleView.center = [self.mapView convertCoordinate:newLocation.coordinate toPointToView:self.view];
//    // slightly adjust position of beam
//    self.headingAngleView.frameTop -= self.headingAngleView.frameHeight/2 + 8;

    
    // PROBLEM: Kartenschrift dreht sich mit ...
    float heading = newHeading.magneticHeading; //in degrees
    float headingDegrees = (heading*M_PI/180)*-1; //assuming needle points to top of iphone. convert to radians
    self.mapView.transform = CGAffineTransformMakeRotation(headingDegrees);
    
    NSLog(@"%f", newHeading.trueHeading);
}


- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager
{
    DLogFuncName();

    NSLog(@"Manager = %@", [manager heading]);
    
    if(!manager.heading.headingAccuracy) return YES; // Got nothing, We can assume we got to calibrate.
    else if( manager.heading.headingAccuracy < 0 ) return YES; // 0 means invalid heading, need to calibrate
    else if( manager.heading.headingAccuracy > 5 )return YES; // 5 degrees is a small value correct for my needs, too.
    else return NO; // All is good. Compass is precise enough.

}


- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    DLogFuncName();
}


- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    DLogFuncName();
}


- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    DLogFuncName();
    NSLog(@"Error = %@",error);
}


- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    DLogFuncName();
}


- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    DLogFuncName();
}


- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    DLogFuncName();
    NSLog(@"Error = %@",error);
}


- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    DLogFuncName();
    NSLog(@"Error = %@",error);
}


- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    DLogFuncName();

    NSLog(@"AuthStatus = %d",status);
}


- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    DLogFuncName();
}


- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager
{
    DLogFuncName();
}


- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager
{
    DLogFuncName();
}


- (void)locationManager:(CLLocationManager *)manager didFinishDeferredUpdatesWithError:(NSError *)error
{
    DLogFuncName();
}


#pragma mark - MapViewDelegate
- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
    DLogFuncName();
}


- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    DLogFuncName();
}


- (void)mapViewWillStartLoadingMap:(MKMapView *)mapView
{
    DLogFuncName();
}


- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView
{
    DLogFuncName();
}


- (void)mapViewDidFailLoadingMap:(MKMapView *)mapView withError:(NSError *)error
{
    DLogFuncName();
    NSLog(@"Error = %@",error);
}


- (void)mapViewWillStartRenderingMap:(MKMapView *)mapView
{
    DLogFuncName();
}


- (void)mapViewDidFinishRenderingMap:(MKMapView *)mapView fullyRendered:(BOOL)fullyRendered
{
    DLogFuncName();
}


//- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
//{
//    DLogFuncName();
//    return nil;
//}
//
//
//- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views
//{
//    DLogFuncName();
//}
//
//
//- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
//{
//    DLogFuncName();
//}
//

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    DLogFuncName();
}


- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
    DLogFuncName();
}


- (void)mapViewDidStopLocatingUser:(MKMapView *)mapView
{
    DLogFuncName();
}


- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    DLogFuncName();
}


- (void)mapView:(MKMapView *)mapView didFailToLocateUserWithError:(NSError *)error
{
    DLogFuncName();
    NSLog(@"Error = %@",error);
}


- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState
{
    DLogFuncName();
}


- (void)mapView:(MKMapView *)mapView didChangeUserTrackingMode:(MKUserTrackingMode)mode animated:(BOOL)animated
{
    DLogFuncName();
}


- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id <MKOverlay>)overlay
{
    DLogFuncName();
    if ([overlay isKindOfClass:[MKTileOverlay class]]) {
        return [[MKTileOverlayRenderer alloc] initWithTileOverlay:overlay];
    }
    
    else if (![overlay isKindOfClass:[MKPolyline class]]) {
        NSLog(@"ERROR ERROR ERROR");
        
        return nil;
    }
    

    MKPolyline *polyLine = (MKPolyline*)overlay;
    NSLog(@"Overlay = %@",polyLine);
    
    MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:polyLine];

    renderer.strokeColor =  [UIColor redColor];   // applying line-width
    renderer.lineWidth = 5.0;
    renderer.alpha = 0.5;

    return renderer;
    
//    if (![overlay isKindOfClass:[MKPolygon class]]) {
//        return nil;
//    }
//    MKPolygon *polygon = (MKPolygon *)overlay;
//    MKPolygonRenderer *renderer = [[MKPolygonRenderer alloc] initWithPolygon:polygon];
//    renderer.fillColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.4];
//    return renderer;
//    
//    return nil;
}


//- (void)mapView:(MKMapView *)mapView didAddOverlayRenderers:(NSArray *)renderers
//{
//
//}


//- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay
//{
//    DLogFuncName();
//    
//    MKPolylineView *routeLineView = [[MKPolylineView alloc] initWithPolyline:overlay] ;
//    routeLineView.fillColor = [UIColor redColor];
//    routeLineView.strokeColor = [UIColor redColor];
//    routeLineView.lineWidth = 3;
//    return routeLineView;
//    
//    return nil;
//}


- (void)mapView:(MKMapView *)mapView didAddOverlayViews:(NSArray *)overlayViews
{
    DLogFuncName();
    

}


- (void)mapViewWillStartLocatingUser:(MKMapView *)mapView
{
    DLogFuncName();

//    mapView.userLocation.
//
//    self.location = [[CLLocation alloc] initWithLatitude:<#(CLLocationDegrees)latitude#> longitude:<#(CLLocationDegrees)longitude#>]
}


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];

    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation))
    {
        [self.view addSubview:self.graphViewController.view];
        [self presentViewController:self.graphViewController animated:YES completion:nil];
    }
    else
    {
//        [self.graphViewController.view removeFromSuperview];
    }
}

@end
