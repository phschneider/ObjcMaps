//
// Created by Philip Schneider on 16.05.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PSTileOverlay : MKTileOverlay

@property NSCache *cache;
@property NSOperationQueue *operationQueue;

+(NSString*) urlTemplate;

- (MKOverlayLevel) level;

- (NSString *)name;

- (NSString*)storageForPath:(MKTileOverlayPath)path;

- (NSDictionary *)tilesInMapRect:(MKMapRect)rect forAllZoomLevelsStartingWith:(int)startZoomLevel;

- (NSDictionary *)tilesInMapRect:(MKMapRect)rect startingZoomLevel:(int)startZoomLevel endZoomLevel:(int)endZoomLevel;

- (NSArray *)tilesInMapRect:(MKMapRect)rect zoomLevel:(int)zoomLevel;

- (NSString *)folderSize;
@end
