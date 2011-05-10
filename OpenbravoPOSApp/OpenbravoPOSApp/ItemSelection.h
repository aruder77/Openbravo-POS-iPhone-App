//
//  ItemSelection.h
//  OpenbravoPOSApp
//
//  Created by Axel Ruder on 30.04.11.
//  Copyright 2011 msg systems ag. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Product.h"


@interface ItemSelection : NSObject {
    
    Product *product;
    NSString *selectedOption;
    
}

@property (nonatomic, retain) Product *product;
@property (nonatomic, retain) NSString *selectedOption;

@end
