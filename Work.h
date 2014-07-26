//
//  Work.h
//  udTime
//
//  Created by Johan Adell on 08/04/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Break, Week;

@interface Work : NSManagedObject

@property (nonatomic, retain) NSString * comment;
@property (nonatomic, retain) NSDate * endtime;
@property (nonatomic, retain) NSDate * modified;
@property (nonatomic, retain) NSDate * starttime;
@property (nonatomic, retain) NSNumber * workid;
@property (nonatomic, retain) NSSet *breaks;
@property (nonatomic, retain) Week *parentweek;
@property (nonatomic, retain) NSManagedObject *parentMonth;
@end

@interface Work (CoreDataGeneratedAccessors)

- (void)addBreaksObject:(Break *)value;
- (void)removeBreaksObject:(Break *)value;
- (void)addBreaks:(NSSet *)values;
- (void)removeBreaks:(NSSet *)values;

@end
