//
//  PSLocationManager.h
//
//  Created by Philip Schneider on 07.11.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#define USERDEFAULTS_HAS_ASKED_FOR_CLLOCATION_AUTHORISATION     @"USERDEFAULTS_HAS_ASKED_FOR_CLLOCATION_AUTHORISATION"
#define NOTIFICATION_LOCATIONMANGER_DID_UPDATE_USERLOCATION     @"NOTIFICATION_LOCATIONMANGER_DID_UPDATE_USERLOCATION"

@interface PSLocationManager : NSObject <CLLocationManagerDelegate>

@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) CLLocation *userLocation;

+ (instancetype)sharedInstance;

- (void)willStartUpdatingQuite;
- (void)willStartUpdating;
- (void)startUpdating;
- (void)stopUpdating;
- (BOOL)canShowUserLocation;
@end
