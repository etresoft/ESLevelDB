/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "ESLevelDBKeySerializer.h"
#import "ESLevelDBType.h"

// Seriaizer using a custom, order-preserving serialization process
// appropriate for keys.
@implementation ESLevelDBKeySerializer

- (NSData *) serialize: (ESLevelDBType) key
  {
  return [(NSString *)key dataUsingEncoding: NSUTF8StringEncoding];
  }

- (ESLevelDBType) deserialize: (const char *) data
  length: (NSUInteger) length
  {
  return
    [[NSString alloc]
      initWithBytes: data
      length: length
      encoding: NSUTF8StringEncoding];
  }

@end
