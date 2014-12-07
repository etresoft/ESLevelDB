/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>
#import "ESLevelDBType.h"
#import "ESLevelDBDataSourceDelegate.h"
#import "ESLevelDB.h"

// This class serves as an adapter for an app-level data source class. It
// can provide data for a NSTableViewDataSource, UITableViewDataSource, or
// NSOutlineViewDataSource.

// Most importantly, this class takes care of all key management. It
// maintains an in-memory tree of all keys. Values are lazily managed via
// ARC.

// Keys are organized as cannonical paths delimited by slashes. Values can
// be referenced via native sort order with NSIndexPath, by full key, or by
// relative key.

// While LevelDB performs its own key sorting, this adapter uses a
// different mechanism to maintain local sorting and to guarantee easy
// insertions. Key path segments are composed of strings floating point
// numbers. These can be easily sorted and subdivided.

// Finally, this class is a subclass of NSMutableArray. Internally it
// wraps keys and objects in an ESLevelDBDataNode. Externally it provides
// an array interface to the data in an ESLevelDB database. It is intended
// to be used in traditional iOS and OS X apps where the entire array is
// kept in memory.

// TODO: Try to optimize memory usage by keeping only object keys in the
// array and doing lazy loading of object values.
@interface ESLevelDBDataSource : NSMutableArray

// The database.
@property (strong) ESLevelDB * db;

// An informal delegate.
@property (weak) id<ESLevelDBDataSourceDelegate> delegate;

@end
