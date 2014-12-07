/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "leveldb/db.h"
#import "leveldb/options.h"

#import "ESLevelDB.h"

// A read-only view of a LevelDB database suitable for a snapshot or the
// database itself.
@interface ESLevelDB ()

// I'll need this.
@property (readonly) dispatch_queue_t queue;

// The LevelDB database object.
@property (assign) std::shared_ptr<leveldb::DB> * db;

// Read options.
@property (assign) leveldb::ReadOptions readOptions;

// I need to know if the database changes.
@property (readonly) NSUInteger lastHash;

// Is this class immutable?
@property (assign) bool immutable;

// Copy constructor.
- (instancetype) initWithESLevelDB: (ESLevelDB *) db;

// Commit a batch.
- (bool) commit: (ESLevelDBScratchPad *) batch;

@end
