/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/
//
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

#import "leveldb/db.h"
#import "leveldb/options.h"
#import "leveldb/write_batch.h"

#import "ESLevelDB.h"
#import "ESLevelDBViewPrivate.h"
#import "ESLevelDBSnapshot.h"
#import "ESLevelDBSnapshotPrivate.h"
#import "ESLevelDBScratchPad.h"
#import "ESLevelDBScratchPadPrivate.h"
#import "ESLevelDBType.h"
#import "ESLevelDBSlice.h"
#import "ESLevelDBKeySlice.h"
#import "ESLevelDBValue.h"

@interface ESLevelDB ()

@property (assign) leveldb::WriteOptions writeOptions;

@end

@implementation ESLevelDB
  {
  // I need to know if the database changes.
  NSUInteger myHash;
  }

@synthesize writeOptions;

// Factory constructor with path.
+ (ESLevelDB *) levelDBWithPath:(NSString *) path
 error: (NSError **) errorOut
  {
	return [[ESLevelDB alloc] initWithPath: path error: errorOut];
  }

// Constructor.
- (id) initWithPath: (NSString *) path error: (NSError **) errorOut
  {
  leveldb::Options options = [[self class] defaultCreateOptions];

  leveldb::DB * db;
  
  leveldb::Status status =
    leveldb::DB::Open(options, [path fileSystemRepresentation], & db);

  if(!status.ok())
    {
    if(errorOut)
      {
      NSString * statusString =
        [[NSString alloc]
          initWithCString: status.ToString().c_str()
          encoding: NSUTF8StringEncoding];
      
      *errorOut =
        [NSError
          errorWithDomain: kESLevelDBErrorDomain
          code: 0
          userInfo:
            [NSDictionary
              dictionaryWithObjectsAndKeys:
                statusString, NSLocalizedDescriptionKey, nil]];
      }
    
    return nil;
    }
    
	if((self = [super initWithDb: db]))
	  {
    self.db = db;
		writeOptions.sync = false;
    myHash = [super hash];
	  }
	
  return self;
  }

// No ARC with C++.
- (void) dealloc
  {
	delete self.db;
  self.db = nil;
  }

// Convenience constructor.
+ (leveldb::Options) defaultCreateOptions
  {
	leveldb::Options options;
	options.create_if_missing = true;
	
  return options;
  }

#pragma mark - NSObject interface

- (NSUInteger) hash
  {
  return myHash;
  }

#pragma mark - NSLevelDBMutableDictionary interface

- (void) setObject: (ESLevelDBType) object forKey: (ESLevelDBKey) key
  {
  [self mutatingOperation:
    ^BOOL
      {
      self.db->Put(
        writeOptions,
        ESleveldb::KeySlice(key),
        ESleveldb::Slice(object, self.serializer)).ok();
        
      return YES;
      }];
  }

- (void) setObject: (ESLevelDBType) object
  forKeyedSubscript: (ESLevelDBKey) key
  {
  [self setObject: object forKey: key];
  }

- (void) setValue: (ESLevelDBType) value forKey: (NSString *) key
  {
  [self mutatingOperation:
    ^BOOL
      {
      if(value)
        self.db->Put(
          writeOptions,
          ESleveldb::KeySlice(key),
          ESleveldb::Slice(value, self.serializer)).ok();

      else
        self.db->Delete(writeOptions, ESleveldb::KeySlice(key));
        
      return YES;
      }];
  }

- (void) addEntriesFromDictionary: (NSDictionary *) dictionary
  {
  ESLevelDBScratchPad * batch = [self batch];
  
  [batch addEntriesFromDictionary: dictionary];
  
  [self commit: batch];
  }

- (void) setDictionary: (NSDictionary *) dictionary
  {
  ESLevelDBScratchPad * batch = [self batch];
  
  [batch removeAllObjects];
  [batch addEntriesFromDictionary: dictionary];
  
  [self commit: batch];
  }

- (void) removeObjectForKey: (ESLevelDBKey) key
  {
  [self mutatingOperation:
    ^BOOL
      {
      self.db->Delete(writeOptions, ESleveldb::KeySlice(key)).ok();
        
      return YES;
      }];
  }

- (void) removeAllObjects
  {
  ESLevelDBScratchPad * batch = [self batch];
  
  [batch removeAllObjects];
  
  [self commit: batch];
  }

- (void) removeObjectsForKeys: (NSArray *) keys
  {
  ESLevelDBScratchPad * batch = [self batch];
  
  [batch removeObjectsForKeys: keys];
  
  [self commit: batch];
  }

// Batch write/atomic update support:
- (ESLevelDBScratchPad *) batch
  {
	return
    [[ESLevelDBScratchPad alloc] initWithESLevelDB: self];
  }

// Commit a batch.
- (BOOL) commit: (ESLevelDBScratchPad *) batch
  {
  return
    [self mutatingOperation:
      ^BOOL
        {
        return self.db->Write(self.writeOptions, batch.batch).ok();
        }];
  }

// Snapshot support:
- (ESLevelDBSnapshot *) snapshot
  {
  ESLevelDBSnapshot * snapshot = [ESLevelDBSnapshot new];
  
  snapshot.db = self.db;
  snapshot.snapshot = self.db->GetSnapshot();
  
  return snapshot;
  }

#pragma mark - Private support

- (BOOL) mutatingOperation: (BOOL (^)(void)) operation
  {
  __block BOOL result = NO;
  
  dispatch_sync(
    self.queue,
    ^{
      ++myHash;
  
      result = operation();
    });
    
  return result;
  }
  
@end
