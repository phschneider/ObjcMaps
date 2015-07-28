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
#import "MBProgressHUD.h"
#import "PSTrackOverlay.h"
#import "PSTrackRenderer.h"
#import "PSPoiStore.h"
#import "PSPoi.h"
#import "PSDistanceAnnotation.h"


@interface PSMapViewController ()
@property (nonatomic) MKMapView *mapView;
@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) PSTrack *track;
@property (nonatomic) WYPopoverController *settingsPopoverController;
@property (nonatomic) UILabel *debugLabel;
@property (nonatomic) UILabel *boundingLabel;
@property (nonatomic) UILabel *areaLabel;
@property (nonatomic) UILabel *distannceLabelWidth;
@property (nonatomic) UILabel *distannceLabelHeight;
@property (nonatomic) UIButton *locationButton;
@property (nonatomic) UIView *debugView;
@end


@implementation PSMapViewController

- (instancetype) init
{
    DLogFuncName();
    self = [super init];
    if (self)
    {
        [[PSPoiStore sharedInstance] addObserver:self forKeyPath:@"pois" options:NSKeyValueObservingOptionNew context:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(poisUpdated) name:@"POIS_UPDATED" object:nil];

        CGRect frame = self.view.bounds;
        frame.origin.y = 44 + 20;
        frame.size.height -= frame.origin.y;

        self.mapView = [[MKMapView alloc] initWithFrame:frame];
        self.mapView.autoresizingMask =  self.view.autoresizingMask;
        self.mapView.delegate = self;
        self.mapView.showsUserLocation = NO;
        [self.view addSubview:self.mapView];

        [self addLabels];
        [self addButtons];

        //View Area
        MKCoordinateRegion region = { { 0.0, 0.0 }, { 0.0, 0.0 } };
        region.center.latitude = self.locationManager.location.coordinate.latitude;
        region.center.longitude = self.locationManager.location.coordinate.longitude;
        region.span.longitudeDelta = 0.005f;
        region.span.longitudeDelta = 0.005f;
        [self.mapView setRegion:region animated:YES];

        UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureRecognizerFired:)];
        [self.mapView addGestureRecognizer:longPressGestureRecognizer];
    }
    return self;
}


- (void)longPressGestureRecognizerFired:(id)uilongPressGestureRecognizerFired
{
    DLogFuncName();
    UILongPressGestureRecognizer *longPressGestureRecognizer = uilongPressGestureRecognizerFired;
    if (longPressGestureRecognizer.state == UIGestureRecognizerStateEnded)
    {
        self.debugView.hidden = NO;
        [UIView animateWithDuration:1.0 delay:0.5 options:UIViewAnimationCurveEaseInOut animations:^
                {
                    self.debugView.alpha = 1.0;
                }
        completion:^(BOOL completed)
        {
            [UIView animateWithDuration:1.0 delay:2.5 options:UIViewAnimationCurveEaseInOut animations:^
                    {
                        self.debugView.alpha = .0;
                    }
                             completion:^(BOOL completed)
                             {
                                               self.debugView.hidden = YES;
                             }];
        }
        ];
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


- (void) addLabels
{
    DLogFuncName();
    
    CGRect frame = self.view.bounds;
    frame.origin.y = 44 + 20;
    frame.size.height -= frame.origin.y ;

    self.areaLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 20)];
    self.areaLabel.textAlignment = NSTextAlignmentCenter;
    self.areaLabel.backgroundColor = [UIColor clearColor];
    self.areaLabel.shadowColor = [UIColor whiteColor];
    self.areaLabel.layer.shadowOffset = CGSizeMake(0, 1);
    self.areaLabel.layer.shadowRadius = 1;

    [self.mapView addSubview:self.areaLabel];

    self.distannceLabelWidth = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, frame.size.width, 20)];
    self.distannceLabelWidth.textAlignment = NSTextAlignmentCenter;
    self.distannceLabelWidth.backgroundColor = [UIColor clearColor];
    self.distannceLabelWidth.shadowColor = [UIColor whiteColor];
    self.distannceLabelWidth.layer.shadowOffset = CGSizeMake(0, 1);
    self.distannceLabelWidth.layer.shadowRadius = 1;
    [self.mapView addSubview:self.distannceLabelWidth];

    self.distannceLabelHeight = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frame.size.height, 20)];
    self.distannceLabelHeight.textAlignment = NSTextAlignmentCenter;
    self.distannceLabelHeight.shadowColor = [UIColor whiteColor];
    self.distannceLabelHeight.layer.shadowOffset = CGSizeMake(0, 1);
    self.distannceLabelHeight.layer.shadowRadius = 1;
    self.distannceLabelHeight.transform = CGAffineTransformMakeRotation( -(M_PI / 2));
    [self.mapView addSubview: self.distannceLabelHeight];

    CGRect dlhFrame = self.distannceLabelHeight.frame;
    dlhFrame.origin.y += dlhFrame.origin.x;
    dlhFrame.origin.x = self.view.bounds.size.width - self.distannceLabelHeight.bounds.size.height;
    self.distannceLabelHeight.frame = dlhFrame;

    self.debugView = [[UIView alloc] initWithFrame:self.mapView.bounds];
    self.debugView.hidden = YES;
    self.debugView.alpha = 0.0;

    self.boundingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, frame.size.height-20-20, frame.size.width, 20)];
    self.boundingLabel.textAlignment = NSTextAlignmentCenter;
    self.boundingLabel.backgroundColor = [UIColor clearColor];
    self.boundingLabel.shadowColor = [UIColor whiteColor];
    self.boundingLabel.layer.shadowOffset = CGSizeMake(0, 1);
    self.boundingLabel.layer.shadowRadius = 1;
    [self.debugView addSubview:self.boundingLabel];
    
    self.debugLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, frame.size.height-20, frame.size.width, 20)];
    self.debugLabel.textAlignment = NSTextAlignmentCenter;
    self.debugLabel.backgroundColor = [UIColor clearColor];
    self.debugLabel.shadowColor = [UIColor whiteColor];
    self.debugLabel.layer.shadowOffset = CGSizeMake(0, 1);
    self.debugLabel.layer.shadowRadius = 1;
    [self.debugView addSubview:self.debugLabel];

    [self.mapView addSubview:self.debugView];
}


