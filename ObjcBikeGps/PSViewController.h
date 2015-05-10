//
//  PSViewController.h
//  ObjcBikeGps
//
//  Created by Philip Schneider on 02.10.14.
//  Copyright (c) 2014 phschneider.net. All rights reserved.
//

#import <UIKit/UIKit.h>


@class MKMapView;
@class RMMapView;
@class PSGraphViewController;


@interface PSViewController : UIViewController <MKMapViewDelegate, CLLocationManagerDelegate>

@end
