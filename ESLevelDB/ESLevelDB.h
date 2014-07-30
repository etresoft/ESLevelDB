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
#import "ESLevelDBView.h"
#import "ESLevelDBMutableDictionary.h"
#import <leveldb/options.h>

#define kESLevelDBErrorDomain @"com.etresoft.ESLevelDB"

@class ESLevelDBSnapshot;
@class ESLevelDBWriteBatch;

@interface ESLevelDB : ESLevelDBView <ESLevelDBMutableDictionary>

@property (assign) leveldb::WriteOptions writeOptions;

// Factory constructor with path.
+ (ESLevelDB *) levelDBWithPath: (NSString *) path
  error: (NSError **) errorOut;

// Batch write/atomic update support.
- (ESLevelDBWriteBatch *) batch;

// Commit a batch.
- (BOOL) commit: (ESLevelDBWriteBatch *) batch;

// Snapshot support.
- (ESLevelDBSnapshot *) snapshot;

@end
