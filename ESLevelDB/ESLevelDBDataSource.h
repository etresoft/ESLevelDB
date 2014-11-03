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
@interface ESLevelDBDataSource : NSObject

// The database.
@property (strong) ESLevelDB * db;

// An informal delegate.
@property (weak) id<ESLevelDBDataSourceDelegate> delegate;

// Get the number of children of an item by absolute location. Returns
// number of top-level items if path is nil.
- (NSInteger) numberOfItemsAtIndexPath: (NSIndexPath *) path;

// Get the number of children at an item. Returns number of top-level items
// if the item is nil.
- (NSInteger) numberOfItemsInItem: (ESLevelDBType) item;

// Get the item at an absolute location. Returns nil if path is nil or
// if there is no item at path.
- (ESLevelDBType) itemAtIndexPath: (NSIndexPath *) path;

// Get the children of an item at an absolute location. Returns all
// top-level items if the path is nil.
- (NSArray *) itemsAtIndexPath: (NSIndexPath *) path;

// Get the children of an item. Returns all items if the item is nil.
// Retuns nil if the item isn't valid.
- (NSArray *) itemsOfItem: (ESLevelDBType) item;

// Replace an item at a given path.
- (void) set: (ESLevelDBType) item at: (NSIndexPath *) path;

// Replace a given item.
- (void) replace: (ESLevelDBType) oldItem with: (ESLevelDBType) newItem;

// Adds a new item at a path. If path is nil, adds a new top-level
// item.
- (void) add: (ESLevelDBType) item at: (NSIndexPath *) path;

// Adds a new item to a parent. If parent is nil, adds a new top-level
// item.
- (void) add: (ESLevelDBType) item to: (ESLevelDBType) parent;

// Adds a new item at an absolute location.
- (void) insert: (ESLevelDBType) item atIndexPath: (NSIndexPath *) path;

// Adds a new item to a parent at a given, relative location.
- (void) insert: (ESLevelDBType) item
  at: (NSUInteger) position in: (ESLevelDBType) parent;

// Remove an item at a given path.
- (void) removeItemAt: (NSIndexPath *) path;

// Remove an item.
- (void) removeItem: (ESLevelDBType) item;

@end
