//
// Created by Philip Schneider on 19.08.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import "PSMapBoxHighContrastTileOverlay.h"


@implementation PSMapBoxHighContrastTileOverlay


- (BOOL)canReplaceMapContent
{
    return YES;
}


+ (NSString *)mapId
{
    return @"mapbox.high-contrast";
}


//+ (NSString *)urlTemplate
//{
//    NSString *accessToken = @"pk.eyJ1IjoicGhzY2huZWlkZXIiLCJhIjoiajRrY3hyUSJ9.iUqFM9KNijSRZoI-cHkyLw";
//    NSString *format = @".png";
//    NSString *mapId = @"mapbox.high-contrast";
//    NSString *urlString = [NSString stringWithFormat:@"https://api.mapbox.com/v4/%@/%ld/%ld/%ld%@?access_token=%@",mapId,format, accessToken];
//
//    NSLog(@"URL = %@",urlString);
//    return [NSURL URLWithString:urlString];
////    NSString *mapId = @"mapbox.high-contrast";
////        NSString *mapId = @"mapbox.light";
////        NSString *mapId = @"mapbox.pencil";
//    NSString *mapId = @"mapbox.run-bike-hike";
//    NSString *urlString = [NSString stringWithFormat:@"https://api.mapbox.com/v4/%@/{z}/{x}/{y}%@?access_token=%@",mapId,format, accessToken];
//}



//- (NSURL *)URLForTilePath:(MKTileOverlayPath)path {
//    NSString *accessToken = @"pk.eyJ1IjoicGhzY2huZWlkZXIiLCJhIjoiajRrY3hyUSJ9.iUqFM9KNijSRZoI-cHkyLw";
//    NSString *format = @".png";
//    NSString *mapId = @"mapbox.high-contrast";
//    NSString *urlString = [NSString stringWithFormat:@"https://api.mapbox.com/v4/%@/%ld/%ld/%ld%@?access_token=%@",mapId,path.z,path.x, path.y,format, accessToken];
//
//    NSLog(@"URL = %@",urlString);
//    return [NSURL URLWithString:urlString];
//}

- (NSString*)name
{
    return @"mapBoxHighContrast";
}


@end
