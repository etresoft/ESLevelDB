/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "ESLevelDBValueEnumerator.h"

#import "leveldb/db.h"
#import "leveldb/options.h"
#import "leveldb/write_batch.h"

#import "ESLevelDBType.h"
#import "ESLevelDBSlice.h"
#import "ESLevelDBKeySlice.h"
#import "ESLevelDB.h"
#import "ESLevelDBPrivate.h"
#import "ESLevelDBEnumeratorPrivate.h"

@implementation ESLevelDBValueEnumerator

- (NSArray *) allObjects
  {
  NSMutableArray * allObjects = [NSMutableArray array];
  
  leveldb::Iterator * allIter =
    (*self.db.db)->NewIterator(self.db.readOptions);
  
  for(allIter->Seek(self.iter->key()); allIter->Valid(); allIter->Next())
    [allObjects addObject: ESleveldb::Slice(allIter->value())];
    
  delete allIter;
  
  return [allObjects copy];
  }

- (id) increment
  {
  if(!self.iter)
    {
    self.iter = (*self.db.db)->NewIterator(self.db.readOptions);
    
    if(!self.iter)
      return nil;
      
    if(self.start)
      self.iter->Seek(ESleveldb::KeySlice(self.start));
    else
      self.iter->SeekToFirst();
    }
  else
    self.iter->Next();
    
  if(self.iter->Valid())
    {
    ESLevelDBType next = ESleveldb::Slice(self.iter->value());
    
    if(self.limit && ([next isEqual: self.limit]))
      return nil;

    return [self setObjects: next];
    }
    
  return nil;
  }

// Support LevelDB's reverse iterator.
- (id) decrement
  {
  if(!self.iter)
    {
    self.iter = (*self.db.db)->NewIterator(self.db.readOptions);
    
    if(!self.iter)
      return nil;
      
    if(self.end)
      self.iter->Seek(ESleveldb::KeySlice(self.end));
    else
      self.iter->SeekToFirst();
    }
  
  if(self.iter->Valid())
    {
    ESLevelDBType current = ESleveldb::Slice(self.iter->value());

    if(self.start && ([current isEqual: self.start]))
      return nil;

    self.iter->Prev();
    
    if(self.iter->Valid())
      return [self setObjects: current];
    }
    
  return nil;
  }

@end
