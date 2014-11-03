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
#import "ESLevelDBKeySlice.h"
#import "ESLevelDBSerializer.h"
#import "ESLevelDB.h"
#import "ESLevelDBPrivate.h"

@implementation ESLevelDBScratchPad

@synthesize deltaCount = myDeltaCount;

@synthesize parentDb = myParentDb;
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
  self = [super initWithESLevelDB: db];
  
  if(self)
    {
    myParentDb = db;
    myBatch = new leveldb::WriteBatch();
    }
    
  return self;
  }

// Destructor.
- (void) dealloc
  {
  delete myBatch;
  }

- (NSUInteger) count
  {
  return [super count] + self.deltaCount;
  }
  
- (BOOL) commit
  {
  return [self.parentDb commit: self];
  }

- (void) setObject: (ESLevelDBType) object forKey: (ESLevelDBKey) key
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
      BOOL exists = ([self objectForKey: key] != nil);
      
      self.batch->Put(
        ESleveldb::KeySlice(key),
        ESleveldb::Slice(object, self.serializer));
        
      [self.keysChanged addObject: @{key: kESLevelDBScratchPadKeyAdded}];
      
      if(!exists)
        ++self.deltaCount;
    });
  }

- (void) setObject: (ESLevelDBType) object
  forKeyedSubscript: (ESLevelDBKey) key
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
      BOOL exists = ([self objectForKey: key] != nil);

      self.batch->Put(
        ESleveldb::KeySlice(key),
        ESleveldb::Slice(object, self.serializer));
        
      [self.keysChanged addObject: @{key: kESLevelDBScratchPadKeyAdded}];
      
      if(!exists)
        ++self.deltaCount;
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
      for(ESLevelDBKey key in dictionary)
        {
        BOOL exists = ([self objectForKey: key] != nil);
        
        self.batch->Put(
          ESleveldb::KeySlice(key),
          ESleveldb::Slice(dictionary[key], self.serializer));
        
        [self.keysChanged addObject: @{key: kESLevelDBScratchPadKeyAdded}];

        if(!exists)
          ++self.deltaCount;
        }
    });
  }

- (void) setDictionary: (NSDictionary *) dictionary
  {
  dispatch_sync(
    self.queue,
    ^{
      for(ESLevelDBKey key in [self allKeys])
        {
        self.batch->Delete(ESleveldb::KeySlice(key));
        
        [self.keysChanged
          addObject: @{key: kESLevelDBScratchPadKeyRemoved}];
          
        --self.deltaCount;
        }
      
      for(ESLevelDBKey key in dictionary)
        {
        self.batch->Put(
          ESleveldb::KeySlice(key),
          ESleveldb::Slice(dictionary[key], self.serializer));
        
        [self.keysChanged addObject: @{key: kESLevelDBScratchPadKeyAdded}];
        
        ++self.deltaCount;
        }
    });
  }

- (void) removeObjectForKey: (ESLevelDBKey) key
  {
  if(!key)
    [NSException
      raise: NSInvalidArgumentException
      format: NSLocalizedString(@"Nil key provided", NULL)];
    
  BOOL exists = ([self objectForKey: key] != nil);

  self.batch->Delete(ESleveldb::KeySlice(key));
  
  [self.keysChanged addObject: @{key: kESLevelDBScratchPadKeyRemoved}];
  
  if(exists)
    --self.deltaCount;
  }

- (void) removeAllObjects
  {
  [self removeObjectsForKeys: [self allKeys]];
  
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
      for(ESLevelDBKey key in keys)
        {
        BOOL exists = ([self objectForKey: key] != nil);
        
        self.batch->Delete(ESleveldb::KeySlice(key));
        
        [self.keysChanged
          addObject: @{key: kESLevelDBScratchPadKeyRemoved}];
          
        if(exists)
          --self.deltaCount;
        }
    });
  }

@end

