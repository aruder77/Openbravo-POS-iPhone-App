//
//  ItemSelectionTableViewController.m
//  OpenbravoPOSApp
//
//  Created by Axel Ruder on 02.04.11.
//  Copyright 2011 msg systems ag. All rights reserved.
//

#import "ItemSelectionTableViewController.h"
#import "OpenbravoPOSAppAppDelegate.h"
#import "Category.h"
#import "Product.h"
#import "ItemSelection.h"


@implementation ItemSelectionTableViewController

@synthesize newItems;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
    }
    return self;
}

- (void)dealloc
{
    [newItems release];
    [super dealloc];
}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)undoAdd
{
    if ([newItems count] > 0) {
        [newItems removeLastObject];
        itemCount--;
        self.navigationItem.title = [NSString stringWithFormat:@"x%d", itemCount];
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];    
    
    UIBarButtonItem *undo = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemUndo target:self action:@selector(undoAdd)];
    UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    self.toolbarItems = [NSArray arrayWithObjects:space, undo, nil];

    [undo release];
    [space release];
    
    delegate = [[OpenbravoPOSAppAppDelegate getInstance] retain];
}

- (void)viewDidUnload
{
    //    [delegate release];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    itemCount = 1;
    if (lastSelectedProduct != nil) {
        [lastSelectedProduct release];
        lastSelectedProduct = nil;
    }
    self.navigationItem.title = @"Produkte";
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
    NSArray *list = [delegate getCategoryList];
    return [list count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *productList = [delegate getProductListForCategoryIndex:section];
    return [productList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
    Product *product = [[delegate getProductListForCategoryIndex:indexPath.section] objectAtIndex:indexPath.row];
    
    cell.textLabel.text = product.name;
    NSString *detailText = [product.attributes objectForKey:@"detailText"];
    if (detailText != nil) {
        cell.detailTextLabel.text = detailText;
    } else {
        cell.detailTextLabel.text = nil;
    }
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Product *localProduct = [[delegate getProductListForCategoryIndex:indexPath.section] objectAtIndex:indexPath.row];
    
    if (localProduct == lastSelectedProduct) {
        itemCount++;
        self.navigationItem.title = [NSString stringWithFormat:@"x%d", itemCount];
    } else {
        itemCount = 1;
        self.navigationItem.title = @"Produkte";
    }

    if (newItems != nil) {
        ItemSelection *selection = [[ItemSelection alloc] init];
        selection.product = localProduct;
        lastSelectedProduct = localProduct;
        [lastSelectedProduct retain];
        [newItems addObject:selection];
        [selection release];
    }
    
    
    if ([localProduct.options count] > 0) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Optionen" delegate:self cancelButtonTitle:@"Abbrechen" destructiveButtonTitle:nil otherButtonTitles:nil];
        for (int i = 0; i < [localProduct.options count]; i++) {
            [actionSheet addButtonWithTitle:[localProduct.options objectAtIndex:i]];
        }
        [actionSheet showInView:self.navigationController.view];
        [actionSheet release];
    }
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    NSMutableArray* array = [[[NSMutableArray alloc] init] autorelease];
    NSArray* categoriesArray = [delegate getCategoryList];
    for (int i = 0; i < [categoriesArray count]; i++) {
        Category* cat = [categoriesArray objectAtIndex:i];
        [array addObject:cat.name];
    }
    return array;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return index;
}

- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
    return [[[delegate getCategoryList] objectAtIndex:section] name];
}

#pragma mark - Action sheet delegate

- (void)actionSheet: (UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex > 0) {
        ItemSelection *selectedItem = [newItems objectAtIndex:([newItems count] - 1)];
        selectedItem.selectedOption = [selectedItem.product.options objectAtIndex:(buttonIndex - 1)];
    }
}

@end
