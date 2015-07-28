//
// Created by Philip Schneider on 24.05.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PSTrack;


@interface PSTrackOverlay : MKPolyline <MKOverlay>

@property (nonatomic) PSTrack *track;

- (instancetype)initWithTrack:(PSTrack *)track;
- (UIColor *)color;
- (CGFloat)lineWidth;
- (CGFloat)alpha;
- (NSArray *)lineDashPattern;
@end