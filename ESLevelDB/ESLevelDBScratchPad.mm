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

@synthesize parentDB = myParentDB;
@synthesize batch = myBatch;
@synthesize keysChanged = myKeysChanged;

- (NSMutableArray *) keysChanged
  {
  if(!myKeysChanged)
    myKeysChanged = [NSMutableArray new];
    
  return myKeysChanged;
  }

// Constructor.
- (instancetype) initWithESLevelDB: (ESLevelDB *) db
  {
  self = [super initWithDb: db.db];
  
  if(self)
    {
    myParentDB = db;
    myBatch = new leveldb::WriteBatch();
    }
    
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
        ESleveldb::Slice(key, self.serializer),
        ESleveldb::Slice(object, self.serializer));
        
      [self.keysChanged addObject: @{key: kESLevelDBScratchPadKeyAdded}];
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
        ESleveldb::Slice(key, self.serializer),
        ESleveldb::Slice(object, self.serializer));
        
      [self.keysChanged addObject: @{key: kESLevelDBScratchPadKeyAdded}];
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
          ESleveldb::Slice(key, self.serializer),
          ESleveldb::Slice(dictionary[key], self.serializer));
        
        [self.keysChanged addObject: @{key: kESLevelDBScratchPadKeyAdded}];
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
        self.batch->Delete(ESleveldb::Slice(key, self.serializer));
        
        [self.keysChanged
          addObject: @{key: kESLevelDBScratchPadKeyRemoved}];
        }
      
      for(ESLevelDBType key in dictionary)
        {
        self.batch->Put(
          ESleveldb::Slice(key, self.serializer),
          ESleveldb::Slice(dictionary[key], self.serializer));
        
        [self.keysChanged addObject: @{key: kESLevelDBScratchPadKeyAdded}];
        }
    });
  }

- (void) removeObjectForKey: (ESLevelDBType) key
  {
  if(!key)
    [NSException
      raise: NSInvalidArgumentException
      format: NSLocalizedString(@"Nil key provided", NULL)];
    
  self.batch->Delete(ESleveldb::Slice(key, self.serializer));
  
  [self.keysChanged addObject: @{key: kESLevelDBScratchPadKeyRemoved}];
  }

- (void) removeAllObjects
  {
  [self removeObjectsForKeys: [self.parentDB allKeys]];
  [self.keysChanged
    enumerateObjectsUsingBlock:
      ^(id obj, NSUInteger idx, BOOL * stop)
      {
        for(id key in obj)
          {
          NSString * operation = obj[key];
          
          if([operation isEqualToString: kESLevelDBScratchPadKeyAdded])
            [self removeObjectForKey: key];
          }
      }];
  }

- (void) removeObjectsForKeys: (NSArray *) keys
  {
  dispatch_sync(
    self.queue,
    ^{
      for(ESLevelDBType key in keys)
        {
        NSLog(@"Deleting object from batch: %@", key);
        self.batch->Delete(ESleveldb::Slice(key, self.serializer));
        
        [self.keysChanged
          addObject: @{key: kESLevelDBScratchPadKeyRemoved}];
        }
    });
  }

@end

