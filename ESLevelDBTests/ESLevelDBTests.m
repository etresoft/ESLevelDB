/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

//
//  ESLevelDBTests.m
//  ESLevelDBTests
//
//  Created by Adam Preble on 8/14/12.
//  Copyright (c) 2012 Adam Preble. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ESLevelDB/ESLevelDB.h"

@interface ESLevelDBTests : XCTestCase
  {
	ESLevelDB * db;
	NSData * largeData;
  }

@end

@implementation ESLevelDBTests

- (void) setUp
  {
  [super setUp];
    
  // Set-up code here.
	
	NSString * path =
    [NSTemporaryDirectory()
      stringByAppendingPathComponent: @"test.leveldb"];
	
	if([[NSFileManager defaultManager] fileExistsAtPath:path])
		[[NSFileManager defaultManager] removeItemAtPath:path error: nil];
	
  NSError * error = nil;
  
	db = [ESLevelDB levelDBWithPath:path error: & error];
  
  XCTAssertNotNil(db, @"Failed setup: %@", [error description]);
  }

- (void) tearDown
  {
  // Tear-down code here.
	db = nil;
    
  [super tearDown];
  }

#pragma mark - ESLevelDBMutableDictionary test cases.

- (void) testAllKeys
  {
	NSDictionary * keysAndValues =
    [self populateWithUUIDsAndReturnDictionary];

	NSArray * sortedOriginalKeys =
    [keysAndValues.allKeys sortedArrayUsingSelector: @selector(compare:)];
    
	XCTAssertEqualObjects(
    sortedOriginalKeys, [db allKeys], @"Failed allKeys");
  }

- (void) testAllKeysForObject
  {
	db[@"a"] = @"1";
	db[@"ab"] = @"2";
	db[@"abc"] = @"3";
	db[@"bc"] = @"4";
	db[@"bcd"] = @"5";
	db[@"cd"] = @"3";
	db[@"cde"] = @"7";

	NSArray * expected = @[@"abc", @"cd"];

	XCTAssertEqualObjects(
    expected, [db allKeysForObject: @"3"], @"Failed allKeysForObject:");
  }

- (void) testAllValues
  {
	db[@"a"] = @"1";
	db[@"ab"] = @"2";
	db[@"abc"] = @"3";
	db[@"bc"] = @"4";

	NSArray * expected = @[@"1", @"2", @"3", @"4"];

	XCTAssertEqualObjects(expected, [db allValues], @"Failed allValues");
  }

- (void) testGetObjectsAndKeys
  {
	db[@"a"] = @"1";
	db[@"ab"] = @"2";
	db[@"abc"] = @"3";
	db[@"bc"] = @"4";

  __unsafe_unretained id * keys =
    (__unsafe_unretained id *)malloc(sizeof(id) * 4);
  __unsafe_unretained id * objects =
    (__unsafe_unretained id *)malloc(sizeof(id) * 4);
  
  [db getObjects: objects andKeys: keys];
  
	NSArray * expectedKeys = @[@"a", @"ab", @"abc", @"bc"];
	NSArray * expectedObjects = @[@"1", @"2", @"3", @"4"];

  BOOL keysMatch = YES;
  
  NSUInteger i = 0;
  
  for(id obj in expectedKeys)
    if(![obj isEqual: keys[i++]])
      keysMatch = NO;
  
  BOOL objectsMatch = YES;
  
  i = 0;
  
  for(id obj in expectedObjects)
    if(![obj isEqual: objects[i++]])
      objectsMatch = NO;
  
  free(keys);
  free(objects);

	XCTAssert(keysMatch, @"Failed getObjects:andKeys: keys don't match");
	XCTAssert(
    objectsMatch, @"Failed getObjects:andKeys: objects don't match");
  }

- (void) testObjectForKey
  {
	NSString * text = @"Hello";
	NSString * key = @"key";
	[db setObject: text forKey: key];
	
	XCTAssertEqualObjects(
    text, [db objectForKey: key], @"Error retrieving string for key.");
  }

- (void) testObjectForKeyedSubscript
  {
	NSString * text = @"Hello";
	NSString * key = @"key";
	[db setObject: text forKey: key];
	
	XCTAssertEqualObjects(
    text, db[key], @"Error retrieving string for key.");
  }

