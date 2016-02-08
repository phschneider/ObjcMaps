//
// Created by Philip Schneider on 16.05.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import <AFNetworking/AFHTTPRequestOperation.h>
#import "PSSettingsViewController.h"
#import "PSTileOverlay.h"
#import "PSAppDelegate.h"
#import "PSMapViewController.h"
#import "MKMapView+PSZoomLevel.h"
#import "MBProgressHUD.h"

@interface PSSettingsViewController()
@property (nonatomic) NSArray *maptypes;
@property(nonatomic) BOOL downloadsEnabled;
@end

@implementation PSSettingsViewController


-(instancetype)init
{
    self = [super init];
    if (self)
    {
        self.title = @"Settings";
        self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
        self.tableView.rowHeight = 40;

        [self.view addSubview:self.tableView];

        // TODO: Auslagern in TileManager
        self.maptypes = @[  [ @{ @"name" : @"Debug", @"classString" : @"PSDebugTileOverlay" , @"size" : @"" , @"canDownload" : @NO } mutableCopy],
                            [ @{ @"name" : @"Apple Default", @"classString" : @"PSAppleDefaultTileOverlay" , @"size" : @"", @"canDownload" : @NO } mutableCopy],
                            [ @{ @"name" : @"Apple Satellite", @"classString" : @"PSAppleSatelliteTileOverlay" , @"size" : @"", @"canDownload" : @NO } mutableCopy],
                            [ @{ @"name" : @"Apple Hybrid", @"classString" : @"PSAppleHybridTileOverlay" , @"size" : @"", @"canDownload" : @NO }  mutableCopy],
                            [ @{ @"name" : @"Open Street Map", @"classString" : @"PSOpenStreetMapTileOverlay" , @"size" : @"", @"canDownload" : @YES } mutableCopy],
                            [ @{ @"name" : @"Open Cycle Map", @"classString" : @"PSOpenCycleMapTileOverlay" , @"size" : @"" , @"canDownload" : @YES } mutableCopy],
                            [ @{ @"name" : @"Light (MapBox)", @"classString" : @"PSMapBoxLightTileOverlay" , @"size" : @"", @"canDownload" : @YES } mutableCopy],
                            [ @{ @"name" : @"Dark (MapBox)", @"classString" : @"PSMapBoxDarkTileOverlay" , @"size" : @"", @"canDownload" : @YES } mutableCopy],
                            [ @{ @"name" : @"Street (MapBox)", @"classString" : @"PSMapBoxTileOverlay" , @"size" : @"",  @"canDownload" : @YES } mutableCopy],
                            [ @{ @"name" : @"Run/Bike/Hike (MapBox)", @"classString" : @"PSMapBoxRunBikeHikeTileOverlay" , @"size" : @"", @"canDownload" : @YES } mutableCopy],
                            [ @{ @"name" : @"PS Custom (MapBox)", @"classString" : @"PSMapBoxCustomTileOverlay" , @"size" : @"", @"canDownload" : @YES } mutableCopy],
                            [ @{ @"name" : @"Hight contrast (MapBox)", @"classString" : @"PSMapBoxHighContrastTileOverlay" , @"size" : @"", @"canDownload" : @YES } mutableCopy],
        ];

        dispatch_queue_t backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        dispatch_async(backgroundQueue,^{
            [self calculateSizes];
        });
    }

    return self;
}


// TODO: auslagern in Tiles
- (void) calculateSizes
{
    DLogFuncName();

    for (NSMutableDictionary *model in self.maptypes)
    {
        Class tileClass = NSClassFromString([model objectForKey:@"classString"]);
        NSString *urlTemplate = [tileClass urlTemplate];
        PSTileOverlay *overlay = [(PSTileOverlay *) [tileClass alloc] initWithURLTemplate:urlTemplate];

        int index = [self.maptypes indexOfObject:model];
        [model setObject:[overlay folderSize] forKey:@"size"];

        dispatch_async(dispatch_get_main_queue(),^{
            [self.tableView reloadRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:index inSection:0] ] withRowAnimation:UITableViewRowAnimationAutomatic];
        });
    }
}


- (CGSize)preferredContentSize
{
    return CGSizeMake(280, [self tableHeight]);
}


#pragma mark - UITableViewDataSource
- (CGFloat) tableHeight
{
    CGFloat height = 0.0;
    for (int i=0; i < [self.tableView numberOfSections]; i++)
    {
        height += ([self.tableView numberOfRowsInSection:i] * self.tableView.rowHeight);;
//        height += [self.tableView tableHeaderView].frame.size.height;
//        height += 100;
    }

//    height += self.tableView.rowHeight;
//    NSLog(@"Height = %f", height);
    return height;
}

//- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
//    NSString* sectionTitle = @"";
//
//    if (section == 0)
//    {
//        sectionTitle = @"Shading";
//    }
//    if (section == 1)
//    {
//        sectionTitle = @"MapTypes";
//    }
//
//    return sectionTitle;
//}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section
{
    return [self.maptypes count];
    NSInteger result = 7;
    if (section == 0)
    {
        result = 2;
    }
    return result;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = [aTableView dequeueReusableCellWithIdentifier:@"WYSettingsTableViewCell"];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"WYSettingsTableViewCell"];
    }

    NSString* tileClassString = [[NSUserDefaults standardUserDefaults] stringForKey:@"TILE_CLASS"];
    NSDictionary *model = [self.maptypes objectAtIndex:indexPath.row];
    Class tileClass = NSClassFromString([model objectForKey:@"classString"]);
    cell.textLabel.text = [model objectForKey:@"name"];

    id object = [[tileClass alloc] init];
    if (object)
    {
        NSString *urlTemplate = [tileClass urlTemplate];
        cell.detailTextLabel.text = [model objectForKey:@"size"];

        if (![tileClassString isEqualToString:[model objectForKey:@"classString"]] && [[model objectForKey:@"canDownload"] boolValue])
        {
            UIImage *image = [UIImage imageNamed:@"gray-265-download"];
            UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 28, 28)]; // tested also initWithFrame:CGRectMake(0, 0, image.size.width, image.size.heigth)
            [UIButton buttonWithType:UIButtonTypeCustom];
            [button setBackgroundImage:image forState:UIControlStateNormal];
            button.backgroundColor = [UIColor clearColor];

            cell.accessoryView = button;
            [button addTarget:self action:@selector(accessoryButtonTapped:withEvent:) forControlEvents:UIControlEventTouchUpInside];
        }
        else
        {
            cell.accessoryView = nil;
        }
    }
    else
    {
        cell.detailTextLabel.text = @"test";
    }


    if ([tileClassString isEqualToString:[model objectForKey:@"classString"]])
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else if ([[model objectForKey:@"name"] rangeOfString:@"Apple"].location != NSNotFound)
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    return cell;
}


