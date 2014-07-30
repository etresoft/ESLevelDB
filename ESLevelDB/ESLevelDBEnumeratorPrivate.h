/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>
#import "ESLevelDBType.h"

@interface ESLevelDBEnumerator ()

// Keep a pointer to the current object so its address can be used by
// NSFastEnumerator.
@property (strong) ESLevelDBType ref;
@property (readonly) id __unsafe_unretained object;
@property (readonly) id __unsafe_unretained * objectPtr;

@end
