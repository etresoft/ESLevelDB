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
  forKey: (ESLevelDBType) key;

- (void) setObject: (ESLevelDBType) object
  forKeyedSubscript: (ESLevelDBType) key;

- (void) setValue: (ESLevelDBType) value forKey: (NSString *) key;

- (void) addEntriesFromDictionary: (NSDictionary *) dictionary;

- (void) setDictionary: (NSDictionary *) dictionary;

- (void) removeObjectForKey: (ESLevelDBType) key;

- (void) removeAllObjects;

- (void) removeObjectsForKeys: (NSArray *) keys;

@end
