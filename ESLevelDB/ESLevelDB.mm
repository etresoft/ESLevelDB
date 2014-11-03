/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/
//
//  Created by Adam Preble on 1/23/12.
//  Copyright (c) 2012 Adam Preble. All rights reserved.
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//	THE SOFTWARE.

#import "leveldb/db.h"
#import "leveldb/options.h"
#import "leveldb/write_batch.h"

#import "ESLevelDB.h"
#import "ESLevelDBPrivate.h"
#import "ESLevelDBSnapshot.h"
#import "ESLevelDBSnapshotPrivate.h"
#import "ESLevelDBScratchPad.h"
#import "ESLevelDBScratchPadPrivate.h"
#import "ESLevelDBType.h"
#import "ESLevelDBSlice.h"
#import "ESLevelDBKeySlice.h"
#import "ESLevelDBValue.h"
#import "ESLevelDBEnumerator.h"
#import "ESLevelDBEnumeratorPrivate.h"
#import "ESLevelDBValueEnumerator.h"
#import "ESLevelDBValueEnumeratorPrivate.h"

@interface ESLevelDB ()

// For NSFastEnumeration support.
@property (readonly) NSMutableDictionary * enumerators;
@property (assign) NSUInteger nextEnumeratorIndex;

// Will be changed for a batch subclass.
@property (assign) leveldb::WriteOptions writeOptions;

@end

@implementation ESLevelDB
  {
  NSUInteger myCount;
  
  // I need to know if the database changes.
  unsigned long myHash;
  }

#pragma mark - Properties

@synthesize serializer = mySerializer;

@synthesize queue = myQueue;

@synthesize db = myDb;

@synthesize readOptions = myReadOptions;

@synthesize lastHash = myLastHash;

@synthesize enumerators = myEnumerators;

@synthesize nextEnumeratorIndex = myNextEnumeratorIndex;

@synthesize writeOptions = myWriteOptions;

// I can't always rely on level db to handle multithreading.
- (dispatch_queue_t) queue
  {
  if(!myQueue)
    {
    NSString * label = [NSString stringWithFormat: @"ESLevelDBQ%p", self];
    
    myQueue =
      dispatch_queue_create([label UTF8String], DISPATCH_QUEUE_SERIAL);
    }
    
  return myQueue;
  }

// See above.
- (NSMutableDictionary *) enumerators
  {
  if(!myEnumerators)
    myEnumerators = [NSMutableDictionary new];
    
  return myEnumerators;
  }

#pragma mark - ESLevelDB operations

// Factory constructor with path.
+ (instancetype) levelDBWithPath:(NSString *) path
 error: (NSError **) errorOut
  {
	return [[ESLevelDB alloc] initWithPath: path error: errorOut];
  }

// Constructor.
- (id) initWithPath: (NSString *) path error: (NSError **) errorOut
  {
  leveldb::DB * db = [self openLevelDB: path error: errorOut];
  
  if(!db)
    return nil;
    
	if((self = [super init]))
    {
    [self connectToLevelDB: std::shared_ptr<leveldb::DB>(db)];
    
    [self setup];
	  }
    
  return self;
  }

// Copy constructor.
- (instancetype) initWithESLevelDB: (ESLevelDB *) db
  {
  if(!db.db)
    return nil;
    
	if((self = [super init]))
    {
    [self connectToLevelDB: *db.db];
    
    [self setup];
    }
    
  return self;
  }

// No ARC with C++.
- (void) dealloc
  {
	delete self.db;
  self.db = nil;
  }

// Copy constructor.
- (instancetype) copyWithZone: (NSZone *) zone
  {
  ESLevelDB * copy = [super copyWithZone: zone];
  
  copy.db = new std::shared_ptr<leveldb::DB>(*self.db);
  copy.serializer = [self.serializer copy];

  [copy setup];
  
  return copy;
  }

// Batch write/atomic update support:
- (ESLevelDBScratchPad *) batchView
  {
	return [[ESLevelDBScratchPad alloc] initWithESLevelDB: self];
  }

// Snapshot support:
- (ESLevelDBSnapshot *) snapshotView
  {
	return [[ESLevelDBSnapshot alloc] initWithESLevelDB: self];
  }