- (void) addButtons
{
    DLogFuncName();
    CGRect frame = self.view.bounds;
    frame.origin.y = 44 + 20;
    frame.size.height -= frame.origin.y;

    UIImage *layersImage = [UIImage imageNamed:@"1064-layers-4"];
    UIButton *layersButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    frame.origin.y = self.mapView.frame.size.height - layersImage.size.height - 15;
    frame.origin.x = self.mapView.frame.size.width - layersImage.size.width - 15;
    frame.size.width = layersImage.size.width;
    frame.size.height =  layersImage.size.height;
    
    layersButton.frame = frame;
    [layersButton setBackgroundColor:[UIColor whiteColor]];
    [layersButton setImage:layersImage forState:UIControlStateNormal];
    [layersButton addTarget:self action:@selector(showMapSwitcherButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.mapView addSubview:layersButton];
    
    
    UIImage *syncImage = [UIImage imageNamed:@"760-refresh-3"];
    UIButton *syncButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    frame.origin.y = self.mapView.frame.size.height - syncImage.size.height - 15;
    frame.origin.x = 15;
    frame.size.width = syncImage.size.width;
    frame.size.height =  syncImage.size.height;
    
    syncButton.frame = frame;
    [syncButton setBackgroundColor:[UIColor whiteColor]];
    [syncButton setImage:syncImage forState:UIControlStateNormal];
    [syncButton addTarget:self action:@selector(syncOsmMapButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.mapView addSubview:syncButton];
    
    UIImage *syncPoisImage = [UIImage imageNamed:@"Emergeny"];
    UIButton *syncPoisButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    frame.origin.y = self.mapView.frame.size.height - syncPoisImage.size.height - 15;
    frame.origin.x = 15 + syncImage.size.width  + 15;
    frame.size.width = syncImage.size.width;
    frame.size.height =  syncImage.size.height;
    
    syncPoisButton.frame = frame;
//    [syncPoisButton setBackgroundColor:[UIColor whiteColor]];
    [syncPoisButton setImage:syncPoisImage forState:UIControlStateNormal];
    [syncPoisButton addTarget:self action:@selector(syncOsmPoisButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.mapView addSubview:syncPoisButton];
    
    self.locationButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    frame.origin.y = self.mapView.frame.size.height - syncImage.size.height - 15;
    frame.origin.x = ceil((self.mapView.frame.size.width - 100)/2);
    frame.size.width = 100;
    frame.size.height =  syncImage.size.height;
    [self.locationButton setTitle:@"Track" forState:UIControlStateNormal];
    self.locationButton.frame = frame;
    
    [self.locationButton addTarget:self action:@selector(locationButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.mapView addSubview:self.locationButton];
}


#pragma mark - View
#pragma mark - Init
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
//            NSLog(@"viewWillAppear  Height > width");
            frame.origin.y = 44 + 20;
            frame.size.height -= frame.origin.y;
        }
        else
        {
//            NSLog(@"viewWillAppear width > height");
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

//    return;


#ifdef USE_OSM
    NSString *template = @"http://b.tiles.wmflabs.org/hikebike/{z}/{x}/{y}.png";
    PSTileOverlay *overlay = [[PSTileOverlay alloc] initWithURLTemplate:template];
    overlay.canReplaceMapContent = NO;
    [self.mapView addOverlay:overlay level:MKOverlayLevelAboveRoads];
#endif

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


- (void) viewDidAppear:(BOOL)animated
{
    DLogFuncName();
    [super viewDidAppear:animated];
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
    // Disable iOS 7 back gesture
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
        self.navigationController.interactivePopGestureRecognizer.delegate = self;
    }
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Enable iOS 7 back gesture
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
        self.navigationController.interactivePopGestureRecognizer.delegate = nil;
    }
}


- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return YES;
    return NO;
}


#pragma mark - Buttons
- (void)locationButtonTapped
{
    DLogFuncName();
    if (    [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined ||
            [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted ||
            [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied )
    {
        // Damit nicht beim laden des viewControllers schon bewegung in der Karte ist ...
        if (!self.locationManager)
        {
            self.locationManager = [[CLLocationManager alloc] init];
            self.locationManager.delegate = self;
        }
        [self.locationManager requestWhenInUseAuthorization];
    }
    else
    {
        [self switchUserTracking];
    }
}


- (void) switchUserTracking
{
    DLogFuncName();
    if (self.mapView.userTrackingMode == MKUserTrackingModeNone)
    {
        self.mapView.showsUserLocation = YES;
        [self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
    }
    else if (self.mapView.userTrackingMode == MKUserTrackingModeFollow)
    {
        self.mapView.showsUserLocation = YES;
        [self.mapView setUserTrackingMode:MKUserTrackingModeFollowWithHeading animated:YES];
    }
    else if (self.mapView.userTrackingMode == MKUserTrackingModeFollowWithHeading)
    {
        self.mapView.showsUserLocation = NO;
        [self.mapView setUserTrackingMode:MKUserTrackingModeNone animated:YES];
    }

    [self updateTrackingButtonTitleForCurrentUserTrackingMode];
//        self.locationManager.distanceFilter = kCLDistanceFilterNone;
//        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
//        [self.locationManager startUpdatingLocation]
}


- (void) updateTrackingButtonTitleForCurrentUserTrackingMode
{
    DLogFuncName();
    if (self.mapView.userTrackingMode == MKUserTrackingModeNone)
    {
        [self.locationButton setTitle:@"None" forState:UIControlStateNormal];
    }
    else if (self.mapView.userTrackingMode == MKUserTrackingModeFollow)
    {
        [self.locationButton setTitle:@"Tracking" forState:UIControlStateNormal];
    }
    else if (self.mapView.userTrackingMode == MKUserTrackingModeFollowWithHeading)
    {
        [self.locationButton setTitle:@"Heading" forState:UIControlStateNormal];
    }
    else
    {
        [self.locationButton setTitle:@"-" forState:UIControlStateNormal];
    }
}

- (void)syncOsmMapButtonTapped:(id)sender
{
    DLogFuncName();
#warning - dieser teil sollte manuell ausgelöst werden, ansonsten gehen zuviele anfragen raus, welche evtl in einen TimeOut laufen
    // 1
    MBProgressHUD *HUD = [MBProgressHUD showHUDAddedTo:self.view animated:NO];
    //    HUD.mode = MBProgressHUDModeIndeterminate;
    HUD.mode = MBProgressHUDModeDeterminateHorizontalBar;
    
    UITapGestureRecognizer *HUDSingleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(singleTap:)];
    [HUD addGestureRecognizer:HUDSingleTap];
    
    NSArray * boundingBox = [self getBoundingBox:self.mapView.visibleMapRect];
    NSString *boundingBoxString = [NSString stringWithFormat:@"%.3f,%.3f,%.3f,%.3f", [[boundingBox objectAtIndex:1] floatValue], [[boundingBox objectAtIndex:0] floatValue], [[boundingBox objectAtIndex:3] floatValue], [[boundingBox objectAtIndex:2] floatValue]];
    
    
    NSString *string = [NSString stringWithFormat:@"http://overpass.osm.rambler.ru/cgi/xapi_meta?way[highway=path][bbox=%@]", boundingBoxString];
    //    NSString *string = [NSString stringWithFormat:@"http://overpass.osm.rambler.ru/cgi/xapi_meta?node[highway=emergency_access_point][bbox=%@]", boundingBoxString];
    NSURL *url = [NSURL URLWithString:string];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    // 2
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    // Make sure to set the responseSerializer correctly
    //    operation.responseSerializer = [AFXMLParserResponseSerializer serializer];

    [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        double progress = (double)totalBytesRead / (double)totalBytesExpectedToRead;
        dispatch_async(dispatch_get_main_queue(),^{
            MBProgressHUD *HUD = [MBProgressHUD HUDForView:self.view];
            HUD.mode = MBProgressHUDModeDeterminateHorizontalBar;
            HUD.labelText = [NSString stringWithFormat:@"SR %lld/%lld", totalBytesRead / 1024, totalBytesExpectedToRead / 1024];
            HUD.progress = (double) totalBytesRead / (double) totalBytesExpectedToRead;
        });
    }];


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


        id xPath = [document functionResultByEvaluatingXPath:@"count(//way)"];
        __block double resultCount = [xPath numericValue];
        __block double current = 0;

        NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docsDir = [dirPaths objectAtIndex:0];
        NSString *databasePath = [[NSString alloc] initWithString: [docsDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.xml",boundingBoxString]]];
        [data writeToFile:databasePath atomically:YES];
        
        NSString *xPathString = @"//way";
        [document enumerateElementsWithXPath:xPathString usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop) {
            //            NSLog(@"%@", element);
            current++;

            MBProgressHUD *HUD = [MBProgressHUD HUDForView:self.view];
            HUD.mode = MBProgressHUDModeDeterminateHorizontalBar;
            HUD.labelText = [NSString stringWithFormat:@"R %lld/%lld", current, resultCount];
            HUD.progress = (double)current / (double)resultCount;;

        
            __block PSTrack *track = [[PSTrack alloc] initWithXmlData:element document:document];
            dispatch_async(dispatch_get_main_queue(),^{

                [self setTracks: @[ track ]];
            });
        }];
        
        
        
        //        [self clearMap];
        
        
        //        [document enumerateElementsWithXPath:@"//Content" usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop) {
        //            NSLog(@"%@", element);
        //        }];
        
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
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


- (void)syncOsmPoisButtonTapped:(id)sender
{
    DLogFuncName();
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mapView removeAnnotations:self.mapView.annotations];
    });
    
    //    MBProgressHUD *HUD = [MBProgressHUD showHUDAddedTo:self.view animated:NO];
    //    HUD.mode = MBProgressHUDModeIndeterminate;
    
    //    UITapGestureRecognizer *HUDSingleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(singleTap:)];
    //    [HUD addGestureRecognizer:HUDSingleTap];
    
    NSArray * boundingBox = [self getBoundingBox:self.mapView.visibleMapRect];
    NSString *boundingBoxString = [NSString stringWithFormat:@"%.3f,%.3f,%.3f,%.3f", [[boundingBox objectAtIndex:1] floatValue], [[boundingBox objectAtIndex:0] floatValue], [[boundingBox objectAtIndex:3] floatValue], [[boundingBox objectAtIndex:2] floatValue]];
    
    
    [[PSPoiStore sharedInstance] loadPoisWithBoundingBox:boundingBoxString];
    
}


- (void)showMapSwitcherButtonTapped:(id)sender
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


#pragma mark - Tracks

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


- (void)setTrack:(PSTrack *)track
{
    DLogFuncName();
    _track = track;

    self.title = [track filename];

    [self addTrack:self.track];
    [self.mapView addAnnotations:[self.track distanceAnnotations]];
}


- (void) addTrack:(PSTrack*) track
{
    DLogFuncName();
    MKPolyline *route = [track route];
    [self.mapView addOverlay:route];

    if (track.color == [UIColor blueColor])
    {
        CLLocationCoordinate2D annocoord = MKCoordinateForMapPoint([track start]);
//    MKAnnotationView *startAnnotation = [[MKAnnotationView alloc]init];
//    startAnnotation.coordinate = annocoord;
//    startAnnotation.title = @"Start";
//    [self.mapView addAnnotation:startAnnotation];


        MKPointAnnotation *startAnnotation = [[MKPointAnnotation alloc] init];
        startAnnotation.coordinate = annocoord;
        startAnnotation.title = @"Start";
        [self.mapView addAnnotation:startAnnotation];
//
//
        CLLocationCoordinate2D finishAnnocoord = MKCoordinateForMapPoint([track finish]);
        MKPointAnnotation *finishAnnotation = [[MKPointAnnotation alloc] init];
        finishAnnotation.coordinate = finishAnnocoord;
        finishAnnotation.title = @"Finish";
        [self.mapView addAnnotation:finishAnnotation];
    }

    // MKCircle Skaliert mit :(
//    MKCircle *finishOverlay = [MKCircle circleWithCenterCoordinate:finishAnnocoord radius:150];
//    [self.mapView addOverlay:finishOverlay];

#ifdef USE_FLYOVER
    int padding = 30;
    [self.mapView setVisibleMapRect:[route boundingMapRect] edgePadding:UIEdgeInsetsMake(padding, padding, padding, padding) animated:YES];

//
    // Dieser Teil nur wenn Route zur Navigation geladen wird
    CLLocationCoordinate2D tmpLocation = MKCoordinateForMapPoint([track start]);

    CLLocationCoordinate2D ground = CLLocationCoordinate2DMake(tmpLocation.latitude, tmpLocation.longitude);
    CLLocationCoordinate2D eye = CLLocationCoordinate2DMake(tmpLocation.latitude, tmpLocation.longitude+.020);
    MKMapCamera *mapCamera = [MKMapCamera cameraLookingAtCenterCoordinate:ground
                                                        fromEyeCoordinate:eye
                                                              eyeAltitude:700];


    [UIView animateWithDuration:0.5
                          delay:1.1
                        options: UIViewAnimationOptionCurveEaseOut
                     animations:^
                     {
                         self.mapView.camera = mapCamera;
                     }
                     completion:^(BOOL finished)
                     {
                         [self flyover:0];
                     }];

    #endif
}



#pragma mark - Map
//- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
//{
//    DLogFuncName();
//    
//    // Sobald die Karte bewegt wird, wird auf UserTrackingMode None gewechselt ...
//    if (mapView.userTrackingMode != MKUserTrackingModeNone)
//    {
//        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 800, 800);
//        [self.mapView setRegion:[self.mapView regionThatFits:region] animated:YES];
//    }
//}

- (NSString *)deviceLocation {
    return [NSString stringWithFormat:@"latitude: %f longitude: %f", self.locationManager.location.coordinate.latitude, self.locationManager.location.coordinate.longitude];
}
- (NSString *)deviceLat {
    return [NSString stringWithFormat:@"%f", self.locationManager.location.coordinate.latitude];
}
- (NSString *)deviceLon {
    return [NSString stringWithFormat:@"%f", self.locationManager.location.coordinate.longitude];
}
- (NSString *)deviceAlt {
    return [NSString stringWithFormat:@"%f", self.locationManager.location.altitude];
}

#pragma mark - Tracking the User Location
- (void)mapViewWillStartLocatingUser:(MKMapView *)mapView
{
    DLogFuncName();
}


- (void)mapViewDidStopLocatingUser:(MKMapView *)mapView
{
    DLogFuncName();
}


- (void)mapView:(MKMapView *)mapView didFailToLocateUserWithError:(NSError *)error
{
    DLogFuncName();
    NSLog(@"LocationServicesEnabled => %d", [CLLocationManager locationServicesEnabled]);
    NSLog(@"AuthStatus => %d", [CLLocationManager authorizationStatus]);
    NSLog(@"didFailToLocateUserWithError => %@", [error localizedDescription]);

    dispatch_async(dispatch_get_main_queue(),^{
        NSString *message = [NSString stringWithFormat:@"didFailWithError:\n%@", [error localizedDescription]];
        [[[UIAlertView alloc] initWithTitle:@"MapView" message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil] show];
    });
    
#warning todo - show red userlocation icon
    if (![CLLocationManager locationServicesEnabled])
    {

    }
    else
    {
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted)
        {

        }
        else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied)
        {
            // The user explicitly denied the use of location services for this application or location services are currently disabled in Settings.

        }
        else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized)
        {

        }
        else
        {

        }
    }
}


