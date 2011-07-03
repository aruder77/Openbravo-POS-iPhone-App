//
//  OpenbravoPOSAppAppDelegate.m
//  OpenbravoPOSApp
//
//  Created by Axel Ruder on 28.03.11.
//  Copyright 2011 msg systems ag. All rights reserved.
//

#import "OpenbravoPOSAppAppDelegate.h"
#import "JSON.h"
#import "Category.h"
#import "Product.h"

@implementation OpenbravoPOSAppAppDelegate

@synthesize categoriesById;
@synthesize productsById;
@synthesize productsByCategory;
@synthesize topTenProducts;

@synthesize netActivityReqs;

@synthesize window=_window;

@synthesize navigationController=_navigationController;

static OpenbravoPOSAppAppDelegate *instance;


- (void) loadCategories
{
    NSString *baseUrl = [OpenbravoPOSAppAppDelegate getWebAppURL];
    NSString *url = [NSString stringWithFormat:@"%@/categories", baseUrl];
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    NSURLResponse *response;
    NSError *error = nil;
    
    [self requestNetworkActivityIndicator];
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];    
    [self releaseNetworkActivityIndicator];
    
    if (error != nil && [error code]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error loading categories!" message:@"Could not retrieve product categories from server!" delegate:self cancelButtonTitle:@"Abbrechen" otherButtonTitles:@"Wiederholen", nil];
        [alertView show];
    } else {
        NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        NSDictionary *results = [responseString JSONValue];
        [responseString release];
        
        self.categoriesById = [NSMutableDictionary dictionary];
        NSArray *localCategories = [results objectForKey:@"categoryInfo"];
        for (int i=0; i < [localCategories count]; i++) {
            NSDictionary* categoriesDict = [localCategories objectAtIndex:i];
            Category* category = [[Category alloc] init];
            category.id = [categoriesDict objectForKey:@"id"];
            category.name = [[categoriesDict objectForKey:@"name"] substringFromIndex:2];
            [categoriesById setValue:category forKey:category.id];
            [category release];
        }
    }

}

