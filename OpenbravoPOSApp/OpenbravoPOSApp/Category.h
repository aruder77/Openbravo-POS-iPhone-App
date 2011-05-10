//
//  Category.h
//  OpenbravoPOSApp
//
//  Created by Axel Ruder on 09.04.11.
//  Copyright 2011 msg systems ag. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Category : NSObject {
    
    NSString* id;
    NSString* name;
}

@property(nonatomic, retain) NSString* id;
@property(nonatomic, retain) NSString* name;

@end
