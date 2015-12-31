//
// Created by Philip Schneider on 10.05.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <MapKit/MapKit.h>
#import <Foundation/Foundation.h>
#import "PSMapViewController.h"
#import "PSTrack.h"
#import "WYPopoverController.h"
#import "PSSettingsViewController.h"
#import "PSMapLocationManager.h"
#import "PSTileOverlay.h"
#import "AFHTTPRequestOperation.h"
#import "Ono.h"
#import "MBProgressHUD.h"
#import "PSTrackOverlay.h"
#import "PSTrackRenderer.h"
#import "PSPoiStore.h"
#import "PSPoi.h"
#import "PSDistanceAnnotation.h"
#import "MKMapView+PSZoomLevel.h"
#import "MKMapView+PSTilesInMapRect.h"
#import "PSTileOverlayRender.h"
#import "PSWayPointAnnotation.h"
#import "PSTrackStore.h"
#import "PSDirectionAnnotation.h"
#import "PSTrackViewController.h"


@interface PSMapViewController ()
@property (nonatomic) MKMapView *mapView;
@property (nonatomic) PSTrack *track;
@property (nonatomic) WYPopoverController *settingsPopoverController;
@property (nonatomic) UILabel *debugLabel;
@property (nonatomic) UILabel *boundingLabel;
@property (nonatomic) UILabel *areaLabel;
@property (nonatomic) UILabel *timeTillHomeLabel;
@property (nonatomic) UILabel *distannceLabelWidth;
@property (nonatomic) UILabel *distannceLabelHeight;
@property (nonatomic) UIButton *locationButton;
@property (nonatomic) UIView *debugView;
@property (nonatomic) MKZoomScale psZoomScale;
@property (nonatomic) CLLocationDegrees olddlat;
@property(nonatomic) PSMapLocationManager *mapLocationManager;
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
        
#ifndef INSELHUEPFEN_MODE
        frame.origin.y = 44 + 20;
        frame.size.height -= frame.origin.y;
#else
        [[PSTrackStore sharedInstance] addObserver:self forKeyPath:@"tracks" options:NSKeyValueObservingOptionNew context:nil];
#endif
        
        self.mapView = [[MKMapView alloc] initWithFrame:frame];
        self.mapView.autoresizingMask =  self.view.autoresizingMask;
        self.mapView.delegate = self;
        self.mapView.showsUserLocation = NO;
        if ([self.mapView respondsToSelector:@selector(showsScale:)])
        {
            self.mapView.showsScale = YES;
        }
        [self.view addSubview:self.mapView];

#ifdef SHOW_DEBUG_LABELS_ON_MAP
        [self addDebugLabels];
#endif

        [self addLabels];
#ifdef SHOW_BUTTONS_ON_MAP
        [self addButtons];
#endif
        UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureRecognizerFired:)];
        [self.mapView addGestureRecognizer:longPressGestureRecognizer];

        
        // Add Gesture Recognizer to MapView to detect taps
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        
        // we require all gesture recognizer except other single-tap gesture recognizers to fail
        for (UIGestureRecognizer *gesture in self.mapView.gestureRecognizers) {
            if ([gesture isKindOfClass:[UITapGestureRecognizer class]]) {
                UITapGestureRecognizer *systemTap = (UITapGestureRecognizer *)gesture;
                
                if (systemTap.numberOfTapsRequired > 1) {
                    [tap requireGestureRecognizerToFail:systemTap];
                }
            } else {
                [tap requireGestureRecognizerToFail:gesture];
            }
        }
        
        [self.mapView addGestureRecognizer:tap];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tileClassChanged) name:@"USERDEFAULTS_SETTINGS_TILECLASS_CHANGED" object:nil];
#ifdef INSELHUEPFEN_MODE
        for (NSArray *coordArray in @[  @[@43.515,@16.2488], //Trogir
                                        @[@43.3288, @16.4403],
                                        @[@43.2605, @16.6551], // Bol
                                        @[@43.1617 ,@16.6942], //Jelsa
                                        @[@42.974, @17.0196],
                                        @[@43.1039, @17.341], // Gradac
                                        @[@42.9671, @16.8112],
                                        @[@43.378, @16.6274], // Postira
                                        @[ @43.39712, @16.300932], // Solta
                                        @[ @43.184034, @16.591802], // Stari Grad
                                        @[@43.3707, @16.3529],
                                        @[@43.5041, @16.4424] // Split
        ])
        {
            CLLocationCoordinate2D ctrpoint;
            ctrpoint.latitude = [coordArray[0] floatValue];
            ctrpoint.longitude = [coordArray[1] floatValue];;
            MKPointAnnotation *addAnnotation = [[MKPointAnnotation alloc] init];
            addAnnotation.coordinate = ctrpoint;
            [self.mapView addAnnotation:addAnnotation];
        }
