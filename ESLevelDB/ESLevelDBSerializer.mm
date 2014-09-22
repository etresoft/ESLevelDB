/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import "ESLevelDBSerializer.h"
#import "ESLevelDBType.h"

// Abstract base class for serializers.
@implementation ESLevelDBSerializer

- (NSData *) serialize: (ESLevelDBType) object
  {
  return nil;
  }

- (ESLevelDBType) deserialize: (const char *) data
  length: (NSUInteger) length
  {
  return nil;
  }

@end
