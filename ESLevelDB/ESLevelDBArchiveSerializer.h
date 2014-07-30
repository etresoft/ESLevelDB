/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#ifndef __ESLevelDB__ArchiveSerializer__
#define __ESLevelDB__ArchiveSerializer__

#import <Foundation/Foundation.h>

#import "ESLevelDBType.h"

// An archive serializer.
namespace ESleveldb
  {
  class ArchiveSerializer : public Serializer
    {
    public:
    
      virtual NSData * serialize(ESLevelDBType object) const
        {
        return [NSKeyedArchiver archivedDataWithRootObject: object];
        }
      
      virtual
        ESLevelDBType deserialize(const char * data, NSUInteger length)
        const
        {
        NSData * objectData =
          [NSData
            dataWithBytesNoCopy: (void *)data
            length: length
            freeWhenDone: NO];
        
        return [NSKeyedUnarchiver unarchiveObjectWithData: objectData];
        }
        
      virtual ESLevelDBType deserialize(NSData * data) const
        {
        return deserialize((const char *)[data bytes], [data length]);
        }
    };
    
  static ArchiveSerializer kArchiveSerializer = ArchiveSerializer();
  }

#endif