// Enumerate a range [start, limit) of keys and objects.
- (void) enumerateKeysAndObjectsFrom: (ESLevelDBKey) from
  limit: (ESLevelDBKey) limit
  usingBlock:
    (void (^)(ESLevelDBKey key, ESLevelDBType obj, BOOL * stop)) block
  {
  ESLevelDBEnumerator * enumerator =
    [[ESLevelDBEnumerator alloc] initWithDB: self];
  
  enumerator.start = from;
  enumerator.limit = limit;
  
  BOOL stop = NO;
  
	while(YES)
    {
    ESLevelDBKey key = [enumerator nextObject];
    
    if(!key)
      break;
      
    ESLevelDBType value = self[key];
    
    block(key, value, & stop);
    
    if(stop)
      break;
	  }
  }

// Enumerator a range [start, limit) of keys and objects with options.
- (void) enumerateKeysAndObjectsFrom: (ESLevelDBKey) from
  limit: (ESLevelDBKey) limit
  withOptions: (NSEnumerationOptions) options
  usingBlock:
    (void (^)(ESLevelDBKey key, ESLevelDBType obj, BOOL * stop)) block
  {
  ESLevelDBEnumerator * enumerator =
    [[ESLevelDBEnumerator alloc] initWithDB: self];
  
  enumerator.start = from;
  enumerator.options = options;
  enumerator.limit = limit;
  
  BOOL stop = NO;
  
	while(YES)
    {
    ESLevelDBKey key = [enumerator nextObject];
    
    if(!key)
      break;
      
    ESLevelDBType value = self[key];
    
    block(key, value, & stop);
    
    if(stop)
      break;
	  }
  }

#pragma mark - ESLevelDB private support

// Convenience constructor.
+ (leveldb::Options) defaultCreateOptions
  {
	leveldb::Options options;
	options.create_if_missing = true;
	
  return options;
  }

// Open the leveldb database.
- (leveldb::DB *) openLevelDB: (NSString *) path
  error: (NSError **) errorOut
  {
  leveldb::Options options = [[self class] defaultCreateOptions];

  leveldb::DB * db;
  
  leveldb::Status status =
    leveldb::DB::Open(options, [path fileSystemRepresentation], & db);

  if(!status.ok())
    {
    if(errorOut)
      {
      NSString * statusString =
        [[NSString alloc]
          initWithCString: status.ToString().c_str()
          encoding: NSUTF8StringEncoding];
      
      *errorOut =
        [NSError
          errorWithDomain: kESLevelDBErrorDomain
          code: 0
          userInfo:
            [NSDictionary
              dictionaryWithObjectsAndKeys:
                statusString, NSLocalizedDescriptionKey, nil]];
      }
    
    delete db;
    
    return nil;
    }
  
  return db;
  }

// Finish connecting to the leveldb database.
- (BOOL) connectToLevelDB: (std::shared_ptr<leveldb::DB>) db
  {
  myDb = new std::shared_ptr<leveldb::DB>(db);
  mySerializer = [ESLevelDBArchiveSerializer new];
  
  return YES;
  }

// Finish setting up.
- (void) setup
  {
  myHash = [super hash];
  
  // I will need to calculate the count at least once.
  myLastHash = ~myHash;
  
  myNextEnumeratorIndex = 0;

  myWriteOptions.sync = false;
  }

#pragma mark - NSObject interface

// Return a hash for various containers.
- (NSUInteger) hash
  {
  return myHash;
  }

#pragma mark - Required NSDictionary overrides

/* This should be sufficient to setup the superclass. If I try to save
   the data it will get copied into level db.
// Constructor with objects and keys.
- (instancetype) initWithObjects: (const id []) objects
  forKeys: (const id<NSCopying> []) keys
  count: (NSUInteger) count
  {
  return [super initWithObjects: objects forKeys: keys count: count];
  } */

// Number of objects.
// LevelDB doesn't support this, but it is important for Cocoa.
- (NSUInteger) count
  {
  // If my database hasn't changed, just return the last count.
  if(self.lastHash == [self hash])
    return myCount;
    
  // I should probably do this in a block, but I don't want to lock up too
  // much in the block.
  __block NSUInteger newCount = 0;
  
  dispatch_sync(
    self.queue,
    ^{
      leveldb::Iterator * iter =
        (*self.db)->NewIterator(leveldb::ReadOptions());
      
      for(iter->SeekToFirst(); iter->Valid(); iter->Next())
        ++newCount;
        
      delete iter;
    });
  
  // Update the count, if necessary.
  if(newCount != myCount)
    {
    [self willChangeValueForKey: @"count"];
    
    myCount = newCount;
    
    [self didChangeValueForKey: @"count"];
    }
  
  // If I am only here because this was the first run, update the last
  // hash so this doesn't happen again.
  if(myLastHash != [self hash])
    {
    [self willChangeValueForKey: @"lastHash"];
  
    myLastHash = [self hash];
  
    [self didChangeValueForKey: @"lastHash"];
    }
    
  return myCount;
  }

