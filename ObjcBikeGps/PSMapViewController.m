//
// Created by Philip Schneider on 10.05.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <MapKit/MapKit.h>
#import "PSMapViewController.h"
#import "PSTrack.h"
#import "WYPopoverController.h"
#import "PSSettingsViewController.h"
#import "PSTileOverlay.h"
#import "AFHTTPRequestOperation.h"
#import "Ono.h"


@interface PSMapViewController ()
@property (nonatomic) MKMapView *mapView;
@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) PSTrack *track;
@property (nonatomic) WYPopoverController *settingsPopoverController;
@property (nonatomic) UILabel *debugLabel;
@property (nonatomic) UILabel *boundingLabel;
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

        self.boundingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, frame.size.height-20-20, frame.size.width, 20)];
        self.boundingLabel.textAlignment = NSTextAlignmentCenter;
        self.boundingLabel.backgroundColor = [UIColor clearColor];
        [self.mapView addSubview:self.boundingLabel];

        self.debugLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, frame.size.height-20, frame.size.width, 20)];
        self.debugLabel.textAlignment = NSTextAlignmentCenter;
        self.debugLabel.backgroundColor = [UIColor clearColor];
        [self.mapView addSubview:self.debugLabel];

        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;

        UIImage *buttonImage = [UIImage imageNamed:@"1064-layers-4"];
        UIButton *customButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        frame.origin.y = self.mapView.frame.size.height - buttonImage.size.height - 15;
        frame.origin.x = self.mapView.frame.size.width - buttonImage.size.width - 15;
        frame.size.width = buttonImage.size.width;
        frame.size.height =  buttonImage.size.height;

        customButton.frame = frame;
        [customButton setBackgroundColor:[UIColor whiteColor]];
        [customButton setImage:buttonImage forState:UIControlStateNormal];
        [customButton addTarget:self action:@selector(showMapSwitcher:) forControlEvents:UIControlEventTouchUpInside];
        [self.mapView addSubview:customButton];
    }
    return self;
}


- (void)showMapSwitcher:(id)sender
{
    DLogFuncName();
    if (self.settingsPopoverController == nil)
    {
        UIView *btn = (UIView *) sender;
        PSSettingsViewController *settingsViewController = [[PSSettingsViewController alloc] init];
        UINavigationController *contentViewController = [[UINavigationController alloc] initWithRootViewController:settingsViewController];


        self.settingsPopoverController = [[WYPopoverController alloc] initWithContentViewController:contentViewController];
        self.settingsPopoverController.delegate = self;
//    settingsPopoverController.passthroughViews = @[btn];
        self.settingsPopoverController.popoverLayoutMargins = UIEdgeInsetsMake(10, 10, 10, 10);
        self.settingsPopoverController.wantsDefaultContentAppearance = NO;

        [self.settingsPopoverController presentPopoverAsDialogAnimated:YES];

//        [self.settingsPopoverController presentPopoverFromRect:[btn convertRect:btn.frame toView:self.mapView]
//                                                        inView:self.view
//                                      permittedArrowDirections:WYPopoverArrowDirectionAny
//                                                      animated:YES
//                                                       options:WYPopoverAnimationOptionFadeWithScale];
    }
    else
    {
        [self done:nil];
    }
}

- (void)done:(id)sender
{
    DLogFuncName();
    [self.settingsPopoverController dismissPopoverAnimated:YES];
    self.settingsPopoverController.delegate = nil;
    self.settingsPopoverController = nil;
}


#pragma mark - WYPopoverControllerDelegate

- (BOOL)popoverControllerShouldDismissPopover:(WYPopoverController *)controller
{
    DLogFuncName();
    return YES;
}