#endif
        self.mapLocationManager = [[PSMapLocationManager alloc] initWithMapViewController:self];
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


#pragma mark - View
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
    [self tileClassChanged];

//    NSString *template = @"http://b.tiles.wmflabs.org/hikebike/{z}/{x}/{y}.png";
//
//    NSString *accessToken = @"pk.eyJ1IjoicGhzY2huZWlkZXIiLCJhIjoiajRrY3hyUSJ9.iUqFM9KNijSRZoI-cHkyLw";
//    NSString *format = @".png";
////    NSString *mapId = @"mapbox.high-contrast";
////        NSString *mapId = @"mapbox.light";
////        NSString *mapId = @"mapbox.pencil";
//            NSString *mapId = @"mapbox.run-bike-hike";
//    NSString *urlString = [NSString stringWithFormat:@"https://api.mapbox.com/v4/%@/{z}/{x}/{y}%@?access_token=%@",mapId,format, accessToken];
//
//
//    PSTileOverlay *overlay = [[PSTileOverlay alloc] initWithURLTemplate:urlString];
//    overlay.canReplaceMapContent = NO;
//    [self.mapView addOverlay:overlay level:MKOverlayLevelAboveRoads];
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

    // Darf nicht ausgeführt werden da die Karte ansonsten wieder umpositioniert wird :(
//    [self zoomToOverlays];

    // Disable iOS 7 back gesture
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
        self.navigationController.interactivePopGestureRecognizer.delegate = self;
    }
}


- (void)viewWillDisappear:(BOOL)animated
{
    DLogFuncName();
    [super viewWillDisappear:animated];
    
    // Enable iOS 7 back gesture
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
        self.navigationController.interactivePopGestureRecognizer.delegate = nil;
    }
}


#pragma mark - View Addons
- (void) addDebugLabels
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


- (void) addLabels
{
    DLogFuncName();

    CGRect frame = self.view.bounds;
    frame.origin.y = 44 + 20;
    frame.size.height -= frame.origin.y ;

    self.timeTillHomeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, frame.size.height-20, frame.size.width, 20)];
    self.timeTillHomeLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    self.timeTillHomeLabel.textAlignment = NSTextAlignmentCenter;
    self.timeTillHomeLabel.backgroundColor = [UIColor clearColor];
    self.timeTillHomeLabel.shadowColor = [UIColor whiteColor];
    self.timeTillHomeLabel.layer.shadowOffset = CGSizeMake(0, 1);
    self.timeTillHomeLabel.layer.shadowRadius = 1;
    self.timeTillHomeLabel.font = [UIFont systemFontOfSize:10];
    self.timeTillHomeLabel.textColor = [UIColor blackColor];

    [self.mapView addSubview:self.timeTillHomeLabel];
}


