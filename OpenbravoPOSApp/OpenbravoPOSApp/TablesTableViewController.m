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


- (void)dealloc
{
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
            
//    UIBarButtonItem *productImageButtonItem = [[UIBarButtonItem alloc]
//                                           initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
//                                           target:self action:@selector(takeImageForProduct)];
//    self.toolbarItems = [NSArray arrayWithObjects:productImageButtonItem, nil];
}

- (void)viewDidUnload
{
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
    [super viewWillAppear:animated];
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
