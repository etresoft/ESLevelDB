/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "leveldb/db.h"
#import "leveldb/options.h"
#import "leveldb/write_batch.h"

#import "ESLevelDBValueEnumerator.h"
#import "ESLevelDBType.h"
#import "ESLevelDBSlice.h"
#import "ESLevelDBView.h"
#import "ESLevelDBViewPrivate.h"
#import "ESLevelDBValueEnumeratorPrivate.h"

@implementation ESLevelDBValueEnumerator
  {
  ESLevelDBView * myView;
  leveldb::Iterator * myIter;
  }

@synthesize object = myObject;
@synthesize objectPtr = myObjectPtr;

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
  }

- (NSArray *) allObjects
  {
  NSMutableArray * allObjects = [NSMutableArray array];
  
  leveldb::Iterator * allIter =
    myView.db->NewIterator(myView.readOptions);
  
  for(allIter->Seek(myIter->value()); allIter->Valid(); allIter->Next())
    [allObjects addObject: ESleveldb::Slice(allIter->key())];
    
  delete allIter;
  
  return [allObjects copy];
  }

- (ESLevelDBType) nextObject
  {
  if(!myIter)
    {
    myIter = myView.db->NewIterator(myView.readOptions);
    
    if(!myIter)
      return nil;
      
    myIter->SeekToFirst();
    }
  else
    myIter->Next();
    
  if(myIter->Valid())
    {
    [self willChangeValueForKey: @"object"];
    [self willChangeValueForKey: @"objectPtr"];
     
    self.ref = ESleveldb::Slice(myIter->value());
    
    // Force (as with a rubber hose) the extracted object into a pointer
    // so that fast enumeration can access it.
    CFTypeRef ref = (__bridge CFTypeRef)self.ref;
    id __unsafe_unretained unsafeId = (__bridge id __unsafe_unretained)ref;
    myObjectPtr = (id __unsafe_unretained *)& unsafeId;
    
    [self didChangeValueForKey: @"objectPtr"];
    [self didChangeValueForKey: @"object"];
    
    return self.ref;
    }
    
  return nil;
  }

@end