#pragma mark - Selecting Annotation Views
- (void)mapView:(MKMapView *)mapView didChangeUserTrackingMode:(MKUserTrackingMode)mode animated:(BOOL)animated
{
    DLogFuncName();
    [self updateTrackingButtonTitleForCurrentUserTrackingMode];
}


- (void) poisUpdated
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mapView removeAnnotations:self.mapView.annotations];
        [self.mapView addAnnotations:[[PSPoiStore sharedInstance] poiList]];
    });

}


- (void) observeValueForKeyPath:(NSString *)keyPath
                       ofObject:(id)object
                         change:(NSDictionary *)change
                        context:(void *)context
{
    if ([keyPath isEqualToString:@"pois"])
    {
//        NSLog(@"Add Entries = %d",[[change objectForKey:@"new"] count]);

        dispatch_async(dispatch_get_main_queue(),^{
            [self.mapView removeAnnotations:self.mapView.annotations];
            [self.mapView addAnnotations:[change objectForKey:@"new"]];
        });
    }

//    NSLog(@"Entries = %d", [[[PSPoiStore sharedInstance] poiList] count]);
    dispatch_async(dispatch_get_main_queue(),^{
        [self.mapView addAnnotations:[[PSPoiStore sharedInstance] poiList]];
    });
}


