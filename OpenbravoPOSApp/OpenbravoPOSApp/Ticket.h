//
//  Ticket.h
//  OpenbravoPOSApp
//
//  Created by Axel Ruder on 13.04.11.
//  Copyright 2011 msg systems ag. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Ticket : NSObject {
    
    NSString* id;
    NSString* name;
    
    NSMutableArray* ticketLines;
}

@property(nonatomic, retain) NSString* id;
@property(nonatomic, retain) NSString* name;
@property(nonatomic, retain) NSMutableArray* ticketLines;

@end
