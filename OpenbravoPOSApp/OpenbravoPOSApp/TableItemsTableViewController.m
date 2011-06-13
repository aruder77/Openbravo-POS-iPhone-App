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
#import <AudioToolbox/AudioToolbox.h>

@implementation TableItemsTableViewController

@synthesize table;
@synthesize tableViewCell;
@synthesize headerView;
@synthesize footerView;
@synthesize addedItems;

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
        UIBarButtonItem *addButtonItem = [[UIBarButtonItem alloc]
                                                    initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                    target:self action:@selector(addItems)];
        UIBarButtonItem *flexibleSpaceButtonItem = [[UIBarButtonItem alloc]
                                                   initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                   target:nil action:nil];
        
        
        UIImage *mailImage = [UIImage imageNamed:@"icon_mail.png"];
        UIButton *mailButton = [UIButton buttonWithType:UIButtonTypeCustom];
        mailButton.bounds = CGRectMake( 0, 0, mailImage.size.width, mailImage.size.height );    
        [mailButton setImage:mailImage forState:UIControlStateNormal];
        [mailButton addTarget:self action:@selector(sendItems) forControlEvents:UIControlEventTouchUpInside];    
        UIBarButtonItem *sendItemsButtonItem = [[UIBarButtonItem alloc] initWithCustomView:mailButton];
        
        UIImage *checkoutImage = [UIImage imageNamed:@"icon_dollar.png"];
        UIButton *checkoutButton = [UIButton buttonWithType:UIButtonTypeCustom];
        checkoutButton.bounds = CGRectMake( 0, 0, checkoutImage.size.width, checkoutImage.size.height );    
        [checkoutButton setImage:checkoutImage forState:UIControlStateNormal];
        [checkoutButton addTarget:self action:@selector(checkout) forControlEvents:UIControlEventTouchUpInside];    
        UIBarButtonItem *checkoutButtonItem = [[UIBarButtonItem alloc] initWithCustomView:checkoutButton];
        
        self.toolbarItems = [NSArray arrayWithObjects:checkoutButtonItem, flexibleSpaceButtonItem, sendItemsButtonItem, flexibleSpaceButtonItem, addButtonItem, nil];
        
        addedItems = [[NSMutableArray alloc] init];
        
        UIImage *moveImage = [UIImage imageNamed:@"icon_shopping_heavy.png"];
        UIButton *moveButton = [UIButton buttonWithType:UIButtonTypeCustom];
        moveButton.bounds = CGRectMake( 0, 0, moveImage.size.width, moveImage.size.height );    
        [moveButton setImage:moveImage forState:UIControlStateNormal];
        [moveButton addTarget:self action:@selector(moveTable) forControlEvents:UIControlEventTouchUpInside];    
        UIBarButtonItem *moveTableButtonItem = [[UIBarButtonItem alloc] initWithCustomView:moveButton];

        self.navigationItem.rightBarButtonItem = moveTableButtonItem;
        
        
        [self.tableView beginUpdates];
        [self.tableView setEditing:YES];
        [self.tableView endUpdates];
        
        [addButtonItem release];
        [flexibleSpaceButtonItem release];
        [sendItemsButtonItem release];
        [checkoutButtonItem release];
        [moveTableButtonItem release];
    }
    return self;
}


- (void)dealloc
{
    [table release];
    [tableViewCell release];
    [headerView release];
    [footerView release];
    [addedItems release];
    
    [addedItems release];
    [itemSelectViewController release];
    [checkoutViewController release];
    [tableSelectionViewController release];
    [sumLabel release];
    [super dealloc];
}

- (void) moveTable
{
    if (tableSelectionViewController == nil) {
        tableSelectionViewController = [[TableSelectionViewController alloc] initWithNibName:@"TablesViewController" bundle:nil];
        tableSelectionViewController.title = @"Tisch auswählen";
        tableSelectionViewController.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelTableSelection)] autorelease];
        tableSelectionViewController.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(saveTableSelection)] autorelease]; 
    }

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:tableSelectionViewController];
    [self.navigationController presentModalViewController:navController animated:YES];
    [navController release];    
}