// Return the object for a key.
- (id) objectForKey: (id) key
  {
  leveldb::ReadOptions options = leveldb::ReadOptions();
  
  ESLevelDBType value;
  
  ESleveldb::Value result(value);
  
	leveldb::Status status =
    (*self.db)->Get(options, ESleveldb::KeySlice(key), & result);

	if(!status.ok())
		return nil;
	
	return value;
  }

// Return a key enumerator.
- (NSEnumerator *) keyEnumerator
  {
  return [[ESLevelDBEnumerator alloc] initWithDB: self];
  }

#pragma mark - NSDictionary overrides

// NSDictionary should handle this, but it doesn't.
// Return all keys.
- (NSArray *) allKeys
  {
	NSMutableArray * keys = [NSMutableArray array];
  
  id key = nil;
  NSEnumerator * enumerator = [self keyEnumerator];
  
  while(key = [enumerator nextObject])
    [keys addObject: key];
    
	return [keys copy];
  } 

/* NSDictionary should handle this.
// Return all keys for a single object.
- (NSArray *) allKeysForObject: (id) object
  {
	NSMutableArray * keys = [NSMutableArray array];
  
  id value = nil;
  NSEnumerator * enumerator = [self objectEnumerator];
  
  while(value = [enumerator nextObject])
    if([object isEqual: value])
      [keys addObject: value];
  
  return [keys copy];
  } */

/* NSDictionary should handle this.
// Return all values.
- (NSArray *) allValues
  {
	NSMutableArray * values = [NSMutableArray array];
  
  id value = nil;
  NSEnumerator * enumerator = [self objectEnumerator];
  
  while(value = [enumerator nextObject])
    [values addObject: value];
  
  return [values copy];
  } */

/* NSDictionary should handle this.
// Return all objects and keys into pre-allocated arrays.
- (void) getObjects: (__unsafe_unretained id []) objects
  andKeys: (__unsafe_unretained id []) keys
  {
  NSUInteger index = 0;
  
  id key = nil;
  NSEnumerator * enumerator = [self keyEnumerator];
  
  while(key = [enumerator nextObject])
    {
    if(keys)
      keys[index] = key;
    
    if(objects)
      objects[index] = self[key];
    
    ++index;
    }
  } */

/* NSDictionary should handle this.
// Return an object for a key using array subscript notation.
- (ESLevelDBType) objectForKeyedSubscript: (id) key
  {
  return [self objectForKey: key];
  } */

/* NSDictionary should handle this.
// Return all objects for a given array of keys with a specific not-found
// marker.
- (NSArray *) objectsForKeys: (NSArray *) keys
  notFoundMarker: (id) object
  {
  NSMutableArray * objects = [NSMutableArray array];
  
  for(ESLevelDBKey key in keys)
    {
    ESLevelDBType value = [self objectForKey: key];
    
    if(!value)
      value = object;
      
    [objects addObject: value];
    }
    
  return [objects copy];
  } */

/* NSDictionary should handle this.
// Return the "value" for a key.
- (id) valueForKey: (NSString *) key
  {
  if([key length])
    {
    if([key characterAtIndex: 0] == '@')
      return [super valueForKey: [key substringFromIndex: 1]];
    else
      return [self objectForKey: key];
    }
    
  return nil;
  } */

// Return an object enumerator.
- (NSEnumerator *) objectEnumerator
  {
  return [[ESLevelDBValueEnumerator alloc] initWithDB: self];
  }

/* NSDictionary should handle this.
// Enumerate keys and objects using a block.
- (void) enumerateKeysAndObjectsUsingBlock:
  (void (^)(id key, id obj, BOOL * stop)) block
  {
  NSEnumerator * enumerator = [self keyEnumerator];
  
  BOOL stop = NO;
  
	while(YES)
    {
    ESLevelDBKey key = [enumerator nextObject];
    
    if(!key)
      break;
    
    block(key, self[key], & stop);
    
    if(stop)
      break;
	  }
  } */

