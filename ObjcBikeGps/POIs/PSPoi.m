//
// Created by Philip Schneider on 25.05.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import <Ono/ONOXMLDocument.h>
#import "PSPoi.h"


@interface PSPoi ()
@property (nonatomic) BOOL isTourism;
@property (nonatomic) BOOL isEmergencyAccessPoint;
@property (nonatomic) NSString *ref;
@end

@implementation PSPoi

- (instancetype)initWithXmlData:(ONOXMLElement*)onoxmlElement
{
#warning todo - types (emergency access point / viewpoint)
    DLogFuncName();
    self = [super init];
    if (self)
    {
        self.isTourism = NO;
        
        self.lat = [[onoxmlElement valueForAttribute:@"lat"] floatValue];
        self.lon = [[onoxmlElement valueForAttribute:@"lon"] floatValue];

        self.coordinate = CLLocationCoordinate2DMake([[onoxmlElement valueForAttribute:@"lat"] floatValue],[[onoxmlElement valueForAttribute:@"lon"] floatValue]);
//        self.onoxmlElement = [onoxmlElement copy];

//        NSMutableArray *points = [[NSMutableArray alloc] init];
//
//        for (ONOXMLElement *child in [onoxmlElement children])
//        {
////            NSString *nodeId = [child valueForAttribute:@"ref"];
////            NSString *xPathString = [NSString stringWithFormat:@"//node[@id=%@]",nodeId];
////            [document enumerateElementsWithXPath:xPathString usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop) {
////                NSLog(@"%@", element);
////                NSNumber *lat = [element valueForAttribute:@"lat"];
////                NSNumber *lon = [element valueForAttribute:@"lon"];
////                NSMutableDictionary *pointDict = [[NSMutableDictionary alloc] init];
////                [pointDict setObject:lat forKey:@"_lat"];
////                [pointDict setObject:lon forKey:@"_lon"];
////                [points addObject:pointDict];
////            }];
//        }
//

        NSMutableString *string = [[NSMutableString alloc] init];
        for (ONOXMLElement *child in [onoxmlElement children])
        {
//            if ([[child valueForAttribute:@"k"] isEqualToString:@"description"])
//            {
//                self.title =  [child valueForAttribute:@"v"];
//            }
            if ([[child valueForAttribute:@"k"] isEqualToString:@"tourism"])
            {
                self.isTourism = YES;
            }
            
            if ([[child valueForAttribute:@"k"] isEqualToString:@"highway"] && [[child valueForAttribute:@"v"] isEqualToString:@"emergency_access_point"])
            {
                self.isEmergencyAccessPoint = YES;
            }
            
            if ([[child valueForAttribute:@"k"] isEqualToString:@"ref"])
            {
                self.ref = [child valueForAttribute:@"v"];
            }

            [string appendFormat:@"%@ = %@", [child valueForAttribute:@"k"], [child valueForAttribute:@"v"]];
        }

        self.title = string;
//        NSDictionary *dictionary = @{ @"trk" :  @{ @"trkseg" : @{ @"trkpt" : points} } };
//        [self parseDictionary:dictionary];
    }
    return self;
}


- (NSString*)title
{
    if (self.isEmergencyAccessPoint)
    {
        return self.ref;
    }
    else
    {
        return _title;
    }
}


- (UIImageView*)imageView
{
    DLogFuncName();
    UIImageView *imageView = nil;
    if (self.isTourism)
    {
        imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"512px-Viewpoint-16.svg"]];
    }
    else
    {
        imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Emergency_access_point"]];
    }

    return imageView;
}

@end
