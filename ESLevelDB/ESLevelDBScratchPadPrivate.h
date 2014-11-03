/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "leveldb/db.h"
#import "leveldb/options.h"
#import "leveldb/write_batch.h"

#import "ESLevelDBScratchPad.h"
#import "ESLevelDBSerializer.h"
#import "ESLevelDB.h"

#define kESLevelDBScratchPadKeyAdded @"keyadded"
#define kESLevelDBScratchPadKeyRemoved @"keyremoved"

@interface ESLevelDBScratchPad ()

// The parent ESLevelDB object.
@property (readonly) ESLevelDB * parentDb;

// The leveldb batch object.
@property (readonly) leveldb::WriteBatch * batch;

// Keep track of the keys added and deleted so the count can be updated.
@property (readonly) NSMutableArray * keysChanged;

// Constructor.
- (instancetype) initWithESLevelDB: (ESLevelDB *) db;

@end

