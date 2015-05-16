//
// Created by Philip Schneider on 10.05.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "PSMapViewController.h"
#import "PSTrack.h"


@interface PSMapViewController ()
@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) PSTrack *track;
@end


@implementation PSMapViewController

- (instancetype) init
{
    DLogFuncName();
    self = [super init];
    if (self)
    {
        CGRect frame = self.view.bounds;
        frame.origin.y = 44 + 20;
        frame.size.height -= frame.origin.y ;

        self.mapView = [[MKMapView alloc] initWithFrame:frame];
        self.mapView.autoresizingMask =  self.view.autoresizingMask;
//        self.mapView.showsUserLocation = YES;
        self.mapView.delegate = self;
//        self.mapView.userTrackingMode = MKUserTrackingModeFollowWithHeading;
        [self.view addSubview:self.mapView];

        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
    }
    return self;
}


- (instancetype) initWithTrack:(PSTrack*)track
{
    DLogFuncName();
    self = [self init];
    if (self)
    {
        self.track = track;
    }
    return self;
}



- (instancetype) initWithTracks:(NSArray*)tracks
{
    DLogFuncName();
    self = [self init];
    if (self)
    {
        self.tracks = tracks;
    }
    return self;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //    // http://wiki.openstreetmap.org/wiki/OpenTopoMap

    if (!self.parentViewController)
    {
        CGRect frame = self.view.bounds;
        if (frame.size.height > frame.size.width)
        {
            NSLog(@"viewWillAppear  Height > width");
            frame.origin.y = 44 + 20;
            frame.size.height -= frame.origin.y;
        }
        else
        {
            NSLog(@"viewWillAppear width > height");
            frame.origin.y = 44 + 20;
            frame.size.height -= frame.origin.y;
        }

        self.mapView.frame = frame;
    }
    return;
    NSString *landShadingTemplate = @"http://tiles.openpistemap.org/landshaded/{z}/{x}/{y}.png";


    NSString *template = @"http://tile.openstreetmap.org/{z}/{x}/{y}.png";
    MKTileOverlay *overlay = [[MKTileOverlay alloc] initWithURLTemplate:template];
    overlay.canReplaceMapContent = YES;

    [self.mapView addOverlay:overlay level:MKOverlayLevelAboveRoads];


    MKTileOverlay *landShadingOverlay = [[MKTileOverlay alloc] initWithURLTemplate:landShadingTemplate];
    landShadingOverlay.canReplaceMapContent = NO;
    [self.mapView addOverlay:landShadingOverlay level:MKOverlayLevelAboveRoads];
}

//


