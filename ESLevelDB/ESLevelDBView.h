/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

#import "ESLevelDBDictionary.h"
#import "ESLevelDBSerializer.h"

// A read-only view of a LevelDB database suitable for a snapshot or the
// database itself.
@interface ESLevelDBView :
  NSObject <ESLevelDBDictionary, NSFastEnumeration>

// Serializer.
@property (assign) ESleveldb::Serializer * serializer;

// Does this view support a fast count?
@property (assign) BOOL fastCount;

@end
