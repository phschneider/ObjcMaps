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

+ (NSString *)urlTemplate
{
    return nil;
}


- (MKOverlayLevel) level
{
    return MKOverlayLevelAboveLabels;
}


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
    return nil;
}



- (NSString*)name
{
    return @"default";
}


- (NSString*)storageForPath:(MKTileOverlayPath)path
{
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    NSString *databasePath = [[NSString alloc] initWithString: [docsDir stringByAppendingPathComponent:[NSString stringWithFormat:@"/tiles/%@/%ld/%ld/%ld.png", [self name], path.z, path.x, path.y]]];
    return databasePath;
}


- (void)loadTileAtPath:(MKTileOverlayPath)path
                result:(void (^)(NSData *data, NSError *error))result
{
    if (!result) {
//        NSLog(@"No result");
        return;
    }

    //    // Tile Overlays
//    CGSize sz = self.tileSize;
//    CGRect rect = CGRectMake(0, 0, sz.width, sz.height);
//    UIGraphicsBeginImageContext(sz);
//    CGContextRef ctx = UIGraphicsGetCurrentContext();
//    [[UIColor blackColor] setStroke];
//    CGContextSetLineWidth(ctx, 1.0);
//    CGContextStrokeRect(ctx, CGRectMake(0, 0, sz.width, sz.height));
//    NSString *text = [NSString stringWithFormat:@"X=%d\nY=%d\nZ=%d",path.x,path.y,path.z];
//    [text drawInRect:rect withAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:20.0],
//            NSForegroundColorAttributeName:[UIColor blackColor]}];
//    UIImage *tileImage = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    NSData *tileData = UIImagePNGRepresentation(tileImage);
//    result(tileData,nil);
//    return

    NSData *cachedData = nil; // [self.cache objectForKey:[self URLForTilePath:path]];
    if (cachedData)
    {
        result(cachedData, nil);
    }
    else
    {

        NSData *storedData = nil; //[NSData dataWithContentsOfFile:databasePath];
        if (storedData)
        {
            // Cache für die Laufzeit der App
            [self.cache setObject:storedData forKey:[self URLForTilePath:path]];
            result(storedData, nil);
        }
        else
        {
            NSURL *url = [super URLForTilePath:path];
            NSURLRequest *request = [NSURLRequest requestWithURL:url];
            [NSURLConnection sendAsynchronousRequest:request queue:self.operationQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                if (data)
                {
                    [self.cache setObject:data forKey:[self URLForTilePath:path]];
                    [[NSFileManager defaultManager] createDirectoryAtPath:[[self storageForPath:path] stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
                    [data writeToFile:[self storageForPath:path] atomically:YES];
                }
                result(data, connectionError);
            }];
        }
    }
}

@end
