//
//  ItemSelectionTableViewController.h
//  OpenbravoPOSApp
//
//  Created by Axel Ruder on 02.04.11.
//  Copyright 2011 msg systems ag. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OpenbravoPOSAppAppDelegate.h"
#import "Product.h"


@interface ItemSelectionTableViewController : UITableViewController <UIActionSheetDelegate> {
   
    NSMutableArray *newItems;
    
    Product *lastSelectedProduct;
    int itemCount;
    
    OpenbravoPOSAppAppDelegate *delegate;

}

@property(nonatomic,retain) NSMutableArray *newItems;



@end
