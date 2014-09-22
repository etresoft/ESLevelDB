/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#ifndef __ESLevelDB__KeySlice__
#define __ESLevelDB__KeySlice__

#import <Foundation/Foundation.h>

#import "leveldb/db.h"

#import "ESLevelDBType.h"
#import "ESLevelDBSerializer.h"
#import "ESLevelDBKeySerializer.h"
#import "ESLevelDBSlice.h"

// A class that can create slices from Objective-C objects using a given
// serializer and convert those slices back into objects.
namespace ESleveldb
  {
  class KeySlice : public Slice
    {
    public:
    
      // Constructor with NSCoding object.
      KeySlice(ESLevelDBKey key) :
        Slice(key, [ESLevelDBKeySerializer new])
        {
        }

      // Copy constructor with leveldb slice.
      KeySlice(const leveldb::Slice & slice) :
        Slice(slice, [ESLevelDBKeySerializer new])
        {
        }

      // Cast to key.
      operator ESLevelDBKey (void) const
        {
        return
          (ESLevelDBKey)[serializer deserialize: data() length: size()];
        }
    };
  }

#endif
