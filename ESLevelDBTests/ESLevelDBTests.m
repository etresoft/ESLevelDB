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
#import "ESLevelDB.h"
#import "ESLevelDBScratchPad.h"

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
	
	db = [ESLevelDB levelDBWithPath:path error:nil];
  }

- (void) tearDown
  {
  // Tear-down code here.
	db = nil;
    
  [super tearDown];
  }

#pragma mark - Tests

- (void) testSetStringForKey
  {
	NSString * text = @"Hello";
	NSString * key = @"key";
	[db setObject: text forKey: key];
	
	XCTAssertEqualObjects(
    text, [db objectForKey: key], @"Error retrieving string for key.");
  }

- (void) testSetDataForKey
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

- (void) testNilForUnknownKey
  {
	XCTAssertNil(
    [db objectForKey: @"made up key"],
    @"stringForKey: should return nil if a key doesn't exist");
    
	XCTAssertNil(
    [db objectForKey: @"another made up key"],
    @"dataForKey: should return nil if a key doesn't exist");
  }

- (void) testObjectForData
  {
	// Create some test data using NSKeyedArchiver:
	NSDate * now = [NSDate date];
  NSDate * then = [now dateByAddingTimeInterval: -100];
  
	[db setObject: now forKey: @"now"];
  [db setObject: then forKey: @"then"];
	
  NSDate * whenever = [now copy];
  
	XCTAssertEqualObjects(
    db[@"now"], whenever, @"Fetched data doesn't match original data.");
  
  XCTAssertNotEqualObjects(db[@"then"], db[@"now"], @"Then wasn't now");
  }

- (void) testObjectForKey
  {
	// Create some test data using NSKeyedArchiver:
	NSDate * now = [NSDate date];
  NSDate * then = [now dateByAddingTimeInterval: -100];
  
	[db setObject: @"now" forKey: now];
  [db setObject: @"then" forKey: then];
	
  __block int count = 0;
  
  [db
    enumerateKeysAndObjectsUsingBlock:
      ^(id<NSObject,NSSecureCoding,NSCopying> key,
      id<NSObject,NSSecureCoding,NSCopying> obj,
      BOOL * stop)
      {
      if([obj isEqual: @"now"])
        {
        }
      else if([obj isEqual: @"then"])
        {
        }
      else
        {
        XCTAssert(YES, @"Unexpected object: %@", obj);
        }
		  
      ++count;
      }];
  
	XCTAssertEqual(count, 2, @"Count is wrong");
  }

/* - (void) testFastEnumeration
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
	
 [db
    enumerateKeysAndObjectsUsingBlock:
      ^(id<NSObject,NSSecureCoding,NSCopying> key,
      id<NSObject,NSSecureCoding,NSCopying> obj,
      BOOL * stop)
  for(NSString * key in db)
    {
    NSLog(@"%@.key1: %@", key, db[key][@"key1"]);
    NSLog(@"%@.key2: %@", key, db[key][@"key2"]);
    NSLog(@"%@.key3: %@", key, db[key][@"key3"]);
    } // ];
  } */

- (void) testRemoveKey
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

- (void) testAllKeys
  {
	NSDictionary * keysAndValues =
    [self populateWithUUIDsAndReturnDictionary];

	NSArray * sortedOriginalKeys =
    [keysAndValues.allKeys sortedArrayUsingSelector: @selector(compare:)];
    
	XCTAssertEqualObjects(sortedOriginalKeys, [db allKeys], @"");
  }

- (void) testEnumeration
  {
	NSDictionary * keysAndValues =
    [self populateWithUUIDsAndReturnDictionary];
	NSArray * sortedOriginalKeys =
    [keysAndValues.allKeys sortedArrayUsingSelector: @selector(compare:)];
	
	__block NSUInteger keyIndex = 0;
  
  [db
    enumerateKeysAndObjectsUsingBlock:
      ^(id<NSObject,NSSecureCoding,NSCopying> key,
      id<NSObject,NSSecureCoding,NSCopying> obj,
      BOOL * stop)
      {
		  XCTAssertEqualObjects(
        key,
        sortedOriginalKeys[keyIndex],
        @"enumerated key does not match");
		  keyIndex++;
      }];
  }

