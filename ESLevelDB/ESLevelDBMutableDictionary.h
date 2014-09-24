/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

#import "ESLevelDBType.h"

@class ESLevelDBScratchPad;

@protocol ESLevelDBMutableDictionary <NSObject>

- (void) setObject: (ESLevelDBType) object
  forKey: (ESLevelDBKey) key;

- (void) setObject: (ESLevelDBType) object
  forKeyedSubscript: (ESLevelDBKey) key;

// TODO: Write test case.
- (void) setValue: (ESLevelDBType) value forKey: (NSString *) key;

// TODO: Write test case.
- (void) addEntriesFromDictionary: (NSDictionary *) dictionary;

// TODO: Write test case.
- (void) setDictionary: (NSDictionary *) dictionary;

- (void) removeObjectForKey: (ESLevelDBKey) key;

// TODO: Write test case.
- (void) removeAllObjects;

// TODO: Write test case.
- (void) removeObjectsForKeys: (NSArray *) keys;

@end
