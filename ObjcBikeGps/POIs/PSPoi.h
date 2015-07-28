//
// Created by Philip Schneider on 25.05.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PSPoi : NSObject  <MKAnnotation>

@property (nonatomic) CGFloat lat;
@property (nonatomic) CGFloat lon;
@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic) NSString *title;

@property (nonatomic) ONOXMLElement *onoxmlElement;

- (instancetype)initWithXmlData:(ONOXMLElement *)onoxmlElement;
- (UIImageView*)imageView;
@end