- (void)singleTap:(id)singleTap
{
    DLogFuncName();
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    #warning todo - kill application
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

#define MERCATOR_RADIUS 85445659.44705395
#define MAX_GOOGLE_LEVELS 20
- (void) calculateMapArea
{
    CLLocationCoordinate2D bottomLeftCoord =
            [self.mapView convertPoint:CGPointMake(0, self.mapView.frame.size.height)
                  toCoordinateFromView:self.mapView];

    CLLocationCoordinate2D bottomRightCoord =
            [self.mapView convertPoint:CGPointMake(self.mapView.frame.size.width, self.mapView.frame.size.height)
                  toCoordinateFromView:self.mapView];


    CLLocation * bottomLeftLocation = [[CLLocation alloc]
            initWithLatitude:bottomLeftCoord.latitude
                   longitude:bottomLeftCoord.longitude];
    CLLocation * bottomRightLocation = [[CLLocation alloc]
            initWithLatitude:bottomRightCoord.latitude
                   longitude:bottomRightCoord.longitude];

    CLLocationDistance hdistanceInMeters = [bottomLeftLocation distanceFromLocation:bottomRightLocation];



    CLLocationCoordinate2D upperLeftCoor =
            [self.mapView convertPoint:CGPointMake(0, 0)
                  toCoordinateFromView:self.mapView];


    CLLocation * upperLeftLocation = [[CLLocation alloc]
            initWithLatitude:upperLeftCoor.latitude
                   longitude:upperLeftCoor.longitude];

    CLLocationDistance vdistanceInMeters = [upperLeftLocation distanceFromLocation:bottomLeftLocation];

    CGFloat verticalDistanceInKm = vdistanceInMeters / 1000;
    NSLog(@"vDistance in Meters= %.2f", verticalDistanceInKm);
    CGFloat horizontalDistanceInKm = hdistanceInMeters / 1000;
    
    NSLog(@"hdistanceInMeters in Meters= %.2f", horizontalDistanceInKm);
    CGFloat area = (verticalDistanceInKm*horizontalDistanceInKm);
    NSLog(@"Square in KMeters= %.2f", area);

    self.distannceLabelWidth.text = [NSString stringWithFormat:@"%.2f km", horizontalDistanceInKm];
    self.distannceLabelHeight.text = [NSString stringWithFormat:@"%.2f km", verticalDistanceInKm];
    self.areaLabel.text = [NSString stringWithFormat:@"%.2f QKM",area];
}


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
//    NSLog(@"BoudningBox = %@", boundingBoxString);
    self.debugLabel.text = [NSString stringWithFormat:@"lat: %f long: %f z: %f", self.mapView.region.span.latitudeDelta, self.mapView.region.span.longitudeDelta, [self getZoomLevel]];
//    NSLog(@"http://api.openstreetmap.org/api/0.6/map?bbox=%@",boundingBoxString);
//    NSLog(@"http://overpass.osm.rambler.ru/cgi/xapi_meta?*[bbox=%@]",boundingBoxString);
}


- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    DLogFuncName();
    [self calculateMapArea];

    NSArray * boundingBox = [self getBoundingBox:self.mapView.visibleMapRect];
    NSString *boundingBoxString = [NSString stringWithFormat:@"%.3f,%.3f,%.3f,%.3f", [[boundingBox objectAtIndex:1] floatValue], [[boundingBox objectAtIndex:0] floatValue], [[boundingBox objectAtIndex:3] floatValue], [[boundingBox objectAtIndex:2] floatValue]];
    self.boundingLabel.text = boundingBoxString;
//    NSLog(@"BoudningBox = %@", boundingBoxString);
    self.debugLabel.text = [NSString stringWithFormat:@"lat: %f long: %f z: %f", self.mapView.region.span.latitudeDelta, self.mapView.region.span.longitudeDelta, [self getZoomLevel]];

//    NSLog(@"http://api.openstreetmap.org/api/0.6/map?bbox=%@",boundingBoxString);
//    NSLog(@"http://overpass.osm.rambler.ru/cgi/xapi_meta?*[bbox=%@]",boundingBoxString);
//    overpass-api.de/api/map?bbox=6.8508,49.1958,7.2302,49.2976

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
//            NSLog(@"ZoomRect = %@", NSStringFromCGRect(cgr));
            [self.mapView setVisibleMapRect:zoomRect animated:YES];
        }
    }
    [self.mapView setVisibleMapRect:zoomRect animated:YES];
}


