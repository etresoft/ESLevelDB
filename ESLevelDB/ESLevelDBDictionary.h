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
 
- (void) getObjects: (__strong ESLevelDBType []) objects
  andKeys: (__strong ESLevelDBType []) keys;

- (ESLevelDBType) objectForKey: (ESLevelDBType) key;

- (ESLevelDBType) objectForKeyedSubscript: (ESLevelDBType) key;

- (NSArray *) objectsForKeys: (NSArray *) keys
  notFoundMarker: (id) anObject;

- (ESLevelDBType) valueForKey: (NSString *) key;

- (NSEnumerator *) keyEnumerator;

- (NSEnumerator *) objectEnumerator;

- (void) enumerateKeysAndObjectsUsingBlock:
  (void (^)(ESLevelDBType key, ESLevelDBType obj, BOOL * stop)) block;

- (void) enumerateKeysAndObjectsWithOptions: (NSEnumerationOptions) options
  usingBlock:
    (void (^)(ESLevelDBType key, ESLevelDBType obj, BOOL * stop)) block;

- (NSArray *) keysSortedByValueUsingComparator: (NSComparator) comparator;

- (NSArray *) keysSortedByValueUsingSelector: (SEL) comparator;

- (NSArray *) keysSortedByValueWithOptions: (NSSortOptions) options
  usingComparator: (NSComparator) comparator;

- (NSSet *) keysOfEntriesPassingTest:
  (BOOL (^)(ESLevelDBType key, ESLevelDBType obj, BOOL * stop)) predicate;

- (NSSet *) keysOfEntriesWithOptions: (NSEnumerationOptions) options
  passingTest:
    (BOOL (^)(ESLevelDBType key, ESLevelDBType obj, BOOL * stop)) predicate;

// To support NSFastEnumeration.
- (unsigned long *) mutationPtr;

@end
