//
//  TableItemsViewController.m
//  OpenbravoPOSApp
//
//  Created by Axel Ruder on 02.04.11.
//  Copyright 2011 msg systems ag. All rights reserved.
//

#import "TableItemsTableViewController.h"
#import "ItemDetailsViewController.h"
#import "ItemSelectionTableViewController.h"
#import "CheckoutTableViewController.h"
#import "JSON.h"
#import "OpenbravoPOSAppAppDelegate.h"
#import "Ticket.h"
#import "TicketLine.h"
#import "ItemSelection.h"
#import "UIAlertView+Blocks.h"

@implementation TableItemsTableViewController

@synthesize table;
@synthesize tableViewCell;
@synthesize headerView;
@synthesize footerView;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)init
{
    self = [super initWithNibName:@"TableItemsViewController" bundle:nil];
    if (self) {
//        self.navigationItem.rightBarButtonItem = self.editButtonItem;
        
        UIBarButtonItem *addButtonItem = [[UIBarButtonItem alloc]
                                                    initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                    target:self action:@selector(addItems)];
        UIBarButtonItem *flexibleSpaceButtonItem = [[UIBarButtonItem alloc]
                                                   initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                   target:nil action:nil];
        UIBarButtonItem *sendItemsButtonItem = [[UIBarButtonItem alloc]
                                               initWithBarButtonSystemItem:UIBarButtonSystemItemReply
                                               target:self action:@selector(sendItems)];
        UIBarButtonItem *checkoutButtonItem = [[UIBarButtonItem alloc]
                                          initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize
                                          target:self action:@selector(checkout)];
        self.toolbarItems = [NSArray arrayWithObjects:checkoutButtonItem, flexibleSpaceButtonItem, sendItemsButtonItem, flexibleSpaceButtonItem, addButtonItem, nil];
        
        addedItems = [[NSMutableArray alloc] init];
        
        [self.tableView beginUpdates];
        [self.tableView setEditing:YES];
        [self.tableView endUpdates];
        
        [addButtonItem release];
        [flexibleSpaceButtonItem release];
        [sendItemsButtonItem release];
        [checkoutButtonItem release];
    }
    return self;
}


- (void)dealloc
{
    [addedItems release];
    [itemSelectViewController release];
    [sumLabel release];
    [super dealloc];
}

- (NSError *)prepareSendItems
{
    NSString *baseUrl = [OpenbravoPOSAppAppDelegate getWebAppURL];
    NSString *url = [NSString stringWithFormat:@"%@/tickets/sendTicketProducts", baseUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc] init];
    
    NSMutableArray *addedItemsIds = [[NSMutableArray alloc] init ];
    for (int i = 0; i < [addedItems count]; i++) {
        Product *product = [addedItems objectAtIndex:i];
        [addedItemsIds addObject:product.id];
    }
    
    [jsonObject setValue:addedItemsIds forKey:@"productIds"];
    [jsonObject setValue:table.id forKey:@"ticketId"];
    [addedItemsIds release];
    
    SBJsonWriter *writer = [[SBJsonWriter alloc] init];
    NSData *data = [writer dataWithObject:jsonObject];
    [jsonObject release];
    [writer release];
    
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:data];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSString *dataLengthString = [[NSString alloc] initWithFormat:@"%d", [data length]];
    [request setValue:dataLengthString forHTTPHeaderField:@"Content-Length"];
    [dataLengthString release];
    
    NSURLResponse *response;
    NSError *error = nil;
	[NSURLConnection sendSynchronousRequest:request
                          returningResponse:&response error:&error];

    return error;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    if([title isEqualToString:@"Wiederholen"]) {
        NSError *error = [self prepareSendItems];
        if (error != nil && [error code]) {
            UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Error!" message:@"Die Bestellung konnte nicht versendet werden!" delegate:self cancelButtonTitle:@"Abbrechen" otherButtonTitles:@"Wiederholen", nil] autorelease];
            [alert show];
        } else {
            UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Erfolgreich" message:@"Die Bestellung wurde erfolgreich versandt!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
            [alert show];
            
            [addedItems removeAllObjects];
        }
    } else {
        NSString *msg = @"Folgende Items wurden nicht versand:";
        for (int i = 0; i < [addedItems count]; i++) {
            Product *selection = [addedItems objectAtIndex:i];
            NSString *oldStr = msg;
            NSString *productName = selection.name;
            msg = [NSString stringWithFormat:@"%@\n%@", oldStr, productName];
        }
        
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Nicht versendet!" message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
        [alert show];
    }
}

- (void)sendItems
{
    NSError *error = [self prepareSendItems];
    
    if (error != nil && [error code]) {
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Error!" message:@"Die Bestellung konnte nicht versendet werden!" delegate:self cancelButtonTitle:@"Abbrechen" otherButtonTitles:@"Wiederholen", nil] autorelease];
        [alert show];
    } else {
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Erfolgreich" message:@"Die Bestellung wurde erfolgreich versandt!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
        [alert show];
        
        [addedItems removeAllObjects];
    }
}