- (void)popoverControllerDidDismissPopover:(WYPopoverController *)controller
{
    DLogFuncName();
    if (controller == self.settingsPopoverController)
    {
        self.settingsPopoverController.delegate = nil;
        self.settingsPopoverController = nil;
    }
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
    DLogFuncName();
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


//    NSString *template = @"http://tile.openstreetmap.org/${z}/${x}/${y}.png";
//    MKTileOverlay *overlay = [[MKTileOverlay alloc] initWithURLTemplate:template];
//    overlay.canReplaceMapContent = NO;
//    [self.mapView addOverlay:overlay level:MKOverlayLevelAboveRoads];

    // Hike And Bike Map
    //    NSString *template = @"http://toolserver.org/tiles/hikebike/${z}/${x}/${y}.png";
//    NSString *template = @"http://a.tiles.wmflabs.org/hikebike/{z}/{x}/{y}.png";

    return;


    NSString *template = @"http://b.tiles.wmflabs.org/hikebike/{z}/{x}/{y}.png";
    PSTileOverlay *overlay = [[PSTileOverlay alloc] initWithURLTemplate:template];
    overlay.canReplaceMapContent = NO;
    [self.mapView addOverlay:overlay level:MKOverlayLevelAboveRoads];

//    // OpenTopoMap
//    // http://wiki.openstreetmap.org/wiki/OpenTopoMap
//    NSString *template = @"http://a.tile.opentopomap.org/{z}/{x}/{y}.png";
//    MKTileOverlay *overlay = [[MKTileOverlay alloc] initWithURLTemplate:template];
//    overlay.canReplaceMapContent = NO;
//    [self.mapView addOverlay:overlay level:MKOverlayLevelAboveRoads];

    return;
//    NSString *landShadingTemplate = @"http://tiles.openpistemap.org/landshaded/{z}/{x}/{y}.png";
//
//
//    NSString *template = @"http://tile.openstreetmap.org/{z}/{x}/{y}.png";
//    MKTileOverlay *overlay = [[MKTileOverlay alloc] initWithURLTemplate:template];
//    overlay.canReplaceMapContent = YES;
//
//    [self.mapView addOverlay:overlay level:MKOverlayLevelAboveRoads];
//
//
//    MKTileOverlay *landShadingOverlay = [[MKTileOverlay alloc] initWithURLTemplate:landShadingTemplate];
//    landShadingOverlay.canReplaceMapContent = NO;
//    [self.mapView addOverlay:landShadingOverlay level:MKOverlayLevelAboveRoads];
}

#define MERCATOR_RADIUS 85445659.44705395
#define MAX_GOOGLE_LEVELS 20

- (double)getZoomLevel
{
    CLLocationDegrees longitudeDelta = self.mapView.region.span.longitudeDelta;
    CGFloat mapWidthInPixels = self.mapView.bounds.size.width;
    double zoomScale = longitudeDelta * MERCATOR_RADIUS * M_PI / (180.0 * mapWidthInPixels);
    double zoomer = MAX_GOOGLE_LEVELS - log2( zoomScale );
    if ( zoomer < 0 ) zoomer = 0;
//  zoomer = round(zoomer);
    return zoomer;
}

//
- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
    DLogFuncName();
    NSArray * boundingBox = [self getBoundingBox:self.mapView.visibleMapRect];
    NSString *boundingBoxString = [NSString stringWithFormat:@"%.3f,%.3f,%.3f,%.3f", [[boundingBox objectAtIndex:1] floatValue], [[boundingBox objectAtIndex:0] floatValue], [[boundingBox objectAtIndex:3] floatValue], [[boundingBox objectAtIndex:2] floatValue]];
    NSLog(@"BoudningBox = %@", boundingBoxString);
    self.debugLabel.text = [NSString stringWithFormat:@"lat: %f long: %f z: %f", self.mapView.region.span.latitudeDelta, self.mapView.region.span.longitudeDelta, [self getZoomLevel]];
    NSLog(@"http://api.openstreetmap.org/api/0.6/map?bbox=%@",boundingBoxString);
    NSLog(@"http://overpass.osm.rambler.ru/cgi/xapi_meta?*[bbox=%@]",boundingBoxString);
}


- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    DLogFuncName();
    NSArray * boundingBox = [self getBoundingBox:self.mapView.visibleMapRect];
    NSString *boundingBoxString = [NSString stringWithFormat:@"%.3f,%.3f,%.3f,%.3f", [[boundingBox objectAtIndex:1] floatValue], [[boundingBox objectAtIndex:0] floatValue], [[boundingBox objectAtIndex:3] floatValue], [[boundingBox objectAtIndex:2] floatValue]];
    self.boundingLabel.text = boundingBoxString;
    NSLog(@"BoudningBox = %@", boundingBoxString);
    self.debugLabel.text = [NSString stringWithFormat:@"lat: %f long: %f z: %f", self.mapView.region.span.latitudeDelta, self.mapView.region.span.longitudeDelta, [self getZoomLevel]];

    NSLog(@"http://api.openstreetmap.org/api/0.6/map?bbox=%@",boundingBoxString);
    NSLog(@"http://overpass.osm.rambler.ru/cgi/xapi_meta?*[bbox=%@]",boundingBoxString);
//    overpass-api.de/api/map?bbox=6.8508,49.1958,7.2302,49.2976


    // 1

    NSString *string = [NSString stringWithFormat:@"http://overpass.osm.rambler.ru/cgi/xapi_meta?way[highway=path][bbox=%@]", boundingBoxString];
    NSURL *url = [NSURL URLWithString:string];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];

    // 2
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    // Make sure to set the responseSerializer correctly
//    operation.responseSerializer = [AFXMLParserResponseSerializer serializer];


    // TODO
    // https://github.com/AFNetworking/AFOnoResponseSerializer

    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {

        // 3

        NSData *data = responseObject;
        NSError *error;

        ONOXMLDocument *document = [ONOXMLDocument XMLDocumentWithData:data error:&error];
//        for (ONOXMLElement *element in document.rootElement.children) {
//            NSLog(@"%@: %@", element.tag, element.attributes);
//        }

        NSString *xPathString = @"//way";
        [document enumerateElementsWithXPath:xPathString usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop) {
            NSLog(@"%@", element);
            __block PSTrack *track = [[PSTrack alloc] initWithXmlData:element document:document];
            dispatch_async(dispatch_get_main_queue(),^{
                [self setTracks: @[ track ]];
            });
        }];



