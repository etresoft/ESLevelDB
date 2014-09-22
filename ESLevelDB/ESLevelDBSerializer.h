/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

#import "ESLevelDBType.h"

// Abstract base class for serializers.
@interface ESLevelDBSerializer : NSObject

- (NSData *) serialize: (ESLevelDBType) object;

- (ESLevelDBType) deserialize: (const char *) data
  length: (NSUInteger) length;

@end
