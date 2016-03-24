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
//    NSString *string = [NSString stringWithFormat:@"http://overpass.osm.rambler.ru/cgi/xapi_meta?node[emergency=assembly_point][bbox=%@]", boundingBoxString];
//    NSString *string = [NSString stringWithFormat:@"http://overpass.osm.rambler.ru/cgi/xapi_meta?node[natural=water|peak][bbox=%@]", boundingBoxString];


    //    NSString *string = [NSString stringWithFormat:@"http://overpass.osm.rambler.ru/cgi/xapi_meta?node[bbox=%@]", boundingBoxString];
    [self loadTourismPoisWithBoundingBox:boundingBoxString];
    [self loadNaturalPoisWithBoundingBox:boundingBoxString];

}


- (NSArray*)poiList
{
    return [self.pois copy];
}


- (void) loadNaturalPoisWithBoundingBox:(NSString*)boundingBoxString
{
    NSArray *values = @[@"peak", @"water"];
    NSString *string = [NSString stringWithFormat:@"http://overpass.osm.rambler.ru/cgi/xapi_meta?node[natural=%@][bbox=%@]", [values componentsJoinedByString:@"|"],boundingBoxString];
    [self loadPoisWithUrl:string];
}


- (void) loadTourismPoisWithBoundingBox:(NSString*)boundingBoxString
{
    NSArray *values = @[@"alpine_hut", @"attraction",@"camp_site",@"hostel",@"information",@"picnic_site",@"viewpoint",@"wilderness_hut"];
    NSString *string = [NSString stringWithFormat:@"http://overpass.osm.rambler.ru/cgi/xapi_meta?node[tourism=%@][bbox=%@]", [values componentsJoinedByString:@"|"],boundingBoxString];
    [self loadPoisWithUrl:string];
}


- (void)loadPoisWithUrl:(NSString *)urlString
{
    NSLog(@"String = %@", urlString);
    NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    NSLog(@"URL = %@", [url absoluteString]);
    NSURLRequest *request = [NSURLRequest requestWithURL:url];


    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];

    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSData *data = responseObject;
        NSError *error;

        ONOXMLDocument *document = [ONOXMLDocument XMLDocumentWithData:data error:&error];
        NSString *xPathString = @"//node";
        id xPath = [document functionResultByEvaluatingXPath:[NSString stringWithFormat:@"count(%@)",xPathString]];
        __block int resultCount = [xPath numericValue];

        if (resultCount > 0)
        {
            NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *docsDir = [dirPaths objectAtIndex:0];
            NSString *databasePath = [[NSString alloc] initWithString: [docsDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.xml", urlString]]];
            [data writeToFile:databasePath atomically:YES];

            [document enumerateElementsWithXPath:xPathString usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop) {
                //            NSLog(@"%@", element);
                PSPoi *poi= [[PSPoi alloc] initWithXmlData:element];
                dispatch_async(dispatch_get_main_queue(),^{
                    [self.pois insertObject:poi atIndex:[_pois count]];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"POIS_UPDATED" object:nil];
                });
            }];
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(),^{
                [[[UIAlertView alloc] initWithTitle:@"No POIs Found" message:@"" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
            });
        }


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

@end