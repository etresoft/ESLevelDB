/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

//  Copyright (c) 2012 Adam Preble. All rights reserved.
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//	THE SOFTWARE.

#import "leveldb/db.h"

#import "ESLevelDBSnapshot.h"
#import "ESLevelDBSnapshotPrivate.h"
#import "ESLevelDB.h"
#import "ESLevelDBPrivate.h"

@implementation ESLevelDBSnapshot

// Constructor.
- (instancetype) initWithESLevelDB: (ESLevelDB *) db
  {
  self = [super initWithESLevelDB: db];
  
  if(self)
    {
    self.snapshot = (*db.db)->GetSnapshot();
    self.immutable = YES;
    
    leveldb::ReadOptions readOptions = self.readOptions;
    
    readOptions.snapshot = self.snapshot;
    
    self.readOptions = readOptions;
    }
    
  return self;
  }

- (void) dealloc
  {
  if(self.db && self.snapshot)
    {
    (*self.db)->ReleaseSnapshot(self.snapshot);
    }
  }

@end

