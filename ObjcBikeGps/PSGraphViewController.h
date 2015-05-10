//
// Created by Philip Schneider on 03.10.14.
// Copyright (c) 2014 phschneider.net. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BEMSimpleLineGraphView.h"

@interface PSGraphViewController: UIViewController <BEMSimpleLineGraphDataSource, BEMSimpleLineGraphDelegate, UITableViewDataSource, UITableViewDelegate>

- (void) setData:(NSArray *)data;

@end