- (void) testObjectsForKeysNotFoundMarker
  {
	db[@"a"] = @"1";
	db[@"ab"] = @"2";
	db[@"abc"] = @"3";
	db[@"bc"] = @"4";
	db[@"bcd"] = @"5";
	db[@"cd"] = @"6";
	db[@"cde"] = @"7";

	NSArray * expected = @[@"3", @"no", @"6"];
  NSArray * found =
    [db objectsForKeys: @[@"abc", @"noone", @"cd"] notFoundMarker: @"no"];

	XCTAssertEqualObjects(
    expected, found, @"objectsForKeys:notFoundMarker failed");
  }

- (void) testValueForKey
  {
	db[@"a"] = @"1";
	db[@"ab"] = @"2";
	db[@"abc"] = @"3";
	db[@"bc"] = @"4";
	db[@"bcd"] = @"5";
	db[@"cd"] = @"6";
	db[@"cde"] = @"7";

	XCTAssertEqualObjects(
    @"5", [db valueForKey: @"bcd"], @"valueForKey: failed");

	XCTAssertEqualObjects(
    db.serializer,
    [db valueForKey: @"@serializer"],
    @"valueForKey: failed");
  }

- (void) testKeyEnumerator
  {
	db[@"b"] = @"2";
	db[@"a"] = @"1";
  
  NSEnumerator * enumerator = [db keyEnumerator];
  
	XCTAssertEqualObjects(
    [enumerator nextObject],
    @"a",
    @"Iterator should start at the first key.");
	
	XCTAssertEqualObjects(
    [enumerator nextObject],
    @"b",
    @"Iterator should progress to the second key.");
  }

- (void) testObjectsEnumerator
  {
	db[@"a"] = @"1";
	db[@"ab"] = @"2";
	db[@"abc"] = @"3";
	db[@"bc"] = @"4";
	db[@"bcd"] = @"5";
	db[@"cd"] = @"6";
	db[@"cde"] = @"7";

	NSArray * expected = @[@"1", @"2", @"3", @"4", @"5", @"6", @"7"];
  
  NSMutableArray * found = [NSMutableArray array];
  
  NSEnumerator * enumerator = [db objectEnumerator];
  
  while(YES)
    {
    ESLevelDBType value = [enumerator nextObject];
    
    if(value)
      [found addObject: value];
    else
      break;
    }
    
	XCTAssertEqualObjects(
    expected, found, @"objectEnumerator failed");
  }

- (void) testEnumerateKeysAndObjectsUsingBlock
  {
	NSDictionary * keysAndValues =
    [self populateWithUUIDsAndReturnDictionary];
	NSArray * sortedOriginalKeys =
    [keysAndValues.allKeys sortedArrayUsingSelector: @selector(compare:)];
	
	__block NSUInteger keyIndex = 0;
  
  [db
    enumerateKeysAndObjectsUsingBlock:
      ^(ESLevelDBKey key, ESLevelDBType obj, BOOL * stop)
      {
		  XCTAssertEqualObjects(
        key,
        sortedOriginalKeys[keyIndex],
        @"enumerated key does not match");
		  keyIndex++;
      }];
  }

- (void) testEnumerateKeysAndObjectsWithOptionsUsingBlock
  {
	NSDictionary * keysAndValues =
    [self populateWithUUIDsAndReturnDictionary];
	NSArray * sortedOriginalKeys =
    [keysAndValues.allKeys sortedArrayUsingSelector: @selector(compare:)];
	
	NSMutableArray * reversedKeys = [NSMutableArray array];
  
  [db
    enumerateKeysAndObjectsWithOptions: NSEnumerationReverse
    usingBlock:
      ^(ESLevelDBKey key, ESLevelDBType obj, BOOL * stop)
        {
        [reversedKeys addObject: key];
        }];

	XCTAssertNotEqualObjects(
    sortedOriginalKeys, reversedKeys, @"Error with reverse iteration.");
  }

