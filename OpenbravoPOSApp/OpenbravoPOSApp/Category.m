//
//  Category.m
//  OpenbravoPOSApp
//
//  Created by Axel Ruder on 09.04.11.
//  Copyright 2011 msg systems ag. All rights reserved.
//

#import "Category.h"


@implementation Category


@synthesize id;
@synthesize name;

- (void)dealloc
{
    [name release];
    [super dealloc];
}

@end
