//
// Created by Philip Schneider on 19.11.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PSMainMenuViewController.h"
#import "PSMapViewController.h"
#import "PSTracksViewController.h"
#import "PSGridButton.h"
#import "PSTrackStore.h"


@implementation PSMainMenuViewController

- (instancetype)init
{
    DLogFuncName();
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    self = [super initWithCollectionViewLayout:flowLayout];
    if (self)
    {
        self.edgesForExtendedLayout = UIRectEdgeBottom;
        self.extendedLayoutIncludesOpaqueBars = NO;
        self.collectionView.backgroundColor = [UIColor whiteColor];
        self.collectionView.delegate = self;
        self.collectionView.dataSource = self;
        [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"bla"];
    }
    return self;
}


#pragma mark - DataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    DLogFuncName();
    return 5;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    DLogFuncName();
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"bla" forIndexPath:indexPath];

    UILabel *label = [[UILabel alloc] initWithFrame:cell.contentView.bounds];
    label.text = [NSString stringWithFormat:@"%d %d", indexPath.row, indexPath.section];
    label.textAlignment = NSTextAlignmentCenter;
    for (UIView *view in cell.contentView.subviews)
    {
        [view removeFromSuperview];
    }
    [cell.contentView addSubview:label];

    cell.contentView.layer.borderColor = [[UIColor blackColor] CGColor];
    cell.contentView.layer.borderWidth = 1.0;
    cell.contentView.layer.cornerRadius = 5.0;

    switch (indexPath.row)
    {
        case 0:
            label.text = @"Map";
            break;
        case 1:
            label.text = @"Alle Tracks";
            break;
        case 2:
            label.text = @"Trails";
            break;
        case 3:
            label.text = @"MTB";
            break;
        case 4:
            label.text = @"Bike";
            break;

    }

    return cell;
}


#pragma mark - Delegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    DLogFuncName();
    UIViewController *viewController = nil;
    switch (indexPath.row)
    {
        case 0:
            viewController = [[PSMapViewController alloc] init];
            break;
        case 1:
            viewController = [[PSTracksViewController alloc] initWithTitle:@"Alle Tracks" tracks:[[PSTrackStore sharedInstance] tracks]];
            break;
        case 2:
            viewController = [[PSTracksViewController alloc] initWithTitle:@"Trails" tracks:[[PSTrackStore sharedInstance] trails]];
            break;
        case 3:
            viewController = [[PSTracksViewController alloc] initWithTitle:@"MTB" tracks:[[PSTrackStore sharedInstance] mtbRoutes]];
            break;
        case 4:
            viewController = [[PSTracksViewController alloc] initWithTitle:@"Bike" tracks:[[PSTrackStore sharedInstance] bikeRoutes]];
            break;
    }

    if (viewController)
    {
        [self.navigationController pushViewController:viewController animated:YES];
    }
}


#pragma mark - Layout Delegate
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    DLogFuncName();
    CGFloat width = self.view.bounds.size.width / 3;
    CGFloat height = self.view.bounds.size.height / 3;
    CGFloat size = MIN(width,height);
    CGSize result = CGSizeMake(size,size);
    return result;
}


- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    DLogFuncName();
    CGFloat width = self.view.bounds.size.width / 3;
    CGFloat diff = (self.view.bounds.size.width / 2) - width;
    return 50;
}


- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    DLogFuncName();
    UIEdgeInsets result = UIEdgeInsetsMake(50,50,50,50);
    return result;
}

@end