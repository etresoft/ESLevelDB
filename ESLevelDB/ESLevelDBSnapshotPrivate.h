/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "leveldb/db.h"
#import "leveldb/options.h"
#import "leveldb/write_batch.h"

@class ESLevelDB;

@interface ESLevelDBSnapshot ()

@property (assign) const leveldb::Snapshot * snapshot;

// Constructor.
- (instancetype) initWithESLevelDB: (ESLevelDB *) db;

@end