- (void) testKeysSortedByValueUsingComparator
  {
	db[@"cde"] = @1;
	db[@"ab"] = @2;
	db[@"bcd"] = @5;
	db[@"cd"] = @6;
	db[@"abc"] = @3;
	db[@"a"] = @7;
	db[@"bc"] = @4;

  NSArray * expectedKeys =
    @[@"cde", @"ab", @"abc", @"bc", @"bcd", @"cd", @"a"];
  
  NSArray * sortedKeys =
    [db
      keysSortedByValueUsingComparator:
        ^NSComparisonResult(id obj1, id obj2)
        {
        return [obj1 compare: obj2];
        }];
  
	XCTAssertEqualObjects(
    sortedKeys, expectedKeys, @"Failed keysSortedByValueUsingComparator:.");
  }

- (void) testKeysSortedByValueUsingSelector
  {
	db[@"cde"] = @1;
	db[@"ab"] = @2;
	db[@"bcd"] = @5;
	db[@"cd"] = @6;
	db[@"abc"] = @3;
	db[@"a"] = @7;
	db[@"bc"] = @4;

  NSArray * expectedKeys =
    @[@"cde", @"ab", @"abc", @"bc", @"bcd", @"cd", @"a"];
  
  NSArray * sortedKeys =
    [db keysSortedByValueUsingSelector: @selector(compare:)];
    
	XCTAssertEqualObjects(
    sortedKeys, expectedKeys, @"Failed keysSortedByValueUsingSelector:.");
  }

- (void) testKeysSortedByValueWithOptionsUsingComparator
  {
	db[@"cde"] = @1;
	db[@"ab"] = @2;
	db[@"bcd"] = @5;
	db[@"cd"] = @6;
	db[@"abc"] = @3;
	db[@"a"] = @7;
	db[@"bc"] = @4;

  NSArray * expectedKeys =
    @[@"cde", @"ab", @"abc", @"bc", @"bcd", @"cd", @"a"];
  
  NSArray * sortedKeys =
    [db keysSortedByValueWithOptions: NSSortStable
      usingComparator:
       ^NSComparisonResult(id obj1, id obj2)
         {
          return [obj1 compare: obj2];
         }];
    
	XCTAssertEqualObjects(
    sortedKeys,
    expectedKeys,
    @"Failed keysSortedByValueWithOptions:usingComparator:.");
  }

- (void) testKeysOfEntriesPassingTest
  {
	db[@"cde"] = @1;
	db[@"ab"] = @2;
	db[@"bcd"] = @5;
	db[@"cd"] = @6;
	db[@"abc"] = @3;
	db[@"a"] = @7;
	db[@"bc"] = @4;

  NSArray * expectedKeys =
    @[@"cde", @"ab", @"abc", @"bc"];
  
  NSSet * passingKeys =
    [db
      keysOfEntriesPassingTest:
        ^BOOL(NSString * key,
          ESLevelDBType obj,
          BOOL * stop)
          {
          return [(NSNumber *)obj intValue] < 5;
          }];
    
  NSUInteger nonMatchingEntries = [expectedKeys count];
  
  for(NSString * key in expectedKeys)
    if([passingKeys containsObject: key])
      --nonMatchingEntries;
    
	XCTAssert(nonMatchingEntries == 0, @"Failed keysOfEntriesPassingTest:");
  }

- (void) testKeysOfEntriesWithOptionsPassingTest
  {
	db[@"cde"] = @1;
	db[@"ab"] = @2;
	db[@"bcd"] = @5;
	db[@"cd"] = @6;
	db[@"abc"] = @3;
	db[@"a"] = @7;
	db[@"bc"] = @4;

  NSArray * expectedKeys =
    @[@"cde", @"ab", @"abc", @"bc"];
    
  NSArray * expectedKeysReversed =
    [expectedKeys
      sortedArrayUsingComparator:
        ^NSComparisonResult(id obj1, id obj2)
          {
          return -[obj1 compare: obj2];
          }];
  
  NSMutableArray * keysReversed = [NSMutableArray array];
  
  NSSet * passingKeys =
    [db
      keysOfEntriesWithOptions: NSEnumerationReverse
      passingTest:
        ^BOOL(ESLevelDBKey key,
          ESLevelDBType obj,
          BOOL * stop)
          {
          if([(NSNumber *)obj intValue] < 5)
            {
            [keysReversed addObject: key];
            
            return YES;
            }
            
          return NO;
          }];
    
  NSUInteger nonMatchingEntries = [expectedKeys count];
  
  for(NSString * key in expectedKeys)
    if([passingKeys containsObject: key])
      --nonMatchingEntries;
    
	XCTAssert(nonMatchingEntries == 0, @"Failed keysOfEntriesPassingText:");

  XCTAssertEqualObjects(
    expectedKeysReversed,
    keysReversed,
    @"Failed keysOfEntriesWithOptions:passingTest: options failed");
  }