- (void) addButtons
{
    DLogFuncName();
    CGRect frame = self.view.bounds;
    frame.origin.y = 44 + 20;
    frame.size.height -= frame.origin.y;

    UIImage *layersImage = [UIImage imageNamed:@"1064-layers-4"];
    UIButton *layersButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    frame.origin.y = 15;
    frame.origin.x = self.mapView.frame.size.width - 48 - 15;
    frame.size.width = 48; // layersImage.size.width;
    frame.size.height =  48; // layersImage.size.height;

    layersButton.frame = frame;
    [layersButton setBackgroundColor: [UIColor colorWithWhite:1 alpha:0.75]];
    [layersButton setImage:layersImage forState:UIControlStateNormal];
    layersButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [layersButton addTarget:self action:@selector(showMapSwitcherButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.mapView addSubview:layersButton];


    UIImage *syncImage = [UIImage imageNamed:@"gray-1061-golf-shot"];
    UIButton *syncButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    frame.origin.y = layersButton.frame.origin.y;
    frame.origin.x = 15;
    frame.size.width = 48; //syncImage.size.width;
    frame.size.height =  48; //syncImage.size.height;

    syncButton.frame = frame;
    [syncButton setBackgroundColor: [UIColor colorWithWhite:1 alpha:0.75]];
    [syncButton setImage:syncImage forState:UIControlStateNormal];
    [syncButton addTarget:self action:@selector(syncOsmMapButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.mapView addSubview:syncButton];

    UIImage *syncPoisImage = [UIImage imageNamed:@"gray-940-pin"];
    UIButton *syncPoisButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    frame.origin.y = layersButton.frame.origin.y;
    frame.origin.x = syncButton.frame.origin.x + syncButton.frame.size.width + 15;
    frame.size.width = 48; //syncImage.size.width;
    frame.size.height =  48; //syncImage.size.height;

    syncPoisButton.frame = frame;
    [syncPoisButton setBackgroundColor: [UIColor colorWithWhite:1 alpha:0.75]];
    [syncPoisButton setImage:syncPoisImage forState:UIControlStateNormal];
    [syncPoisButton addTarget:self action:@selector(syncOsmPoisButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.mapView addSubview:syncPoisButton];

    self.locationButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.locationButton.backgroundColor = [UIColor whiteColor];
    frame.origin.y = self.mapView.frame.size.height - 50 - 15;
    frame.size.width = self.mapView.frame.size.width - 100;
    frame.origin.x = ceil((self.mapView.frame.size.width - frame.size.width)/2);
    frame.size.height =  50;
    [self.locationButton setTitle:@"Track" forState:UIControlStateNormal];
    self.locationButton.frame = frame;
    self.locationButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [self.locationButton addTarget:self action:@selector(locationButtonTapped) forControlEvents:UIControlEventTouchUpInside];

    [self.mapView addSubview:self.locationButton];
}


#pragma mark - Gestures
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    DLogFuncName();
    return YES;
    return NO;
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


#pragma mark - Buttons
- (void)locationButtonTapped
{
    DLogFuncName();
    [self.mapLocationManager update];
}


- (void)debugMapTiles
{
    DLogFuncName();
//    double numTilesAt1_0 = MKMapSizeWorld.width / TILE_SIZE;
//    MKZoomScale currentZoomScale = self.mapView.bounds.size.width / self.mapView.visibleMapRect.size.width;
//

//    NSLog(@"Map Titles: \n %@", [self.mapView tilesInMapRect:self.mapView.visibleMapRect zoomScale:self.psZoomScale]);
//
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


// TODO: Lager mich aus
- (void)syncOsmMapButtonTapped:(id)sender
{
    DLogFuncName();

    MBProgressHUD *HUD = [MBProgressHUD showHUDAddedTo:self.view animated:NO];
    
    UITapGestureRecognizer *HUDSingleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(singleTap:)];
    [HUD addGestureRecognizer:HUDSingleTap];
    
    NSArray * boundingBox = [self getBoundingBox:self.mapView.visibleMapRect];
    NSString *boundingBoxString = [NSString stringWithFormat:@"%.3f,%.3f,%.3f,%.3f", [[boundingBox objectAtIndex:1] floatValue], [[boundingBox objectAtIndex:0] floatValue], [[boundingBox objectAtIndex:3] floatValue], [[boundingBox objectAtIndex:2] floatValue]];
    
    
//    NSString *string = [NSString stringWithFormat:@"http://overpass.osm.rambler.ru/cgi/xapi_meta?way[highway=path][bbox=%@]", boundingBoxString];
    NSString *string = [NSString stringWithFormat:@"http://overpass.osm.rambler.ru/cgi/xapi_meta?way[mtb:scale=*][bbox=%@]", boundingBoxString];
    //    NSString *string = [NSString stringWithFormat:@"http://overpass.osm.rambler.ru/cgi/xapi_meta?node[highway=emergency_access_point][bbox=%@]", boundingBoxString];
    NSURL *url = [NSURL URLWithString:string];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    // Make sure to set the responseSerializer correctly
    //    operation.responseSerializer = [AFXMLParserResponseSerializer serializer];

    [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        if (totalBytesExpectedToRead == -1)
        {
            dispatch_async(dispatch_get_main_queue(),^{
                MBProgressHUD *HUD = [MBProgressHUD HUDForView:self.view];
                HUD.mode = MBProgressHUDModeIndeterminate;
                HUD.labelText = [NSString stringWithFormat:@"%lld", totalBytesRead];
            });
        }
        else
        {
            if (totalBytesExpectedToRead == totalBytesRead)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    MBProgressHUD *HUD = [MBProgressHUD HUDForView:self.view];
                    [HUD hide:NO];
                });
            }
            else
            {
                double progress = (double)totalBytesRead / (double)totalBytesExpectedToRead;
                dispatch_async(dispatch_get_main_queue(),^{
                    MBProgressHUD *HUD = [MBProgressHUD HUDForView:self.view];
                    HUD.mode = MBProgressHUDModeDeterminateHorizontalBar;
                    HUD.labelText = [NSString stringWithFormat:@"%lld/%lld", totalBytesRead / 1024, totalBytesExpectedToRead / 1024];
                    HUD.progress = progress;
                });
            }
        }
    }];


    // TODO
    // https://github.com/AFNetworking/AFOnoResponseSerializer
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSData *data = responseObject;
        NSError *error;
        
        ONOXMLDocument *document = [ONOXMLDocument XMLDocumentWithData:data error:&error];
        id xPath = [document functionResultByEvaluatingXPath:@"count(//way)"];
        __block int resultCount = [xPath numericValue];
        __block int current = 0;

        dispatch_async(dispatch_get_main_queue(),^{
            MBProgressHUD *HUD = [MBProgressHUD showHUDAddedTo:self.view animated:NO];
            UITapGestureRecognizer *HUDSingleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector  (singleTap:)];
            [HUD addGestureRecognizer:HUDSingleTap];
            HUD.mode = MBProgressHUDModeDeterminateHorizontalBar;
            HUD.labelText = [NSString stringWithFormat:@"verarbeite %d von %d", 0, resultCount];
            HUD.progress = 0.0 / (double)resultCount;
        });
        
        
        NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docsDir = [dirPaths objectAtIndex:0];
        NSString *databasePath = [[NSString alloc] initWithString: [docsDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.xml",boundingBoxString]]];
        [data writeToFile:databasePath atomically:YES];
        
        NSString *xPathString = @"//way";
        
        __block NSMutableArray *trackArray = [[NSMutableArray alloc] init];
        [document enumerateElementsWithXPath:xPathString usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
                ++current;
//                NSLog(@"Track y%d",current);
                PSTrack *track = [[PSTrack alloc] initWithXmlData:element document:document];
                [trackArray addObject:track];
                
                dispatch_sync(dispatch_get_main_queue(), ^{
//                    NSLog(@"HUD = %d", current);
                    MBProgressHUD *HUD = [MBProgressHUD HUDForView:self.view];
                    HUD.labelText = [NSString stringWithFormat:@"verarbeite %d von %d", current, resultCount];
                    HUD.progress = (double)current / (double)resultCount;
                });
                
                
                if ([trackArray count] == resultCount)
                {
                    dispatch_async(dispatch_get_main_queue(),^{
//                        NSLog(@"DONE ...");
                        
                        NSMutableArray *oldArray = [[NSMutableArray alloc] initWithArray:self.tracks];
                        [oldArray addObjectsFromArray:[trackArray copy]];
                        [self setTracks: oldArray];
                        [trackArray removeAllObjects];
                        
                        MBProgressHUD *HUD = [MBProgressHUD HUDForView:self.view];
                        [HUD hide:NO];
                    });
                }
            });
        }];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error Retrieving OSM Data ..."
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