#pragma mark - Custom

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


#pragma mark - Map Overlays
//-(MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay
//{
//    MKPolygonView *pv = [[MKPolygonView alloc] initWithPolygon:overlay];
//    
//    if ([overlay.title isEqualToString:@"one"])
//        pv.fillColor = [UIColor redColor];
//    else if ([overlay.title isEqualToString:@"other"])
//        pv.fillColor = [UIColor yellowColor];
//    else
//        pv.fillColor = [UIColor blueColor];
//    
//    return pv;
//}


//- (MKOverlayView *)mapView:(MKMapView *)map viewForOverlay:(id <MKOverlay>)overlay
//{
////    NSLog(@"overlay %@",overlay);
//
//    if ([[overlay title] isEqualToString:@"circle1"]){
//
//        MKCircleView *circleView = [[MKCircleView alloc] initWithOverlay:overlay];
//        //circleView.strokeColor = [UIColor redColor];
//        circleView.fillColor = [[UIColor redColor] colorWithAlphaComponent:0.3];
//
//        return circleView;
//    }
//    return nil;
//}


//-(MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay
//    if (overlay == )
//    if(overlay == self.routeLine)
//    {
//        if(nil == self.routeLineView)
//        {
//            self.routeLineView = [[MKPolylineView alloc] initWithPolyline:self.routeLine];
//            self.routeLineView.fillColor = [UIColor redColor];
//            self.routeLineView.strokeColor = [UIColor redColor];
//            self.routeLineView.lineWidth = 5;
//
//        }
//
//        return self.routeLineView;
//    }
//
//    return [self.track overlayView];
//    return nil;
//}


- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id <MKOverlay>)overlay
{
    DLogFuncName();

    if ([overlay isKindOfClass:[MKCircle class]] || [overlay isKindOfClass:[MKCircleView class]])
    {
        // MKCircle Skaliert mit :(
        MKCircleRenderer * renderer = [[MKCircleRenderer alloc] initWithOverlay:overlay];
        renderer.alpha = 0.5;
        renderer.fillColor = [UIColor blackColor];
        return renderer;
    }


    if ([overlay isKindOfClass:[MKTileOverlay class]]) {
        return [[MKTileOverlayRenderer alloc] initWithTileOverlay:overlay];
    }

    if (![overlay isKindOfClass:[MKPolyline class]]) {
//        NSLog(@"ERROR ERROR ERROR");
        return nil;
    }

    if ([overlay isKindOfClass:[PSTrackOverlay class]])
    {
        PSTrackOverlay *trackOverlay = overlay;

        PSTrack *track = ((PSTrackOverlay*)overlay).track;
        MKPolyline *polyLine = (MKPolyline*)overlay;
//        NSLog(@"Overlay = %@",polyLine);

        PSTrackRenderer *renderer = [[PSTrackRenderer alloc] initWithPolyline:polyLine];
        renderer.lineWidth = trackOverlay.lineWidth;
        renderer.strokeColor = trackOverlay.color;
        renderer.alpha = trackOverlay.alpha;
        renderer.lineDashPattern = trackOverlay.lineDashPattern;

//        MKCircle *circle = [MKCircle circleWithCenterCoordinate:[track coordinates][0] radius:5.0];
//        [circle setTitle:@"circle1"];
//        [mapView addOverlay:circle];
       
        return renderer;
    }
    else
    {
        CGFloat hue = ( arc4random() % 256 / 256.0 );  //  0.0 to 1.0
        CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from white
        CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from black
        UIColor *color = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];

        MKPolyline *polyLine = (MKPolyline*)overlay;
//        NSLog(@"Overlay = %@",polyLine);

        MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:polyLine];
        renderer.strokeColor = color;
        renderer.lineDashPattern = @[@2, @5];
        renderer.lineWidth = 1.0;
        renderer.alpha = 0.5;

        return renderer;
    }


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


#pragma mark - Map Annotations


- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay
{
    if ([overlay isKindOfClass:[MKCircle class]]) {
        MKCircleView *circleView = [[MKCircleView alloc] initWithCircle:(MKCircle*)overlay];
        circleView.fillColor = [[UIColor greenColor] colorWithAlphaComponent:0.2];
        circleView.strokeColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
        circleView.lineWidth = 2;
        return circleView;
        }
    return nil;
}


- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    DLogFuncName();
   //    static NSString *annotaionIdentifier=@"annotationIdentifier";
//    MKPinAnnotationView *annotationView=(MKPinAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:annotaionIdentifier ];
//    if (annotationView==nil) {
//        annotationView = [[MKPinAnnotationView alloc] init];
//        
//    }

    CGFloat labelSize = 15.0;

    if (annotation == mapView.userLocation)
    {
        return nil;
    }



    if ([annotation isKindOfClass:[PSDistanceAnnotation class]])
    {
        MKAnnotationView *annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@""];
        annotationView.canShowCallout = NO;
        
        CGRect frame = CGRectZero;
        frame.size = CGSizeMake(20.0,20.0);
        
        UILabel *label = [[UILabel alloc] initWithFrame:annotationView.frame];
        label.frame = frame;
        label.textAlignment = NSTextAlignmentCenter;
        label.text = annotation.title;
        label.backgroundColor = [UIColor yellowColor];
        label.adjustsFontSizeToFitWidth = YES;
        label.font = [UIFont systemFontOfSize:10.0];
        label.clipsToBounds = YES;
        label.textColor = [UIColor blackColor];
        label.layer.cornerRadius = frame.size.width/2;
        