- (void) testEnumerateKeysAndObjectsFromLimitUsingBlock
  {
	db[@"a"] = @"1";
	db[@"ab"] = @"2";
	db[@"abc"] = @"3";
	db[@"bc"] = @"4";
	db[@"bcd"] = @"5";
	db[@"cd"] = @"6";
	db[@"cde"] = @"7";
	
  __block NSMutableArray * found = [NSMutableArray array];
  
  [db
    enumerateKeysAndObjectsFrom: @"ab"
    limit: @"cd"
    usingBlock:
      ^(ESLevelDBKey key, ESLevelDBType obj, BOOL * stop)
        {
        [found addObject: obj];
        }];
  
  XCTAssertEqualObjects(
    @"2",
    [found firstObject],
    @"First iterator result is %@ but should be 2", [found firstObject]);

  XCTAssertEqualObjects(
    @"5",
    [found lastObject],
    @"Last iterator result is %@ but should be 5", [found lastObject]);
  }

- (void) testEnumerateKeysAndObjectsFromLimitWithOptionsUsingBlock
  {
	db[@"a"] = @"1";
	db[@"ab"] = @"2";
	db[@"abc"] = @"3";
	db[@"bc"] = @"4";
	db[@"bcd"] = @"5";
	db[@"cd"] = @"6";
	db[@"cde"] = @"7";
	
  __block NSMutableArray * found = [NSMutableArray array];
  
  [db
    enumerateKeysAndObjectsFrom: @"ab"
    limit: @"cd"
    withOptions: NSEnumerationReverse
    usingBlock:
      ^(ESLevelDBKey key, ESLevelDBType obj, BOOL * stop)
        {
        [found addObject: obj];
        }];
  
  XCTAssertEqualObjects(
    @"5",
    [found firstObject],
    @"First iterator result is %@ but should be 2", [found firstObject]);

  XCTAssertEqualObjects(
    @"2",
    [found lastObject],
    @"Last iterator result is %@ but should be 5", [found lastObject]);
  }

#pragma mark - ESLevelDBMutableDictionary test cases.

- (void) testSetObjectForKey
  {
	// Create some test data using NSKeyedArchiver:
	NSData * data =
    [NSKeyedArchiver archivedDataWithRootObject: [NSDate date]];
	NSString * key = @"key";
	[db setObject: data forKey: key];
	
	NSData * fetched = (NSData *)[db objectForKey: key];
  
	XCTAssertNotNil(fetched, @"Key for data not found.");
	XCTAssertEqualObjects(
    data, fetched, @"Fetched data doesn't match original data.");
  }

- (void) testSetObjectForKeyedSubscript
  {
	NSString * text = @"Hello";
	NSString * key = @"key";
	db[key] = text;
	
	XCTAssertEqualObjects(text, db[key], @"Error retrieving string for key.");
  }

// TODO: Missing test cases.

- (void) testRemoveObjectForKey
  {
	NSString * text = @"Hello";
	NSString * key = @"key";
	[db setObject: text forKey: key];
	
	XCTAssertEqualObjects(
    text,
    [db objectForKey:key],
    @"stringForKey should have returned the original text");
	
	[db removeObjectForKey: key];
	
	XCTAssertNil(
    [db objectForKey:key],
    @"stringForKey should return nil after removal of key");
    
	XCTAssertNil(
    [db objectForKey:key],
    @"dataForKey should return nil after removal of key");
  }

#pragma mark - NSFastEnumeration

- (void) testFastEnumeration
  {
	// Create some test data using NSKeyedArchiver:
	[db
    setObject:
      @{
        @"key1" : @"This is a key",
        @"key2" : [NSDate date],
        @"key3" : @4.5
      }
    forKey: @"dict 1"];
    
	[db
    setObject:
      @{
        @"key1" : @"This is another key",
        @"key2" : [db[@"dict 1"][@"key2"] dateByAddingTimeInterval: -1],
        @"key3" : @4.51
      }
    forKey: @"dict 2"];
	
  for(NSString * key in db)
    {
    NSLog(@"%@.key1: %@", key, db[key][@"key1"]);
    NSLog(@"%@.key2: %@", key, db[key][@"key2"]);
    NSLog(@"%@.key3: %@", key, db[key][@"key3"]);
    }
  }

