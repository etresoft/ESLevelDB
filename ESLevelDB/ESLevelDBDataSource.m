/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "ESLevelDBDataSource.h"
#import "ESLevelDBDataNode.h"
#import "ESLevelDBDataSourceDelegate.h"
#import "ESLevelDB.h"

@interface ESLevelDBDataSource ()

@property (strong) NSMutableArray * backingStore;

@end

@implementation ESLevelDBDataSource

@synthesize backingStore = myBackingStore;

// Constructor.
- (id) init
  {
  self = [super init];
  
  if(self)
    {
    myBackingStore = [NSMutableArray new];
    }
    
  return self;
  }

#pragma mark - Required NSArray overrides

// Return the number of objects in the array.
- (NSUInteger) count
  {
  __block NSUInteger count = 0;
  
  dispatch_sync(
    self.db.queue,
    ^{
      count = self.backingStore.count;
    });
    
  return count;
  }

// Return the value at an index.
- (id) objectAtIndex: (NSUInteger) index
  {
  __block id object = nil;
  
  dispatch_sync(
    self.db.queue,
    ^{
      object = [[self.backingStore objectAtIndex: index] value];
    });
    
  return object;
  }

#pragma mark - Required NSMutableArray overrides

// Insert an object at the specified index.
- (void) insertObject: (id) anObject atIndex: (NSUInteger) index
  {
  dispatch_sync(
    self.db.queue,
    ^{
      ESLevelDBDataNode * node = [ESLevelDBDataNode new];
      
      // Generate a key and insert the key and object into the database.
      node.key = [self generateKeyAtIndex: index forObject: anObject];
      node.value = anObject;
      
      [self.backingStore insertObject: node atIndex: index];
    });
  }

// Remove an object at the specified index.
- (void) removeObjectAtIndex: (NSUInteger) index
  {
  dispatch_sync(
    self.db.queue,
    ^{
      // Remove the node from the database.
      [self removeNode: [self.backingStore objectAtIndex: index]];
      
      [self.backingStore removeObjectAtIndex: index];
    });
  }

// Add an object to the end of the array.
- (void) addObject: (id) anObject
  {
  dispatch_sync(
    self.db.queue,
    ^{
      ESLevelDBDataNode * node = [ESLevelDBDataNode new];
      
      // Generate a key and insert the key and object into the database.
      node.key = [self generateKeyForObject: anObject];
      node.value = anObject;
      
      [self.backingStore addObject: node];
    });
  }

// Remove the last object.
- (void) removeLastObject
  {
  dispatch_sync(
    self.db.queue,
    ^{
      // Remove the node from the database.
      [self removeNode: [self.backingStore lastObject]];

      [self.backingStore removeLastObject];
    });
  }

// Replace an object at a given index with another object.
- (void) replaceObjectAtIndex: (NSUInteger) index withObject: (id) anObject
  {
  dispatch_sync(
    self.db.queue,
    ^{
      ESLevelDBDataNode * node = [ESLevelDBDataNode new];
      
      // Generate a key and insert the key and object into the database.
      node.key = [self generateKeyAtIndex: index forObject: anObject];
      node.value = anObject;
      
      // Remove the node from the database.
      [self removeNode: [self.backingStore objectAtIndex: index]];
      
      [self.backingStore replaceObjectAtIndex: index withObject: node];
    });
  }

#pragma mark - Helper methods

- (NSString *) generateKeyAtIndex: (NSUInteger) index
  forObject: (id) anObject
  {
  return nil;
  }

- (NSString *) generateKeyForObject: (id) anObject
  {
  return nil;
  }

- (void) removeNode: (ESLevelDBDataNode *) node
  {
  }

#pragma mark - Handle remote updates

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
  bool responds =
    [self.delegate
      respondsToSelector: @selector(dataSource:willInsert:at:with:)];
    
  if(responds)
    [self.delegate
      dataSource: self willInsert: node at: [self pathToNode: node]];
  }

- (void) didInsert: (ESLevelDBDataNode *) node
  {
  bool responds =
    [self.delegate
      respondsToSelector: @selector(dataSource:didInsert:at:with:)];
    
  if(responds)
    [self.delegate
      dataSource: self didInsert: node at: [self pathToNode: node]];
  }

- (void) willRemove: (ESLevelDBDataNode *) node
  {
  bool responds =
    [self.delegate
      respondsToSelector: @selector(dataSource:willRemove:at:with:)];
    
  if(responds)
    [self.delegate
      dataSource: self willRemove: node at: [self pathToNode: node]];
  }

- (void) didRemove: (ESLevelDBDataNode *) node at: (NSIndexPath *) path
  {
  bool responds =
    [self.delegate
      respondsToSelector: @selector(dataSource:didRemove:at:with:)];
    
  if(responds)
    [self.delegate
      dataSource: self didRemove: node at: [self pathToNode: node]];
  }

- (void) willUpdate: (ESLevelDBDataNode *) node
  with: (ESLevelDBType) value
  {
  bool responds =
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
  bool responds =
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
