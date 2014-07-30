/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#ifndef __ESLevelDB__Serializer__
#define __ESLevelDB__Serializer__

#import <Foundation/Foundation.h>
#import "ESLevelDBType.h"

// Abstract base class for serializers.
namespace ESleveldb
  {
  class Serializer
    {
    public:
    
      virtual NSData * serialize(ESLevelDBType object) const = 0;
      
      virtual
        ESLevelDBType
        deserialize(const char * data, NSUInteger length) const = 0;
      
      virtual ESLevelDBType deserialize(NSData * data) const = 0;
    };
  }

#endif