- (void)setTracks:(NSArray *)tracks
{
    _tracks = tracks;

    for (PSTrack *track in tracks)
    {
        [self addTrack:track];
//            [self.mapView addAnnotations:[track distanceAnnotations]];
    }


    MKMapRect zoomRect = MKMapRectNull;
    for (id <MKAnnotation> annotation in self.mapView.annotations)
    {
        MKMapPoint annotationPoint = MKMapPointForCoordinate(annotation.coordinate);
        MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0, 1000);
        if (MKMapRectIsNull(zoomRect)) {
            zoomRect = pointRect;
        } else {
            zoomRect = MKMapRectUnion(zoomRect, pointRect);
        }

        double minMapHeight = 10; //choose some value that fit your needs
        double minMapWidth = 10;  //the same as above
        BOOL needChange = NO;

        double x = MKMapRectGetMinX(zoomRect);
        double y = MKMapRectGetMinY(zoomRect);
        double w = MKMapRectGetWidth(zoomRect);
        double h = MKMapRectGetHeight(zoomRect);  //here was an error!!

        if(MKMapRectGetHeight(zoomRect) < minMapHeight){
            x -= minMapWidth/2;
            w += minMapWidth/2;
            needChange = YES;
        }
        if(MKMapRectGetWidth(zoomRect) < minMapWidth){
            y -= minMapHeight/2;
            h += minMapHeight/2;
            needChange = YES;
        }
        if(needChange){
            zoomRect = MKMapRectMake(x, y, w, h);
        }

        MKCoordinateRegion mkcr = MKCoordinateRegionForMapRect(zoomRect);
        CGRect cgr = [self.mapView convertRegion:mkcr toRectToView:self.view];
        NSLog(@"ZoomRect = %@", NSStringFromCGRect(cgr));
        [self.mapView setVisibleMapRect:zoomRect animated:YES];
    }




    zoomRect = MKMapRectNull;
    for (id <MKOverlay> overlay in self.mapView.overlays)
    {
        MKMapPoint annotationPoint = MKMapPointForCoordinate(overlay.coordinate);
        MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0, 1000);
        if (MKMapRectIsNull(zoomRect)) {
            zoomRect = pointRect;
        } else {
            zoomRect = MKMapRectUnion(zoomRect, pointRect);
        }

        double minMapHeight = 10; //choose some value that fit your needs
        double minMapWidth = 10;  //the same as above
        BOOL needChange = NO;

        double x = MKMapRectGetMinX(zoomRect);
        double y = MKMapRectGetMinY(zoomRect);
        double w = MKMapRectGetWidth(zoomRect);
        double h = MKMapRectGetHeight(zoomRect);  //here was an error!!

        if(MKMapRectGetHeight(zoomRect) < minMapHeight){
            x -= minMapWidth/2;
            w += minMapWidth/2;
            needChange = YES;
        }
        if(MKMapRectGetWidth(zoomRect) < minMapWidth){
            y -= minMapHeight/2;
            h += minMapHeight/2;
            needChange = YES;
        }
        if(needChange){
            zoomRect = MKMapRectMake(x, y, w, h);
        }

        MKCoordinateRegion mkcr = MKCoordinateRegionForMapRect(zoomRect);
        CGRect cgr = [self.mapView convertRegion:mkcr toRectToView:self.view];
        NSLog(@"ZoomRect = %@", NSStringFromCGRect(cgr));
        [self.mapView setVisibleMapRect:zoomRect animated:YES];
    }

//        [self.mapView setVisibleMapRect:zoomRect animated:YES];
}

#pragma mark - Custom
- (void)setTrack:(PSTrack *)track
{
    _track = track;

    self.title = [track filename];

    [self addTrack:self.track];
    [self.mapView addAnnotations:[self.track distanceAnnotations]];

//    [self.locationManager requestWhenInUseAuthorization];
//
//    [self.locationManager startUpdatingLocation];
//    [self.locationManager startUpdatingHeading];
}


- (void) viewDidAppear:(BOOL)animated
{
    
//    NSString *overpassAPIString = [NSString stringWithFormat:@"%.2f,%.2f,%.2f,%.2f",self.mapView.visibleMapRect.origin.x,self.mapView.visibleMapRect.origin.y,self.mapView.visibleMapRect.size.width,self.mapView.visibleMapRect.size.height];
//    @"http://www.overpass.de/api/xapi?node[bbox=8.23,48.59,8.3,49.0][railway=tram_stop]";
//    NSURL *overpassAPIUrl = [NSURL URLWithString:overpassAPIString];
//    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:overpassAPIUrl];
//    
//    NSURLResponse *response;
//    NSError *error;
//    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
//    
//    NSString *strData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
//    NSLog(@"%@",data);
//    NSLog(@"%@",strData);

//    self.mapView.frame = self.view.bounds;
}

- (void) addTrack:(PSTrack*) track
{
    MKPolyline *route = [track route];
    [self.mapView addOverlay:route];

    int padding = 30;
    [self.mapView setVisibleMapRect:[route boundingMapRect] edgePadding:UIEdgeInsetsMake(padding, padding, padding, padding) animated:YES];


    // Dieser Teil nur wenn Route zur Navigation geladen wird
    CLLocationCoordinate2D tmpLocation = MKCoordinateForMapPoint([track start]);

    CLLocationCoordinate2D ground = CLLocationCoordinate2DMake(tmpLocation.latitude, tmpLocation.longitude);
    CLLocationCoordinate2D eye = CLLocationCoordinate2DMake(tmpLocation.latitude, tmpLocation.longitude+.020);
    MKMapCamera *mapCamera = [MKMapCamera cameraLookingAtCenterCoordinate:ground
                                                        fromEyeCoordinate:eye
                                                              eyeAltitude:700];

//    [UIView animateWithDuration:0.5
//                          delay:1.1
//                        options: UIViewAnimationOptionCurveEaseOut
//                     animations:^
//                     {
//                         self.mapView.camera = mapCamera;
//                     }
//                     completion:^(BOOL finished)
//                     {
////                         [self flyover:0];
//                     }];


}


