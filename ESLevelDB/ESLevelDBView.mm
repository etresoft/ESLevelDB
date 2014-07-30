/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "ESLevelDBView.h"
#import "ESLevelDBViewPrivate.h"
#import "leveldb/db.h"
#import "leveldb/options.h"
#import "ESLevelDBType.h"
#import "ESLevelDBSlice.h"
#import "ESLevelDBValue.h"
#import "ESLevelDBEnumerator.h"
#import "ESLevelDBEnumeratorPrivate.h"
#import "ESLevelDBValueEnumerator.h"
#import "ESLevelDBValueEnumeratorPrivate.h"

// To support NSFastEnumeration.
@interface ESLevelDBView ()

@property (readonly) NSMutableDictionary * enumerators;
@property (assign) NSUInteger nextEnumeratorIndex;

@end

@implementation ESLevelDBView
  {
  // Another hack to support the NSFastEnumeration API soup.
  unsigned long immutable;
  }

@synthesize count = myCount;

@synthesize fastCount = myFastCount;

@synthesize queue = myQueue;

@synthesize readOptions = myReadOptions;

@synthesize lastHash = myLastHash;

@synthesize enumerators = myEnumerators;

@synthesize nextEnumeratorIndex = myNextEnumeratorIndex;

// Constructor.
- (instancetype) init
  {
  self = [super init];
  
  if(self)
    {
    myFastCount = YES;
    immutable = [super hash];
    
    // I will need to calculate the count at least once.
    myLastHash = ~immutable;
    
    myNextEnumeratorIndex = 0;
    }
    
  return self;
  }

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

- (NSMutableDictionary *) enumerators
  {
  if(!myEnumerators)
    myEnumerators = [[NSMutableDictionary alloc] init];
    
  return myEnumerators;
  }

#pragma mark - ESLevelDBDictionary interface

