//
//  TablesViewController.h
//  OpenbravoPOSApp
//
//  Created by Axel Ruder on 02.04.11.
//  Copyright 2011 msg systems ag. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Table.h"

@interface TableSelectionViewController : UITableViewController {
    
    NSMutableData *responseData;
    
    NSMutableArray *tableArray;
    NSMutableArray *busyTables;
    
    UIImage *busyImage;
    UIImage *emptyImage;
    
    Table *selectedTable;
}

-(BOOL) isTableBusy:(Table *)table;

@property(nonatomic, retain) Table *selectedTable;

@end
