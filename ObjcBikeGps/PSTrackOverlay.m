//
// Created by Philip Schneider on 24.05.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import "PSTrackOverlay.h"
#import "PSTrack.h"


@implementation PSTrackOverlay


- (instancetype)initWithTrack:(PSTrack*)track
{
    self = [super init];
    if (self)
    {
        self.track = track;
    }

    return self;
}


- (UIColor *)color
{
    DLogFuncName();
    return self.track.color;
}

- (CGFloat)lineWidth
{
    DLogFuncName();
    return self.track.lineWidth;
}

- (CGFloat)alpha
{
    DLogFuncName();
    return self.track.alpha;
}


- (NSArray*)lineDashPattern
{
    DLogFuncName();
    return self.track.lineDashPattern;
}

@end
