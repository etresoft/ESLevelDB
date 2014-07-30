/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "leveldb/db.h"
#import "leveldb/options.h"
#import "leveldb/write_batch.h"

@interface ESLevelDBSnapshot ()

@property (assign) const leveldb::Snapshot * snapshot;

@end

