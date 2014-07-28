//
//  Againstworktime.h
//  udTime
//
//  Created by Johan Adell on 27/07/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Month, Week;

@interface Againstworktime : NSManagedObject

@property (nonatomic, retain) NSNumber * againstworktimeid;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSDate * modified;
@property (nonatomic, retain) NSNumber * time;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) Month *parentMonth;
@property (nonatomic, retain) Week *parentweek;

@end