-(NSArray *) getTopTenProductList:(NSDictionary *)topTenDictionary {
    NSArray *keyList = [topTenDictionary allKeys];
    NSArray *sortedArray = [keyList sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    NSMutableArray *productsArray = [[[NSMutableArray alloc] init] autorelease];
    for (id object in sortedArray) {
        [productsArray addObject:[topTenDictionary valueForKey:object]];
    }
    return productsArray;
}

- (void) loadProducts
{
    if ([categoriesById count] == 0) {
        [self loadCategories];
    }
    
    NSString *baseUrl = [OpenbravoPOSAppAppDelegate getWebAppURL];
    NSURLResponse *response;
    NSError *error = nil;
    
    NSString *productUrl = [NSString stringWithFormat:@"%@/products", baseUrl];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:productUrl]];
    [self requestNetworkActivityIndicator];
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    [self releaseNetworkActivityIndicator];
    
    if (error != nil && [error code]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error loading products!" message:@"Could not retrieve products from server!" delegate:self cancelButtonTitle:@"Abbrechen" otherButtonTitles:@"Wiederholen", nil];
        [alertView show];
    } else {
        NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        NSDictionary *results = [responseString JSONValue];
        [responseString release];
        
        self.productsById = [NSMutableDictionary dictionary];
        self.productsByCategory = [NSMutableDictionary dictionary];
        
        NSArray *localProducts = [results objectForKey:@"productInfo"];
        
        NSMutableDictionary *topTenProductDict = [[NSMutableDictionary alloc] init];
        
        for (int i=0; i < [localProducts count]; i++) {
            NSDictionary* productsDict = [localProducts objectAtIndex:i];
            Product* product = [[Product alloc] init];
            product.id = [productsDict objectForKey:@"id"];
            product.name = [productsDict objectForKey:@"name"];
            product.categoryId = [productsDict objectForKey:@"categoryId"];
            
            NSDictionary *attrDict = [productsDict objectForKey:@"attributes"];
            product.attributes = [[[NSMutableDictionary alloc] init ] autorelease];
            product.options = [[[NSMutableArray alloc] init] autorelease];
            
            if (attrDict != nil) {
                id entryDict = [attrDict objectForKey:@"entry"];
                if (entryDict != nil) {
                    NSArray *entries;
                    if ([entryDict isKindOfClass:[NSDictionary class]]) {
                        entries = [[NSMutableArray alloc] init];
                        [(NSMutableArray *)entries addObject:entryDict];
                    } else {
                        entries = entryDict;
                        [entries retain];
                    }
                    for (int i = 0; i < [entries count]; i++) {
                        NSDictionary *entry = [entries objectAtIndex:i];
                        NSDictionary *keyEntry = [entry objectForKey:@"key"];
                        NSString *key = [keyEntry objectForKey:@"$"];
                        
                        NSDictionary *valueEntry = [entry objectForKey:@"value"];
                        NSString *value = [valueEntry objectForKey:@"$"];
                        
                        if ([[key substringToIndex:[@"option" length]] isEqualToString:@"option"])
                        {
                            [product.options addObject:value];
                        } else if ([key isEqualToString:@"topTenPosition"]) {
                            [topTenProductDict setValue:product forKey:value];
                        } else {
                            [product.attributes setValue:value forKey:key];
                        }
                    }
                    [entries release];
                }
            }
                        
            [productsById setValue:product forKey:product.id];
            Category* category = [categoriesById objectForKey:product.categoryId];
            NSMutableArray* array = [productsByCategory objectForKey:category.id];
            if (array == nil) {
                array = [[NSMutableArray array] retain];
                [productsByCategory setValue:array forKey:category.id];
                [array release];
            }
            [array addObject:product];
            [product release];
        }
        self.topTenProducts = [self getTopTenProductList:topTenProductDict];
        [topTenProductDict release];
    }
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    NSString *alertTitle = [alertView title];
    if ([alertTitle isEqualToString:@"Error loading categories!"]) {
        if([title isEqualToString:@"Wiederholen"]) {
            [self loadCategories];
        }
    } else {
        if([title isEqualToString:@"Wiederholen"]) {
            [self loadProducts];
        }
    }
    [alertView release];
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    instance = self;
    
    netActivityReqs = 0;
    
    [self loadCategories];

    [self loadProducts];
    
    
    // Override point for customization after application launch.
    // Add the navigation controller's view to the window and display.
    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

- (void)dealloc
{
    [categoriesById release];
    [productsById release];
    [productsByCategory release];
    [_window release];
    [_navigationController release];
    [super dealloc];
}


+(NSString *) getWebAppURL {
    return @"http://192.168.178.102:8080/pda/resources";
}
    
+(OpenbravoPOSAppAppDelegate *) getInstance {
    return instance;
}

-(NSArray *) getCategoryList {
    NSArray *list = [categoriesById allValues];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name"
                                                  ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray *sortedArray = [list sortedArrayUsingDescriptors:sortDescriptors];
    [sortDescriptor release];
    
    Category *topTenCategory = [[Category alloc] init];
    topTenCategory.name = @"Top Ten";
    NSMutableArray *categories = [NSMutableArray arrayWithCapacity:([sortedArray count] + 1)];
    [categories addObject:topTenCategory];
    [topTenCategory release];
    [categories addObjectsFromArray:sortedArray];
    
    return categories;
}

-(NSArray *) getProductListForCategoryIndex:(NSInteger)index {
    if (index == 0) {
        return self.topTenProducts;
    }
    Category* cat = [[self getCategoryList] objectAtIndex:index];
    return [productsByCategory objectForKey:cat.id];
}

-(void) requestNetworkActivityIndicator {
	UIApplication* app = [UIApplication sharedApplication];
	app.networkActivityIndicatorVisible = YES;
    
	self.netActivityReqs++;
}

-(void) releaseNetworkActivityIndicator {
    
	self.netActivityReqs--;
	if(self.netActivityReqs <= 0)
	{
		UIApplication* app = [UIApplication sharedApplication];
		app.networkActivityIndicatorVisible = NO;
	}
    
	//failsafe
	if(self.netActivityReqs < 0)
		self.netActivityReqs = 0;
}

@end
