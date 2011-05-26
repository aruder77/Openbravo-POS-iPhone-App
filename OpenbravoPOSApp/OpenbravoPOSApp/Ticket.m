//
//  Ticket.m
//  OpenbravoPOSApp
//
//  Created by Axel Ruder on 13.04.11.
//  Copyright 2011 msg systems ag. All rights reserved.
//

#import "Ticket.h"


@implementation Ticket

@synthesize id;
@synthesize name;
@synthesize ticketLines;

- (void) dealloc 
{
    [name release];
    [ticketLines release];
    
    [super dealloc];
}

@end