#pragma mark - Other tests

- (void) testNilForUnknownKey
  {
	XCTAssertNil(
    [db objectForKey: @"made up key"],
    @"objectForKey: should return nil if a key doesn't exist");
  }

- (void) testSubscriptingNilForUnknownKey
  {
	XCTAssertNil(
    db[@"no such key as this key"],
    @"Subscripting access should return nil for an unknown key.");
  }

- (void) testLargeValue
  {
	NSString * key = @"key";
	NSData * data = [self largeData];
	
	[db setObject: data forKey: key];
  
	XCTAssertEqualObjects(
    data,
    [db objectForKey:key],
    @"Data read from database does not match original.");
  }

/* - (void) testcount
  {
	[self populateWithUUIDsAndReturnDictionary];
  
  XCTAssertEqual(64, [db count], @"Count is %ld, should be 64", [db count]);
  
	ESLevelDBScratchPad * batch = [db batch];
  
	[batch setObject: @"1" forKey: @"a"];

  XCTAssertEqual(
    65, [batch count], @"Count is %ld, should be 65", [batch count]);

	[batch removeAllObjects];
	[batch setObject: @"2" forKey: @"b"];
	[batch removeObjectForKey: @"b"];
	[batch commit];
  
  XCTAssertEqual(0, [db count], @"Count is %ld, should be 0", [db count]);
  } */

#pragma mark - LevelDB seekable iterators

- (void) testIteratorSeek
  {
	db[@"a"] = @"1";
	db[@"ab"] = @"2";
	db[@"abc"] = @"3";
	
  ESLevelDBEnumerator * enumerator =
    [[ESLevelDBEnumerator alloc] initWithView: db];

  enumerator.start = @"ab";
  
  ESLevelDBType key = [enumerator nextObject];
  
	XCTAssertEqualObjects(
    key, @"ab", @"Iterator did not seek properly.");
  }

- (void) testIteratorSeekToNonExistentKey
  {
	db[@"a"] = @"1";
	db[@"ab"] = @"2";
	db[@"abc"] = @"3";
	
  ESLevelDBEnumerator * enumerator =
    [[ESLevelDBEnumerator alloc] initWithView: db];

  enumerator.start = @"aa";
  
  ESLevelDBType key = [enumerator nextObject];
  
  NSLog(@"The key is %@", key);
  
	XCTAssertEqualObjects(
    key, @"ab", @"Iterator did not seek properly.");
  }

- (void) testIteratorStepPastEnd
  {
	db[@"a"] = @"1";
	db[@"ab"] = @"2";
	db[@"abc"] = @"3";
	
  ESLevelDBEnumerator * enumerator =
    [[ESLevelDBEnumerator alloc] initWithView: db];

  enumerator.start = @"ab";
  
  [enumerator nextObject];
  [enumerator nextObject];

  XCTAssertNil(
    [enumerator nextObject], @"Iterator should return nil at end of keys.");
  }

#pragma mark - ESLevelDBScratchPad

- (void) testAtomicSimple
  {
	[db setObject:@"3" forKey:@"c"];
	
	ESLevelDBScratchPad * batch = [db batch];
	
  [batch setObject: @"1" forKey: @"a"];
	[batch setObject: @"2" forKey: @"b"];
	[batch removeObjectForKey: @"c"];
	[batch commit];
	
	XCTAssertEqualObjects(db[@"a"], @"1", @"Batch write did not execute");
	XCTAssertEqualObjects(db[@"b"], @"2", @"Batch write did not execute");
	XCTAssertNil(db[@"c"], @"Batch write did not remove key");
  }

