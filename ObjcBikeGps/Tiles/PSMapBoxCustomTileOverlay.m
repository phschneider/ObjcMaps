//
// Created by Philip Schneider on 25.08.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import "PSMapBoxCustomTileOverlay.h"


@implementation PSMapBoxCustomTileOverlay

+ (NSString *)mapId
{
    return @"phschneider.842a0982";
}


- (NSString*)name
{
    return [[self class] mapId];
}

@end
