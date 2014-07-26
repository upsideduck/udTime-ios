//
//  Week.h
//  udTime
//
//  Created by Johan Adell on 08/04/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Againstworktime, Asworktime, Work;

@interface Week : NSManagedObject

@property (nonatomic, retain) NSNumber * againstworktime;
@property (nonatomic, retain) NSNumber * asworktime;
@property (nonatomic, retain) NSDate * modified;
@property (nonatomic, retain) NSNumber * modifiedtimestamp;
@property (nonatomic, retain) NSString * totaldifftime;
@property (nonatomic, retain) NSNumber * towork;
@property (nonatomic, retain) NSNumber * week;
@property (nonatomic, retain) NSString * weekdifftime;
@property (nonatomic, retain) NSNumber * weekid;
@property (nonatomic, retain) NSNumber * worked;
@property (nonatomic, retain) NSString * workedtime;
@property (nonatomic, retain) NSNumber * year;
@property (nonatomic, retain) NSSet *againstworktimeperiods;
@property (nonatomic, retain) NSSet *asworktimeperiods;
@property (nonatomic, retain) NSSet *workperiods;
@end

@interface Week (CoreDataGeneratedAccessors)

- (void)addAgainstworktimeperiodsObject:(Againstworktime *)value;
- (void)removeAgainstworktimeperiodsObject:(Againstworktime *)value;
- (void)addAgainstworktimeperiods:(NSSet *)values;
- (void)removeAgainstworktimeperiods:(NSSet *)values;

- (void)addAsworktimeperiodsObject:(Asworktime *)value;
- (void)removeAsworktimeperiodsObject:(Asworktime *)value;
- (void)addAsworktimeperiods:(NSSet *)values;
- (void)removeAsworktimeperiods:(NSSet *)values;

- (void)addWorkperiodsObject:(Work *)value;
- (void)removeWorkperiodsObject:(Work *)value;
- (void)addWorkperiods:(NSSet *)values;
- (void)removeWorkperiods:(NSSet *)values;

@end