- (void) cancelTableSelection 
{
    [self dismissModalViewControllerAnimated:YES];
    NSLog(@"cancelTableSelection");
}

- (void) saveTableSelection
{
    Table *selectedTable = tableSelectionViewController.selectedTable;
    if (selectedTable != nil) {
        if ([tableSelectionViewController isTableBusy:tableSelectionViewController.selectedTable]) {
            // ask if tables should be merged
        }
        
        NSString *baseUrl = [OpenbravoPOSAppAppDelegate getWebAppURL];
        NSString *url = [NSString stringWithFormat:@"%@/tickets/moveTicket?fromTable=%@&toTable=%@", baseUrl, self.table.id, selectedTable.id];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
        
        [request setHTTPMethod:@"DELETE"];
        NSURLResponse *response = nil;
        NSError *error = nil;
        [[OpenbravoPOSAppAppDelegate getInstance] requestNetworkActivityIndicator];
        [NSURLConnection sendSynchronousRequest:request
                              returningResponse:&response error:&error];
        [[OpenbravoPOSAppAppDelegate getInstance] releaseNetworkActivityIndicator];
        
    }
    
    [self dismissModalViewControllerAnimated:YES];    
    [self.navigationController popViewControllerAnimated:NO];
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
    [[OpenbravoPOSAppAppDelegate getInstance] requestNetworkActivityIndicator];
	[NSURLConnection sendSynchronousRequest:request
                          returningResponse:&response error:&error];
    [[OpenbravoPOSAppAppDelegate getInstance] releaseNetworkActivityIndicator];

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
        [addedItems removeAllObjects];
        [self.navigationController popViewControllerAnimated:YES];
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
    navController.toolbarHidden = NO;
    [self.navigationController presentModalViewController:navController animated:YES];
    [navController release];
}

- (void)checkout
{
    checkoutViewController = [[CheckoutTableViewController alloc] initWithTicket:ticket];
    checkoutViewController.title = @"Bezahlen";
    checkoutViewController.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelItemSelection)] autorelease];
    checkoutViewController.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeTicket)] autorelease]; 
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:checkoutViewController];
    navController.toolbarHidden = NO;
    [self.navigationController presentModalViewController:navController animated:YES];
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

- (void)cancelItemSelection
{
    itemSelectViewController.newItems = nil;
    if (checkoutViewController != nil) {
        [checkoutViewController release];
        checkoutViewController = nil;
    }
    
    [self dismissModalViewControllerAnimated:YES];
}

- (void)postTicketUpdateToURL:(NSString *) url forTicket:(NSString *) ticketId withProducts:( NSArray *) productIds withErrorMsg:(NSString *) errorMsg {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc] init];
    
    [jsonObject setValue:productIds forKey:@"productIds"];
    [jsonObject setValue:ticketId forKey:@"ticketId"];
    
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
    [[OpenbravoPOSAppAppDelegate getInstance] requestNetworkActivityIndicator];
	[NSURLConnection sendSynchronousRequest:request
                                         returningResponse:&response error:&error];
    [[OpenbravoPOSAppAppDelegate getInstance] releaseNetworkActivityIndicator];
    
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
            [self postTicketUpdateToURL:url forTicket:ticketId withProducts:productIds withErrorMsg:errorMsg];
        };

        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Error!" message:errorMsg cancelButtonItem:cancelButton otherButtonItems:repeatButton, nil] autorelease];
        
        [alert show];
    } else {
        itemSelectViewController.newItems = nil;
        [self dismissModalViewControllerAnimated:YES];    
    }
}

