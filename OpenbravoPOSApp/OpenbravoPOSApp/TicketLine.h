//
//  TicketLine.h
//  OpenbravoPOSApp
//
//  Created by Axel Ruder on 13.04.11.
//  Copyright 2011 msg systems ag. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Product.h"


@interface TicketLine : NSObject {
    NSString* id;
    Product *product;
    float multiply;
    float price;
}

@property(nonatomic, retain) NSString *id;
@property(nonatomic, retain) Product *product;
@property(nonatomic, assign) float multiply;
@property(nonatomic, assign) float price;

@end
