//
// Created by Philip Schneider on 28.12.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PSMapViewController;


@interface PSMapLocationManager : NSObject <CLLocationManagerDelegate>
- (instancetype)initWithMapViewController:(PSMapViewController *)mapViewController;

- (void)update;
@end