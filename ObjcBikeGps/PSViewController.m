//
//  PSViewController.m
//  ObjcBikeGps
//
//  Created by Philip Schneider on 02.10.14.
//  Copyright (c) 2014 phschneider.net. All rights reserved.
//

#import <MapKit/MapKit.h>
#import <Mapbox-iOS-SDK/RMMapView.h>
#import "PSViewController.h"
//#import "Ono.h"
#import "XMLDictionary.h"
#import "Mapbox-iOS-SDK/Mapbox.h"
#import "Mapbox.h"
#import "RMConfiguration.h"

@interface PSViewController ()

@property(nonatomic, strong) MKMapView *mapView;
@property(nonatomic, strong) CLLocationManager *locationManager;
@property(nonatomic, strong) UILabel *locationLabel;
@property(nonatomic, strong) UILabel *speedLabel;
@property(nonatomic, strong) UILabel *altLabel;
@property(nonatomic, strong) RMMapView *mapBoxView;
@end

@implementation PSViewController

- (instancetype) init
{
    DLogFuncName();
    self = [super init];
    if (self)
    {
        self.mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
        self.mapView.autoresizingMask =  self.view.autoresizingMask;
        self.mapView.showsUserLocation = YES;
        self.mapView.delegate = self;
        self.mapView.userTrackingMode = MKUserTrackingModeFollowWithHeading;
        [self.view addSubview:self.mapView];

////        [[RMConfiguration configuration] setAccessToken:@"sk.eyJ1IjoicGhzY2huZWlkZXIiLCJhIjoiUXlhODk5SSJ9.IqKJIWbBDyKk95GCetG15g"];
//        RMMapboxSource *tileSource = [[RMMapboxSource alloc] initWithMapID:@"phschneider.jlhn5d27"];
//        self.mapBoxView  = [[RMMapView alloc] initWithFrame:self.view.bounds andTilesource:tileSource];
//        self.mapBoxView.userTrackingMode = RMUserTrackingModeFollowWithHeading;
//        self.mapBoxView.autoresizingMask =  self.view.autoresizingMask;

        [self.view addSubview:self.mapBoxView];

        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        [self.locationManager startUpdatingLocation];
        [self.locationManager startUpdatingHeading];

        self.locationLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.locationLabel.adjustsFontSizeToFitWidth = YES;
        self.locationLabel.backgroundColor = [UIColor blackColor];
        self.locationLabel.textColor = [UIColor whiteColor];
        self.locationLabel.shadowColor = [UIColor blackColor];
        self.locationLabel.shadowOffset = CGSizeMake(2, 2);
        [self.view addSubview:self.locationLabel];

        self.speedLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.speedLabel.adjustsFontSizeToFitWidth = YES;
        self.speedLabel.backgroundColor = [UIColor blackColor];
        self.speedLabel.textColor = [UIColor whiteColor];
        self.speedLabel.shadowColor = [UIColor blackColor];
        self.speedLabel.shadowOffset = CGSizeMake(2, 2);
        [self.view addSubview:self.speedLabel];


        self.altLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.altLabel.adjustsFontSizeToFitWidth = YES;
        self.altLabel.backgroundColor = [UIColor blackColor];
        self.altLabel.textColor = [UIColor whiteColor];
        self.altLabel.shadowColor = [UIColor blackColor];
        self.altLabel.shadowOffset = CGSizeMake(2, 2);
        [self.view addSubview:self.altLabel];
    }
    return self;
}


- (void)viewDidLoad
{
    DLogFuncName();
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}


- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self addMapOverlay];
}

