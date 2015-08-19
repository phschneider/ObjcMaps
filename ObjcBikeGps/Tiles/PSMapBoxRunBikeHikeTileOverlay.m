//
// Created by Philip Schneider on 19.08.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import "PSMapBoxRunBikeHikeTileOverlay.h"


@implementation PSMapBoxRunBikeHikeTileOverlay


+ (NSString *)mapId
{
    return @"mapbox.run-bike-hike";
}

//
//+ (NSString*) urlTemplate
//{
//    NSString *accessToken = @"pk.eyJ1IjoicGhzY2huZWlkZXIiLCJhIjoiajRrY3hyUSJ9.iUqFM9KNijSRZoI-cHkyLw";
//    NSString *format = @".png";
//    NSString *mapId = @"mapbox.run-bike-hike";
////    NSString *urlString = [NSString stringWithFormat:@"https://api.mapbox.com/v4/%@/%ld/%ld/%ld%@?access_token=%@",mapId,path.z,path.x, path.y,format, accessToken];
//
////    NSLog(@"URL = %@",urlString);
//    return @"";
////    return urlString;
//}

//- (instancetype)init
//{
//    self = [super initWithURLTemplate:[PSTileOverlay urlTemplate]];
//    if (self)
//    {
//
//    }
//
//    return self;
//}
//
//
//- (NSURL *)URLForTilePath:(MKTileOverlayPath)path
//{
//    return [NSURL URLWithString:[[self class] urlTemplate]];
//}
//


- (NSString*)name
{
    return @"mapBoxRunBikeHike";
}

@end