- (void) testAtomicWithClear
  {
	[db setObject: @"3" forKey: @"c"];

	ESLevelDBScratchPad * batch = [db batch];
	
  [batch setObject: @"1" forKey: @"a"];
	[batch setObject: @"2" forKey: @"b"];
	[batch removeObjectForKey: @"c"];
	[batch removeAllObjects];
	[batch commit];
	
	XCTAssertNil(db[@"a"], @"Batch write did not clear buffered write");
	XCTAssertNil(db[@"b"], @"Batch write did not clear buffered write");
	
  // I changed the APLevelDB batch clear to removeAllObjects.
  //XCTAssertEqualObjects(db[@"c"], @"3", @"Batch clear buffered remove");
  }

- (void)testAtomicWithClearThenMutate
  {
	[db setObject: @"3" forKey: @"c"];

	ESLevelDBScratchPad * batch = [db batch];
  
	[batch setObject: @"1" forKey: @"a"];
	[batch removeAllObjects];
	[batch setObject: @"2" forKey: @"b"];
	[batch removeObjectForKey: @"c"];
	[batch commit];
	
	XCTAssertNil(db[@"a"], @"Batch write did not clear buffered write");
	XCTAssertEqualObjects(
    db[@"b"], @"2", @"Batch write did not execute after clear");
	XCTAssertNil(db[@"c"], @"Batch write did not remove key after clear");
  }

- (void) testAtomicAsync
  {
	// Create a background queue on which we will perform the write.
	dispatch_queue_t queue =
    dispatch_queue_create(__PRETTY_FUNCTION__, DISPATCH_QUEUE_SERIAL);
	
	// The semaphore will tell us when the write block has been called.
	dispatch_semaphore_t sem = dispatch_semaphore_create(0);
	
	[db setObject: @"3" forKey: @"c"];
	
	ESLevelDBScratchPad * batch = [db batch];

	// Batch a few writes immediately:
	[batch setObject: @"1" forKey: @"a"];
	[batch setObject: @"2" forKey: @"b"];
	
	XCTAssertNil(db[@"a"], @"Precondition failed");
	XCTAssertNil(db[@"b"], @"Precondition failed");
	XCTAssertEqualObjects(db[@"c"], @"3", @"Precondition failed");
	
	// Demonstrate, to the extent that we can, that the batch object
	// can be passed on to other areas of the program.  We don't have
	// to execute it immediately, or even from the same thread.
	dispatch_async(
    queue,
    ^{
		  // According to the leveldb docs, the leveldb object does necessary
      // synchronization for writes from multiple threads, so it's okay to
      // send commitWriteBatch: from a thread/queue other than the one the
      // database was created on.
		  [batch removeObjectForKey:@"c"];
		
		  // Execute the batched writes:
		  [batch commit];
		
		  // Tell the main thread that we're done and it can check our work.
		  dispatch_semaphore_signal(sem);
	  });
	
	dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
	
	XCTAssertEqualObjects(db[@"a"], @"1", @"Batch write did not execute");
	XCTAssertEqualObjects(db[@"b"], @"2", @"Batch write did not execute");
	XCTAssertNil(db[@"c"], @"Batch write did not remove key");
  }

#pragma mark - Helpers

- (NSData *) largeData
  {
	if(!largeData)
	  {
    // 10MB
		NSUInteger numberOfBytes = 1024 * 1024 * 10;
    
		NSMutableData *data = [NSMutableData dataWithCapacity: numberOfBytes];
		
    [data setLength: numberOfBytes];
    
		char * buffer = [data mutableBytes];
		
    for(NSUInteger i = 0; i < numberOfBytes; i++)
			buffer[i] = i & 0xff;
		
		largeData = [data copy];
	  }
	
  return largeData;
  }

- (NSDictionary *) populateWithUUIDsAndReturnDictionary
  {
	// Generate random keys and values using UUIDs:
	const int numberOfKeys = 64;
  
	NSMutableDictionary * keysAndValues =
    [NSMutableDictionary dictionaryWithCapacity:numberOfKeys];
    
	for(int i = 0; i < numberOfKeys; i++)
		@autoreleasepool
      {
			keysAndValues[[[NSUUID UUID] UUIDString]] =
        [[NSUUID UUID] UUIDString];
		  }
	
	[keysAndValues
    enumerateKeysAndObjectsUsingBlock:
      ^(id key, id obj, BOOL * stop)
        {
		    [db setObject: obj forKey: key];
	      }];
	
	return keysAndValues;
  }

@end
