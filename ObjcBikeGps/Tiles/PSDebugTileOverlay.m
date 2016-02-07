//
// Created by Philip Schneider on 07.02.16.
// Copyright (c) 2016 phschneider.net. All rights reserved.
//

#import "PSDebugTileOverlay.h"


@implementation PSDebugTileOverlay

- (void)loadTileAtPath:(MKTileOverlayPath)path result:(void (^)(NSData *data, NSError *error))result
{
    DLogFuncName();
    if (!result) {
//        NSLog(@"No result");
        return;
    }

    // Tile Overlays
    CGSize sz = self.tileSize;
    CGRect rect = CGRectMake(0, 0, sz.width, sz.height);
    UIGraphicsBeginImageContext(sz);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [[UIColor blackColor] setStroke];
    CGContextSetLineWidth(ctx, 1.0);
    CGContextStrokeRect(ctx, CGRectMake(0, 0, sz.width, sz.height));
    NSString *text = [NSString stringWithFormat:@"X=%d\nY=%d\nZ=%d",path.x,path.y,path.z];
    [text drawInRect:rect withAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:20.0],
            NSForegroundColorAttributeName:[UIColor blackColor]}];
    UIImage *tileImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    NSData *tileData = UIImagePNGRepresentation(tileImage);
    result(tileData,nil);
}

@end