/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "ESLevelDBWriteBatch.h"

#import "leveldb/db.h"
#import "leveldb/options.h"
#import "leveldb/write_batch.h"
#import "ESLevelDBSerializer.h"
#import "ESLevelDB.h"

#define kESLevelDBWriteBatchKeyAdded @"keyadded"
#define kESLevelDBWriteBatchKeyRemoved @"keyremoved"

@interface ESLevelDBWriteBatch ()

@property (strong) ESLevelDB * db;
@property (assign) ESleveldb::Serializer * serializer;

// Why not make it thread-safe?
@property (readonly) dispatch_queue_t queue;

// Keep track of the keys added and deleted so the count can be updated.
@property (readonly) NSMutableArray * keysChanged;

@end

