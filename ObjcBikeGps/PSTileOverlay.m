//
// Created by Philip Schneider on 16.05.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import "PSTileOverlay.h"

@interface PSTileOverlay ()
@property NSCache *cache;
@property NSOperationQueue *operationQueue;
@end

@implementation PSTileOverlay

- (instancetype)initWithURLTemplate:(NSString *)URLTemplate
{
    self = [super initWithURLTemplate:URLTemplate];
    if (self)
    {
        self.cache = [[NSCache alloc] init];
        self.operationQueue = [[NSOperationQueue alloc] init];
    }

    return self;
}


- (NSURL *)URLForTilePath:(MKTileOverlayPath)path {
    return [NSURL URLWithString:[NSString stringWithFormat:@"http://b.tiles.wmflabs.org/hikebike/%ld/%ld/%ld.png", path.z, path.x, path.y]];
}


- (void)loadTileAtPath:(MKTileOverlayPath)path
                result:(void (^)(NSData *data, NSError *error))result
{
    if (!result) {
//        NSLog(@"No result");
        return;
    }

    NSData *cachedData = [self.cache objectForKey:[self URLForTilePath:path]];
    if (cachedData) {
//        NSLog(@"cached data");
        result(cachedData, nil);
    } else {
    
//        NSLog(@"Request Data for path");
        NSURLRequest *request = [NSURLRequest requestWithURL:[self URLForTilePath:path]];
        [NSURLConnection sendAsynchronousRequest:request queue:self.operationQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
//            NSLog(@"Set data for path");

//            NSLog(@"Data = %@", data);
            
            if (data)
            {
                [self.cache setObject:data forKey:[self URLForTilePath:path]];
            }
            result(data, connectionError);
        }];
    }
}

@end
