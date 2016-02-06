//
// Created by Philip Schneider on 16.05.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import "PSSettingsViewController.h"
#import "PSTileOverlay.h"

@interface PSSettingsViewController()
@property (nonatomic) NSArray *maptypes;
@end

@implementation PSSettingsViewController


-(instancetype)init
{
    self = [super init];
    if (self)
    {
        self.title = @"Settings";
        self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0,0,280,400) style:UITableViewStylePlain];
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
        self.tableView.rowHeight = 40;

        [self.view addSubview:self.tableView];

        // TODO: Auslagern in TileManager
        self.maptypes = @[  [ @{ @"name" : @"Apple Default", @"classString" : @"PSAppleDefaultTileOverlay" , @"size" : @""} mutableCopy],
                            [ @{ @"name" : @"Apple Satellite", @"classString" : @"PSAppleSatelliteTileOverlay" , @"size" : @""} mutableCopy],
                            [ @{ @"name" : @"Apple Hybrid", @"classString" : @"PSAppleHybridTileOverlay" , @"size" : @""}  mutableCopy],
                            [ @{ @"name" : @"Open Street Map", @"classString" : @"PSOpenStreetMapTileOverlay" , @"size" : @""} mutableCopy],
                            [ @{ @"name" : @"Open Cycle Map", @"classString" : @"PSOpenCycleMapTileOverlay" , @"size" : @""} mutableCopy],
                            [ @{ @"name" : @"Light (MapBox)", @"classString" : @"PSMapBoxLightTileOverlay" , @"size" : @""} mutableCopy],
                            [ @{ @"name" : @"Dark (MapBox)", @"classString" : @"PSMapBoxDarkTileOverlay" , @"size" : @""} mutableCopy],
                            [ @{ @"name" : @"Street (MapBox)", @"classString" : @"PSMapBoxTileOverlay" , @"size" : @""} mutableCopy],
                            [ @{ @"name" : @"Run/Bike/Hike (MapBox)", @"classString" : @"PSMapBoxRunBikeHikeTileOverlay" , @"size" : @""} mutableCopy],
                            [ @{ @"name" : @"PS Custom (MapBox)", @"classString" : @"PSMapBoxCustomTileOverlay" , @"size" : @""} mutableCopy],
                            [ @{ @"name" : @"Hight contrast (MapBox)", @"classString" : @"PSMapBoxHighContrastTileOverlay" , @"size" : @""} mutableCopy],
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

        NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docsDir = [dirPaths objectAtIndex:0];
        NSString *databasePath = [[NSString alloc] initWithString:[docsDir stringByAppendingPathComponent:[NSString stringWithFormat:@"/tiles/%@", [overlay name]]]];

        int index = [self.maptypes indexOfObject:model];
        [model setObject:[self sizeOfFolder:databasePath] forKey:@"size"];

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
        NSLog(@"URL Template = %@", urlTemplate);

        cell.detailTextLabel.text = [model objectForKey:@"size"];

        if (![tileClassString isEqualToString:[model objectForKey:@"classString"]])
        {
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"gray-265-download"]];
            cell.accessoryView = imageView;
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


- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    DLogFuncName();

    NSDictionary *model = [self.maptypes objectAtIndex:indexPath.row];
    Class tileClass = NSClassFromString([model objectForKey:@"classString"]);
    id object = [[tileClass alloc] init];
    if (object)
    {
        NSString * urlTemplate = [tileClass urlTemplate];
    }
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


-(NSString *)sizeOfFolder:(NSString *)folderPath
{
    DLogFuncName();

    unsigned long long int folderSize = [self recursiveSizeForFolder:folderPath];
    //This line will give you formatted size from bytes ....
    NSString *folderSizeStr = [NSByteCountFormatter stringFromByteCount:folderSize countStyle:NSByteCountFormatterCountStyleFile];

    return folderSizeStr;
}


- (unsigned long long int)recursiveSizeForFolder:(NSString*)folderPath
{
    DLogFuncName();

    unsigned long long int folderSize = 0;
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderPath error:nil];
    NSEnumerator *contentsEnumurator = [contents objectEnumerator];

    NSString *file;
    while (file = [contentsEnumurator nextObject]) 
    {
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[folderPath stringByAppendingPathComponent:file] error:nil];
        NSString *fileType = [fileAttributes objectForKey:NSFileType];

        if ([fileType isEqualToString:NSFileTypeDirectory])
        {
            folderSize += [self recursiveSizeForFolder:[folderPath stringByAppendingPathComponent:file]];
        }
        else
        {
            folderSize += [[fileAttributes objectForKey:NSFileSize] intValue];
        }
    }
    return folderSize;
}

@end
