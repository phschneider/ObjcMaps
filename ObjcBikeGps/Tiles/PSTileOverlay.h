//
// Created by Philip Schneider on 16.05.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PSTileOverlay : MKTileOverlay

+(NSString*) urlTemplate;
- (MKOverlayLevel) level;

- (NSString *)name;
@end