- (void)addItems
{
    if (itemSelectViewController == nil) {
        itemSelectViewController = [[ItemSelectionTableViewController alloc] initWithNibName:@"ItemSelectionTableViewController" bundle:nil];
        itemSelectViewController.title = @"Artikel hinzufügen";
        itemSelectViewController.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelItemSelection)] autorelease];
        itemSelectViewController.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveItemSelection)] autorelease]; 
    }
    NSMutableArray *itemArray = [[NSMutableArray alloc] init];
    itemSelectViewController.newItems = itemArray;
    [itemArray release];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:itemSelectViewController];
    [self.navigationController presentModalViewController:navController animated:YES];
    [navController release];
}

- (void)checkout
{
    CheckoutTableViewController *checkoutViewController = [[CheckoutTableViewController alloc] initWithTicket:ticket];
    checkoutViewController.title = @"Bezahlen";
    checkoutViewController.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelItemSelection)] autorelease];
    checkoutViewController.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeTicket)] autorelease]; 
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:checkoutViewController];
    [self.navigationController presentModalViewController:navController animated:YES];
    [checkoutViewController release];
    [navController release];
}

- (void)prepareForTable:(Table *) pTable 
{
    self.table = pTable;
    self.title = [NSString stringWithFormat:@"Tisch %@", pTable.name];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)closeTicket
{
    [self dismissModalViewControllerAnimated:YES];
    
    NSString *baseUrl = [OpenbravoPOSAppAppDelegate getWebAppURL];
    NSString *url = [NSString stringWithFormat:@"%@/tickets/closeTicket?place=%@", baseUrl, self.table.id];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    [request setHTTPMethod:@"DELETE"];
    NSURLResponse *response;
    NSError *error;
    [NSURLConnection sendSynchronousRequest:request
                          returningResponse:&response error:&error];
    
    
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)cancelItemSelection
{
    itemSelectViewController.newItems = nil;
    
    [self dismissModalViewControllerAnimated:YES];
}

- (void)saveItemSelection {
    NSString *baseUrl = [OpenbravoPOSAppAppDelegate getWebAppURL];
    NSString *url = [NSString stringWithFormat:@"%@/tickets/ticketProducts", baseUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc] init];
    NSMutableArray *ticketsArray = [[NSMutableArray alloc] init ];
    
    for (int i = 0; i < [itemSelectViewController.newItems count]; i++) {
        ItemSelection *itemSelection = [itemSelectViewController.newItems objectAtIndex:i];
        Product *product = [itemSelection product];
        NSString *idWithOption = [NSString stringWithFormat:@"%@#%@", product.id, itemSelection.selectedOption];
        [ticketsArray addObject:idWithOption];
        [addedItems addObject:product];
    }
    
    [jsonObject setValue:ticketsArray forKey:@"productIds"];
    [jsonObject setValue:table.id forKey:@"ticketId"];
    [ticketsArray release];
    
    SBJsonWriter *writer = [[SBJsonWriter alloc] init];
    NSData *data = [writer dataWithObject:jsonObject];
    [jsonObject release];
    [writer release];
    
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:data];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSString *dataLengthString = [[NSString alloc] initWithFormat:@"%d", [data length]];
    [request setValue:dataLengthString forHTTPHeaderField:@"Content-Length"];
    [dataLengthString release];
    
    NSURLResponse *response;
    NSError *error = nil;
	[NSURLConnection sendSynchronousRequest:request
                                         returningResponse:&response error:&error];
    
    if (error != nil && [error code]) {
        RIButtonItem *cancelButton = [[RIButtonItem alloc] init];
        cancelButton.label = @"Abbrechen";
        cancelButton.action = ^
        {
            // do nothing
        };
        
        RIButtonItem *repeatButton = [[RIButtonItem alloc] init];
        repeatButton.label = @"Wiederholen";
        repeatButton.action = ^
        {
            [self saveItemSelection];
        };

        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Error!" message:@"Die Produkte konnten nicht hinzugefügt werden!" cancelButtonItem:cancelButton otherButtonItems:repeatButton, nil] autorelease];
        
        [alert show];
    } else {
        itemSelectViewController.newItems = nil;
        [self dismissModalViewControllerAnimated:YES];    
    }
}


-(void)updateTicket
{
    NSString *baseUrl = [OpenbravoPOSAppAppDelegate getWebAppURL];
    NSString *url = [NSString stringWithFormat:@"%@/tickets/ticket?place=%@", baseUrl, table.id];
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    NSURLResponse *response;
    NSError *error = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:&response error:&error];
    if (error != nil && [error code]) {
        RIButtonItem *cancelButton = [[RIButtonItem alloc] init];
        cancelButton.label = @"Abbrechen";
        cancelButton.action = ^
        {
            // do nothing
        };
        
        RIButtonItem *repeatButton = [[RIButtonItem alloc] init];
        repeatButton.label = @"Wiederholen";
        repeatButton.action = ^
        {
            [self updateTicket];
        };
        
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Error!" message:@"Das Ticket konnte nicht aktualisiert werden!" cancelButtonItem:cancelButton otherButtonItems:repeatButton, nil] autorelease];
        
        [alert show];
    } else {
        NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"Response: %@", responseString);
        
        NSDictionary *results = [responseString JSONValue];
        [responseString release];
        [self readTicket:results];
    }
}



