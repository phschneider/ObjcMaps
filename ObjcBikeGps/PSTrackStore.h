//
// Created by Philip Schneider on 10.05.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PSTrackStore : NSObject


+ (PSTrackStore *)sharedInstance;
//@property (nonatomic, readonly) NSMutableArray* tracks;

- (NSArray *)trails;

- (NSArray *)routes;
@end