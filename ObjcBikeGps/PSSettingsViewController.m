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


        self.maptypes = @[  @{ @"name" : @"Apple Default", @"classString" : @"PSAppleDefaultTileOverlay" },
                            @{ @"name" : @"Apple Satellite", @"classString" : @"PSAppleSatelliteTileOverlay" },
                            @{ @"name" : @"Apple Hybrid", @"classString" : @"PSAppleHybridTileOverlay" },
                            @{ @"name" : @"Open Street Map", @"classString" : @"PSOpenStreetMapTileOverlay" },
                            @{ @"name" : @"Open Cycle Map", @"classString" : @"PSOpenCycleMapTileOverlay" },
                            @{ @"name" : @"Light (MapBox)", @"classString" : @"PSMapBoxLightTileOverlay" },
                            @{ @"name" : @"Dark (MapBox)", @"classString" : @"PSMapBoxDarkTileOverlay" },
                            @{ @"name" : @"Street (MapBox)", @"classString" : @"PSMapBoxTileOverlay" },
                            @{ @"name" : @"Run/Bike/Hike (MapBox)", @"classString" : @"PSMapBoxRunBikeHikeTileOverlay" },
                            @{ @"name" : @"PS Custom (MapBox)", @"classString" : @"PSMapBoxCustomTileOverlay" },
                            @{ @"name" : @"Hight contrast (MapBox)", @"classString" : @"PSMapBoxHighContrastTileOverlay" }
        ];
    }

    return self;
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

    height += self.tableView.rowHeight;
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
    //UITableViewCell* cell = [aTableView dequeueReusableCellWithIdentifier:@"WYSettingsTableViewCell" forIndexPath:indexPath];

    UITableViewCell* cell = [aTableView dequeueReusableCellWithIdentifier:@"WYSettingsTableViewCell"];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"WYSettingsTableViewCell"];
    }

    NSString* tileClassString = [[NSUserDefaults standardUserDefaults] stringForKey:@"TILE_CLASS"];

    cell.textLabel.text = @"";
    cell.accessoryType = UITableViewCellAccessoryNone;
    NSDictionary *model = [self.maptypes objectAtIndex:indexPath.row];
    cell.textLabel.text = [model objectForKey:@"name"];

    Class tileClass = NSClassFromString([model objectForKey:@"classString"]);
    id object = [[tileClass alloc] init];
    if (object) {

        NSString *urlTemplate = [tileClass urlTemplate];
        NSLog(@"URL Template = %@", urlTemplate);

        PSTileOverlay *overlay = [(PSTileOverlay *) [tileClass alloc] initWithURLTemplate:urlTemplate];


        NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docsDir = [dirPaths objectAtIndex:0];
        NSString *databasePath = [[NSString alloc] initWithString:[docsDir stringByAppendingPathComponent:[NSString stringWithFormat:@"/tiles/%@", [overlay name]]]];


        cell.detailTextLabel.text = [self sizeOfFolder:databasePath];
    }
    else
    {
        cell.detailTextLabel.text = @"test";
    }



    if ([tileClassString isEqualToString:[model objectForKey:@"classString"]])
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    return cell;
}


#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
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