// NSDictionary does not handle enumeration options, but I will.
// Enumerate keys and objects using a block with options.
- (void) enumerateKeysAndObjectsWithOptions: (NSEnumerationOptions) options
  usingBlock: (void (^)(id key, id obj, BOOL * stop)) block
  {
  ESLevelDBEnumerator * enumerator =
    [[ESLevelDBEnumerator alloc] initWithDB: self];
  
  enumerator.options = options;
  
  BOOL stop = NO;
  
	while(YES)
    {
    ESLevelDBKey key = [enumerator nextObject];
    
    if(!key)
      break;
      
    ESLevelDBType value = self[key];
    
    block(key, value, & stop);
    
    if(stop)
      break;
	  }
  } 

/* NSDictionary should handle this.
// Return sorted keys using a comparator.
- (NSArray *) keysSortedByValueUsingComparator: (NSComparator) comparator
  {
  return
    [[self allKeys]
      sortedArrayUsingComparator:
        ^NSComparisonResult(id key1, id key2)
          {
          return comparator(self[key1], self[key2]);
          }];
  } */

/* NSDictionary should handle this.
// Return sorted keys using a comparator selector.
- (NSArray *) keysSortedByValueUsingSelector: (SEL) comparator
  {
  return
    [[self allKeys]
      sortedArrayUsingComparator:
        ^NSComparisonResult(id key1, id key2)
          {
          id obj1 = self[key1];
          id obj2 = self[key2];
          id result = [obj1 performSelector: comparator withObject: obj2];
            
          return (NSComparisonResult)(long)result;
          }];
  } */

/* NSDictionary should handle this.
// Return sorted keys using a comparator with options.
- (NSArray *) keysSortedByValueWithOptions: (NSSortOptions) options
  usingComparator: (NSComparator) comparator
  {
  return
    [[self allKeys]
      sortedArrayWithOptions: options
      usingComparator:
        ^NSComparisonResult(id key1, id key2)
          {
          return comparator(self[key1], self[key2]);
          }];
  } */

/* NSDictionary should handle this.
// Return a set of keys passing a predicate test.
- (NSSet *) keysOfEntriesPassingTest:
  (BOOL (^)(id key, id obj, BOOL * stop)) predicate
  {
  NSMutableSet * entriesPassingTest = [NSMutableSet set];
  
  [self
    enumerateKeysAndObjectsUsingBlock:
      ^(ESLevelDBKey key, ESLevelDBType obj, BOOL * stop)
        {
        if(predicate(key, obj, stop))
          [entriesPassingTest addObject: key];
        }];

  return [entriesPassingTest copy];
  } */

// NSDictionary does not support enumeration options, but I will.
// Return a set of keys passing a predicate test with options.
- (NSSet *) keysOfEntriesWithOptions: (NSEnumerationOptions) options
  passingTest: (BOOL (^)(id key, id obj, BOOL * stop)) predicate
  {
  NSMutableSet * entriesPassingTest = [NSMutableSet set];
  
  [self
    enumerateKeysAndObjectsWithOptions: options
    usingBlock:
      ^(ESLevelDBKey key, ESLevelDBType obj, BOOL * stop)
        {
        if(predicate(key, obj, stop))
          [entriesPassingTest addObject: key];
        }];

  return [entriesPassingTest copy];
  }

#pragma mark - Required NSMutableDictionary overrides

// Set an object for a key.
- (void) setObject: (id) object forKey: (id<NSCopying>) key
  {
  [self mutatingOperation:
    ^BOOL
      {
      (*self.db)->Put(
        self.writeOptions,
        ESleveldb::KeySlice((NSString *)key),
        ESleveldb::Slice(object, self.serializer)).ok();
        
      return YES;
      }];
  }

// Remove an object and key.
- (void) removeObjectForKey: (ESLevelDBKey) key
  {
  [self mutatingOperation:
    ^BOOL
      {
      (*self.db)->Delete(self.writeOptions, ESleveldb::KeySlice(key)).ok();
        
      return YES;
      }];
  }

#pragma mark - NSMutableDictionary overrides

/* NSMutableDictionary should handle this.
// Set and object and key using array subscript notation.
- (void) setObject: (id) object forKeyedSubscript: (id<NSCopying>) key
  {
  [self setObject: object forKey: key];
  } */

