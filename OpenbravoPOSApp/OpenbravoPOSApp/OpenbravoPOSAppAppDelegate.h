//
//  OpenbravoPOSAppAppDelegate.h
//  OpenbravoPOSApp
//
//  Created by Axel Ruder on 28.03.11.
//  Copyright 2011 msg systems ag. All rights reserved.
//

#import <UIKit/UIKit.h>

 
@interface OpenbravoPOSAppAppDelegate : NSObject <UIApplicationDelegate> {

    NSDictionary* categoriesById;
    NSDictionary* productsById;
    NSDictionary* productsByCategory;
    
}

// maps category-ids to categories
@property(nonatomic, retain) NSDictionary *categoriesById;

// maps product-ids to products
@property(nonatomic, retain) NSDictionary *productsById;

// maps categories to an array of products
@property(nonatomic, retain) NSDictionary *productsByCategory;


@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;

// the base web application URL
+(NSString *) getWebAppURL;

// returns the only instance of OpenbravoPOSAppAppDelegate
+(OpenbravoPOSAppAppDelegate *) getInstance;

-(NSArray *) getCategoryList;

-(NSArray *) getProductListForCategoryIndex:(NSInteger)index;
@end
