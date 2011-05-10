//
//  Table.h
//  OpenbravoPOSApp
//
//  Created by Axel Ruder on 06.04.11.
//  Copyright 2011 msg systems ag. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Table : NSObject {
    
    NSString *id;
    NSString *name;
    
}

@property(nonatomic, retain) NSString *id;
@property(nonatomic, retain) NSString *name;

@end
