//
//  ItemSelection.m
//  OpenbravoPOSApp
//
//  Created by Axel Ruder on 30.04.11.
//  Copyright 2011 msg systems ag. All rights reserved.
//

#import "ItemSelection.h"


@implementation ItemSelection

@synthesize product;
@synthesize selectedOption;

- (void) dealloc 
{
    [product release];
    [selectedOption release];
}
@end
