//
// Created by Philip Schneider on 16.05.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PSTileOverlay.h"
#import "MKMapView+PSZoomLevel.h"

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
    return MKOverlayLevelAboveRoads;
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


- (NSString*)mainFolder
{
    DLogFuncName();

    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];

    NSString *databasePath = [[NSString alloc] initWithString:[docsDir stringByAppendingPathComponent:[NSString stringWithFormat:@"/tiles/%@", [self name]]]];
    return databasePath;
}


- (NSString*)storageForPath:(MKTileOverlayPath)path
{
    DLogFuncName();

    return [self storageForZ:path.z x:path.x y:path.y];
}


- (NSString*)storageForZ:(NSInteger)z x:(NSInteger)x y:(NSInteger)y
{
    DLogFuncName();
    return [NSString stringWithFormat:@"%@/%ld/%ld/%ld.png", [self mainFolder], z, x, y];
}


- (void)loadTileAtPath:(MKTileOverlayPath)path result:(void (^)(NSData *data, NSError *error))result
{
    DLogFuncName();
    if (!result) {
//        NSLog(@"No result");
        return;
    }

    NSData *cachedData = (USE_CACHE) ? [self.cache objectForKey:[self URLForTilePath:path]] : nil;
    if (cachedData)
    {
        result(cachedData, nil);
    }
    else
    {
        NSData *storedData = (USE_LOCAL_STORAGE) ? [NSData dataWithContentsOfFile:[self storageForPath:path]] : nil;
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
            NSURL *url = [super URLForTilePath:path];
            NSURLRequest *request = [NSURLRequest requestWithURL:url];
            [NSURLConnection sendAsynchronousRequest:request queue:self.operationQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                if (data)
                {
                    if (USE_CACHE)
                    {
                        [self.cache setObject:data forKey:[self URLForTilePath:path]];
                    }

                    if (USE_LOCAL_STORAGE)
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


- (NSDictionary *)tilesInMapRect:(MKMapRect)rect forAllZoomLevelsStartingWith:(int)startZoomLevel
{
    DLogFuncName();

    return [self tilesInMapRect:rect startingZoomLevel:startZoomLevel endZoomLevel:MAX_GOOGLE_LEVELS];
}



- (NSDictionary *)tilesInMapRect:(MKMapRect)rect startingZoomLevel:(int)startZoomLevel endZoomLevel:(int)endZoomLevel
{
    DLogFuncName();

    NSInteger currentZoomLevel = startZoomLevel;
    NSMutableDictionary *mutableDictionary = [[NSMutableDictionary alloc] init];
    if (startZoomLevel == endZoomLevel)
    {
        NSArray * tiles = [self tilesInMapRect:rect zoomLevel:currentZoomLevel];
        [mutableDictionary setObject:tiles forKey:[NSNumber numberWithInteger:currentZoomLevel]];
    }
    else
    {
        while (currentZoomLevel <= endZoomLevel)
        {
            NSArray * tiles = [self tilesInMapRect:rect zoomLevel:currentZoomLevel];
            [mutableDictionary setObject:tiles forKey:[NSNumber numberWithInteger:currentZoomLevel]];
            currentZoomLevel++;
        }
    }
    return mutableDictionary;
}


- (NSArray *)tilesInMapRect:(MKMapRect)rect zoomLevel:(int)zoomLevel
{
    DLogFuncName();

    NSInteger z = zoomLevel;

    NSMutableArray *tiles = [NSMutableArray array];

    double width = MKMapSizeWorld.width;
    double height = MKMapSizeWorld.height;
    double horizontalTiles = pow(2, zoomLevel);;

    CGFloat x = MKMapRectGetMinX(rect);
    CGFloat y = MKMapRectGetMinY(rect);
    CGFloat w = MKMapRectGetWidth(rect);
    CGFloat h = MKMapRectGetHeight(rect);

    CGFloat tileSizeForCurrentZoomLevel = width / horizontalTiles;
    CGFloat minXTile = (CGFloat)x / tileSizeForCurrentZoomLevel;
    CGFloat maxXTile = (x + w) / tileSizeForCurrentZoomLevel;

    CGFloat minYTile = (CGFloat)y / (height / horizontalTiles);
    CGFloat maxYTile = (y + h) / (height / horizontalTiles);

    NSInteger minX = floor(minXTile);
    NSInteger maxX = ceil(maxXTile);
    NSInteger minY = floor(minYTile);
    NSInteger maxY = ceil(maxYTile);

    for(NSInteger x = minX; x <= maxX; x++)
    {
        for(NSInteger y = minY; y <=maxY; y++)
        {
            NSString *tileKey = [self storageForZ:z x:x y:y];
            if (![NSData dataWithContentsOfFile:tileKey])
            {
                MKTileOverlayPath path;
                path.x = x;
                path.y = y;
                path.z = z;
                path.contentScaleFactor = [[UIScreen mainScreen] scale];

                NSURL *url = [super URLForTilePath:path];
                NSAssert(url, @"No url to add, perhaps missed init with template ...");
                [tiles addObject:@{@"URL": url, @"STORAGE": [self storageForPath:path]}];
            }
        }
    }
    return tiles;
}



#pragma mark - Size
- (NSString *)folderSize
{
    DLogFuncName();

    return [self sizeOfFolder:[self mainFolder]];
}


-(NSString *)sizeOfFolder:(NSString *)folderPath
{
    DLogFuncName();

    unsigned long long int folderSize = [self recursiveSizeForFolder:folderPath];
    //This line will give you formatted size from bytes ....
    NSString *folderSizeStr = [NSByteCountFormatter stringFromByteCount:folderSize countStyle:NSByteCountFormatterCountStyleFile];

    return folderSizeStr;
}


- (unsigned long long int)recursiveSizeForFolder:(NSString*)folderPath
{
    DLogFuncName();

    unsigned long long int folderSize = 0;
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderPath error:nil];
    NSEnumerator *contentsEnumurator = [contents objectEnumerator];

    NSString *file;
    while (file = [contentsEnumurator nextObject])
    {
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[folderPath stringByAppendingPathComponent:file] error:nil];
        NSString *fileType = [fileAttributes objectForKey:NSFileType];

        if ([fileType isEqualToString:NSFileTypeDirectory])
        {
            folderSize += [self recursiveSizeForFolder:[folderPath stringByAppendingPathComponent:file]];
        }
        else
        {
            folderSize += [[fileAttributes objectForKey:NSFileSize] intValue];
        }
    }
    return folderSize;
}

@end