// LevelDB doesn't support this, but it is important for Cocoa.
- (NSUInteger) count
  {
  // If my database hasn't changed, just return the last count.
  if(self.lastHash == [self hash])
    return myCount;
    
  // I should probably do this in a block, but I don't want to lock up too
  // much in the block.
  __block NSUInteger newCount = myCount;
  
  dispatch_sync(
    self.queue,
    ^{
      // Get the count from the database itself. If I can't find one, then
      // fall back to iteration.
      BOOL hasCount = NO;
      
      if(self.fastCount)
        {
        NSNumber * count =
          (NSNumber *)[self objectForKey: (ESLevelDBType)kCountKey];
      
        if(count)
          {
          newCount = [count unsignedIntegerValue];
          
          hasCount = YES;
          }
        }

      // If I didn't have a count in the database or I am not using fast
      // count at all, iterate for the count.
      if(!hasCount)
        {
        newCount = 0;
        
        leveldb::Iterator * iter =
          self.db->NewIterator(leveldb::ReadOptions());
        
        for(iter->SeekToFirst(); iter->Valid(); iter->Next())
          ++newCount;
        }
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

- (NSArray *) allKeys
  {
	NSMutableArray * keys = [NSMutableArray array];
  
  leveldb::Iterator * iter =
    self.db->NewIterator(leveldb::ReadOptions());
  
	for(iter->SeekToFirst(); iter->Valid(); iter->Next())
		[keys addObject: ESleveldb::Slice(iter->key())];
    
	return [keys copy];
  }

- (NSArray *) allKeysForObject: (NSObject<NSCoding> *) object
  {
	NSMutableArray * keys = [NSMutableArray array];
  
  leveldb::Iterator * iter =
    self.db->NewIterator(leveldb::ReadOptions());
  
	for(iter->SeekToFirst(); iter->Valid(); iter->Next())
    {
		ESleveldb::Slice key = iter->key();
    ESleveldb::Slice value = iter->value();
    
    if([object isEqualTo: static_cast<NSObject<NSCoding> *>(value)])
      [keys addObject: static_cast<NSObject<NSCoding> *>(key)];
	  }

	delete iter;
  
  return [keys copy];
  }

- (NSArray *) allValues
  {
	NSMutableArray * values = [NSMutableArray array];
  
  leveldb::Iterator * iter =
    self.db->NewIterator(leveldb::ReadOptions());
  
	for(iter->SeekToFirst(); iter->Valid(); iter->Next())
    {
    ESleveldb::Slice value = iter->value();
    
    [values addObject: static_cast<NSObject<NSCoding> *>(value)];
	  }

	delete iter;
  
  return [values copy];
  }

- (void) getObjects: (__strong ESLevelDBType []) objects
  andKeys: (__strong ESLevelDBType []) keys
  {
  *keys =
    (__bridge ESLevelDBType)malloc(sizeof(ESLevelDBType) * [self count]);
  *objects =
    (__bridge ESLevelDBType)malloc(sizeof(ESLevelDBType) * [self count]);
  
  leveldb::Iterator * iter =
    self.db->NewIterator(leveldb::ReadOptions());
  
  NSUInteger index = 0;
  
	for(iter->SeekToFirst(); iter->Valid(); iter->Next())
    {
		ESleveldb::Slice key = iter->key();
    ESleveldb::Slice value = iter->value();
    
    keys[index] = static_cast<ESLevelDBType>(key);
    objects[index] = static_cast<ESLevelDBType>(value);
	  }

	delete iter;
  }

- (ESLevelDBType) objectForKey: (ESLevelDBType) key
  {
  leveldb::ReadOptions options = leveldb::ReadOptions();
  
  ESLevelDBType value;
  
  ESleveldb::Value result(value);
  
	leveldb::Status status =
    self.db->Get(
      options, ESleveldb::Slice(key, *self.serializer), & result);

	if(!status.ok())
		return nil;
	
	return value;
  }

- (ESLevelDBType) objectForKeyedSubscript: (ESLevelDBType) key
  {
  leveldb::ReadOptions options = leveldb::ReadOptions();
  
  ESLevelDBType value;
  
  ESleveldb::Value result(value);
  
	leveldb::Status status =
    self.db->Get(
      options, ESleveldb::Slice(key, *self.serializer), & result);

	if(!status.ok())
		return nil;
	
	return value;
  }

- (NSArray *) objectsForKeys: (NSArray *) keys
  notFoundMarker: (id) object
  {
  NSMutableArray * objects = [NSMutableArray array];
  
  for(NSObject<NSCoding> * key in keys)
    {
    ESLevelDBType value = [self objectForKey: key];
    
    if(!value)
      value = object;
      
    [objects addObject: value];
    }
    
  return [objects copy];
  }

- (ESLevelDBType) valueForKey: (NSString *) key
  {
  if([key length])
    if([key characterAtIndex: 0] == '@')
      return [self objectForKey: [key substringFromIndex: 1]];
    
  return nil;
  }

- (NSEnumerator *) keyEnumerator
  {
  return [[ESLevelDBEnumerator alloc] initWithView: self];
  }

- (NSEnumerator *) objectEnumerator
  {
  return [[ESLevelDBValueEnumerator alloc] initWithView: self];
  }

- (void) enumerateKeysAndObjectsUsingBlock:
  (void (^)(ESLevelDBType key, ESLevelDBType obj, BOOL * stop)) block
  {
  leveldb::Iterator * iter =
    self.db->NewIterator(leveldb::ReadOptions());
  
  BOOL stop = NO;
  
	for(iter->SeekToFirst(); iter->Valid(); iter->Next())
    {
		ESleveldb::Slice key = iter->key();
    ESleveldb::Slice value = iter->value();
    
    block(key, value, & stop);
    
    if(stop)
      break;
	  }
  }

- (void) enumerateKeysAndObjectsWithOptions: (NSEnumerationOptions) opts
  usingBlock:
    (void (^)(ESLevelDBType key, ESLevelDBType obj, BOOL *stop)) block
  {
  // According to the docs, I can just ignore this one for NSDictionary.
  [self enumerateKeysAndObjectsUsingBlock: block];
  }

- (NSArray *) keysSortedByValueUsingComparator: (NSComparator) comparator
  {
  return [[self allKeys] sortedArrayUsingComparator: comparator];
  }

- (NSArray *) keysSortedByValueUsingSelector: (SEL) comparator
  {
  return [[self allKeys] sortedArrayUsingSelector: comparator];
  }

- (NSArray *) keysSortedByValueWithOptions: (NSSortOptions) options
  usingComparator: (NSComparator) comparator
  {
  return
    [[self allKeys]
      sortedArrayWithOptions: options usingComparator: comparator];
  }

- (NSSet *) keysOfEntriesPassingTest:
  (BOOL (^)(ESLevelDBType key, ESLevelDBType obj, BOOL * stop)) predicate
  {
  return
    [NSSet setWithArray:
      [[self allKeys]
        objectsAtIndexes:
          [[self allKeys]
            indexesOfObjectsPassingTest:
              (BOOL (^)(id obj, NSUInteger idx, BOOL *stop))predicate]]];
  }

- (NSSet *) keysOfEntriesWithOptions: (NSEnumerationOptions) options
  passingTest:
    (BOOL (^)(ESLevelDBType key, ESLevelDBType obj, BOOL * stop)) predicate
  {
  return
    [NSSet setWithArray:
      [[self allKeys]
        objectsAtIndexes:
          [[self allKeys]
            indexesOfObjectsWithOptions: options
            passingTest:
              (BOOL (^)(id obj, NSUInteger idx, BOOL *stop))predicate]]];
  }

// To support NSFastEnumeration.
- (unsigned long *) mutationPtr
  {
  return & immutable;
  }

#pragma mark - NSFastEnumeration interface

// Create an enumerator and return an index into the enumerator dictionary.
- (NSUInteger) createEnumerator
  {
  __block NSUInteger enumeratorIndex;
  
  dispatch_sync(
    self.queue,
    ^{
      ESLevelDBEnumerator * enumerator =
        [[ESLevelDBEnumerator alloc] initWithView: self];
        
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
    return 0;
    
  state->itemsPtr = enumerator.objectPtr;
  
  return 1;
  }

@end
