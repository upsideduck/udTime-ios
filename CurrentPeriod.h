//
//  CurrentPeriod.h
//  udTime
//
//  Created by Johan Adell on 05/01/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import "Period.h"

@interface CurrentPeriod : Period

extern NSInteger FREE;
extern NSInteger WORK;
extern NSInteger BREAK;

@property (nonatomic, strong) NSMutableArray *finishedBreaks;
@property (nonatomic) NSInteger secondaryStarttime;
@property (nonatomic) NSInteger secondaryDbId;
@property (nonatomic) NSInteger secondaryModified;

-(void)clearPeriod;
-(NSInteger)periodType;
-(NSInteger)totalBreakSeconds;
-(NSDictionary *)exportCurrentPeriodDictionary;
-(void)importCurrentPeriod:(NSDictionary *)dictionary;

-(Period *)startBreakWithTimestamp:(NSInteger)timestamp;
-(Period *)endBreakWithTimestamp:(NSInteger)timestamp;
-(Period *)startWorkWithTimestamp:(NSInteger)timestamp;
-(Period *)endWorkWithTimestamp:(NSInteger)timestamp;

@end
