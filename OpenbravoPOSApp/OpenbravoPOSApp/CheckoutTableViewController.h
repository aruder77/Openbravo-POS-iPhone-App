//
//  CheckoutTableView.h
//  OpenbravoPOSApp
//
//  Created by Axel Ruder on 02.04.11.
//  Copyright 2011 msg systems ag. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Ticket.h"


@interface CheckoutTableViewController : UITableViewController {
    
    Ticket *ticket;
    
    NSMutableArray *items;
    NSMutableArray *selection;
    NSMutableArray *finishedItems;
    
    float sum;
    
    IBOutlet UIView *footerView;
    IBOutlet UILabel *sumLabel;
}

@property(nonatomic, retain) Ticket *ticket;

@property(nonatomic, retain) IBOutlet UIView *footerView;

@property(nonatomic, retain) NSMutableArray *finishedItems;

@property(nonatomic, retain) NSMutableArray *items;

@property(nonatomic, retain) NSMutableArray *selection;

- (id) initWithTicket:(Ticket *)ticket;

- (void)removeSelectedItems;

@end
