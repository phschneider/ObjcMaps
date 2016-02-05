//
// Created by Philip Schneider on 10.05.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DZNSegmentedControl;
@class BFNavigationBarDrawer;


@interface PSTracksViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
- (instancetype)initWithTitle:(NSString *)title tracks:(NSArray *)array;
@end