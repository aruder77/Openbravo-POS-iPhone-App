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
#import "TableSelectionViewController.h"


@interface TablesTableViewController : TableSelectionViewController {
    
    TableItemsTableViewController *tableItemsViewController;
    ProductSelectionTableViewController *productSelectViewController;
    
}

@end
