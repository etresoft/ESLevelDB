/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>
#import "ESLevelDBType.h"

@class ESLevelDBDataSource;
@class ESLevelDBDataNode;

@protocol ESLevelDBDataSourceDelegate <NSObject>

@optional - (void) dataSource: (ESLevelDBDataSource *) dataSource
  willInsert: (ESLevelDBDataNode *) node at: (NSIndexPath *) path;

- (void) dataSource: (ESLevelDBDataSource *) dataSource
  didInsert: (ESLevelDBDataNode *) node at: (NSIndexPath *) path;

@optional - (void) dataSource: (ESLevelDBDataSource *) dataSource
  willRemove: (ESLevelDBDataNode *) node at: (NSIndexPath *) path;

- (void) dataSource: (ESLevelDBDataSource *) dataSource
  didRemove: (ESLevelDBDataNode *) node at: (NSIndexPath *) path;

@optional - (void) dataSource: (ESLevelDBDataSource *) dataSource
  willUpdate: (ESLevelDBDataNode *) node
  at: (NSIndexPath *) path
  with: (ESLevelDBType) value;

- (void) dataSource: (ESLevelDBDataSource *) dataSource
  didUpdate: (ESLevelDBDataNode *) node
  at: (NSIndexPath *) path
  with: (ESLevelDBType) value;

@end
