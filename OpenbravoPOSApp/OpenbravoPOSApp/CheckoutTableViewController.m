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

    UIBarButtonItem *flexibleSpaceButtonItem = [[UIBarButtonItem alloc]
                                           initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                           target:nil action:nil];
    UIBarButtonItem *checkoutButtonItem = [[UIBarButtonItem alloc]
                                           initWithBarButtonSystemItem:UIBarButtonSystemItemPageCurl
                                           target:self action:nil];
    self.toolbarItems = [NSArray arrayWithObjects:flexibleSpaceButtonItem, checkoutButtonItem, nil];

    
    [[NSBundle mainBundle] loadNibNamed:@"SectionFooterView" owner:self options:nil];
    self.tableView.tableFooterView = footerView;
    sumLabel.text = [NSString stringWithFormat:@"%.2f €", sum];
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
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    TicketLine *line = [items objectAtIndex:indexPath.row];
    cell.textLabel.text = line.product.name;
    
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
        [selection addObject:indexPath];
        sum += line.price;
        
    } else if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        [selection removeObject:indexPath];
        sum -= line.price;
    }
    sumLabel.text = [NSString stringWithFormat:@"%.2f €", sum];
}

@end