//        [self clearMap];


//        [document enumerateElementsWithXPath:@"//Content" usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop) {
//            NSLog(@"%@", element);
//        }];


    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

        // 4
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error Retrieving Weather"
                                                            message:[error localizedDescription]
                                                           delegate:nil
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil];
        [alertView show];
    }];

    // 5
    [operation start];
}


- (void)setTracks:(NSArray *)tracks
{
    DLogFuncName();
    _tracks = tracks;

    for (PSTrack *track in tracks)
    {
        [self addTrack:track];
//            [self.mapView addAnnotations:[track distanceAnnotations]];
    }


//    MKMapRect zoomRect = MKMapRectNull;
//    for (id <MKAnnotation> annotation in self.mapView.annotations)
//    {
//        MKMapPoint annotationPoint = MKMapPointForCoordinate(annotation.coordinate);
//        MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0, 1000);
//        if (MKMapRectIsNull(zoomRect)) {
//            zoomRect = pointRect;
//        } else {
//            zoomRect = MKMapRectUnion(zoomRect, pointRect);
//        }
//
//        double minMapHeight = 10; //choose some value that fit your needs
//        double minMapWidth = 10;  //the same as above
//        BOOL needChange = NO;
//
//        double x = MKMapRectGetMinX(zoomRect);
//        double y = MKMapRectGetMinY(zoomRect);
//        double w = MKMapRectGetWidth(zoomRect);
//        double h = MKMapRectGetHeight(zoomRect);  //here was an error!!
//
//        if(MKMapRectGetHeight(zoomRect) < minMapHeight){
//            x -= minMapWidth/2;
//            w += minMapWidth/2;
//            needChange = YES;
//        }
//        if(MKMapRectGetWidth(zoomRect) < minMapWidth){
//            y -= minMapHeight/2;
//            h += minMapHeight/2;
//            needChange = YES;
//        }
//        if(needChange){
//            zoomRect = MKMapRectMake(x, y, w, h);
//        }
//
//        MKCoordinateRegion mkcr = MKCoordinateRegionForMapRect(zoomRect);
//        CGRect cgr = [self.mapView convertRegion:mkcr toRectToView:self.view];
//        NSLog(@"ZoomRect = %@", NSStringFromCGRect(cgr));
//        [self.mapView setVisibleMapRect:zoomRect animated:YES];
//    }
//

}




- (void)zoomToOverlays
{
    MKMapRect zoomRect = MKMapRectNull;
    for (id <MKOverlay> overlay in self.mapView.overlays)
    {
        if ([overlay isKindOfClass:[MKPolyline class]])
        {
            MKMapPoint annotationPoint = MKMapPointForCoordinate(overlay.coordinate);
            MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0, 1000);
            if (MKMapRectIsNull(zoomRect))
            {
                zoomRect = pointRect;
            } else
            {
                zoomRect = MKMapRectUnion(zoomRect, pointRect);
            }

            double minMapHeight = 10; //choose some value that fit your needs
            double minMapWidth = 10;  //the same as above
            BOOL needChange = NO;

            double x = MKMapRectGetMinX(zoomRect);
            double y = MKMapRectGetMinY(zoomRect);
            double w = MKMapRectGetWidth(zoomRect);
            double h = MKMapRectGetHeight(zoomRect);  //here was an error!!

            if (MKMapRectGetHeight(zoomRect) < minMapHeight)
            {
                x -= minMapWidth / 2;
                w += minMapWidth / 2;
                needChange = YES;
            }
            if (MKMapRectGetWidth(zoomRect) < minMapWidth)
            {
                y -= minMapHeight / 2;
                h += minMapHeight / 2;
                needChange = YES;
            }
            if (needChange)
            {
                zoomRect = MKMapRectMake(x, y, w, h);
            }

            MKCoordinateRegion mkcr = MKCoordinateRegionForMapRect(zoomRect);
            CGRect cgr = [self.mapView convertRegion:mkcr toRectToView:self.view];
            NSLog(@"ZoomRect = %@", NSStringFromCGRect(cgr));
            [self.mapView setVisibleMapRect:zoomRect animated:YES];
        }
    }
    [self.mapView setVisibleMapRect:zoomRect animated:YES];
}


