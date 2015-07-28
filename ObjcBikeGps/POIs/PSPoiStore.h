//
// Created by Philip Schneider on 25.05.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PSPoiStore : NSObject

+ (PSPoiStore *)sharedInstance;
- (void)loadPoisWithBoundingBox:(NSString *)boundingBox;
- (NSArray* )poiList;

@end
