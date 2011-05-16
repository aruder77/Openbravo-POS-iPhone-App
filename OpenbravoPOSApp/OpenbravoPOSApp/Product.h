//
//  Product.h
//  OpenbravoPOSApp
//
//  Created by Axel Ruder on 10.04.11.
//  Copyright 2011 msg systems ag. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Product : NSObject {
    
    NSString* id;
    NSString* name;
    NSString* categoryId;
    NSMutableDictionary *attributes;
    NSMutableArray *options;
    double price;
}

@property(nonatomic, retain) NSString* id;
@property(nonatomic, retain) NSString* name;
@property(nonatomic, retain) NSString* categoryId;
@property(nonatomic, retain) NSMutableDictionary* attributes;
@property(nonatomic, retain) NSMutableArray *options;
@property(nonatomic, assign) double price;

@end
