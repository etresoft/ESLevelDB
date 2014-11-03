/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "ESLevelDBDataSource.h"
#import "ESLevelDBDataNode.h"
#import "ESLevelDBDataSourceDelegate.h"
#import "ESLevelDB.h"

#define kMinKeyPart 0.00000000000000000001
#define kMaxKeyPart 99999999999999999999.0

@interface ESLevelDBDataSource ()

@property (strong) ESLevelDBDataNode * root;
@property (strong) NSMutableDictionary * keyLookup;
@property (strong) NSMutableDictionary * valueLookup;

@end

@implementation ESLevelDBDataSource

@synthesize root = myRoot;
@synthesize keyLookup = myKeyLookup;
@synthesize valueLookup = myValueLookup;

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    myRoot = [ESLevelDBDataNode new];
    
    myRoot.children = [NSMutableArray new];
    
    myValueLookup = [NSMutableDictionary new];
    }
    
  return self;
  }

// Get the number of children of an item by absolute location. Returns
// number of top-level items if path is nil.
- (NSInteger) numberOfItemsAtIndexPath: (NSIndexPath *) path
  {
  __block NSUInteger count = 0;
  
  dispatch_sync(
    self.db.queue,
    ^{
      count = [self nodeAtPath: path].children.count;
    });
  
  return count;
  }

// Get the number of children at an item. Returns number of top-level items
// if the item is nil.
- (NSInteger) numberOfItemsInItem: (ESLevelDBType) item
  {
  __block NSUInteger count = 0;
  
  dispatch_sync(
    self.db.queue,
    ^{
      if(!item)
        count = self.root.children.count;
      else
        count = [self.valueLookup[item] count];
    });
  
  return count;
  }

// Get the item at an absolute location. Returns nil if path is nil or
// if there is no item at path.
- (ESLevelDBType) itemAtIndexPath: (NSIndexPath *) path
  {
  __block ESLevelDBType result = nil;
  
  dispatch_sync(
    self.db.queue,
    ^{
      result = [self nodeAtPath: path].value;
    });
  
  return result;
  }

// Get the children of an item at an absolute location. Returns all
// top-level items if the path is nil.
- (NSArray *) itemsAtIndexPath: (NSIndexPath *) path
  {
  __block NSArray * children = nil;
  
  dispatch_sync(
    self.db.queue,
    ^{
      children = [self nodeAtPath: path].children;
    });
  
  return children;
  }

// Get the children of an item. Returns all items if the item is nil.
// Retuns nil if the item isn't valid.
- (NSArray *) itemsOfItem: (ESLevelDBType) item
  {
  if(!item)
    return self.root.children;
    
  __block NSArray * children = nil;
  
  dispatch_sync(
    self.db.queue,
    ^{
      children = [self.valueLookup[item] children];
    });
  
  return children;
  }

// Replace an item at a given path.
- (void) set: (ESLevelDBType) item at: (NSIndexPath *) path
  {
  dispatch_sync(
    self.db.queue,
    ^{
      [self setNodeAt: path with: item];
    });
  }

// Replace a given item.
- (void) replace: (ESLevelDBType) oldItem with: (ESLevelDBType) newItem
  {
  dispatch_sync(
    self.db.queue,
    ^{
      [self replaceNode: self.valueLookup[newItem] with: newItem];
    });
  }

// Adds a new item at a path. If path is nil, adds a new top-level
// item.
- (void) add: (ESLevelDBType) item at: (NSIndexPath *) path
  {
  dispatch_sync(
    self.db.queue,
    ^{
      [self add: item toParentNode: [self nodeAtPath: path]];
    });
  }

// Adds a new item to a parent. If parent is nil, adds a new top-level
// item.
- (void) add: (ESLevelDBType) item to: (ESLevelDBType) parent
  {
  dispatch_sync(
    self.db.queue,
    ^{
      [self add: item toParentNode: self.valueLookup[parent]];
    });
  }

