# ESLevelDB

This project is based on Adam Preble's APLevelDB. It no longer shares much code from APLevelDB so it really can't be called a fork. Most of the files are new. What follows is the APLevelDB description updated for ESLevelDB.

A stylish Objective-C wrapper for [LevelDB][].  What's LevelDB?  It describes itself as: "a fast key-value storage library written at Google that provides an ordered mapping from string keys to string values."  ESLevelDB is made available under the [New BSD License][].

ESLevelDB is comprised of a number of classes, `ESLevelDB` and `ESLevelDBScratchPad` are likely to be the most commonly used.  It is written to be compiled under ARC.  ESLevelDB was written by [John Daniel][] and adapted from [Adam Preble][]'s [APLevelDB][].

The key difference between this project an APLevelDB is that APLevelDB is an Objective-C wrapper around LevelDB. ESLevelDB is designed to be a Core Data replacement. It looks and acts like an NSMutableDictionary that gets automatically persisted. 

There are some caveats for LevelDB's design, but not many. For example, although any object that conforms to the NSSecureCoding protocol could be used for values and keys, in practice, NSString is used. Primarily this due to LevelDB's support for seekable iterators. The default object serialization is not stable with respect to sorting so something had to give. There are a few new capabilities and methods for those seekable iterators. ESLevelDB includes an extensive test suite. 

ESLevelDB is a work in progress. It works well for simple objects. It still needs logic to support persisting changes to objects. Currently you would have to store a new object to write. It doesn't support iCloud yet, but it will.

This is an Xcode project to build ESLevelDB as a standalone framework or iOS library. It includes leveldb and snappy. It is meant to be used as part of a Xcode app workspace. Xcode is very picky about things. Modern Xcode is designed to work with with workspaces and workspaces require a very specific construction and build process. Traditional open-source methods won't work.

## Usage

Create the following directory hierarchy:
LevelDB/
  ESLevelDB (this project)
  leveldb (the original LevelDB project)
  snappy (the original Snappy project)

Open `ESLevelDB.xcodeproj` and run the unit tests (Product, Test) or compile the ESLevelDB framework and add it to your project.

Note: I also have an [LevelDB Xcode wrapper][] and a [Snappy Xcode wrapper][]. Due to the bundled nature of this project, the other wrappers are not required. But they were useful in building this project.

### Creating An Instance

	NSString * path = ...;
	NSError * err;
	ESLevelDB * db = [ESLevelDB levelDBWithPath: path error: & err];

### Getting and Setting Values - same as NSDictionary

	db[@"key"] = @"the value";
	NSString * value = db[@"key"];

### Iterating - same as NSDictionary.

You can iterate over the entire database:

	[db 
	  enumerateKeysAndObjectsUsingBlock:
	    ^(ESLevelDBKey key, ESLevelDBType obj, BOOL * stop) 
	      {
		    NSLog(@"key = %@, value = %@", key, value);
	      }];	

Or use fast enumeration.

	for(ESLevelDBKey key in db)
	  NSLog(@"key = %@, value = %@", key, db[key]);	

One of LevelDB's most useful features is that its keys are ordered. Using `ESLevelDBIterator` (or convenience methods) you can iterate over the key ranges:

  [db
    enumerateKeysAndObjectsFrom: @"ab"
    limit: @"cd"
    usingBlock:
      ^(ESLevelDBKey key, ESLevelDBType obj, BOOL * stop)
        {
        [found addObject: obj];
        }];

### Storing Objects

ESLevelDB uses strings for keys, but its values need only conform to NSSecureCoding.

Portions of APLevelDB are based on [APLevelDB][]. Portions of APLevelDB are based on [LevelDB-ObjC][].  Its license can be found in `APLevelDB.mm`.

[LevelDB]: http://code.google.com/p/leveldb/
[John Daniel]: http://etresoft.com/
[Adam Preble]: http://adampreble.net/
[LevelDB-ObjC]: https://github.com/hoisie/LevelDB-ObjC
[New BSD License]: http://www.opensource.org/licenses/bsd-license.php
[LevelDB Xcode wrapper]: https://github.com/etresoft/LevelDB-Xcode
[Snappy Xcode wrapper]: https://github.com/etresoft/Snappy-Xcode
