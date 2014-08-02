/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#ifndef __ESLevelDB__Slice__
#define __ESLevelDB__Slice__

#import <Foundation/Foundation.h>

#import "leveldb/db.h"

#import "ESLevelDBType.h"
#import "ESLevelDBSerializer.h"
#import "ESLevelDBArchiveSerializer.h"

// A class that can create slices from Objective-C objects using a given
// serializer and convert those slices back into objects.
namespace ESleveldb
  {
  class Slice : public leveldb::Slice
    {
    public:
    
      // Constructor with NSCoding object.
      Slice(ESLevelDBType object,
        ESLevelDBSerializer * serializer =
          [ESLevelDBArchiveSerializer new]) :
        leveldb::Slice(makeSlice(object, serializer)),
        serializer(serializer)
        {
        }

      // Copy constructor with leveldb slice.
      Slice(const leveldb::Slice & slice,
        ESLevelDBSerializer * serializer =
          [ESLevelDBArchiveSerializer new]) :
        leveldb::Slice(slice), serializer(serializer)
        {
        }
      
      // Cast to NSCoding object.
      operator ESLevelDBType (void) const
        {
        return [serializer deserialize: data() length: size()];
        }

    private:
    
      // Create a slice from an NSCoding object.
      leveldb::Slice makeSlice(
        ESLevelDBType object, ESLevelDBSerializer * serializer)
        {
        NSData * data = [serializer serialize: object];
        
        return leveldb::Slice((const char *)[data bytes], [data length]);
        }
      
      // A serializer.
      ESLevelDBSerializer * serializer;
    };
  }

#endif