// Adds a new item at an absolute location.
- (void) insert: (ESLevelDBType) item atIndexPath: (NSIndexPath *) path
  {
  dispatch_sync(
    self.db.queue,
    ^{
      NSUInteger index = 0;
      
      ESLevelDBDataNode * parentNode = self.root;
      
      if(path.length)
        {
        index = [path indexAtPosition: path.length - 1];
      
        NSIndexPath * parentPath = [path indexPathByRemovingLastIndex];
      
        parentNode = [self nodeAtPath: parentPath];
        }
        
      [self insert: item at: index inParentNode: parentNode];
    });
  }

// Adds a new item to a parent at a given, relative location.
- (void) insert: (ESLevelDBType) item
  at: (NSUInteger) position in: (ESLevelDBType) parent
  {
  dispatch_sync(
    self.db.queue,
    ^{
      ESLevelDBDataNode * parentNode = self.root;

      if(parent)
        parentNode = self.valueLookup[parent];
        
      [self insert: item at: position inParentNode: parentNode];
    });
  }

// Remove an item at a given path.
- (void) removeItemAt: (NSIndexPath *) path
  {
  dispatch_sync(
    self.db.queue,
    ^{
      [self removeNode: [self nodeAtPath: path]];
    });
  }

// Remove an item.
- (void) removeItem: (ESLevelDBType) item
  {
  dispatch_sync(
    self.db.queue,
    ^{
      [self removeNode: self.valueLookup[item]];
    });
  }

#pragma mark - Handle remote update

// Add a value at a given key from a remote peer.
- (void) peerAddValue: (ESLevelDBType) value forKey: (ESLevelDBKey) key
  {
  dispatch_sync(
    self.db.queue,
    ^{
      [self performPeerAddValue: value forKey: key];
    });
  }

// Update a value at a given key from a remote peer.
- (void) peerUpdateValue: (ESLevelDBType) value forKey: (ESLevelDBKey) key
  {
  dispatch_sync(
    self.db.queue,
    ^{
      [self performPeerUpdateValue: value forKey: key];
    });
  }

// Remove a value at a given key from a remote peer.
- (void) peerRemoveKey: (ESLevelDBKey) key
  {
  dispatch_sync(
    self.db.queue,
    ^{
      [self performPeerRemoveKey: key];
    });
  }

#pragma mark - Helper routines.

- (ESLevelDBDataNode *) nodeAtPath: (NSIndexPath *) path
  {
  ESLevelDBDataNode * node = self.root;

  for(NSUInteger i = 0; i < path.length; ++i)
    {
    NSUInteger index = [path indexAtPosition: i];
    
    if(index >= node.children.count)
      return nil;
      
    node = node.children[index];
    }
    
  return node;
  }

// Set a node value.
- (void) setNode: (ESLevelDBDataNode *) node with: (ESLevelDBType) item
  {
  if(node)
    {
    [self willUpdate: node with: item];
    
    self.db[node.key] = item;
    
    [self.valueLookup removeObjectForKey: node.value];
    
    node.value = item;

    self.valueLookup[item] = node;
    
    [self didUpdate: node with: item];
    }
  }

// Replace a node value.
- (void) replaceNode: (ESLevelDBDataNode *) node with: (ESLevelDBType) item
  {
  if(node)
    {
    [self willUpdate: node with: item];
    
    self.db[node.key] = item;
    
    [self.valueLookup removeObjectForKey: node.value];
    
    node.value = item;

    self.valueLookup[item] = node;
    
    [self didUpdate: node with: item];
    }
  }

// Adds a new item to a parent. If parent is nil, adds a new top-level
// item.
- (void) add: (ESLevelDBType) item
  toParentNode: (ESLevelDBDataNode *) parentNode
  {
  if(!parentNode)
    parentNode = self.root;
  
  ESLevelDBDataNode * lastNode = parentNode.children.lastObject;
  
  ESLevelDBDataNode * node = [ESLevelDBDataNode new];
  
  if(lastNode)
    node.key = [self keyBetween: lastNode.key and: nil];
  else
    // TODO: Create a new key in parent.
    node.key = [self keyBetween: nil and: parentNode.key];
  
  // TODO: What if key is nil.
  
  node.value = item;
  
  [parentNode.children addObject: node];
  
  self.db[node.key] = item;
  
  self.keyLookup[node.key] = node;
  self.valueLookup[item] = node;

  // TODO: Call delegate.
  }

