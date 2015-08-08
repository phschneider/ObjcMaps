//
// Created by Philip Schneider on 06.08.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import "MKMapView+PSTilesInMapRect.h"
#import "MKMapView+PSZoomLevel.h"


#define MAX_ZOOM 20


#define TILE_SIZE 256

// macht nur sinn zu nutzen, wenn wir alle daten offline speichern!!!

// Convert an MKZoomScale to a zoom level where level 0 contains 4 256px square tiles,
// which is the convention used by gdal2tiles.py.
static NSInteger zoomScaleToZoomLevel(MKZoomScale scale) {
    double numTilesAt1_0 = MKMapSizeWorld.width / TILE_SIZE;
    NSInteger zoomLevelAt1_0 = log2(numTilesAt1_0);  // add 1 because the convention skips a virtual level with 1 tile.
    NSInteger zoomLevel = MAX(0, zoomLevelAt1_0 + floor(log2f(scale) + 0.5));
    return zoomLevel;
}


@implementation MKMapView (PSTilesInMapRect)


- (NSArray *)tilesInMapRect:(MKMapRect)rect zoomScale:(MKZoomScale)scale
{
//    if (scale ==  0.001272353920918288)
//    {
//        scale = 0.001953;
//    }

    NSLog(@"tilesInMapRect ZoomScale = %f", scale);
    NSInteger z = zoomScaleToZoomLevel(scale);

    NSInteger overZoom = 1;
    NSInteger zoomCap = MAX_ZOOM;  // A constant set to the max tile set depth.

    if (z > zoomCap) {
        // overZoom progression: 1, 2, 4, 8, etc...
        overZoom = pow(2, (z - zoomCap));
        z = zoomCap;
    }

    // When we are zoomed in beyond the tile set, use the tiles
    // from the maximum z-depth, but render them larger.
    NSInteger adjustedTileSize = overZoom * TILE_SIZE;

    NSInteger minX = floor((MKMapRectGetMinX(rect) * scale) / adjustedTileSize);
    NSInteger maxX = floor((MKMapRectGetMaxX(rect) * scale) / adjustedTileSize);
    NSInteger minY = floor((MKMapRectGetMinY(rect) * scale) / adjustedTileSize);
    NSInteger maxY = floor((MKMapRectGetMaxY(rect) * scale) / adjustedTileSize);

    NSMutableArray *tiles = nil;
    NSLog(@"First Loop = %d", (maxX - minX));
    NSLog(@"Second Loop = %d", (maxY - minY));

    for (NSInteger x = minX; x < maxX; x++) {
        for (NSInteger y = minY; y < maxY; y++) {

            NSString *tileKey = [[NSString alloc] initWithFormat:@"%d/%d/%d", z, x, y]; // was flippedY
            if (!tiles) {
                tiles = [NSMutableArray array];
            }

            MKMapRect frame = MKMapRectMake((double)(x * TILE_SIZE) / scale,
                    (double)(y * TILE_SIZE) / scale,
                    TILE_SIZE / scale,
                    TILE_SIZE / scale);

            [tiles addObject:tileKey];
        }
    }
    return tiles;
}

//@end
//
//
//- (NSArray *)tilesInMapRect:(MKMapRect)rect zoomScale:(MKZoomScale)scale
//{
//    NSMutableArray *tilePaths = [[NSMutableArray alloc] init];
//    NSMutableArray *tiles = [[NSMutableArray alloc] init];
//
//    NSString *tileBase = @"http://b.tiles.wmflabs.org/hikebike";
//    NSInteger z = [self zoomLevel]-1;
//
////    MKTileOverlay *tileOverlay = (MKTileOverlay *)self.overlay;
////    path.x = mapRect.origin.x*zoomScale/tileOverlay.tileSize.width;
////    path.y = mapRect.origin.y*zoomScale/tileOverlay.tileSize.width;
////    path.z = log2(zoomScale)+20;
//
//    // OverZoom Mode - Detect when we are zoomed beyond the tile set.
//    NSInteger overZoom = 1;
//    NSInteger zoomCap = MAX_ZOOM;  // A constant set to the max tile set depth.
//
//    if (z > zoomCap) {
//        // overZoom progression: 1, 2, 4, 8, etc...
//        overZoom = pow(2, (z - zoomCap));
//        z = zoomCap;
//    }
//
//    // When we are zoomed in beyond the tile set, use the tiles
//    // from the maximum z-depth, but render them larger.
//    NSInteger adjustedTileSize = overZoom * TILE_SIZE;
//
//    // Number of tiles wide or high (but not wide * high)
//    NSInteger tilesAtZ = pow(2, z);
//    NSLog(@"tilesAtZ = %d",tilesAtZ);
//
//    NSInteger minX = rect.origin.x * z/adjustedTileSize;
//    NSInteger maxX = floor((MKMapRectGetMaxX(rect)) / adjustedTileSize);
//    maxX = ( (maxX-minX) / adjustedTileSize);
//    maxX = minX + maxX;
//
//    NSInteger minY = floor((MKMapRectGetMinY(rect)) / adjustedTileSize);
//    NSInteger maxY = floor((MKMapRectGetMaxY(rect)) / adjustedTileSize);
//    maxY = ((maxY-minY) / adjustedTileSize);
//    maxY = minY + maxY;
//
//    NSLog(@"First Loop = %d", (maxX - minX));
//    NSLog(@"Second Loop = %d", (maxY - minY));
//
//    for (NSInteger x = minX; x <= maxX; x++)
//    {
//        for (NSInteger y = minY; y <= maxY; y++)
//        {
//            // As in initWithTilePath, need to flip y index to match the gdal2tiles.py convention.
//            NSInteger flippedY = abs(y + 1 - tilesAtZ);
//            NSString *tileKey = [[NSString alloc] initWithFormat:@"%d/%d/%d", z, x, flippedY];
//            NSLog(@"tileKey = %@", tileKey);
//            if (![tilePaths containsObject:tileKey])
//            {
//                NSString *path = [[NSString alloc] initWithFormat:@"%@/%@.png", tileBase, tileKey];
//                NSLog(@"TilePath = %@", path);
//                [tiles addObject:path];
//                [tilePaths addObject:tileKey];
//            }
//        }
//    }
//    return tiles;
//}

@end
