//
//  PSLocationManager.m
//
//  Created by Philip Schneider on 07.11.14.
//
//

#import "PSLocationManager.h"

@implementation PSLocationManager

+ (instancetype)sharedInstance
{
    static id sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once (&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}


- (id)init
{
    self = [super init];
    if (self) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
    }
    return self;
}


#pragma mark - Start/Stop
// Zugriff von Extern mit Datenschutzabfrage falls noch nicht erlaubt
- (void) willStartUpdatingQuite
{
    if ( [self canShowUserLocation])
    {
        [self startUpdating];
    }
    else if (![self hasAlreadyAskedForAuthorisation])
    {
        [self askForAuthorisation];
    }
}


// Zugriff von Extern mit allen AlertViews
- (void) willStartUpdating
{
    if ( [self canShowUserLocation])
    {
        [self startUpdating];
    }
    else
    {
        if (![self locationServicesEnabled])
        {
            [self showLocationServicesDeactivatedAlertView];
        }
        else if (![self hasAlreadyAskedForAuthorisation])
        {
            [self askForAuthorisation];
        }
        else if (![self locationServicesAuthorized])
        {
            [self showLocationServicesNotAuthorizedAlertView];
        }
        else
        {
            [self showLocationServicesDeniedAlertView];
        }
    }
}


- (void) startUpdating
{
    if ([self canShowUserLocation])
    {
        [self.locationManager startUpdatingLocation];
    }
    else
    {
        [self.locationManager stopUpdatingLocation];
    }
}


- (void) stopUpdating
{
    if (self.locationManager)
    [self.locationManager stopUpdatingLocation];
}


#pragma mark - Delegate
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    if ([locations count])
    {
        self.userLocation = [locations objectAtIndex:0];;
    }
    else
    {
        self.userLocation = nil;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_LOCATIONMANGER_DID_UPDATE_USERLOCATION object:nil];
}


- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if ([self canShowUserLocation])
    {
        [self startUpdating];
    }
    else
    {
        [self stopUpdating];
    }
}


- (void)locationManager: (CLLocationManager *)manager
       didFailWithError: (NSError *)error {

    NSString *errorString;
    [manager stopUpdatingLocation];
    NSLog(@"Error: %@ Code: %d",[error localizedDescription], [error code]);
    switch([error code]) {
        case kCLErrorDenied:
            //Access denied by user
            errorString = @"Zugriff auf Ortungsdienste vom Benutzer gesperrt. Bitte Ortungsdienste aktivieren/für App freigeben.";
            //Do something...
            break;
        case kCLErrorLocationUnknown:
            //Probably temporary...
            errorString = @"GPS Daten nicht verfügbar.";
            //Do something else...
            break;
        default:
            errorString = @"Ein unbekannter Fehler ist aufgetreten.";
            break;
    }

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Fehler" message:errorString delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    [alert show];
}


// Auth - Handshake ist durch
// wenn möglich, zeige userlocation an
- (BOOL) canShowUserLocation
{
    BOOL canShow = ([self locationServicesEnabled] && [self hasAlreadyAskedForAuthorisation] && [self locationServicesAuthorized]);
    NSLog(@"canShow = %d", canShow);
    return canShow;
}


#pragma mark - Helper
- (BOOL)hasAlreadyAskedForAuthorisation
{
    BOOL asked = [[NSUserDefaults standardUserDefaults] boolForKey:USERDEFAULTS_HAS_ASKED_FOR_CLLOCATION_AUTHORISATION];
    NSLog(@"asked = %d", asked);
    return asked;
}


- (void) setHasAskedForAuthorisation
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:USERDEFAULTS_HAS_ASKED_FOR_CLLOCATION_AUTHORISATION];
    [[NSUserDefaults standardUserDefaults] synchronize];
}



- (void)askForAuthorisation
{
    BOOL isIos7 = [[[UITabBar alloc] init] respondsToSelector:@selector(barTintColor)];
    BOOL isIos8 = [[NSStream class] respondsToSelector:@selector(getBoundStreamsWithBufferSize:inputStream:outputStream:)];
    
    if (isIos7 && !isIos8)
    {
        // Zugriff auf die Location startet unter iOS7 die Authorisierungsanfrage (Falls noch nicht zuvor geschehen)
        [self.locationManager startUpdatingLocation];
        [self.locationManager stopUpdatingLocation];
    }
    else
    {
        NSAssert([[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationWhenInUseUsageDescription"], @"no NSLocationWhenInUseUsageDescription provided");
        [self.locationManager requestWhenInUseAuthorization];
    }
    
    [self setHasAskedForAuthorisation];
}



- (BOOL)locationServicesAuthorized
{
    BOOL isIos7 = [[[UITabBar alloc] init] respondsToSelector:@selector(barTintColor)];
    BOOL isIos8 = [[NSStream class] respondsToSelector:@selector(getBoundStreamsWithBufferSize:inputStream:outputStream:)];
    
    BOOL authorized = ([CLLocationManager authorizationStatus] == ((isIos7 && !isIos8) ? kCLAuthorizationStatusAuthorized : kCLAuthorizationStatusAuthorizedWhenInUse));
    NSLog(@"LocationServices Authorized = %d", authorized);
    return authorized;
}


- (BOOL)locationServicesEnabled
{
    BOOL enabled = [CLLocationManager locationServicesEnabled];
    NSLog(@"LocationServices Enabled = %d", enabled);
    return enabled;
}



#pragma mark - Alerts
- (void)showLocationServicesDeniedAlertView
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Location denied", nil)
                                                    message:NSLocalizedString(@"error_message_nolocation", nil)
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                          otherButtonTitles:nil];
    [alert show];
}


- (void)showLocationServicesDeactivatedAlertView
{
    UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"location_services_deactivated", nil)
                                                         message:NSLocalizedString(@"location_services_deactivated_description", nil)
                                                        delegate:nil
                                               cancelButtonTitle:NSLocalizedString(@"dialog_ok", nil)
                                               otherButtonTitles: nil];
    [alertView show];
}


- (void)showLocationServicesNotAuthorizedAlertView
{
    UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"location_services_notauthorized", nil)
                                                         message:NSLocalizedString(@"location_services_notauthorized_description", nil)
                                                        delegate:nil
                                               cancelButtonTitle:NSLocalizedString(@"dialog_ok", nil)
                                               otherButtonTitles:nil];
    [alertView show];
}


@end
