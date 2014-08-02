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

@interface ESLevelDBTests : XCTestCase {
	ESLevelDB *_db;
	NSData *_largeData;
}

@end

@implementation ESLevelDBTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
	
	NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"test.leveldb"];
	
  //NSLog(@"Created test file %@", path);
	if ([[NSFileManager defaultManager] fileExistsAtPath:path])
		[[NSFileManager defaultManager] removeItemAtPath:path error:nil];
	
	_db = [ESLevelDB levelDBWithPath:path error:nil];
}

- (void)tearDown
{
    // Tear-down code here.
	_db = nil;
    
    [super tearDown];
}

#pragma mark - Tests

- (void)testSetStringForKey
{
	NSString *text = @"Hello";
	NSString *key = @"key";
	[_db setObject:text forKey:key];
	
	XCTAssertEqualObjects(text, [_db objectForKey:key], @"Error retrieving string for key.");
}

- (void)testSetDataForKey
{
	// Create some test data using NSKeyedArchiver:
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:[NSDate date]];
	NSString *key = @"key";
	[_db setObject:data forKey:key];
	
	NSData *fetched = [_db objectForKey:key];
	XCTAssertNotNil(fetched, @"Key for data not found.");
	XCTAssertEqualObjects(data, fetched, @"Fetched data doesn't match original data.");
}

- (void)testNilForUnknownKey
{
	XCTAssertNil([_db objectForKey:@"made up key"], @"stringForKey: should return nil if a key doesn't exist");
	XCTAssertNil([_db objectForKey:@"another made up key"], @"dataForKey: should return nil if a key doesn't exist");
}

- (void)testRemoveKey
{
	NSString *text = @"Hello";
	NSString *key = @"key";
	[_db setObject:text forKey:key];
	
	XCTAssertEqualObjects(text, [_db objectForKey:key], @"stringForKey should have returned the original text");
	
	[_db removeObjectForKey:key];
	
	XCTAssertNil([_db objectForKey:key], @"stringForKey should return nil after removal of key");
	XCTAssertNil([_db objectForKey:key], @"dataForKey should return nil after removal of key");
}

- (void)testAllKeys
{
	NSDictionary *keysAndValues = [self populateWithUUIDsAndReturnDictionary];

	NSArray *sortedOriginalKeys = [keysAndValues.allKeys sortedArrayUsingSelector:@selector(compare:)];
	XCTAssertEqualObjects(sortedOriginalKeys, [_db allKeys], @"");
}

- (void)testEnumeration
{
	NSDictionary *keysAndValues = [self populateWithUUIDsAndReturnDictionary];
	NSArray *sortedOriginalKeys = [keysAndValues.allKeys sortedArrayUsingSelector:@selector(compare:)];
	
	__block NSUInteger keyIndex = 0;
  [_db
    enumerateKeysAndObjectsUsingBlock:
      ^(id<NSObject,NSSecureCoding,NSCopying> key,
      id<NSObject,NSSecureCoding,NSCopying> obj,
      BOOL * stop)
      {
		  XCTAssertEqualObjects(key, sortedOriginalKeys[keyIndex], @"enumerated key does not match");
		  keyIndex++;
      }];
}

- (void)testEnumerationUsingStrings
{
	NSDictionary *keysAndValues = [self populateWithUUIDsAndReturnDictionary];
	NSArray *sortedOriginalKeys = [keysAndValues.allKeys sortedArrayUsingSelector:@selector(compare:)];
	
	__block NSUInteger keyIndex = 0;
  [_db
    enumerateKeysAndObjectsUsingBlock:
      ^(id<NSObject,NSSecureCoding,NSCopying> key,
        id<NSObject,NSSecureCoding,NSCopying> obj,
        BOOL * stop)
        {
        NSString *originalKey = sortedOriginalKeys[keyIndex];
        XCTAssertEqualObjects(key, originalKey, @"enumerated key does not match");
        XCTAssertEqualObjects(obj, keysAndValues[originalKey], @"enumerated value does not match");
        
        keyIndex++;
    
        }];
}

- (void)testSubscripting
{
	NSString *text = @"Hello";
	NSString *key = @"key";
	_db[key] = text;
	
	XCTAssertEqualObjects(text, _db[key], @"Error retrieving string for key.");
}

