/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

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

#import <Foundation/Foundation.h>

#import "ESLevelDBType.h"

#define kESLevelDBErrorDomain @"com.etresoft.ESLevelDB"

@class ESLevelDBScratchPad;
@class ESLevelDBSnapshot;
@class ESLevelDBSerializer;

// This class is an NSMutableDictionary subclass that uses ESLevelDB as a
// backing store. NSMutableDictionary is designed to keep all objects in
// memory so this class has additional overrides to avoid keeping all
// objects in memory.
@interface ESLevelDB : NSMutableDictionary

// Serializer.
@property (strong) ESLevelDBSerializer * serializer;

// Factory constructor with path.
+ (instancetype) levelDBWithPath: (NSString *) path
  error: (NSError **) errorOut;

// Constructor.
- (id) initWithPath: (NSString *) path error: (NSError **) errorOut;

// Batch write/atomic update support.
- (ESLevelDBScratchPad *) batchView;

// Read-only snapshot support.
- (ESLevelDBSnapshot *) snapshotView;

// To support leveldb's seekable enumerators.

// Enumerate a range [start, limit) of keys and objects.
- (void) enumerateKeysAndObjectsFrom: (ESLevelDBKey) from
  limit: (ESLevelDBKey) limit
  usingBlock:
    (void (^)(ESLevelDBKey key, ESLevelDBType obj, bool * stop)) block;

// Enumerator a range [start, limit) of keys and objects with options.
- (void) enumerateKeysAndObjectsFrom: (ESLevelDBKey) from
  limit: (ESLevelDBKey) limit
  withOptions: (NSEnumerationOptions) options
  usingBlock:
    (void (^)(ESLevelDBKey key, ESLevelDBType obj, bool * stop)) block;

@end