#pragma mark - Notifications
- (void) tileClassChanged
{
    NSString *tileClassString = [[NSUserDefaults standardUserDefaults] objectForKey:@"TILE_CLASS"];
//    NSLog(@"TileClass = %@", tileClassString);

    if (!tileClassString)
    {
        tileClassString = @"PSTileOverlay";
    }


    if ([tileClassString isEqualToString:@"PSAppleSatelliteTileOverlay"])
    {
        self.mapView.mapType = MKMapTypeSatellite;
    }
    else if ([tileClassString isEqualToString:@"PSAppleHybridTileOverlay"])
    {
        self.mapView.mapType = MKMapTypeHybrid;
    }
    else if ([tileClassString isEqualToString:@"PSAppleDefaultTileOverlay"])
    {
        self.mapView.mapType = MKMapTypeStandard;
    }
    else
    {
        self.mapView.mapType = MKMapTypeStandard;
    }

    Class tileClass = NSClassFromString(tileClassString);
    id object = [[tileClass alloc] init];
    PSTileOverlay *overlay = nil;
    if (object)
    {
        NSString *urlTemplate = [tileClass urlTemplate];
//        NSLog(@"URL Template = %@", urlTemplate);
        overlay = [(PSTileOverlay *) [tileClass alloc] initWithURLTemplate:urlTemplate];
    }
    else
    {
        NSLog(@"No object");
    }

    if ([overlay level] == MKOverlayLevelAboveLabels)
    {
        [self removeAllOverlays];
    }
    else
    {
        [self removeAllTileOverlays];
    }


    if (overlay)
    {
        [self.mapView addOverlay:overlay level:[overlay level]];
    }

    if ([overlay level] == MKOverlayLevelAboveLabels)
    {
        if (self.track)
        {
//            NSLog(@"Readding track");
            [self addTrack:self.track];
        }
        else if (self.tracks)
        {
//            NSLog(@"Readding tracks");
            for (PSTrack *track in self.tracks)
            {
                [self addTrack:track];
            }
        }
    }
}


#pragma mark - Tracks

- (void)setTracks:(NSArray *)tracks
{
    DLogFuncName();
    _tracks = tracks;

    [self clearMap];
    
    if (self.track)
    {
        [self setTrack:self.track];
    }
    
    for (PSTrack *track in tracks)
    {
        [self addTrack:track];
    }

    [self zoomToOverlays];
}