- (void)testSubscriptingNilForUnknownKey
{
	XCTAssertNil(_db[@"no such key as this key"], @"Subscripting access should return nil for an unknown key.");
}

- (void)testLargeValue
{
	NSString *key = @"key";
	NSData *data = [self largeData];
	
	[_db setObject:data forKey:key];
	XCTAssertEqualObjects(data, [_db objectForKey:key], @"Data read from database does not match original.");
}

#pragma mark - Tests - Iterators

- (void)testIteratorNilOnEmptyDatabase
{
	//ESLevelDBIterator *iter = [ESLevelDBIterator iteratorWithLevelDB:_db];
	//XCTAssertNil(iter, @"Iterator should be nil for an empty database.");
}

- (void)testIteratorNotNilOnPopulatedDatabase
{
	_db[@"a"] = @"1";
	//ESLevelDBIterator *iter = [ESLevelDBIterator iteratorWithLevelDB:_db];
	//XCTAssertNotNil(iter, @"Iterator should not be nil if the database contains anything.");
}

- (void)testIteratorStartsAtFirstKey
{
	_db[@"b"] = @"2";
	_db[@"a"] = @"1";
  NSEnumerator * enumerator = [_db keyEnumerator];
	XCTAssertEqualObjects([enumerator nextObject], @"a", @"Iterator should start at the first key.");
	
	XCTAssertEqualObjects([enumerator nextObject], @"b", @"Iterator should progress to the second key.");
}

- (void)testIteratorSeek
{
	/* _db[@"a"] = @"1";
	_db[@"ab"] = @"2";
	_db[@"abc"] = @"3";
	
	ESLevelDBIterator *iter = [ESLevelDBIterator iteratorWithLevelDB:_db];
	[iter seekToKey:@"ab"];
	
	XCTAssertEqualObjects([iter key], @"ab", @"Iterator did not seek properly.");
	XCTAssertEqualObjects([iter valueAsString], @"2", @"Iterator value incorrect.");
	
	XCTAssertEqualObjects([iter nextKey], @"abc", @"Iterator did not seek properly.");
	XCTAssertEqualObjects([iter valueAsString], @"3", @"Iterator value incorrect."); */
}

- (void)testIteratorSeekToNonExistentKey
{
	/* _db[@"a"] = @"1";
	_db[@"ab"] = @"2";
	_db[@"abc"] = @"3";
	
	ESLevelDBIterator *iter = [ESLevelDBIterator iteratorWithLevelDB:_db];
	[iter seekToKey:@"aa"]; // seeking to a key that doesn't exist should jump us to the next possible key.
	
	XCTAssertEqualObjects([iter key], @"ab", @"Iterator did not seek properly.");
	XCTAssertEqualObjects([iter valueAsString], @"2", @"Iterator value incorrect.");
	
	XCTAssertEqualObjects([iter nextKey], @"abc", @"Iterator did not advance properly.");
	XCTAssertEqualObjects([iter valueAsString], @"3", @"Iterator value incorrect."); */
}

- (void)testIteratorStepPastEnd
{
	/* _db[@"a"] = @"1";
	_db[@"ab"] = @"2";
	_db[@"abc"] = @"3";
	
	ESLevelDBIterator *iter = [ESLevelDBIterator iteratorWithLevelDB:_db];
	[iter seekToKey:@"ab"];
	[iter nextKey]; // abc
	XCTAssertNil([iter nextKey], @"Iterator should return nil at end of keys.");
	XCTAssertNil([iter valueAsData], @"Iterator should return nil at end of keys.");
	XCTAssertNil([iter valueAsString], @"Iterator should return nil at end of keys."); */
}


#pragma mark - Atomic Updates

- (void)testAtomicSimple
{
	[_db setObject:@"3" forKey:@"c"];
	
	ESLevelDBScratchPad * batch = [_db batch];
	[batch setObject:@"1" forKey:@"a"];
	[batch setObject:@"2" forKey:@"b"];
	[batch removeObjectForKey:@"c"];
	[batch commit];
	
	XCTAssertEqualObjects(_db[@"a"], @"1", @"Batch write did not execute");
	XCTAssertEqualObjects(_db[@"b"], @"2", @"Batch write did not execute");
	XCTAssertNil(_db[@"c"], @"Batch write did not remove key");
}

