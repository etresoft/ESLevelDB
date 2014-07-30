/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "leveldb/db.h"
#import "leveldb/options.h"

#import "ESLevelDBView.h"

#define kCountKey @"ESLevelDB_recordcount"

// A read-only view of a LevelDB database suitable for a snapshot or the
// database itself.
@interface ESLevelDBView ()

// I'll need this.
@property (readonly) dispatch_queue_t queue;

// The LevelDB database object.
@property (assign) leveldb::DB * db;

// Read options.
@property (assign) leveldb::ReadOptions readOptions;

// I need to know if the database changes.
@property (readonly) NSUInteger lastHash;

@end