- (void)setTrack:(PSTrack *)track
{
    DLogFuncName();
    _track = track;

    self.title = [track filename];

    [self.mapView addAnnotations:[self.track distanceAnnotations]];
    [self.mapView addAnnotations:[self.track wayPoints]];
    [self.mapView addAnnotations:[self.track directionAnnotations]];
    [self addTrack:self.track];
    
    [self zoomToPolyLine:self.mapView polyline:[track route] animated:YES];
}


- (void) addTrack:(PSTrack*) track
{
    DLogFuncName();
    MKPolyline *route = [track route];
    [self.mapView addOverlay:route];

    if (track.trackType == PSTrackTypeOsm)
    {
        NSArray *directionAnnotations = [track directionAnnotations];
        if ([directionAnnotations count] > 3)
        {
             [self.mapView addAnnotations:@[ [directionAnnotations firstObject] , [directionAnnotations lastObject] ]];
        }
        else  if ([directionAnnotations count] > 0)
        {
             [self.mapView addAnnotations:@[ [directionAnnotations firstObject]] ];
        }
    }
    else if (track.trackType != PSTrackTypeOsm)
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



- (void) setRegion
{
    DLogFuncName();
    //View Area
    MKCoordinateRegion region = { { 0.0, 0.0 }, { 0.0, 0.0 } };
//    region.center.latitude = self.mapLocationManager.location.coordinate.latitude;
//    region.center.longitude = self.locationManager.location.coordinate.longitude;
    region.span.longitudeDelta = 0.005f;
    region.span.longitudeDelta = 0.005f;
    [self.mapView setRegion:region animated:YES];
}


#pragma mark - 
/** Returns the distance of |pt| to |poly| in meters
 *
 * from http://paulbourke.net/geometry/pointlineplane/DistancePoint.java
 *
 */
- (double)distanceOfPoint:(MKMapPoint)pt toPoly:(MKPolyline *)poly
{
    double distance = MAXFLOAT;
    for (int n = 0; n < poly.pointCount - 1; n++) {
        
        MKMapPoint ptA = poly.points[n];
        MKMapPoint ptB = poly.points[n + 1];
        
        double xDelta = ptB.x - ptA.x;
        double yDelta = ptB.y - ptA.y;
        
        if (xDelta == 0.0 && yDelta == 0.0) {
            
            // Points must not be equal
            continue;
        }
        
        double u = ((pt.x - ptA.x) * xDelta + (pt.y - ptA.y) * yDelta) / (xDelta * xDelta + yDelta * yDelta);
        MKMapPoint ptClosest;
        if (u < 0.0) {
            
            ptClosest = ptA;
        }
        else if (u > 1.0) {
            
            ptClosest = ptB;
        }
        else {
            
            ptClosest = MKMapPointMake(ptA.x + u * xDelta, ptA.y + u * yDelta);
        }
        
        distance = MIN(distance, MKMetersBetweenMapPoints(ptClosest, pt));
    }
    
    return distance;
}


/** Converts |px| to meters at location |pt| */
- (double)metersFromPixel:(NSUInteger)px atPoint:(CGPoint)pt
{
    CGPoint ptB = CGPointMake(pt.x + px, pt.y);
    
    CLLocationCoordinate2D coordA = [self.mapView convertPoint:pt toCoordinateFromView:self.mapView];
    CLLocationCoordinate2D coordB = [self.mapView convertPoint:ptB toCoordinateFromView:self.mapView];
    
    return MKMetersBetweenMapPoints(MKMapPointForCoordinate(coordA), MKMapPointForCoordinate(coordB));
}


#define MAX_DISTANCE_PX 22.0f
- (void)handleTap:(UITapGestureRecognizer *)tap
{
    if ((tap.state & UIGestureRecognizerStateRecognized) == UIGestureRecognizerStateRecognized) {
        
        // Get map coordinate from touch point
        CGPoint touchPt = [tap locationInView:self.mapView];
        CLLocationCoordinate2D coord = [self.mapView convertPoint:touchPt toCoordinateFromView:self.mapView];
        
        double maxMeters = [self metersFromPixel:MAX_DISTANCE_PX atPoint:touchPt];
        
        float nearestDistance = MAXFLOAT;
        MKPolyline *nearestPoly = nil;
        
        // for every overlay ...
        for (id <MKOverlay> overlay in self.mapView.overlays) {
            
            // .. if MKPolyline ...
            if ([overlay isKindOfClass:[MKPolyline class]]) {
                
                // ... get the distance ...
                float distance = [self distanceOfPoint:MKMapPointForCoordinate(coord)
                                                toPoly:overlay];
                
                // ... and find the nearest one
                if (distance < nearestDistance) {
                    
                    nearestDistance = distance;
                    nearestPoly = overlay;
                }
            }
        }
        
        if (nearestDistance <= maxMeters) {
            if ([nearestPoly isKindOfClass:[PSTrackOverlay class]])
            {
                PSTrackOverlay *trackOverlay = nearestPoly;
                PSTrackViewController *trackViewController = [[PSTrackViewController alloc] initWithTrack:trackOverlay.track];
                [self.navigationController pushViewController:trackViewController animated:YES];
            }
            NSLog(@"Touched poly: %@\n"
                  "    distance: %f", nearestPoly, nearestDistance);
        }
    }
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


//- (void)viewWillLayoutSubviews
//{
//    DLogFuncName();
//    [super viewWillLayoutSubviews];
//}


- (void)viewWillLayoutSubviews
{
    DLogFuncName();
    [super viewWillLayoutSubviews];

    CGRect windowFrame = [[[UIApplication sharedApplication] keyWindow] frame];
    CGRect frame = self.view.frame;
    frame.size.width = windowFrame.size.width;
    frame.size.height = windowFrame.size.height;
    self.view.frame =  frame;


}


- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    DLogFuncName();
    CLLocation *location = userLocation.location;

    CLLocationSpeed speed = location.speed;
    CLLocationDistance altitude = location.altitude;
    CLLocationAccuracy horizontalAccuracy = location.horizontalAccuracy;
    CLLocationAccuracy verticalAccuracy = location.verticalAccuracy;

    CLLocationDistance distance = [location distanceFromLocation:HOME_LOCATION];
    CGFloat distanceInKm = (distance / 1000);
    CGFloat timeInHours = (distance/DEFAULT_SPEED_IN_KM);

    NSString *timeString = @"";
    if (timeInHours < 1.0)
    {
        timeString = [NSString stringWithFormat:@"%.2fm",(timeInHours * 60)];
    }
    else
    {
        timeString = [NSString stringWithFormat:@"%.2fh",timeInHours];
    }

    self.timeTillHomeLabel.text = [NSString stringWithFormat:@"%.2f %.2fm | %.2fkm = %@ | %.2fh %.2fv", speed, altitude, distanceInKm, timeString, horizontalAccuracy, verticalAccuracy];
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
    DLogFuncName();
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
    DLogFuncName();
    if ([keyPath isEqualToString:@"pois"])
    {
//        NSLog(@"Add Entries = %d",[[change objectForKey:@"new"] count]);

        dispatch_async(dispatch_get_main_queue(),^{
            [self.mapView removeAnnotations:self.mapView.annotations];
            [self.mapView addAnnotations:[change objectForKey:@"new"]];
        });
    }

    if ([keyPath isEqualToString:@"tracks"])
    {
        dispatch_async(dispatch_get_main_queue(),^{
            NSMutableArray *array = [NSMutableArray arrayWithArray:[[self tracks] copy]];
            if ([[change objectForKey:@"new"] isKindOfClass:[NSArray class]])
            {
                [array addObjectsFromArray:[change objectForKey:@"new"]];
            }
            else
            {
                [array addObject:[change objectForKey:@"new"]];
            }
            [self setTracks:array];
        });
    }

//    NSLog(@"Entries = %d", [[[PSPoiStore sharedInstance] poiList] count]);
    dispatch_async(dispatch_get_main_queue(),^{
        [self.mapView addAnnotations:[[PSPoiStore sharedInstance] poiList]];
    });
}


#ifdef INSELHUEPFEN_MODE
-(BOOL)prefersStatusBarHidden{
    return YES;
}
#endif


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
    DLogFuncName();
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
//    NSLog(@"vDistance in Meters= %.2f", verticalDistanceInKm);
    CGFloat horizontalDistanceInKm = hdistanceInMeters / 1000;
    
//    NSLog(@"hdistanceInMeters in Meters= %.2f", horizontalDistanceInKm);
    CGFloat area = (verticalDistanceInKm*horizontalDistanceInKm);
//    NSLog(@"Square in KMeters= %.2f", area);

    int size = 0;
    self.distannceLabelWidth.text = [NSString stringWithFormat:@"%.2f km (Size: %f)", horizontalDistanceInKm, size];
    self.distannceLabelHeight.text = [NSString stringWithFormat:@"%.2f km (Zoom: %f)", verticalDistanceInKm, [self.mapView zoomLevel]];
    self.areaLabel.text = [NSString stringWithFormat:@"%.2f QKM",area];
}