//        label.center = CGPointMake(label.center.x, label.center.y + 5);
        [annotationView addSubview:label];
        return annotationView;
    }
    

    if ([annotation isKindOfClass:[PSPoi class]])
    {

        MKAnnotationView *annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@""];
        annotationView.canShowCallout = YES;
        
        CGRect frame = CGRectZero;
        frame.size = CGSizeMake(12.0,12.0);

        UIImageView *imageView = [((PSPoi*)annotation) imageView];
    //
    //    UILabel *label = [[UILabel alloc] initWithFrame:annotationView.frame];
    //    label.frame = frame;
    //    label.textAlignment = NSTextAlignmentCenter;
    //    label.text = annotation.title;
    //    label.backgroundColor = [UIColor yellowColor];
    //    label.adjustsFontSizeToFitWidth = YES;
    //    label.font = [UIFont systemFontOfSize:10.0];
    //    label.clipsToBounds = YES;
    //    label.textColor = [UIColor whiteColor];
    //    label.layer.cornerRadius = frame.size.width/2;

        // Centriere das Label in der Annotation
        imageView.frame = CGRectMake(0,0,10,10);
        imageView.center = annotationView.center;
    //    label.center = CGPointMake(label.center.x, label.center.y + 5);

        [annotationView addSubview:imageView];
        return annotationView;
    }

    if ([annotation isKindOfClass:[MKPointAnnotation class]])
    {
        MKPointAnnotation *pointAnnotation = (MKPointAnnotation *)annotation;
        if ([pointAnnotation.title isEqualToString:@"Finish"])
        {
            // IMAGE ...
//            MKAnnotationView *annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@""];
//            annotationView.canShowCallout = YES;
//
//            CGRect frame = CGRectZero;
//            frame.size = CGSizeMake(12.0,12.0);
//
//            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"1435537202_54"]];
//            imageView.frame = CGRectMake(0,0,30,30);
//            imageView.center = annotationView.center;
//
//            [annotationView addSubview:imageView];
//            return annotationView;

            MKAnnotationView *annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@""];
            CGRect frame = CGRectZero;
            frame.size = CGSizeMake(labelSize,labelSize);

            UILabel *label = [[UILabel alloc] initWithFrame:annotationView.frame];
            label.frame = frame;
            label.textAlignment = NSTextAlignmentCenter;
            label.text = @"F";
            label.backgroundColor = [UIColor whiteColor];
            label.adjustsFontSizeToFitWidth = YES;
            label.font = [UIFont systemFontOfSize:10.0];
            label.clipsToBounds = YES;
            label.textColor = [UIColor blackColor];
            label.layer.cornerRadius = frame.size.width/2;
            label.alpha = 0.8;
            label.layer.borderColor = [[UIColor blackColor] CGColor];
            label.layer.borderWidth = 1.0;
            [annotationView addSubview:label];
            return annotationView;
        }
        else if ([pointAnnotation.title isEqualToString:@"Start"])
        {
//            MKAnnotationView *annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@""];
//            annotationView.canShowCallout = YES;

            MKAnnotationView *annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@""];
            CGRect frame = CGRectZero;
            frame.size = CGSizeMake(labelSize,labelSize);

            UILabel *label = [[UILabel alloc] initWithFrame:annotationView.frame];
            label.frame = frame;
            label.textAlignment = NSTextAlignmentCenter;
            label.text = @"S";
            label.backgroundColor = [UIColor blackColor];
            label.adjustsFontSizeToFitWidth = YES;
            label.font = [UIFont systemFontOfSize:10.0];
            label.clipsToBounds = YES;
            label.textColor = [UIColor whiteColor];
            label.layer.cornerRadius = frame.size.width/2;
            label.alpha = 0.8;
            label.center = annotationView.center;
            label.layer.borderColor = [[UIColor whiteColor] CGColor];
            label.layer.borderWidth = 1.0;
            [annotationView addSubview:label];
            return annotationView;
        }
    }
//    else
//    {
//        annotationView=(MKPinAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:annotaionIdentifier ];
//        annotationView.pinColor = [UIColor blueColor];
//    }

    return nil;
}


#pragma mark - ViewControler
- (NSUInteger)supportedInterfaceOrientations
{
    DLogFuncName();
    return UIInterfaceOrientationMaskAll;
}


#pragma mark - Location Manager Delegate
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    NSLog(@"didUpdateLocations: %@", [locations lastObject]);
    
}


- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
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


- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Location manager error: %@", error.localizedDescription);

    dispatch_async(dispatch_get_main_queue(),^{
        NSString *message = [NSString stringWithFormat:@"didFailWithError:\n%@", [error localizedDescription]];
        [[[UIAlertView alloc] initWithTitle:@"LocationManager" message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil] show];
    });
}


- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusAuthorizedAlways)
    {
        [self switchUserTracking];
    }
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse)
    {
        [self switchUserTracking];

    }
    else if (status == kCLAuthorizationStatusDenied)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Location services not authorized"
                                                        message:@"This app needs you to authorize locations services to work."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    else
    {
        NSLog(@"Wrong location status");
    }
}

@end
