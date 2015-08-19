//
// Created by Philip Schneider on 19.08.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import "PSOpenCycleMapTileOverlay.h"


@implementation PSOpenCycleMapTileOverlay


+ (NSString *)urlTemplate
{
    NSString *urlString = [NSString stringWithFormat:@"http://b.tiles.wmflabs.org/hikebike/{z}/{x}/{y}.png"];
    NSLog(@"urlTemplate = %@",urlString);
    return urlString;
}


- (NSString*)name
{
    return @"openCycleMap";
}

@end