- (void)closeTicket
{    
    [self dismissModalViewControllerAnimated:YES];
    
    NSString *baseUrl = [OpenbravoPOSAppAppDelegate getWebAppURL];
    NSString *url = [NSString stringWithFormat:@"%@/tickets/closeTicketForItems", baseUrl];
    [checkoutViewController removeSelectedItems];
    if ([checkoutViewController.items count] > 0) {
        NSMutableArray *products = [[NSMutableArray alloc] init ];
        for (int i = 0; i < [checkoutViewController.finishedItems count]; i++) {
            TicketLine *line = [checkoutViewController.finishedItems objectAtIndex:i];
            [products addObject:[line product].id];
        }
        [self postTicketUpdateToURL:url forTicket:table.id withProducts:products withErrorMsg:@"Das Ticket konnte nicht abgeschlossen werden!"];    
        [products release];
        [self updateTicket];
        [self.tableView reloadData];
    } else {    
        url = [NSString stringWithFormat:@"%@/tickets/closeTicket?place=%@", baseUrl, self.table.id];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
        
        [request setHTTPMethod:@"DELETE"];
        NSURLResponse *response = nil;
        NSError *error = nil;
        [[OpenbravoPOSAppAppDelegate getInstance] requestNetworkActivityIndicator];
        [NSURLConnection sendSynchronousRequest:request
                              returningResponse:&response error:&error];
        [[OpenbravoPOSAppAppDelegate getInstance] releaseNetworkActivityIndicator];

        [self.navigationController popViewControllerAnimated:NO];
    }
    
    [checkoutViewController release];
    checkoutViewController = nil;    
    
    [addedItems removeAllObjects];
}


- (void)saveItemSelection
{
    NSMutableArray *ticketsArray = [[NSMutableArray alloc] init ];
    
    for (int i = 0; i < [itemSelectViewController.newItems count]; i++) {
        ItemSelection *itemSelection = [itemSelectViewController.newItems objectAtIndex:i];
        Product *product = [itemSelection product];
        NSString *idWithOption = [NSString stringWithFormat:@"%@#%@", product.id, itemSelection.selectedOption];
        [ticketsArray addObject:idWithOption];
        [addedItems addObject:product];
    }
    
    NSString *baseUrl = [OpenbravoPOSAppAppDelegate getWebAppURL];
    NSString *url = [NSString stringWithFormat:@"%@/tickets/ticketProducts", baseUrl];
    [self postTicketUpdateToURL:url forTicket:table.id withProducts:ticketsArray withErrorMsg:@"Die Produkte konnten nicht hinzugefügt werden!"];
    
    [ticketsArray release];
}
     



-(void)updateTicket
{
    NSString *baseUrl = [OpenbravoPOSAppAppDelegate getWebAppURL];
    NSString *url = [NSString stringWithFormat:@"%@/tickets/ticket?place=%@", baseUrl, table.id];
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    NSURLResponse *response;
    NSError *error = nil;
    [[OpenbravoPOSAppAppDelegate getInstance] requestNetworkActivityIndicator];
	NSData *data = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:&response error:&error];
    [[OpenbravoPOSAppAppDelegate getInstance] releaseNetworkActivityIndicator];
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
        ticket = nil;
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
    self.navigationController.toolbarHidden = NO;

    [super viewWillAppear:animated];
    [addedItems removeAllObjects];
    [self updateTicket];
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self becomeFirstResponder];
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
    int c = [ticket.ticketLines count];
    return c;
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
    [[OpenbravoPOSAppAppDelegate getInstance] requestNetworkActivityIndicator];
	[NSURLConnection sendSynchronousRequest:request
                          returningResponse:&response error:&error];
    [[OpenbravoPOSAppAppDelegate getInstance] releaseNetworkActivityIndicator];
    
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

#pragma mark - UIResponder

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    /*
    //Get the filename of the sound file:
    NSString *path = [[NSBundle mainBundle] pathForResource:@"cash" ofType:@"wav"];
    
	//declare a system sound id
	SystemSoundID soundID;
    
	//Get a URL for the sound file
	NSURL *filePath = [NSURL fileURLWithPath:path isDirectory:NO];
    
	//Use audio sevices to create the sound
	AudioServicesCreateSystemSoundID((CFURLRef)filePath, &soundID);
    
	//Use audio services to play the sound
	AudioServicesPlaySystemSound(soundID);
    
    [self checkout];
     */
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
}

- (void)motionCancelled:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
}

@end
