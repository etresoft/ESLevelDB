/***********************************************************************
 ** Etresoft
 ** John Daniel
 ** Copyright (c) 2014. All rights reserved.
 **********************************************************************/

#import <Foundation/Foundation.h>
#import "ESLevelDBType.h"

@class ESLevelDBView;

@interface ESLevelDBEnumerator : NSEnumerator

// Constructor with view.
- (instancetype) initWithView: (ESLevelDBView *) view;

// The start of this range, if applicable.
@property (strong) ESLevelDBKey start;

// The end (exclusive) of this range, if applicable.
@property (strong) ESLevelDBKey limit;

// Enumerator options.
@property (assign) NSEnumerationOptions options;

@end