- (void) clearMap
{
    DLogFuncName();
//    if (self.track)
//    {
//        [self.mapView removeOverlay:self.track];
//    }
//
//    if (self.tracks)
//    {
//        [self.mapView removeOverlays:self.tracks];
//    }

    [self.mapView removeOverlay:self.mapView.overlays];
}


- (void) flyover:(int)index
{

    PSTrack *track = self.track;
    __block int i = index;

    [UIView animateWithDuration:2
                          delay:0.1
                        options: UIViewAnimationCurveLinear
                     animations:^
                     {
                         CLLocationCoordinate2D eye;
                         CLLocationCoordinate2D tmpLocation = [track coordinates][i];

//                         if ([track numberOfCoordinates] > index)
//                         {
//                             CLLocationCoordinate2D nextLocation = [track coordinates][i+1];
//                             eye = CLLocationCoordinate2DMake(nextLocation.latitude, nextLocation.longitude);
//                         }
                         if (index > 2 )
                         {
                             CLLocationCoordinate2D prevLocation = [track coordinates][i-2];
                             eye = CLLocationCoordinate2DMake(prevLocation.latitude, prevLocation.longitude);
                         }
                         else
                         {
                            eye = CLLocationCoordinate2DMake(tmpLocation.latitude, tmpLocation.longitude + .020);
                         }

                         CLLocationCoordinate2D ground = CLLocationCoordinate2DMake(tmpLocation.latitude, tmpLocation.longitude);
                         MKMapCamera *mapCamera = [MKMapCamera cameraLookingAtCenterCoordinate:ground
                                                                             fromEyeCoordinate:eye
                                                                                   eyeAltitude:50];
                         self.mapView.camera = mapCamera;

//                         if ([track numberOfCoordinates] > index)
//                         {
//                             dispatch_after(2, dispatch_get_main_queue(), ^
//                                {[self flyover:++i];
//                             });
//                         }
                     }
                     completion:^(BOOL finished)
                     {
                         if ([track numberOfCoordinates] > index)
                         {
                             [self flyover:++i];
                         }
                     }];
}

#pragma mark - Location
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{

}


- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{

}


#pragma mark - Map
//-(MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay
//{
////    if (overlay == )
////    if(overlay == self.routeLine)
////    {
////        if(nil == self.routeLineView)
////        {
////            self.routeLineView = [[MKPolylineView alloc] initWithPolyline:self.routeLine];
////            self.routeLineView.fillColor = [UIColor redColor];
////            self.routeLineView.strokeColor = [UIColor redColor];
////            self.routeLineView.lineWidth = 5;
////
////        }
////
////        return self.routeLineView;
////    }
//
//    return [self.track overlayView];
//    return nil;
//}


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

    CGFloat hue = ( arc4random() % 256 / 256.0 );  //  0.0 to 1.0
    CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from white
    CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from black
    UIColor *color = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
    renderer.strokeColor = color;

    renderer.lineDashPattern = @[@2, @5];
//    renderer.strokeColor =  [UIColor ];   // applying line-width
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


- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    static NSString *annotaionIdentifier=@"annotationIdentifier";
//    MKPinAnnotationView *annotationView=(MKPinAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:annotaionIdentifier ];
//    if (annotationView==nil) {
//
    MKAnnotationView *annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@""];
    annotationView.canShowCallout = YES;

    CGRect frame = CGRectZero;
    frame.size = CGSizeMake(12.0,12.0);

    UILabel *label = [[UILabel alloc] initWithFrame:annotationView.frame];
    label.frame = frame;
    label.textAlignment = NSTextAlignmentCenter;
    label.text = annotation.title;
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

    return annotationView;
}


- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

@end
