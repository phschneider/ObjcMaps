//
// Created by Philip Schneider on 28.12.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import "PSMapLocationManager.h"
#import "PSMapViewController.h"


@interface PSMapLocationManager ()
@property(nonatomic, weak) PSMapViewController *mapViewController;
@property (nonatomic) CLLocationManager *locationManager;
@end

@implementation PSMapLocationManager


- (instancetype)init {
    DLogFuncName();
    self = [super init];
    if (self)
    {

    }
    return self;
}


- (instancetype)initWithMapViewController:(PSMapViewController*)mapViewController
{
    DLogFuncName();
    self = [self init];
    if (self)
    {
        self.mapViewController = mapViewController;
    }
    return self;
}


#pragma mark - Location Manager Delegate
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    DLogFuncName();
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
    DLogFuncName();
    NSLog(@"Location manager error: %@", error.localizedDescription);

    dispatch_async(dispatch_get_main_queue(),^{
        NSString *message = [NSString stringWithFormat:@"didFailWithError:\n%@", [error localizedDescription]];
        [[[UIAlertView alloc] initWithTitle:@"LocationManager" message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil] show];
    });
}


- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    DLogFuncName();
    if (status == kCLAuthorizationStatusAuthorizedAlways)
    {
        [self.mapViewController switchUserTracking];
    }
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse)
    {
        [self.mapViewController switchUserTracking];

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


- (NSString *)deviceLocation
{
    DLogFuncName();
    return [NSString stringWithFormat:@"latitude: %f longitude: %f", self.locationManager.location.coordinate.latitude, self.locationManager.location.coordinate.longitude];
}


- (NSString *)deviceLat
{
    DLogFuncName();
    return [NSString stringWithFormat:@"%f", self.locationManager.location.coordinate.latitude];
}


- (NSString *)deviceLon
{
    DLogFuncName();
    return [NSString stringWithFormat:@"%f", self.locationManager.location.coordinate.longitude];
}


- (NSString *)deviceAlt {
    DLogFuncName();
    return [NSString stringWithFormat:@"%f", self.locationManager.location.altitude];
}


- (void)update
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
        [self.mapViewController switchUserTracking];
    }
}
@end