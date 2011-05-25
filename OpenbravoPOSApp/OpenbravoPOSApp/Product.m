//
//  Product.m
//  OpenbravoPOSApp
//
//  Created by Axel Ruder on 10.04.11.
//  Copyright 2011 msg systems ag. All rights reserved.
//

#import "Product.h"


@implementation Product

@synthesize id;
@synthesize name;
@synthesize categoryId;
@synthesize attributes;
@synthesize options;
@synthesize price;

- (void)dealloc
{
    [name release];
    [categoryId release];
    [attributes release];
    [options release];
    [super dealloc];
}

@end
