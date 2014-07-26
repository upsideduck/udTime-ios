//
//  Asworktime.h
//  udTime
//
//  Created by Johan Adell on 08/04/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Month, Week;

@interface Asworktime : NSManagedObject

@property (nonatomic, retain) NSNumber * asworktimeid;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSDate * modified;
@property (nonatomic, retain) NSNumber * time;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) Week *parentweek;
@property (nonatomic, retain) Month *parentMonth;

@end
