//
// Created by Philip Schneider on 10.05.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

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
            track = [[PSTrack alloc] initWithFilename:filename];
        }

        [self willChangeValueForKey:@"tracks"];
        [self.tracks insertObject:track atIndex:[_tracks count]];
        [self didChangeValueForKey:@"tracks"];
    }
}

@end
