/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "leveldb/db.h"
#import "leveldb/options.h"
#import "leveldb/write_batch.h"

#import "ESLevelDBScratchPad.h"
#import "ESLevelDBScratchPadPrivate.h"
#import "ESLevelDBType.h"
#import "ESLevelDBSlice.h"
#import "ESLevelDBSerializer.h"
#import "ESLevelDB.h"
#import "ESLevelDBViewPrivate.h"

@implementation ESLevelDBScratchPad

@synthesize batch = myBatch;
@synthesize keysChanged = myKeysChanged;

- (NSMutableArray *) keysChanged
  {
  if(!myKeysChanged)
    myKeysChanged = [NSMutableArray new];
    
  return myKeysChanged;
  }

// Constructor.
- (instancetype) init
  {
  self = [super init];
  
  if(self)
    myBatch = new leveldb::WriteBatch();
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  delete myBatch;
  }

- (BOOL) commit
  {
  return [self.parentDB commit: self];
  }

- (void) setObject: (ESLevelDBType) object forKey: (ESLevelDBType) key
  {
  if(!key)
    [NSException
      raise: NSInvalidArgumentException
      format: NSLocalizedString(@"Nil key provided", NULL)];
    
  if(!object)
    [NSException
      raise: NSInvalidArgumentException
      format: NSLocalizedString(@"Nil value provided", NULL)];

  dispatch_sync(
    self.queue,
    ^{
      self.batch->Put(
        ESleveldb::Slice(key, *self.serializer),
        ESleveldb::Slice(object, *self.serializer));
        
      [myKeysChanged addObject: @{kESLevelDBScratchPadKeyAdded: key}];
    });
  }

- (void) setObject: (ESLevelDBType) object
  forKeyedSubscript: (ESLevelDBType) key
  {
  if(!key)
    [NSException
      raise: NSInvalidArgumentException
      format: NSLocalizedString(@"Nil key provided", NULL)];
    
  if(!object)
    [NSException
      raise: NSInvalidArgumentException
      format: NSLocalizedString(@"Nil value provided", NULL)];

  dispatch_sync(
    self.queue,
    ^{
      self.batch->Put(
        ESleveldb::Slice(key, *self.serializer),
        ESleveldb::Slice(object, *self.serializer));
        
      [myKeysChanged addObject: @{kESLevelDBScratchPadKeyAdded: key}];
    });
  }

- (void) setValue: (ESLevelDBType) value forKey: (NSString *) key
  {
  if(!value)
    [self removeObjectForKey: key];
  else
    [self setObject: value forKey: key];
  }

- (void) addEntriesFromDictionary: (NSDictionary *) dictionary
  {
  dispatch_sync(
    self.queue,
    ^{
      for(ESLevelDBType key in dictionary)
        {
        self.batch->Put(
          ESleveldb::Slice(key, *self.serializer),
          ESleveldb::Slice(dictionary[key], *self.serializer));
        
        [myKeysChanged addObject: @{key: kESLevelDBScratchPadKeyAdded}];
        }
    });
  }

- (void) setDictionary: (NSDictionary *) dictionary
  {
  dispatch_sync(
    self.queue,
    ^{
      for(ESLevelDBType key in [self.parentDB allKeys])
        {
        self.batch->Delete(ESleveldb::Slice(key, *self.serializer));
        
        [myKeysChanged addObject: @{key: kESLevelDBScratchPadKeyRemoved}];
        }
      
      for(ESLevelDBType key in dictionary)
        {
        self.batch->Put(
          ESleveldb::Slice(key, *self.serializer),
          ESleveldb::Slice(dictionary[key], *self.serializer));
        
        [myKeysChanged addObject: @{key: kESLevelDBScratchPadKeyAdded}];
        }
    });
  }

- (void) removeObjectForKey: (ESLevelDBType) key
  {
  if(!key)
    [NSException
      raise: NSInvalidArgumentException
      format: NSLocalizedString(@"Nil key provided", NULL)];
    
  self.batch->Delete(ESleveldb::Slice(key, *self.serializer));
  
  [myKeysChanged addObject: @{key: kESLevelDBScratchPadKeyRemoved}];
  }

- (void) removeAllObjects
  {
  [self removeObjectsForKeys: [self.parentDB allKeys]];
  }

- (void) removeObjectsForKeys: (NSArray *) keys
  {
  dispatch_sync(
    self.queue,
    ^{
      for(ESLevelDBType key in keys)
        {
        self.batch->Delete(ESleveldb::Slice(key, *self.serializer));
        
        [myKeysChanged addObject: @{key: kESLevelDBScratchPadKeyRemoved}];
        }
    });
  }

@end

