//
//  TicketLine.m
//  OpenbravoPOSApp
//
//  Created by Axel Ruder on 13.04.11.
//  Copyright 2011 msg systems ag. All rights reserved.
//

#import "TicketLine.h"


@implementation TicketLine

@synthesize id;
@synthesize product;
@synthesize price;
@synthesize multiply;

- (void) dealloc 
{
    [product release];
    
    [super dealloc];
}
@end