- (void)testAtomicWithClear
{
	[_db setObject:@"3" forKey:@"c"];

	ESLevelDBScratchPad * batch = [_db batch];
	[batch setObject:@"1" forKey:@"a"];
	[batch setObject:@"2" forKey:@"b"];
	[batch removeObjectForKey:@"c"];
	[batch removeAllObjects];
	[batch commit];
	
	XCTAssertNil(_db[@"a"], @"Batch write did not clear buffered write");
	XCTAssertNil(_db[@"b"], @"Batch write did not clear buffered write");
	//XCTAssertEqualObjects(_db[@"c"], @"3", @"Batch clear buffered remove");
}

- (void)testAtomicWithClearThenMutate
{
	[_db setObject:@"3" forKey:@"c"];

	ESLevelDBScratchPad * batch = [_db batch];
	[batch setObject:@"1" forKey:@"a"];
	[batch removeAllObjects];
	[batch setObject:@"2" forKey:@"b"];
	[batch removeObjectForKey:@"c"];
	[batch commit];
	
	XCTAssertNil(_db[@"a"], @"Batch write did not clear buffered write");
	XCTAssertEqualObjects(_db[@"b"], @"2", @"Batch write did not execute after clear");
	XCTAssertNil(_db[@"c"], @"Batch write did not remove key after clear");
}

- (void)testAtomicAsync
{
	// Create a background queue on which we will perform the write.
	dispatch_queue_t queue = dispatch_queue_create(__PRETTY_FUNCTION__, DISPATCH_QUEUE_SERIAL);
	
	// The semaphore will tell us when the write block has been called.
	dispatch_semaphore_t sem = dispatch_semaphore_create(0);
	
	[_db setObject:@"3" forKey:@"c"];
	
	ESLevelDBScratchPad * batch = [_db batch];

	// Batch a few writes immediately:
	[batch setObject:@"1" forKey:@"a"];
	[batch setObject:@"2" forKey:@"b"];
	
	XCTAssertNil(_db[@"a"], @"Precondition failed");
	XCTAssertNil(_db[@"b"], @"Precondition failed");
	XCTAssertEqualObjects(_db[@"c"], @"3", @"Precondition failed");
	
	// Demonstrate, to the extent that we can, that the batch object
	// can be passed on to other areas of the program.  We don't have
	// to execute it immediately, or even from the same thread.
	dispatch_async(queue, ^{
		// According to the leveldb docs, the leveldb object does necessary synchronization for
		// writes from multiple threads, so it's okay to send commitWriteBatch: from a thread/queue
		// other than the one the database was created on.
		[batch removeObjectForKey:@"c"];
		
		// Execute the batched writes:
		[batch commit];
		
		// Tell the main thread that we're done and it can check our work.
		dispatch_semaphore_signal(sem);
	});
	
	dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
	
	XCTAssertEqualObjects(_db[@"a"], @"1", @"Batch write did not execute");
	XCTAssertEqualObjects(_db[@"b"], @"2", @"Batch write did not execute");
	XCTAssertNil(_db[@"c"], @"Batch write did not remove key");
}


#pragma mark - Helpers

- (NSData *)largeData
{
	if (!_largeData)
	{
		NSUInteger numberOfBytes = 1024*1024*10; // 10MB
		NSMutableData *data = [NSMutableData dataWithCapacity:numberOfBytes];
		[data setLength:numberOfBytes];
		char *buffer = [data mutableBytes];
		for (NSUInteger i = 0; i < numberOfBytes; i++)
		{
			buffer[i] = i & 0xff;
		}
		_largeData = [data copy];
	}
	return _largeData;
}

- (NSDictionary *)populateWithUUIDsAndReturnDictionary
{
	// Generate random keys and values using UUIDs:
	const int numberOfKeys = 64;
	NSMutableDictionary *keysAndValues = [NSMutableDictionary dictionaryWithCapacity:numberOfKeys];
	for (int i = 0; i < numberOfKeys; i++)
	{
		@autoreleasepool {
			keysAndValues[ [[NSUUID UUID] UUIDString] ] = [[NSUUID UUID] UUIDString];
		}
	}
	
	[keysAndValues enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		[_db setObject:obj forKey:key];
	}];
	
	return keysAndValues;
}



@end