// Adds a new item to a parent at a given, relative location.
- (void) insert: (ESLevelDBType) item
  at: (NSUInteger) position inParentNode: (ESLevelDBDataNode *) parentNode
  {
  if(!parentNode)
    parentNode = self.root;

  ESLevelDBDataNode * node = [ESLevelDBDataNode new];
  
  ESLevelDBDataNode * predecessor =
    parentNode.children.count > position
      ? parentNode.children[position]
      : nil;

  ESLevelDBDataNode * successor =
    parentNode.children.count > (position + 1)
      ? parentNode.children[position + 1]
      : nil;
  
  if(predecessor && successor)
    node.key = [self keyBetween: predecessor.key and: successor.key];
  else if(predecessor)
    node.key = [self keyBetween: predecessor.key and: nil];
  else if(successor)
    node.key = [self keyBetween: nil and: successor.key];
  else
    // TODO: Create a new key in parent.
    node.key = [self keyBetween: nil and: parentNode.key];
 
  // TODO: What if key is nil?
  
  node.value = item;
  
  [parentNode.children insertObject: node atIndex: position];
  
  self.db[node.key] = item;
  
  self.keyLookup[node.key] = node;
  self.valueLookup[item] = node;

  // TODO: Call delegate.
  }

// Remove an item from a parent at an index.
- (void) removeNode: (ESLevelDBDataNode *) node
  {
  if(node)
    {
    [self.db removeObjectForKey: node.key];
  
    [node.parent.children removeObject: node];
    
    [self.keyLookup removeObjectForKey: node.key];
    [self.valueLookup removeObjectForKey: node.value];

    // TODO: Call delegate.
    }
  }

// Return a key between two others.
// TODO: What about /path/to/deep/key and nil?
- (ESLevelDBKey) keyBetween: (ESLevelDBKey) key1 and: (ESLevelDBKey) key2
  {
  // Split the keys by path delimiters.
  NSArray * key1Parts = [key1 componentsSeparatedByString: @"/"];
  NSArray * key2Parts = [key2 componentsSeparatedByString: @"/"];

  NSMutableArray * resultParts = [NSMutableArray array];
  
  NSNumber * key1Part = nil;
  NSNumber * key2Part = nil;
  
  // Iterate through both keys by segment.
  NSEnumerator * key1Enumerator = [key1Parts objectEnumerator];
  NSEnumerator * key2Enumerator = [key2Parts objectEnumerator];
  
  // Absorb all of the keys that are the same.
  while(YES)
    {
    key1Part = [key1Enumerator nextObject];
    key2Part = [key2Enumerator nextObject];
    
    if(!key1Part || !key2Part)
      break;
      
    if(![key1Part isEqualToNumber: key2Part])
      break;
      
    [resultParts addObject: key1Part];
    }
   
  // At this point, either one or both of the key parts is null or
  // the key parts are not identical.
    
  NSNumber * resultPart = [self keyPartBetween: key1Part and: key2Part];
    
  if(!resultPart)
    return nil;
    
  [resultParts addObject: resultPart];
  
  // Return the resulting key.
  return [resultParts componentsJoinedByString: @"/"];
  }

// Get a key portion between two NSNumber values, which could be nil.
- (NSNumber *) keyPartBetween: (NSNumber *) key1Part
  and: (NSNumber *) key2Part
  {
  double result;
  
  // This will work even if both parts are nil.
  if(!key2Part)
    {
    double value = [key1Part doubleValue];
    
    // Rein in edge cases.
    if(value >= kMaxKeyPart)
      value = kMaxKeyPart - 1.0;
      
    result = value + ((kMaxKeyPart - value) / 2.0);
    }
    
  else if(!key1Part)
    {
    double value = [key1Part doubleValue];
    
    // Rein in edge cases.
    if(value == 0.0)
      value = 1.0;
      
    result = value / 2.0;
    }
    
  else
    {
    double key1 = [key1Part doubleValue];
    double key2 = [key2Part doubleValue];
    
    // I can't resolve this one here.
    if(key1 == key2)
      return nil;
      
    result = key1 + ((key2 - key1) / 2.0);
    }
    
  return [NSNumber numberWithDouble: result];
  }

