/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "ESLevelDBEnumerator.h"

#import "leveldb/db.h"
#import "leveldb/options.h"
#import "leveldb/write_batch.h"

#import "ESLevelDBType.h"
#import "ESLevelDBKeySlice.h"
#import "ESLevelDB.h"
#import "ESLevelDBPrivate.h"
#import "ESLevelDBEnumeratorPrivate.h"

@implementation ESLevelDBEnumerator

@synthesize db = myDb;
@synthesize iter = myIter;

@synthesize object = myObject;
@synthesize objectPtr = myObjectPtr;
@synthesize limit = myLimit;

// Use leveldb's iterator to find the first invalid key key for an end
// iterator.
- (void) setLimit: (ESLevelDBKey) limit
  {
  if(limit != myLimit)
    {
    [self willChangeValueForKey: @"limit"];
    
    myLimit = limit;
    
    [self didChangeValueForKey: @"limit"];
    
    // See if the ending iterator actually exists. If it does, go to the
    // next key.
    leveldb::Iterator * end =
      (*self.db.db)->NewIterator(self.db.readOptions);
    
    end->Seek(ESleveldb::KeySlice(limit));
    
    ESLevelDBKey found = ESleveldb::KeySlice(end->key());
      
    if(!(self.options & NSEnumerationReverse))
      if([found isEqual: myLimit])
        end->Next();
        
    self.end = ESleveldb::KeySlice(end->key());
      
    delete end;
    }
  }

- (ESLevelDBType) limit
  {
  return myLimit;
  }

// Constructor with database.
- (instancetype) initWithDB: (ESLevelDB *) db
  {
  self = [super init];
  
  if(self)
    {
    myIter = 0;
    myDb = db;
    }
    
  return self;
  }

- (void) dealloc
  {
  delete myIter;
  myIter = 0;
  myDb = nil;
  }

- (NSArray *) allObjects
  {
  NSMutableArray * allObjects = [NSMutableArray array];
  
  leveldb::Iterator * allIter =
    (*self.db.db)->NewIterator(self.db.readOptions);
  
  for(allIter->Seek(self.iter->key()); allIter->Valid(); allIter->Next())
    [allObjects addObject: ESleveldb::KeySlice(allIter->key())];
    
  delete allIter;
  
  return [allObjects copy];
  }

- (id) nextObject
  {
  if(self.options & NSEnumerationReverse)
    return [self decrement];
  
  return [self increment];
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
    ESLevelDBKey next = ESleveldb::KeySlice(self.iter->key());
    
    if(self.limit && ([next isEqual: self.limit]))
      return nil;

    return [self setObjects: next];
    }
    
  return nil;
  }

// Support LevelDB's reverse iterator.
- (id) decrement
  {
  BOOL last = NO;
  
  if(!self.iter)
    {
    self.iter = (*self.db.db)->NewIterator(self.db.readOptions);
    
    if(!self.iter)
      return nil;
      
    if(self.end)
      self.iter->Seek(ESleveldb::KeySlice(self.end));
    else
      {
      self.iter->SeekToLast();
      
      last = YES;
      }
    }
  
  if(self.iter->Valid())
    {
    ESLevelDBKey current = ESleveldb::KeySlice(self.iter->key());

    if(self.start && ([current isEqual: self.start]))
      return nil;

    if(!last)
      self.iter->Prev();
    
    if(self.iter->Valid())
      return [self setObjects: ESleveldb::KeySlice(self.iter->key())];
    }
    
  return nil;
  }

// Set the internal objects.
- (id) setObjects: (id) ref
  {
  [self willChangeValueForKey: @"object"];
  [self willChangeValueForKey: @"objectPtr"];
   
  self.ref = ref;
  
  // Force (as with a rubber hose) the extracted object into a pointer
  // so that fast enumeration can access it.
  CFTypeRef key = (__bridge CFTypeRef)self.ref;
  myObject = (__bridge id __unsafe_unretained)key;
  myObjectPtr = (id __unsafe_unretained *)& myObject;
  
  [self didChangeValueForKey: @"objectPtr"];
  [self didChangeValueForKey: @"object"];
    
  return self.ref;
  }

@end