- (double)getZoomLevel
{
    DLogFuncName();
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

    MKZoomScale currentZoomScale = self.mapView.bounds.size.width / self.mapView.visibleMapRect.size.width;
//    NSLog(@"CurrentZoomScale = %f | PSZoomScale = %f", currentZoomScale, self.psZoomScale);

    NSArray * boundingBox = [self getBoundingBox:self.mapView.visibleMapRect];
    NSString *boundingBoxString = [NSString stringWithFormat:@"%.3f,%.3f,%.3f,%.3f", [[boundingBox objectAtIndex:1] floatValue], [[boundingBox objectAtIndex:0] floatValue], [[boundingBox objectAtIndex:3] floatValue], [[boundingBox objectAtIndex:2] floatValue]];
    self.boundingLabel.text = boundingBoxString;
//    NSLog(@"BoudningBox = %@", boundingBoxString);
    self.debugLabel.text = [NSString stringWithFormat:@"lat: %f long: %f z: %f", self.mapView.region.span.latitudeDelta, self.mapView.region.span.longitudeDelta, [self getZoomLevel]];

//    NSLog(@"http://api.openstreetmap.org/api/0.6/map?bbox=%@",boundingBoxString);
//    NSLog(@"http://overpass.osm.rambler.ru/cgi/xapi_meta?*[bbox=%@]",boundingBoxString);
//    overpass-api.de/api/map?bbox=6.8508,49.1958,7.2302,49.2976
}


