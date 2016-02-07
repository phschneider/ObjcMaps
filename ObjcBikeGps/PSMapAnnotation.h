//
//  PSMapAnnotation.h
//  ObjcBikeGps
//
//  Created by Philip Schneider on 07.02.16.
//  Copyright © 2016 phschneider.net. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PSMapAnnotation : NSObject

@property (nonatomic, weak) MKAnnotationView *view;
@property (nonatomic) NSString *title;
@property (nonatomic) CLLocationCoordinate2D coordinate;

- (id) initWithCoordinate:(CLLocationCoordinate2D)coordinate title:(NSString*)title;

@end
