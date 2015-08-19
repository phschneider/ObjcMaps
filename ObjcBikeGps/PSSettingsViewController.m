//
// Created by Philip Schneider on 16.05.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import "PSSettingsViewController.h"

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
        self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0,0,220,300) style:UITableViewStyleGrouped];
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
        self.tableView.rowHeight = 40;

        [self.view addSubview:self.tableView];


        self.maptypes = @[  @{ @"name" : @"Open Street Map", @"classString" : @"PSOpenStreetMapTileOverlay" },
                            @{ @"name" : @"Open Cycle Map", @"classString" : @"PSOpenCycleMapTileOverlay" },
                            @{ @"name" : @"Light (MapBox)", @"classString" : @"PSMapBoxLightTileOverlay" },
                            @{ @"name" : @"Dark (MapBox)", @"classString" : @"PSMapBoxDarkTileOverlay" },
                            @{ @"name" : @"Street (MapBox)", @"classString" : @"PSMapBoxTileOverlay" },
                            @{ @"name" : @"Run/Bike/Hike (MapBox)", @"classString" : @"PSMapBoxRunBikeHikeTileOverlay" },
                            @{ @"name" : @"Hight contrast (MapBox)", @"classString" : @"PSMapBoxHighContrastTileOverlay" }
        ];
    }

    return self;
}


- (CGSize)preferredContentSize
{
    return CGSizeMake(220, [self tableHeight]);
}


#pragma mark - UITableViewDataSource
- (CGFloat) tableHeight
{
    CGFloat height = 0.0;
    for (int i=0; i < [self.tableView numberOfSections]; i++)
    {
        height += ([self.tableView numberOfRowsInSection:i] * self.tableView.rowHeight);;
//        height += [self.tableView tableHeaderView].frame.size.height;
        height += 100;
    }
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
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"WYSettingsTableViewCell"];
    }

    NSString* tileClassString = [[NSUserDefaults standardUserDefaults] stringForKey:@"TILE_CLASS"];

    cell.textLabel.text = @"";
    cell.accessoryType = UITableViewCellAccessoryNone;
    NSDictionary *model = [self.maptypes objectAtIndex:indexPath.row];
    cell.textLabel.text = [model objectForKey:@"name"];

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

@end