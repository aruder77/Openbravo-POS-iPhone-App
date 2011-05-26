//
//  CheckoutTableView.m
//  OpenbravoPOSApp
//
//  Created by Axel Ruder on 02.04.11.
//  Copyright 2011 msg systems ag. All rights reserved.
//

#import "CheckoutTableViewController.h"
#import "TicketLine.h"


@implementation CheckoutTableViewController

@synthesize ticket;
@synthesize footerView;
@synthesize finishedItems;
@synthesize items;
@synthesize selection;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id) initWithTicket:(Ticket *)pTicket {
    self = [super initWithNibName:@"CheckoutTableView" bundle:nil];
    if (self) {
        self.ticket = pTicket;
        selection = [[NSMutableArray alloc] init];
        finishedItems = [[NSMutableArray alloc] init];
        items = [[NSMutableArray arrayWithArray:ticket.ticketLines] retain];
    }
    return self;
}

- (void)dealloc
{
    [footerView release];
    [finishedItems release];
    [items release];
    [selection release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];    
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [selection removeAllObjects];
    sum = 0;
    
    UIBarButtonItem *selectAllItem = [[UIBarButtonItem alloc] initWithTitle:@"Alle" style:UIBarButtonItemStyleBordered target:self action:@selector(selectAllItems)];
    
    UIBarButtonItem *selectNoItem = [[UIBarButtonItem alloc] initWithTitle:@"Keine" style:UIBarButtonItemStyleBordered target:self action:@selector(selectNoItems)];
    
    UIBarButtonItem *flexibleSpaceButtonItem = [[UIBarButtonItem alloc]
                                           initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                           target:nil action:nil];
    UIBarButtonItem *checkoutButtonItem = [[UIBarButtonItem alloc]
                                           initWithBarButtonSystemItem:UIBarButtonSystemItemPageCurl
                                           target:self action:@selector(removeSelectedItems)];
    self.toolbarItems = [NSArray arrayWithObjects:selectAllItem, selectNoItem, flexibleSpaceButtonItem, checkoutButtonItem, nil];
    [flexibleSpaceButtonItem release];
    [checkoutButtonItem release];

    
    [[NSBundle mainBundle] loadNibNamed:@"SectionFooterView" owner:self options:nil];
    self.tableView.tableFooterView = footerView;
    sumLabel.text = [NSString stringWithFormat:@"%.2f €", sum];
}

- (void)updateSum
{
    sum = 0;
    for (int i = 0; i < [selection count]; i++) {
        TicketLine *line = [selection objectAtIndex:i];
        sum += line.price;
    }
    sumLabel.text = [NSString stringWithFormat:@"%.2f €", sum];    
}

- (void)selectAllItems
{
    [selection addObjectsFromArray:items];
    [self updateSum];
    [self.tableView reloadData];
}

- (void)selectNoItems
{
    [selection removeAllObjects];
    [self updateSum];
    [self.tableView reloadData];
}

- (void)removeSelectedItems
{
    [finishedItems addObjectsFromArray:selection];
    [items removeObjectsInArray:selection];
    [selection removeAllObjects];

    sum = 0;
    sumLabel.text = [NSString stringWithFormat:@"%.2f €", sum];
    [self.tableView reloadData];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
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
    return [items count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
    }
    TicketLine *line = [items objectAtIndex:indexPath.row];
    cell.textLabel.text = line.product.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%.2f €", line.price];
    
    if ([selection containsObject:line]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:NO];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    TicketLine *line = [items objectAtIndex:indexPath.row];
    if (cell.accessoryType == UITableViewCellAccessoryNone) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        [selection addObject:line];
        sum += line.price;
        
    } else if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        [selection removeObject:line];
        sum -= line.price;
    }
    sumLabel.text = [NSString stringWithFormat:@"%.2f €", sum];
}

@end
