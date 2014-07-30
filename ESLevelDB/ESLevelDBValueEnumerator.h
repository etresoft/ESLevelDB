/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>

@class ESLevelDBView;

@interface ESLevelDBValueEnumerator : NSEnumerator

// Constructor with view.
- (instancetype) initWithView: (ESLevelDBView *) view;

@end
