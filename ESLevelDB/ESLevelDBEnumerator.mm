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
#import "ESLevelDBView.h"
#import "ESLevelDBViewPrivate.h"
#import "ESLevelDBEnumeratorPrivate.h"

@implementation ESLevelDBEnumerator
  {
  ESLevelDBView * myView;
  leveldb::Iterator * myIter;
  }

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
    leveldb::Iterator * end = myView.db->NewIterator(myView.readOptions);
    
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

// Constructor with view.
- (instancetype) initWithView: (ESLevelDBView *) view
  {
  self = [super init];
  
  if(self)
    {
    myIter = 0;
    myView = view;
    }
    
  return self;
  }

- (void) dealloc
  {
  delete myIter;
  myIter = 0;
  myView = nil;
  }

- (NSArray *) allObjects
  {
  NSMutableArray * allObjects = [NSMutableArray array];
  
  leveldb::Iterator * allIter =
    myView.db->NewIterator(myView.readOptions);
  
  for(allIter->Seek(myIter->key()); allIter->Valid(); allIter->Next())
    [allObjects addObject: ESleveldb::KeySlice(allIter->key())];
    
  delete allIter;
  
  return [allObjects copy];
  }

- (ESLevelDBType) nextObject
  {
  ESLevelDBType result = nil;
  
  if(self.options & NSEnumerationReverse)
    result = [self decrement];
  else
    result = [self increment];
    
  if(!result)
    {
    delete myIter;
    myIter = 0;
    }
    
  return result;
  }

- (ESLevelDBKey) increment
  {
  if(!myIter)
    {
    myIter = myView.db->NewIterator(myView.readOptions);
    
    if(!myIter)
      return nil;
      
    if(self.start)
      myIter->Seek(ESleveldb::KeySlice(self.start));
    else
      myIter->SeekToFirst();
    }
  else
    myIter->Next();
    
  if(myIter->Valid())
    {
    ESLevelDBKey next = ESleveldb::KeySlice(myIter->key());
    
    if(self.limit && ([next isEqual: self.limit]))
      return nil;

    [self willChangeValueForKey: @"object"];
    [self willChangeValueForKey: @"objectPtr"];
     
    self.ref = next;
    
    // Force (as with a rubber hose) the extracted object into a pointer
    // so that fast enumeration can access it.
    CFTypeRef ref = (__bridge CFTypeRef)self.ref;
    myObject = (__bridge id __unsafe_unretained)ref;
    myObjectPtr = (id __unsafe_unretained *)& myObject;
    
    [self didChangeValueForKey: @"objectPtr"];
    [self didChangeValueForKey: @"object"];
    
    return self.ref;
    }
    
  return nil;
  }

// Support LevelDB's reverse iterator.
- (ESLevelDBKey) decrement
  {
  if(!myIter)
    {
    myIter = myView.db->NewIterator(myView.readOptions);
    
    if(!myIter)
      return nil;
      
    if(self.end)
      myIter->Seek(ESleveldb::KeySlice(self.end));
    else
      myIter->SeekToFirst();
    }
  
  if(myIter->Valid())
    {
    ESLevelDBKey current = ESleveldb::KeySlice(myIter->key());

    if(self.start && ([current isEqual: self.start]))
      return nil;

    myIter->Prev();
    
    if(myIter->Valid())
      {
      [self willChangeValueForKey: @"object"];
      [self willChangeValueForKey: @"objectPtr"];
       
      self.ref = ESleveldb::KeySlice(myIter->key());
      
      // Force (as with a rubber hose) the extracted object into a pointer
      // so that fast enumeration can access it.
      CFTypeRef ref = (__bridge CFTypeRef)self.ref;
      myObject = (__bridge id __unsafe_unretained)ref;
      myObjectPtr = (id __unsafe_unretained *)& myObject;
      
      [self didChangeValueForKey: @"objectPtr"];
      [self didChangeValueForKey: @"object"];
      
      return self.ref;
      }
    }
    
  return nil;
  }

@end
