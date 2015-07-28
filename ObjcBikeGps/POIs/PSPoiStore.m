//
// Created by Philip Schneider on 25.05.15.
// Copyright (c) 2015 phschneider.net. All rights reserved.
//

#import <MBProgressHUD/MBProgressHUD.h>
#import <AFNetworking/AFHTTPRequestOperation.h>
#import <Ono/ONOXMLDocument.h>
#import "PSPoiStore.h"
#import "PSPoi.h"


@interface PSPoiStore ()
@property (nonatomic) NSMutableArray* pois;
@end


@implementation PSPoiStore


+ (PSPoiStore*)sharedInstance {
    static PSPoiStore *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}


- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.pois = [[NSMutableArray alloc] init];
    }

    return self;
}


- (void) loadPoisWithBoundingBox:(NSString*)boundingBoxString
{
    DLogFuncName();

//    NSString *string = [NSString stringWithFormat:@"http://overpass.osm.rambler.ru/cgi/xapi_meta?node[tourism=viewpoint][bbox=%@]", boundingBoxString];
    NSString *string = [NSString stringWithFormat:@"http://overpass.osm.rambler.ru/cgi/xapi_meta?node[emergency=assembly_point][bbox=%@]", boundingBoxString];
    NSURL *url = [NSURL URLWithString:string];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];


    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];

        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSData *data = responseObject;
        NSError *error;

        ONOXMLDocument *document = [ONOXMLDocument XMLDocumentWithData:data error:&error];
            id xPath = [document XPath:@"count(//node)"];


        NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docsDir = [dirPaths objectAtIndex:0];
        NSString *databasePath = [[NSString alloc] initWithString: [docsDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.xml",boundingBoxString]]];
        [data writeToFile:databasePath atomically:YES];

        NSString *xPathString = @"//node";
        [document enumerateElementsWithXPath:xPathString usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop) {
//            NSLog(@"%@", element);
            PSPoi *poi= [[PSPoi alloc] initWithXmlData:element];
//            dispatch_async(dispatch_get_main_queue(),^{

                [self.pois insertObject:poi atIndex:[_pois count]];

//            });
        }];

            [[NSNotificationCenter defaultCenter] postNotificationName:@"POIS_UPDATED" object:nil];

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error Retrieving Weather"
                                                            message:[error localizedDescription]
                                                           delegate:nil
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil];
        [alertView show];
    }];


    [operation start];
}


- (NSArray*)poiList
{
    return [self.pois copy];
}

@end