-  (void) addMapOverlay
{
    // Compare Maps
    // http://wiki.openstreetmap.org/wiki/Tileserver
    
    // Hike & Bike
//    NSString *template = @"http://toolserver.org/tiles/hikebike/${z}/${x}/${y}.png";
    // NSString *template = @" http://{a,b,c}.tiles.wmflabs.org/hikebike/{z}/{x}/{y}.png
    NSString *template = @"http://a.tiles.wmflabs.org/hikebike/{z}/{x}/{y}.png";
    
    // Fahrradrouten
//    NSString *template = @"http://tile.lonvia.de/cycling/{z}/{x}/{y}.png";
    
    // Wanderruten
//    NSString *template = @"http://tile.lonvia.de/hiking/{z}/{x}/{y}.png";
    
    
    // Hillshading
//    NSString *template = @"http://toolserver.org/~cmarqu/hill/{z}/{x}/{y}.png";
    
    // Landshading ...
//    NSString *template = @"http://tiles.openpistemap.org/landshaded/{z}/{x}/{y}.png";
    
//     NSString *template = @"http://www.wanderreitkarte.de/topo/{z}/{x}/{y}.png";
    //OpenCycleMap:
//    NSString *template = @"http://b.tile.opencyclemap.org/cycle/{z}/{x}/{y}.png";
    //MapQuest:
    
//    NSString *template = @"http://otile3.mqcdn.com/tiles/1.0.0/osm/{z}/{x}/{y}.jpg";

    // OpenStreetMap
//    NSString *template = @"http://tile.openstreetmap.org/{z}/{x}/{y}.png";
    
    MKTileOverlay *overlay = [[MKTileOverlay alloc] initWithURLTemplate:template];
    overlay.canReplaceMapContent = YES;
    [self.mapView addOverlay:overlay level:MKOverlayLevelAboveLabels];

    
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"N´rideHom-3" ofType:@"gpx"];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    if (data)
    {
        NSDictionary *routingDict = [NSDictionary dictionaryWithXMLData:data];
//         NSLog(@"routingDict  %@", routingDict);
        
        
        NSArray *trek = [[[routingDict objectForKey:@"trk"] objectForKey:@"trkseg"] objectForKey:@"trkpt"];
        
        int pointCount = [trek count] / 2;
        
        MKMapPoint *pointArr = malloc(sizeof(CLLocationCoordinate2D)
                                      * pointCount);
        CLLocation* Location1;
        CLLocation *tmpLocation;
        CLLocationDistance distance = 0.0;
        
        int pointArrIndex = 0;  //it's simpler to keep a separate index for pointArr
        for (NSDictionary * pointDict in trek)
        {
            CLLocationCoordinate2D workingCoordinate;
            workingCoordinate.latitude=[[pointDict objectForKey:@"_lat"] doubleValue];
            workingCoordinate.longitude=[[pointDict objectForKey:@"_lon"] doubleValue];
            
//            NSLog(@"Coordinate = %f %f  ELEVATION %f TIME %@", workingCoordinate.latitude, workingCoordinate.longitude,[[pointDict objectForKey:@"ele"] doubleValue], [pointDict objectForKey:@"time"]);
            
            // Distance
            tmpLocation = [[CLLocation alloc] initWithLatitude:[[pointDict objectForKey:@"_lat"] doubleValue] longitude:[[pointDict objectForKey:@"_long"] doubleValue]];
            if (pointArrIndex > 0)
            {
                distance += [Location1 distanceFromLocation:tmpLocation];
//                NSLog(@"Distance = %f", distance);
            }
            Location1 = tmpLocation;
            
            MKMapPoint point = MKMapPointForCoordinate(workingCoordinate);
            pointArr[pointArrIndex] = point;
            pointArrIndex++;         
        }
        
        // create the polyline based on the array of points.
        MKPolyline *routeLine = [MKPolyline polylineWithPoints:pointArr count:pointArrIndex];
        [self.mapView addOverlay:routeLine];
        free(pointArr);
    }
    else
    {
        NSLog(@"No Data for %@", filePath);
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
    frame.origin.y = frame.size.height - 20;
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


- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay
{
    DLogFuncName();
    
    MKPolylineView *routeLineView = [[MKPolylineView alloc] initWithPolyline:overlay] ;
    routeLineView.fillColor = [UIColor redColor];
    routeLineView.strokeColor = [UIColor redColor];
    routeLineView.lineWidth = 3;
    return routeLineView;
    
    return nil;
}


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



@end
