//
//  ItemSelectionTableViewController.h
//  OpenbravoPOSApp
//
//  Created by Axel Ruder on 02.04.11.
//  Copyright 2011 msg systems ag. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OpenbravoPOSAppAppDelegate.h"


@interface ProductSelectionTableViewController : UITableViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate> {
    
    OpenbravoPOSAppAppDelegate *delegate;
    
}


@end
