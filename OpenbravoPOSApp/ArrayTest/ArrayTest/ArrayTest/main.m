//
//  main.m
//  ArrayTest
//
//  Created by Axel Ruder on 06.04.11.
//  Copyright 2011 msg systems ag. All rights reserved.
//

#import <Foundation/Foundation.h>

int main (int argc, const char * argv[])
{

    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    // insert code here...
    NSLog(@"Hello, World!");
    
    NSMutableArray *array = [NSMutableArray array];
    

    [pool drain];
    return 0;
}