- (void) accessoryButtonTapped: (UIControl *) button withEvent: (UIEvent *) event
{
    DLogFuncName();
    NSIndexPath * indexPath = [self.tableView indexPathForRowAtPoint: [[[event touchesForView: button] anyObject] locationInView: self.tableView]];
    if ( indexPath == nil )
        return;

    [self.tableView.delegate tableView: self.tableView accessoryButtonTappedForRowWithIndexPath: indexPath];
}


- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    DLogFuncName();

    NSDictionary *model = [self.maptypes objectAtIndex:indexPath.row];
    Class tileClass = NSClassFromString([model objectForKey:@"classString"]);
    NSString * urlTemplate = [tileClass urlTemplate];
    id object = [(PSTileOverlay *) [tileClass alloc] initWithURLTemplate:urlTemplate];

    if (object && [[model objectForKey:@"canDownload"] boolValue])
    {
        UINavigationController * navigationController = [((PSAppDelegate *) [[UIApplication sharedApplication] delegate]) window].rootViewController;
        PSMapViewController *mapViewController = [navigationController topViewController];

//        NSDictionary *tileUrls = [object tilesInMapRect:mapViewController.mapView.visibleMapRect startingZoomLevel:mapViewController.mapView.zoomLevel endZoomLevel:mapViewController.mapView.zoomLevel+1];

        MBProgressHUD *HUD = [MBProgressHUD showHUDAddedTo:self.view animated:NO];
        HUD.mode = MBProgressHUDModeIndeterminate;
        self.downloadsEnabled = YES;

        UITapGestureRecognizer *HUDSingleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(singleTap:)];
        [HUD addGestureRecognizer:HUDSingleTap];

        dispatch_queue_t backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        dispatch_async(backgroundQueue,^{
            NSDictionary * tileUrls = [object tilesInMapRect:mapViewController.mapView.visibleMapRect forAllZoomLevelsStartingWith:mapViewController.mapView.zoomLevel];
            [self downloadTilesInDictionary:tileUrls];
        });
    }
}


- (void) downloadTilesInDictionary:(NSDictionary *)tileDictionary
{
    DLogFuncName();

    if (!self.downloadsEnabled)
    {
        return;
    }

    MBProgressHUD *HUD = [MBProgressHUD HUDForView:self.view];
    HUD.mode = MBProgressHUDModeDeterminateHorizontalBar;
    HUD.progress = 0.0;

    if ([[tileDictionary allKeys] count] == 0)
    {
        [HUD hide:YES];
    }
    else
    {
        [HUD show:YES];
    }

    for (NSNumber *zoomLevel in [tileDictionary allKeys])
    {
        __block NSArray *tiles = [tileDictionary objectForKey:zoomLevel];
        __block int index = 0;

        if ([tiles count] == 0)
        {
            [HUD hide:YES];
        }
        else
        {
            [HUD show:YES];
        }

        for (NSDictionary *model in tiles)
        {
            NSURL *tileUrl = [model objectForKey:@"URL"];
            __block NSString *storagePath = [model objectForKey:@"STORAGE"];

            NSURLRequest *request = [NSURLRequest requestWithURL:tileUrl];
            AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];

            [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSData *data = responseObject;

                [[NSFileManager defaultManager] createDirectoryAtPath:[storagePath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
                [data writeToFile:storagePath atomically:YES];

                double progress = (double)index / [tiles count];
                dispatch_async(dispatch_get_main_queue(),^{
                    HUD.progress = progress;
                    [HUD show:NO];
                    HUD.labelText = [NSString stringWithFormat:@"%lld/%lld", ++index, [tiles count]];
                    if (index == [tiles count])
                    {
                        [HUD hide:YES];
                    }
                });

            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                [HUD hide:NO];
                [[[UIAlertView alloc] initWithTitle:[error localizedDescription] message:[error userInfo] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];

            }];

            if (self.downloadsEnabled)
            {
                useconds_t seconds = (useconds_t)(100000/(0.5));
                usleep(seconds);
                [operation start];
            }
        }
    }
}


- (void)singleTap:(id)singleTap
{
    DLogFuncName();
    self.downloadsEnabled = NO;
    MBProgressHUD *HUD = [MBProgressHUD HUDForView:self.view];
    [HUD hide:NO];
}


#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DLogFuncName();

    [aTableView deselectRowAtIndexPath:indexPath animated:YES];

    NSDictionary *model = [self.maptypes objectAtIndex:indexPath.row];
    [[NSUserDefaults standardUserDefaults] setObject:[model objectForKey:@"classString"] forKey:@"TILE_CLASS"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [aTableView reloadData];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"USERDEFAULTS_SETTINGS_TILECLASS_CHANGED" object:nil];
}

@end
