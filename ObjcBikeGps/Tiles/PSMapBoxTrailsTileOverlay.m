//
//  PSMapBoxTrailsTileOverlay.m
//  ObjcBikeGps
//
//  Created by Philip Schneider on 18.02.16.
//  Copyright © 2016 phschneider.net. All rights reserved.
//

#import "PSMapBoxTrailsTileOverlay.h"

@implementation PSMapBoxTrailsTileOverlay

+ (NSString *)mapId
{
    return @"phschneider-style-two.e41d7c02";
}


- (NSString*)name
{
    return @"mapBoxTrail";
}


+ (NSString *)accessToken
{
    return @"pk.eyJ1IjoicGhzY2huZWlkZXIiLCJhIjoiajRrY3hyUSJ9.iUqFM9KNijSRZoI-cHkyLw";
}


- (void)loadTileAtPath:(MKTileOverlayPath)path result:(void (^)(NSData *data, NSError *error))result
{
    DLogFuncName();
    if (!result) {
        //        NSLog(@"No result");
        return;
    }
    
    NSData *cachedData = (0) ? [self.cache objectForKey:[self URLForTilePath:path]] : nil;
    if (cachedData)
    {
        result(cachedData, nil);
    }
    else
    {
        NSData *storedData = (0) ? [NSData dataWithContentsOfFile:[self storageForPath:path]] : nil;
        if (storedData)
        {
            // Cache für die Laufzeit der App
            if (USE_CACHE)
            {
                [self.cache setObject:storedData forKey:[self URLForTilePath:path]];
            }
            result(storedData, nil);
        }
        else
        {
            NSURL *url = [self URLForTilePath:path];
        
            NSURLRequest *request = [NSURLRequest requestWithURL:url];
            [NSURLConnection sendAsynchronousRequest:request queue:self.operationQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                if (connectionError)
                {
                    NSLog(@"Error = %@", connectionError);
                }
                if (data)
                {
                    if (0)
                    {
                        [self.cache setObject:data forKey:[self URLForTilePath:path]];
                    }
                    
                    if (0)
                    {
                        [[NSFileManager defaultManager] createDirectoryAtPath:[[self storageForPath:path] stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
                        [data writeToFile:[self storageForPath:path] atomically:YES];
                    }
                }
                result(data, connectionError);
            }];
        }
    }
}


@end
