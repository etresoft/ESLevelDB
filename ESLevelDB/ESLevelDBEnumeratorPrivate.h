/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

#import "ESLevelDBType.h"

@interface ESLevelDBEnumerator ()

@property (strong) ESLevelDB * db;
@property (assign) leveldb::Iterator * iter;

// Keep a pointer to the current object so its address can be used by
// NSFastEnumerator.
@property (strong) id ref;
@property (readonly) id __unsafe_unretained object;
@property (readonly) id __unsafe_unretained * objectPtr;

// Use leveldb's iterator to find the ending key for comparison.
@property (strong) ESLevelDBKey end;

// Set the internal objects.
- (id) setObjects: (id) ref;

@end