#pragma mark - Custom
- (void)setTrack:(PSTrack *)track
{
    DLogFuncName();
    _track = track;

    self.title = [track filename];

    [self addTrack:self.track];
//    [self.mapView addAnnotations:[self.track distanceAnnotations]];

//    [self.locationManager requestWhenInUseAuthorization];
//
//    [self.locationManager startUpdatingLocation];
//    [self.locationManager startUpdatingHeading];
}


- (void) viewDidAppear:(BOOL)animated
{
    DLogFuncName();
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

    [self zoomToOverlays];

}

- (void) addTrack:(PSTrack*) track
{
    DLogFuncName();
    MKPolyline *route = [track route];
    [self.mapView addOverlay:route];

//    int padding = 30;
//    [self.mapView setVisibleMapRect:[route boundingMapRect] edgePadding:UIEdgeInsetsMake(padding, padding, padding, padding) animated:YES];
//
//
//    // Dieser Teil nur wenn Route zur Navigation geladen wird
//    CLLocationCoordinate2D tmpLocation = MKCoordinateForMapPoint([track start]);
//
//    CLLocationCoordinate2D ground = CLLocationCoordinate2DMake(tmpLocation.latitude, tmpLocation.longitude);
//    CLLocationCoordinate2D eye = CLLocationCoordinate2DMake(tmpLocation.latitude, tmpLocation.longitude+.020);
//    MKMapCamera *mapCamera = [MKMapCamera cameraLookingAtCenterCoordinate:ground
//                                                        fromEyeCoordinate:eye
//                                                              eyeAltitude:700];

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

    if ([self.mapView.overlays count])
    {
        NSArray *overlays = [[self.mapView overlays] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self isKindOfClass: %@", [MKPolyline class]]];
        if ([overlays count])
        {
            [self.mapView removeOverlays:overlays];
        }
    }
}


- (void) flyover:(int)index
{
    DLogFuncName();
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


#pragma mark - Bounding box
-(CLLocationCoordinate2D)getNECoordinate:(MKMapRect)mRect{
    return [self getCoordinateFromMapRectanglePoint:MKMapRectGetMaxX(mRect) y:mRect.origin.y];
}
-(CLLocationCoordinate2D)getNWCoordinate:(MKMapRect)mRect{
    return [self getCoordinateFromMapRectanglePoint:MKMapRectGetMinX(mRect) y:mRect.origin.y];
}
-(CLLocationCoordinate2D)getSECoordinate:(MKMapRect)mRect{
    return [self getCoordinateFromMapRectanglePoint:MKMapRectGetMaxX(mRect) y:MKMapRectGetMaxY(mRect)];
}
-(CLLocationCoordinate2D)getSWCoordinate:(MKMapRect)mRect{
    return [self getCoordinateFromMapRectanglePoint:mRect.origin.x y:MKMapRectGetMaxY(mRect)];
}

// http://www.softwarepassion.com/how-to-get-geographic-coordinates-of-the-visible-mkmapview-area-in-ios/
-(CLLocationCoordinate2D)getCoordinateFromMapRectanglePoint:(double)x y:(double)y{
    MKMapPoint swMapPoint = MKMapPointMake(x, y);
    return MKCoordinateForMapPoint(swMapPoint);
}

-(NSArray *)getBoundingBox:(MKMapRect)mRect{
    CLLocationCoordinate2D bottomLeft = [self getSWCoordinate:mRect];
    CLLocationCoordinate2D topRight = [self getNECoordinate:mRect];
    return @[[NSNumber numberWithDouble:bottomLeft.latitude ],
            [NSNumber numberWithDouble:bottomLeft.longitude],
            [NSNumber numberWithDouble:topRight.latitude],
            [NSNumber numberWithDouble:topRight.longitude]];
}


//- (NSArray*)getBoundingBox:(MKCoordinateRegion *)mapRegion;
//{
//    MKCoordinateRegion *mapRegion = myMap.region;
//
//    CGFloat maxLatitude = mapRegion.center.latitude + mapRegion.span.latitudeDelta/2;
//    CGFloat minLatitude = mapRegion.center.latitude - mapRegion.span.latitudeDelta/2;
//
//    CGFloat maxLongitude = mapRegion.center.longitude+ mapRegion.span.longitudeDelta/2;
//    CGFloat minLongitude = mapRegion.center.longitude- mapRegion.span.longitudeDelta/2;
//
//}

#pragma mark - Location
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    DLogFuncName();
}


- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    DLogFuncName();
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
//
//    else if (![overlay isKindOfClass:[MKPolyline class]]) {
//        NSLog(@"ERROR ERROR ERROR");
//
//        return nil;
//    }
//

    if (![overlay isKindOfClass:[MKPolyline class]]) {
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
    DLogFuncName();
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
    DLogFuncName();
    return UIInterfaceOrientationMaskAll;
}

@end
