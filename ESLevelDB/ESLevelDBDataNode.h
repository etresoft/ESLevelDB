/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>
#import "ESLevelDBType.h"

@interface ESLevelDBDataNode : NSObject

@property (assign) ESLevelDBDataNode * parent;
@property (strong) NSString * key;
@property (strong) ESLevelDBType value;
@property (strong) NSMutableArray * children;

@end
