//
//  TablesViewController.h
//  OpenbravoPOSApp
//
//  Created by Axel Ruder on 02.04.11.
//  Copyright 2011 msg systems ag. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TableItemsTableViewController.h"
#import "ProductSelectionTableViewController.h"


@interface TablesTableViewController : UITableViewController {
    
    NSMutableData *responseData;
    
    NSMutableArray *tableArray;
    NSMutableArray *busyTables;
    
    TableItemsTableViewController *tableItemsViewController;
    ProductSelectionTableViewController *productSelectViewController;
    
    UIImage *busyImage;
    UIImage *emptyImage;
}

-(BOOL) isTableBusy:(Table *)table;

@end