// Um um alle Overlays zu zentrieren
- (void)zoomToOverlays
{
    DLogFuncName();
    
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

            double minMapHeight = 480; //choose some value that fit your needs
            double minMapWidth = 320;  //the same as above
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
//            [self.mapView setVisibleMapRect:zoomRect animated:YES];
        }
    }

//    NSLog(@"ZoomRect = %@", NSStringFromCGRect(cgr));
    [self.mapView setVisibleMapRect:zoomRect edgePadding:UIEdgeInsetsMake(20.0, 20.0, 20.0, 20.0) animated:YES];
}


// Um um einen Track zu zentrieren...
-(void)zoomToPolyLine: (MKMapView*)map polyline: (MKPolyline*)polyline animated: (BOOL)animated
{
    DLogFuncName();
    [map setVisibleMapRect:[polyline boundingMapRect] edgePadding:UIEdgeInsetsMake(50.0, 50.0, 50.0, 50.0) animated:animated];
}


#pragma mark - Custom
- (void) clearMap
{
    DLogFuncName();

    [self removeAllPolylines];
    [self removeAllAnnotations];
}


- (void)removeAllPointAnnotations
{
    DLogFuncName();
    if ([self.mapView.annotations count])
    {
        NSArray *annotations = [[self.mapView annotations] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self isKindOfClass: %@", [MKPointAnnotation class]]];
        if ([annotations count])
        {
            [self.mapView removeAnnotations:annotations];
        }
    }
}


- (void)removeAllAnnotations
{
    DLogFuncName();
    if ([self.mapView.annotations count])
    {
        NSArray *annotations = [self.mapView annotations];
        if ([annotations count])
        {
            [self.mapView removeAnnotations:annotations];
        }
    }
}


- (void)removeAllPolylines
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


- (void)removeAllTileOverlays
{
    DLogFuncName();
    if ([self.mapView.overlays count])
    {
        NSArray *overlays = [[self.mapView overlays] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self isKindOfClass: %@", [MKTileOverlay class]]];
        if ([overlays count])
        {
            [self.mapView removeOverlays:overlays];
        }
    }
}


- (void)removeAllOverlays
{
    DLogFuncName();
    if ([self.mapView.overlays count])
    {
        NSArray *overlays = self.mapView.overlays;
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
-(CLLocationCoordinate2D)getNECoordinate:(MKMapRect)mRect
{
    DLogFuncName();
    return [self getCoordinateFromMapRectanglePoint:MKMapRectGetMaxX(mRect) y:mRect.origin.y];
}


-(CLLocationCoordinate2D)getNWCoordinate:(MKMapRect)mRect
{
    DLogFuncName();
    return [self getCoordinateFromMapRectanglePoint:MKMapRectGetMinX(mRect) y:mRect.origin.y];
}


-(CLLocationCoordinate2D)getSECoordinate:(MKMapRect)mRect
{
    DLogFuncName();
    return [self getCoordinateFromMapRectanglePoint:MKMapRectGetMaxX(mRect) y:MKMapRectGetMaxY(mRect)];
}


-(CLLocationCoordinate2D)getSWCoordinate:(MKMapRect)mRect
{
    DLogFuncName();
    return [self getCoordinateFromMapRectanglePoint:mRect.origin.x y:MKMapRectGetMaxY(mRect)];
}


// http://www.softwarepassion.com/how-to-get-geographic-coordinates-of-the-visible-mkmapview-area-in-ios/
-(CLLocationCoordinate2D)getCoordinateFromMapRectanglePoint:(double)x y:(double)y
{
    DLogFuncName();
    MKMapPoint swMapPoint = MKMapPointMake(x, y);
    return MKCoordinateForMapPoint(swMapPoint);
}


-(NSArray *)getBoundingBox:(MKMapRect)mRect
{
    DLogFuncName();
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
        NSLog(@"Circle Overlay");
        // MKCircle Skaliert mit :(
        MKCircleRenderer * renderer = [[MKCircleRenderer alloc] initWithOverlay:overlay];
        renderer.alpha = 0.5;
        renderer.fillColor = [UIColor blackColor];
        return renderer;
    }


    if ([overlay isKindOfClass:[MKTileOverlay class]])
    {
        NSLog(@"TileOverlay");
        PSTileOverlayRender *render =  [[PSTileOverlayRender alloc] initWithTileOverlay:overlay];
        return render;
    }

    if (![overlay isKindOfClass:[MKPolyline class]]) {
//        NSLog(@"ERROR ERROR ERROR");
        return nil;
    }

    if ([overlay isKindOfClass:[PSTrackOverlay class]])
    {
//        NSLog(@"TrackOverlay");

        PSTrackOverlay *trackOverlay = overlay;

        PSTrack *track = ((PSTrackOverlay*)overlay).track;
        MKPolyline *polyLine = (MKPolyline*)overlay;

        PSTrackRenderer *renderer = [[PSTrackRenderer alloc] initWithPolyline:polyLine];
        renderer.lineWidth = trackOverlay.lineWidth;
        renderer.strokeColor = trackOverlay.color;
        renderer.alpha = trackOverlay.alpha;
        renderer.lineDashPattern = trackOverlay.lineDashPattern;
//
//        MKCircle *circle = [MKCircle circleWithCenterCoordinate:[track coordinates][0] radius:5.0];
//        [circle setTitle:@"circle1"];
//        [mapView addOverlay:circle];
       
        return renderer;
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(),^{
            [[[UIAlertView alloc] initWithTitle:@"rendererForOverlay" message:@"not defined" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
        });

//        NSLog(@"PolyLine Overlay");

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
    DLogFuncName();
    if ([overlay isKindOfClass:[MKCircle class]])
    {
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
//        NSLog(@"view For Distance Annotation");
        static NSString *reuseIdentifier = @"DISTANCE";
        MKAnnotationView *annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
        annotationView.canShowCallout = NO;
        
        CGRect frame = CGRectZero;
        frame.size = CGSizeMake(labelSize,labelSize);
        
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
        label.layer.borderColor = [[UIColor blackColor] CGColor];
        label.layer.borderWidth = 1.0;
        label.center = annotationView.center;
        [annotationView addSubview:label];
        return annotationView;
    }


    if ([annotation isKindOfClass:[PSWayPointAnnotation class]])
    {
//        NSLog(@"view For WayPoint Annotation");

        static NSString *reuseIdentifier = @"WAYPOINT";
        MKAnnotationView *annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
        annotationView.canShowCallout = NO;

        CGRect frame = CGRectZero;
        frame.size = CGSizeMake(10,10);

        UILabel *label = [[UILabel alloc] initWithFrame:annotationView.frame];
        label.frame = frame;
        label.textAlignment = NSTextAlignmentCenter;
        label.text = annotation.title;
        label.backgroundColor = [UIColor whiteColor];
        label.adjustsFontSizeToFitWidth = YES;
        label.font = [UIFont systemFontOfSize:5.0];
        label.clipsToBounds = YES;
        label.textColor = [UIColor blackColor];
        label.layer.cornerRadius = frame.size.width/2;
        label.center = annotationView.center;
        [annotationView addSubview:label];
        return annotationView;
    }


    if ([annotation isKindOfClass:[PSDirectionAnnotation class]])
    {
//        NSLog(@"view For Distance Annotation");
        static NSString *reuseIdentifier = @"DIRECTION";
        PSDirectionAnnotation *directionAnnotation = annotation;
        MKAnnotationView *annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
        annotationView.canShowCallout = NO;
        annotationView.image = [UIImage imageNamed:@"white-193-location-arrow"];


        CGAffineTransform transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(directionAnnotation.degrees));
        annotationView.transform = transform;

        return annotationView;;
    }
    

    if ([annotation isKindOfClass:[PSPoi class]])
    {
//        NSLog(@"view For POI Annotation");

        static NSString *reuseIdentifier = @"POI";
        MKAnnotationView *annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
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
//        NSLog(@"view For MKPoint Annotation");

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
            static NSString *reuseIdentifier = @"FINISH";
            MKAnnotationView *annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
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
            label.center = annotationView.center;
            [annotationView addSubview:label];
            return annotationView;
        }
        else if ([pointAnnotation.title isEqualToString:@"Start"])
        {
//            MKAnnotationView *annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@""];
//            annotationView.canShowCallout = YES;
            static NSString *reuseIdentifier = @"START";
            MKAnnotationView *annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
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
            label.center = annotationView.center;
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

@end