/* NSMutableDictionary should handle this.
// Set a "value" for a key.
- (void) setValue: (id) value forKey: (NSString *) key
  {
  [self mutatingOperation:
    ^BOOL
      {
      if(value)
        self.db->Put(
          self.writeOptions,
          ESleveldb::KeySlice(key),
          ESleveldb::Slice(value, self.serializer)).ok();

      else
        self.db->Delete(self.writeOptions, ESleveldb::KeySlice(key));
        
      return YES;
      }];
  } */

// Add entries from another dictionary.
- (void) addEntriesFromDictionary: (NSDictionary *) dictionary
  {
  // Use an atomic operation.
  ESLevelDBScratchPad * batch = [self batchView];
  
  [batch addEntriesFromDictionary: dictionary];
  
  [batch commit];
  }

// Set all entries form another dictionary.
- (void) setDictionary: (NSDictionary *) dictionary
  {
  // Use an atomic operation.
  ESLevelDBScratchPad * batch = [self batchView];
  
  [batch removeAllObjects];
  [batch addEntriesFromDictionary: dictionary];
  
  [batch commit];
  }

// Remove all objects.
- (void) removeAllObjects
  {
  // Use an atomic operation.
  ESLevelDBScratchPad * batch = [self batchView];
  
  [batch removeAllObjects];
  
  [batch commit];
  }

// Remove all objects and keys from a given array of keys.
- (void) removeObjectsForKeys: (NSArray *) keys
  {
  // Use an atomic operation.
  ESLevelDBScratchPad * batch = [self batchView];
  
  [batch removeObjectsForKeys: keys];
  
  [batch commit];
  }

#pragma mark - NSFastEnumeration interface

// This really isn't going to be that fast. It will be slower than
// regular enumeration really. The NSFastEnumerationState really doesn't
// provide any options.
- (NSUInteger) countByEnumeratingWithState: (NSFastEnumerationState *) state
  objects: (id __unsafe_unretained []) stackbuf count: (NSUInteger) length
  {
  // I guess the framework initializes this to zero for me.
  if(state->state == 0)
    {
    // The mutationPtr will point to a constant for a read-only class but
    // will be updated for a mutable class. I guess it won't be thread-safe,
    // but since this will cause an exception, Apple doesn't care.
    state->mutationsPtr = [self mutationPtr];
    
    // Create an enumerator and return the index to it.
    state->extra[0] = [self createEnumerator];
    
    // and update state to indicate that enumeration has started
    state->state = 1;
    }
  
  // I should have an enumerator at this location now.
  NSNumber * index =
    [NSNumber numberWithUnsignedInteger: state->extra[0]];

  ESLevelDBEnumerator * enumerator = self.enumerators[index];
  
  // Try to increment.
  if(![enumerator nextObject])
    {
    // The raw pointer in state->extra[0] holds a reference.
    [self.enumerators removeObjectForKey: index];
    
    return 0;
    }
    
  state->itemsPtr = enumerator.objectPtr;
  
  return 1;
  }

// To support NSFastEnumeration.
- (unsigned long *) mutationPtr
  {
  return & myHash;
  }

// Create an enumerator and return an index into the enumerator dictionary.
- (NSUInteger) createEnumerator
  {
  __block NSUInteger enumeratorIndex;
  
  dispatch_sync(
    self.queue,
    ^{
      ESLevelDBEnumerator * enumerator =
        [[ESLevelDBEnumerator alloc] initWithDB: self];
        
      enumeratorIndex = self.nextEnumeratorIndex;
      
      NSNumber * index =
        [NSNumber numberWithUnsignedInteger: enumeratorIndex];
      
      self.enumerators[index] = enumerator;
      
      [self willChangeValueForKey: @"nextEnumeratorIndex"];
      
      ++myNextEnumeratorIndex;
    
      [self didChangeValueForKey: @"nextEnumeratorIndex"];
    });
    
  return enumeratorIndex;
  }

#pragma mark - Batch support

// Commit a batch.
- (BOOL) commit: (ESLevelDBScratchPad *) batch
  {
  return
    [self mutatingOperation:
      ^BOOL
        {
        return (*self.db)->Write(self.writeOptions, batch.batch).ok();
        }];
  }

#pragma mark - Private support

- (BOOL) mutatingOperation: (BOOL (^)(void)) operation
  {
  __block BOOL result = NO;
  
  dispatch_sync(
    self.queue,
    ^{
      ++myHash;
  
      result = operation();
    });
    
  return result;
  }

@end
