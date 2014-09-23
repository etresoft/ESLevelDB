/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

#import "ESLevelDBType.h"

// Implement as much of the NSDictionary interface as possible.
@protocol ESLevelDBDictionary <NSObject, NSFastEnumeration>

// LevelDB doesn't support this, but it is important for Cocoa.
@property (readonly) NSUInteger count;

- (NSArray *) allKeys;
- (NSArray *) allKeysForObject: (ESLevelDBType) object;

- (NSArray *) allValues;
 
- (void) getObjects: (__unsafe_unretained id []) objects
  andKeys: (__unsafe_unretained id []) keys;

- (ESLevelDBType) objectForKey: (ESLevelDBKey) key;

- (ESLevelDBType) objectForKeyedSubscript: (ESLevelDBKey) key;

- (NSArray *) objectsForKeys: (NSArray *) keys
  notFoundMarker: (id) anObject;

// TODO: Write test case.
- (ESLevelDBType) valueForKey: (NSString *) key;

- (NSEnumerator *) keyEnumerator;

- (NSEnumerator *) objectEnumerator;

- (void) enumerateKeysAndObjectsUsingBlock:
  (void (^)(ESLevelDBKey key, ESLevelDBType obj, BOOL * stop)) block;

- (void) enumerateKeysAndObjectsWithOptions: (NSEnumerationOptions) options
  usingBlock:
    (void (^)(ESLevelDBKey key, ESLevelDBType obj, BOOL * stop)) block;

// TODO: Write test case.
- (NSArray *) keysSortedByValueUsingComparator: (NSComparator) comparator;

// TODO: Write test case.
- (NSArray *) keysSortedByValueUsingSelector: (SEL) comparator;

// TODO: Write test case.
- (NSArray *) keysSortedByValueWithOptions: (NSSortOptions) options
  usingComparator: (NSComparator) comparator;

// TODO: Write test case.
- (NSSet *) keysOfEntriesPassingTest:
  (BOOL (^)(ESLevelDBKey key, ESLevelDBType obj, BOOL * stop)) predicate;

// TODO: Write test case.
- (NSSet *) keysOfEntriesWithOptions: (NSEnumerationOptions) options
  passingTest:
    (BOOL (^)(ESLevelDBKey key, ESLevelDBType obj, BOOL * stop)) predicate;

// To support leveldb's seekable enumerators.

// Enumerate a range [start, limit) of keys and objects.
- (void) enumerateKeysAndObjectsFrom: (ESLevelDBKey) from
  limit: (ESLevelDBKey) limit
  usingBlock:
    (void (^)(ESLevelDBKey key, ESLevelDBType obj, BOOL * stop)) block;

// Enumerator a range [start, limit) of keys and objects with options.
- (void) enumerateKeysAndObjectsFrom: (ESLevelDBKey) from
  limit: (ESLevelDBKey) limit
  withOptions: (NSEnumerationOptions) options
  usingBlock:
    (void (^)(ESLevelDBKey key, ESLevelDBType obj, BOOL * stop)) block;

// Get keys in range [start, limit).
- (NSArray *) keysOfEntriesFrom: (ESLevelDBKey) from
  limit: (ESLevelDBKey) limit;

// Get keys in range [start, limit) with options.
- (NSArray *) keysOfEntriesFrom: (ESLevelDBKey) from
  limit: (ESLevelDBKey) limit
  withOptions: (NSEnumerationOptions) options;

@end
