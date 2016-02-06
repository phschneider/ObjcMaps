//
// Created by Philip Schneider on 16.05.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PSTileOverlay : MKTileOverlay

+(NSString*) urlTemplate;

+ (NSArray *)tilesInMapRect:(MKMapRect)rect zoomScale:(MKZoomScale)scale;

- (MKOverlayLevel) level;

- (NSString *)name;

- (NSString *)folderSize;
@end
