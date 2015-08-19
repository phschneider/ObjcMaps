//
// Created by Philip Schneider on 19.08.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import "PSMapBoxTileOverlay.h"


@implementation PSMapBoxTileOverlay

+ (NSString *)mapId
{
    return @"mapbox.streets";
}


+ (NSString *)urlTemplate
{
    NSString *accessToken = @"pk.eyJ1IjoicGhzY2huZWlkZXIiLCJhIjoiajRrY3hyUSJ9.iUqFM9KNijSRZoI-cHkyLw";
    NSString *format = @".png";
    NSString *urlString = [NSString stringWithFormat:@"https://api.mapbox.com/v4/%@/{z}/{x}/{y}%@?access_token=%@", [self mapId], format, accessToken];

    NSLog(@"URL = %@",urlString);
    return urlString;
}


- (NSString*)name
{
    return @"mapBoxDefault";
}

@end
