//
// Created by Philip Schneider on 10.05.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PSTrackStore.h"
#import "PSTrack.h"


@interface PSTrackStore ()
@property (nonatomic) NSMutableArray* tracks;
@end

@implementation PSTrackStore

+ (PSTrackStore*)sharedInstance {
    static PSTrackStore *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}


- (instancetype)init
{
    DLogFuncName();
    self = [super init];
    if (self)
    {
        self.tracks = [[NSMutableArray alloc] init];
        [self performSelectorInBackground:@selector(loadTracks) withObject:nil];
    }
    return self;
}


- (void) loadTracks
{
    DLogFuncName();

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *bundleRoot = [[NSBundle mainBundle] bundleURL];
    NSArray * dirContents =
            [fileManager contentsOfDirectoryAtURL:bundleRoot
                       includingPropertiesForKeys:@[]
                                          options:NSDirectoryEnumerationSkipsHiddenFiles
                                            error:nil];
    NSPredicate * fltr = [NSPredicate predicateWithFormat:@"pathExtension='gpx'"];

    NSMutableArray *tracks = [[NSMutableArray alloc] init];
    for (NSURL *url in [dirContents filteredArrayUsingPredicate:fltr])
    {
        PSTrack *track = nil;
        NSString *filename = [[[url absoluteString] lastPathComponent] stringByReplacingOccurrencesOfString:@".gpx" withString:@""];
#ifdef INSELHUEPFEN_MODE
        if (    [[filename lowercaseString] rangeOfString:@"trail"].location == NSNotFound &&
                [[filename lowercaseString] rangeOfString:@"route"].location == NSNotFound &&
                [[filename lowercaseString] rangeOfString:@"tour"].location == NSNotFound)
        {
            NSLog(@"FIlename = %@", filename);
            track = [[PSTrack alloc] initWithFilename:filename trackType:PSTrackTypeUnknown];
        }
#else
        if ([[filename lowercaseString] rangeOfString:@"trail"].location != NSNotFound)
        {
            track = [[PSTrack alloc] initWithFilename:filename trackType:PSTrackTypeTrail];
        }
        else if ([[filename lowercaseString] rangeOfString:@"route"].location != NSNotFound)
        {
            track = [[PSTrack alloc] initWithFilename:filename trackType:PSTrackTypeRoundTrip];
        }
        else
        {
            track = [[PSTrack alloc] initWithFilename:filename trackType:PSTrackTypeUnknown];
        }
#endif
        if (track)
        {
            [self willChangeValueForKey:@"tracks"];
            [self.tracks insertObject:track atIndex:[_tracks count]];
            [self didChangeValueForKey:@"tracks"];
        }
    }
    NSLog(@"finished loading tracks");
}


#pragma mark - Getter
- (NSArray*)trails
{
    DLogFuncName();

    return [self.tracks filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"trackType = %d",PSTrackTypeTrail]];
}


- (NSArray*)routes
{
    DLogFuncName();

    return [self.tracks filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"trackType = %d",PSTrackTypeRoundTrip]];
}


@end
