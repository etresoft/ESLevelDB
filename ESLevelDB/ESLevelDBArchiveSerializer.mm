/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "ESLevelDBArchiveSerializer.h"
#import "ESLevelDBType.h"

// Seriaizer using NSKeyedArchiver and NSKeyedUnarchiver.
@implementation ESLevelDBArchiveSerializer

- (NSData *) serialize: (ESLevelDBType) object
  {
  return [NSKeyedArchiver archivedDataWithRootObject: object];
  }

- (ESLevelDBType) deserialize: (const char *) data
  length: (NSUInteger) length
  {
  NSData * objectData =
    [NSData
      dataWithBytesNoCopy: (void *)data
      length: length
      freeWhenDone: NO];
  
  return [NSKeyedUnarchiver unarchiveObjectWithData: objectData];
  }

- (ESLevelDBType) deserialize: (NSData *) data
  {
  return
    [self deserialize: (const char *)[data bytes] length: [data length]];
  }

@end
