//
// Created by Philip Schneider on 16.05.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import "PSSettingsViewController.h"


@implementation PSSettingsViewController

-(instancetype)init
{
    self = [super init];
    if (self)
    {
        self.title = @"Settings";
        self.tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStyleGrouped];
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
        self.tableView.rowHeight = 40;

        [self.view addSubview:self.tableView];
    }

    return self;
}


- (CGSize)preferredContentSize
{
    return CGSizeMake(320, [self tableHeight]);
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
    NSLog(@"Height = %f", height);
    return height;
}

- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
    NSString* sectionTitle = @"";

    if (section == 0)
    {
        sectionTitle = @"Shading";
    }
    if (section == 1)
    {
        sectionTitle = @"MapTypes";
    }

    return sectionTitle;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section
{
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

    [self updateCell:cell atIndexPath:indexPath];

    return cell;
}


#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [aTableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == 0)
    {
        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
        NSString* pdfPhotoSize = (indexPath.row == 0) ? @"large" : @"half";
        [defaults setObject:pdfPhotoSize forKey:@"PDF_PHOTO_SIZE"];
        [defaults synchronize];

        UITableViewCell* cell;

        indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        cell = [self.tableView cellForRowAtIndexPath:indexPath];
        [self updateCell:cell atIndexPath:indexPath];

        indexPath = [NSIndexPath indexPathForRow:1 inSection:0];
        cell = [self.tableView cellForRowAtIndexPath:indexPath];
        [self updateCell:cell atIndexPath:indexPath];
    }
    else
    {
//        WYAnotherViewController *anotherViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"WYAnotherViewController"];
//        anotherViewController.preferredContentSize = CGSizeMake(320, 420);
//        [self.navigationController pushViewController:anotherViewController animated:YES];
    }
}

#pragma mark - Private

- (void)updateCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    NSString* pdfPhotoSize = [[NSUserDefaults standardUserDefaults] stringForKey:@"PDF_PHOTO_SIZE"];

    cell.textLabel.text = @"";
    cell.accessoryType = UITableViewCellAccessoryNone;

    if (indexPath.section == 0)
    {
        if (indexPath.row % 2 == 0)
        {
            cell.textLabel.text = @"hillshading";
            if ([pdfPhotoSize isEqualToString:@"large"])
            {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
        }
        else if (indexPath.row % 2 == 1)
        {
            cell.textLabel.text = @"landshading";
            if ([pdfPhotoSize isEqualToString:@"half"])
            {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
        }
    }
    else
    {
        if (indexPath.row == 0)
        {
            cell.textLabel.text = @"Apple Satellite";
        }
        else if (indexPath.row == 1)
        {
            cell.textLabel.text = @"Apple Hybrid";
        }
        else if (indexPath.row == 2)
        {
            cell.textLabel.text = @"Hike & Bike";
        }
        else if (indexPath.row == 3)
        {
            cell.textLabel.text = @"Open Street Map";
        }
        else if (indexPath.row == 4)
        {
            cell.textLabel.text = @"Open Cycle Map";
        }
        else if (indexPath.row == 5)
        {
            cell.textLabel.text = @"OpenPTMap";
        }
        else if (indexPath.row == 6)
        {
            cell.textLabel.text = @"Open Topo Map";
        }
    }
}


@end