// Add a value at a given key from a remote peer.
// TODO: Thread safety.
- (void) performPeerAddValue: (ESLevelDBType) value
  forKey: (ESLevelDBKey) key
  {
  // This key/value pair has already been added to a peer. I can't reject
  // it. I must accomodate it.
  ESLevelDBDataNode * node = [ESLevelDBDataNode new];
  
  node.key = key;
  node.value = value;
  
  // See if I already have this key. If I do, I will need to move it.
  ESLevelDBDataNode * current = self.keyLookup[key];
  
  if(current)
    {
    ESLevelDBDataNode * parentNode = current.parent;

    NSUInteger position = [parentNode.children indexOfObject: current];
    
    ESLevelDBDataNode * successor =
      parentNode.children.count > (position + 1)
        ? parentNode.children[position + 1]
        : nil;
    
    ESLevelDBKey conflictedKey;
    
    if(successor)
      conflictedKey = [self keyBetween: key and: successor.key];
    else
      // TODO: Create a new key in parent.
      conflictedKey = [self keyBetween: nil and: parentNode.key];

    // TODO: What if key is nil.
    current.key = conflictedKey;
    
    self.keyLookup[conflictedKey] = current;
    }

  // TODO: Insert into parent node.
  
  // These operations are safe now that the conflicting entry has been
  // moved aside.
  self.db[key] = value;
  
  self.keyLookup[key] = node;
  self.valueLookup[value] = node;

  // TODO: Call delegate.
  }

// Update a value at a given key from a remote peer.
- (void) performPeerUpdateValue: (ESLevelDBType) value
  forKey: (ESLevelDBKey) key
  {
  [self.db setObject: value forKey: key];

  // TODO: Call delegate.
  }

// Remove a value at a given key from a remote peer.
- (void) performPeerRemoveKey: (ESLevelDBKey) key
  {
  [self.db removeObjectForKey: key];
  
  // TODO: Call delegate.
  }

// TODO: Finish this
- (NSIndexPath *) pathToNode: (ESLevelDBDataNode *) node
  {
  return nil;
  }

#pragma mark - Delegate interface.

- (void) willInsert: (ESLevelDBDataNode *) node
  {
  BOOL responds =
    [self.delegate
      respondsToSelector: @selector(dataSource:willInsert:at:with:)];
    
  if(responds)
    [self.delegate
      dataSource: self willInsert: node at: [self pathToNode: node]];
  }

- (void) didInsert: (ESLevelDBDataNode *) node
  {
  BOOL responds =
    [self.delegate
      respondsToSelector: @selector(dataSource:didInsert:at:with:)];
    
  if(responds)
    [self.delegate
      dataSource: self didInsert: node at: [self pathToNode: node]];
  }

- (void) willRemove: (ESLevelDBDataNode *) node
  {
  BOOL responds =
    [self.delegate
      respondsToSelector: @selector(dataSource:willRemove:at:with:)];
    
  if(responds)
    [self.delegate
      dataSource: self willRemove: node at: [self pathToNode: node]];
  }

- (void) didRemove: (ESLevelDBDataNode *) node at: (NSIndexPath *) path
  {
  BOOL responds =
    [self.delegate
      respondsToSelector: @selector(dataSource:didRemove:at:with:)];
    
  if(responds)
    [self.delegate
      dataSource: self didRemove: node at: [self pathToNode: node]];
  }

- (void) willUpdate: (ESLevelDBDataNode *) node
  with: (ESLevelDBType) value
  {
  BOOL responds =
    [self.delegate
      respondsToSelector: @selector(dataSource:willUpdate:at:with:)];
    
  if(responds)
    [self.delegate
      dataSource: self
      willUpdate: node
      at: [self pathToNode: node]
      with: value];
  }

- (void) didUpdate: (ESLevelDBDataNode *) node
  with: (ESLevelDBType) value
  {
  BOOL responds =
    [self.delegate
      respondsToSelector: @selector(dataSource:didUpdate:at:with:)];
    
  if(responds)
    [self.delegate
      dataSource: self
      didUpdate: node
      at: [self pathToNode: node]
      with: value];
  }

@end