#pragma mark - View lifecycle

-(void)readTicket:(NSDictionary*) dict
{
    if (ticket != nil) {
        [ticket release];
    }
    sum = 0;
    ticket = [[Ticket alloc] init];
    ticket.id = [dict objectForKey:@"id"];
    ticket.name = [dict objectForKey:@"ticketId"];
    NSMutableArray *ticketLines = [[NSMutableArray alloc] init];
    id linesId = [dict objectForKey:@"m_aLines"];
    NSArray *lines = linesId;
    if ([linesId isKindOfClass:[NSDictionary class]]) {
        NSMutableArray *localLines = [[[NSMutableArray alloc] init] autorelease];
        [localLines addObject:linesId];
        lines = localLines;
    }
    for (int i = 0; i < [lines count]; i++) {
        NSDictionary *line = [lines objectAtIndex:i];
        TicketLine *ticketLine = [[TicketLine alloc] init];
        ticketLine.id = [line objectForKey:@"m_iLine"];
        
        NSString *productId = [line objectForKey:@"productid"];
        Product *product = [[OpenbravoPOSAppAppDelegate getInstance].productsById objectForKey:productId];
        ticketLine.product = product;
        ticketLine.price = [[line objectForKey:@"price"] floatValue];
        ticketLine.multiply = [[line objectForKey:@"multiply"] floatValue];
        sum += ticketLine.price * ticketLine.multiply;
        [ticketLines addObject:ticketLine];
        [ticketLine release];
    }
    ticket.ticketLines = ticketLines;
    [ticketLines release];
    sumLabel.text = [NSString stringWithFormat:@"%.2f €", sum];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSBundle mainBundle] loadNibNamed:@"SectionFooterView" owner:self options:nil];
    self.tableView.tableFooterView = footerView;
    
//    [[NSBundle mainBundle] loadNibNamed:@"SwitchTableTableHeader" owner:self options:nil];
//    self.tableView.tableHeaderView = headerView;
}

- (void)viewDidUnload
{
    [sumLabel release];
    sumLabel = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateTicket];
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [ticket.ticketLines count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    TicketLine *line = [ticket.ticketLines objectAtIndex:indexPath.row];
    cell.textLabel.text = line.product.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%.2f €", line.price];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [self deleteRowAtIndexPath:indexPath];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
}

- (void)deleteRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *baseUrl = [OpenbravoPOSAppAppDelegate getWebAppURL];
    NSString *url = [NSString stringWithFormat:@"%@/tickets/deleteTicketProducts", baseUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc] init];
    NSMutableArray *ticketsArray = [[NSMutableArray alloc] init ];
    TicketLine *line = [ticket.ticketLines objectAtIndex:indexPath.row];
    [ticketsArray addObject:line.product.id];
    [addedItems removeObject:line.product];
    
    [jsonObject setValue:ticketsArray forKey:@"productIds"];
    [jsonObject setValue:table.id forKey:@"ticketId"];
    [ticketsArray release];
    
    SBJsonWriter *writer = [[SBJsonWriter alloc] init];
    NSData *data = [writer dataWithObject:jsonObject];
    [jsonObject release];
    [writer release];
    
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:data];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSString *dataLengthString = [[NSString alloc] initWithFormat:@"%d", [data length]];
    [request setValue:dataLengthString forHTTPHeaderField:@"Content-Length"];
    [dataLengthString release];
    
    NSURLResponse *response;
    NSError *error = nil;
	[NSURLConnection sendSynchronousRequest:request
                          returningResponse:&response error:&error];
    
    if (error != nil && [error code]) {
        RIButtonItem *cancelButton = [[RIButtonItem alloc] init];
        cancelButton.label = @"Abbrechen";
        cancelButton.action = ^
        {
            // do nothing
        };
        
        RIButtonItem *repeatButton = [[RIButtonItem alloc] init];
        repeatButton.label = @"Wiederholen";
        repeatButton.action = ^
        {
            [self deleteRowAtIndexPath:indexPath];
        };
        
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Error!" message:@"Die Produkte konnten nicht gelöscht werden!" cancelButtonItem:cancelButton otherButtonItems:repeatButton, nil] autorelease];
        
        [alert show];
    } else {
        [self updateTicket];
    }
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//     ItemDetailsViewController *detailViewController = [[ItemDetailsViewController
//                                                    alloc] initWithNibName:@"ItemDetailsViewController" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
//     [self.navigationController pushViewController:detailViewController animated:YES];
//     [detailViewController release];
}

@end
