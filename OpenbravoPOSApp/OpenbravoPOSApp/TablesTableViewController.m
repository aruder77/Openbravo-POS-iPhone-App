//
//  TablesViewController.m
//  OpenbravoPOSApp
//
//  Created by Axel Ruder on 02.04.11.
//  Copyright 2011 msg systems ag. All rights reserved.
//

#import "TablesTableViewController.h"
#import "TableItemsTableViewController.h"
#import "OpenbravoPOSAppAppDelegate.h"
#import "JSON.h"
#import "Table.h"
#import "UIAlertView+Blocks.h"

@implementation TablesTableViewController


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
    }
    return self;
}

- (void)dealloc
{
    [busyTables release];
    [tableArray release];
    if (tableItemsViewController != nil) {
        [tableItemsViewController release];
    }
    if (productSelectViewController != nil) {
        [productSelectViewController release];
    }
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

-(BOOL) isTableBusy:(Table *)table {
    return [busyTables containsObject:table.id];
}

- (void)takeImageForProduct 
{
    if (productSelectViewController == nil) {
        productSelectViewController = [[ProductSelectionTableViewController alloc] initWithNibName:@"ItemSelectionTableViewController" bundle:nil];
        productSelectViewController.title = @"Bild für Produkt";
        productSelectViewController.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelProductSelection)] autorelease];
    }
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:productSelectViewController];
    [self.navigationController presentModalViewController:navController animated:YES];
    [navController release];
}

- (void) cancelProductSelection
{
    [self.navigationController dismissModalViewControllerAnimated:YES];
}

- (void) saveImageForProduct
{
    [self.navigationController dismissModalViewControllerAnimated:YES];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (tableArray == nil) {
        tableArray = [[NSMutableArray alloc] init];
    }
    if (busyImage == nil) {
        NSString *busyImageFile = [[NSBundle mainBundle] pathForResource:@"edit_group" ofType:@"png"];
        busyImage = [[UIImage alloc] initWithContentsOfFile:busyImageFile];
        NSString *emptyImageFile = [[NSBundle mainBundle] pathForResource:@"empty" ofType:@"png"];
        emptyImage = [[UIImage alloc] initWithContentsOfFile:emptyImageFile];
    }
    
    responseData = [[NSMutableData alloc] init];
    NSString *baseUrl = [OpenbravoPOSAppAppDelegate getWebAppURL];
    NSString *url = [NSString stringWithFormat:@"%@/tables", baseUrl];
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
	[[NSURLConnection alloc] initWithRequest:request delegate:self];
    
//    UIBarButtonItem *productImageButtonItem = [[UIBarButtonItem alloc]
//                                           initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
//                                           target:self action:@selector(takeImageForProduct)];
//    self.toolbarItems = [NSArray arrayWithObjects:productImageButtonItem, nil];
}

- (void)viewDidUnload
{
    [busyImage release];
    [emptyImage release];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    NSString *baseUrl = [OpenbravoPOSAppAppDelegate getWebAppURL];
    if (tableItemsViewController.table != nil) {
        if ([tableItemsViewController.addedItems count] > 0) {
            RIButtonItem *cancelButton = [[RIButtonItem alloc] init];
            cancelButton.label = @"Nein";
            cancelButton.action = ^
            {
                // do nothing
            };
            
            RIButtonItem *repeatButton = [[RIButtonItem alloc] init];
            repeatButton.label = @"Ja";
            repeatButton.action = ^
            {
                [tableItemsViewController sendItems];
            };
            
            UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Warning!" message:@"Bestellung ist noch nicht an die Bar/Kueche gesendet worden! Senden?" cancelButtonItem:cancelButton otherButtonItems:repeatButton, nil] autorelease];
            
            [cancelButton release];
            [repeatButton release];
            [alert show];
        }
        
        NSString *url = [NSString stringWithFormat:@"%@/tickets/deleteTicketIfEmpty?place=%@", baseUrl, tableItemsViewController.table.id];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
        
        [request setHTTPMethod:@"DELETE"];
        NSURLResponse *response;
        NSError *error;
        [NSURLConnection sendSynchronousRequest:request
                              returningResponse:&response error:&error];
    }
    
    NSString *url = [NSString stringWithFormat:@"%@/tables/busyTables", baseUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    [request setHTTPMethod:@"GET"];
    NSURLResponse *response;
    NSError *error;
    NSData *data = [NSURLConnection sendSynchronousRequest:request
                          returningResponse:&response error:&error];
    NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	NSDictionary *results = [responseString JSONValue];
    [responseString release];
    
    if (busyTables == nil) {
        busyTables = [[NSMutableArray alloc] init];
    } else {
        [busyTables removeAllObjects];
    }
    
    NSArray *localTables;
    id result = [results objectForKey:@"place"];
    if ([result isKindOfClass:[NSDictionary class]]) {
        localTables = [[NSMutableArray alloc] init];
        [((NSMutableArray *)localTables) addObject:result];
    } else {
        localTables = result;
    }
    
    for (int i=0; i < [localTables count]; i++) {
        NSDictionary* tableDict = [localTables objectAtIndex:i];        
        [busyTables addObject:[tableDict objectForKey:@"id"]];
    }

    [super viewWillAppear:animated];
    
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

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	[responseData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[responseData appendData:data];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    if([title isEqualToString:@"Wiederholen"]) {
        NSString *baseUrl = [OpenbravoPOSAppAppDelegate getWebAppURL];
        NSString *url = [NSString stringWithFormat:@"%@/tables", baseUrl];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
        [[NSURLConnection alloc] initWithRequest:request delegate:self];
    }
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error loading tables!" message:@"Could not retrieve tables from server!" delegate:self cancelButtonTitle:@"Abbrechen" otherButtonTitles:@"Wiederholen", nil];
    [alertView show];
    [alertView release];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [connection release];
    
	NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
	[responseData release];
    NSLog(@"Response: %@", responseString);
    
	NSDictionary *results = [responseString JSONValue];
    NSLog(@"Count: %d", [results count]);
    
    NSArray *localTables = [results objectForKey:@"place"];
    for (int i=0; i < [localTables count]; i++) {
        NSDictionary* tableDict = [localTables objectAtIndex:i];
        Table *t = [[Table alloc] init];
        t.id = [tableDict objectForKey:@"id"];
        t.name = [tableDict objectForKey:@"name"];
        NSLog(@"Tisch: [id=%@, name=%@]", t.id, t.name);
        [tableArray addObject:t];
        NSLog(@"###Table count: %d", [tableArray count]);
        [t release];
        
    }
    [responseString release];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    int rowCount = 0;
    if (tableArray != nil) {
        rowCount = [tableArray count];
    }
    return rowCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    cell.textLabel.text = [[tableArray objectAtIndex:indexPath.row] name];
    if ([self isTableBusy:[tableArray objectAtIndex:indexPath.row]]) {
        cell.imageView.image = busyImage;
    } else {
        cell.imageView.image = emptyImage;
    }
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableItemsViewController == nil) {
        tableItemsViewController = [[TableItemsTableViewController alloc] init];
    }
    [tableItemsViewController prepareForTable:[tableArray objectAtIndex:indexPath.row]];

    [self.navigationController pushViewController:tableItemsViewController animated:YES];
}

@end