- (void) testEnumerationUsingStrings
  {
	NSDictionary * keysAndValues =
    [self populateWithUUIDsAndReturnDictionary];
	NSArray * sortedOriginalKeys =
    [keysAndValues.allKeys sortedArrayUsingSelector: @selector(compare:)];
	
	__block NSUInteger keyIndex = 0;
  
  [db
    enumerateKeysAndObjectsUsingBlock:
      ^(id<NSObject,NSSecureCoding,NSCopying> key,
        id<NSObject,NSSecureCoding,NSCopying> obj,
        BOOL * stop)
        {
        NSString * originalKey = sortedOriginalKeys[keyIndex];
        XCTAssertEqualObjects(
          key, originalKey, @"enumerated key does not match");
        XCTAssertEqualObjects(
          obj,
          keysAndValues[originalKey],
          @"enumerated value does not match");
        
        keyIndex++;
        }];
  }

- (void) testSubscripting
  {
	NSString * text = @"Hello";
	NSString * key = @"key";
	db[key] = text;
	
	XCTAssertEqualObjects(text, db[key], @"Error retrieving string for key.");
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

#pragma mark - Tests - Iterators

- (void) testIteratorStartsAtFirstKey
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

/* - (void) testIteratorSeek
  {
	db[@"a"] = @"1";
	db[@"ab"] = @"2";
	db[@"abc"] = @"3";
	
	ESLevelDBIterator * iter =
    [ESLevelDBIterator iteratorWithLevelDB:db];
	
  [iter seekToKey:@"ab"];
	
	XCTAssertEqualObjects(
    [iter key], @"ab", @"Iterator did not seek properly.");
	
  XCTAssertEqualObjects(
    [iter valueAsString], @"2", @"Iterator value incorrect.");
	
	XCTAssertEqualObjects(
    [iter nextKey], @"abc", @"Iterator did not seek properly.");
	
  XCTAssertEqualObjects(
    [iter valueAsString], @"3", @"Iterator value incorrect.");
  } */

/* - (void) testIteratorSeekToNonExistentKey
  {
	db[@"a"] = @"1";
	db[@"ab"] = @"2";
	db[@"abc"] = @"3";
	
	ESLevelDBIterator * iter = [ESLevelDBIterator iteratorWithLevelDB:db];
	
  // seeking to a key that doesn't exist should jump us to the next 
  // possible key.
  [iter seekToKey:@"aa"];
	
	XCTAssertEqualObjects(
    [iter key], @"ab", @"Iterator did not seek properly.");
	
  XCTAssertEqualObjects(
    [iter valueAsString], @"2", @"Iterator value incorrect.");
	
	XCTAssertEqualObjects(
    [iter nextKey], @"abc", @"Iterator did not advance properly.");
	
  XCTAssertEqualObjects(
    [iter valueAsString], @"3", @"Iterator value incorrect.");
  } */

/* - (void) testIteratorStepPastEnd
  {
	db[@"a"] = @"1";
	db[@"ab"] = @"2";
	db[@"abc"] = @"3";
	
	ESLevelDBIterator * iter = [ESLevelDBIterator iteratorWithLevelDB: db];
	
  [iter seekToKey:@"ab"];
	
  // abc
  [iter nextKey];
	
  XCTAssertNil(
    [iter nextKey], @"Iterator should return nil at end of keys.");
	XCTAssertNil(
    [iter valueAsData], @"Iterator should return nil at end of keys.");
	XCTAssertNil(
    [iter valueAsString], @"Iterator should return nil at end of keys.");
  } */

#pragma mark - Atomic Updates

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
