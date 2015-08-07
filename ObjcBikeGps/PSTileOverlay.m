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
    NSString *urlString = [NSString stringWithFormat:@"http://b.tiles.wmflabs.org/hikebike/%ld/%ld/%ld.png", path.z, path.x, path.y];
//    NSLog(@"URL = %@",urlString);
    return [NSURL URLWithString:urlString];
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

    NSData *cachedData = [self.cache objectForKey:[self URLForTilePath:path]];
    if (cachedData)
    {
        result(cachedData, nil);
    }
    else
    {
        NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docsDir = [dirPaths objectAtIndex:0];
        NSString *databasePath = [[NSString alloc] initWithString: [docsDir stringByAppendingPathComponent:[NSString stringWithFormat:@"/tiles/hikebike/%ld/%ld/%ld.png", path.z, path.x, path.y]]];
        NSData *storedData = [NSData dataWithContentsOfFile:databasePath];
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
                    [[NSFileManager defaultManager] createDirectoryAtPath:[databasePath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
                    [data writeToFile:databasePath atomically:YES];
                }
                result(data, connectionError);
            }];
        }
    }
}

@end
