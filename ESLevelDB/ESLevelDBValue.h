/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#ifndef __ESLevelDB__Value__
#define __ESLevelDB__Value__

#import <functional>

#import <Foundation/Foundation.h>

#import "leveldb/db.h"

#import "ESLevelDBType.h"
#import "ESLevelDBSerializer.h"
#import "ESLevelDBArchiveSerializer.h"

// A wrapper for a value. Once wrapped, leveldb will deserialize the value
// into the object using the specified serializer.
namespace ESleveldb
  {
  class Value : public leveldb::Value
    {
    public:
    
      // Constructor.
      Value(ESLevelDBType __strong & object,
        ESLevelDBSerializer * serializer =
          [ESLevelDBArchiveSerializer new]) :
        serializer(serializer), object(object)
        {
        }
      
      // Assign from data and length.
      leveldb::Value & assign(const char * data, size_t size)
        {
        object = [serializer deserialize: data length: size];
        
        return *this;
        }

    private:
    
      // A serializer.
      ESLevelDBSerializer * serializer;
      
      // My actual object.
      ESLevelDBType __strong & object;
    };  
  }

#endif // defined(__ESLevelDB__Value__)
