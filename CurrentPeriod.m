//
//  CurrentPeriod.m
//  udTime
//
//  Created by Johan Adell on 05/01/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import "CurrentPeriod.h"

@implementation CurrentPeriod


NSInteger FREE = 0;
NSInteger WORK = 1;
NSInteger BREAK = 2;

-(NSMutableArray *)finishedBreaks{
    if (!_finishedBreaks) _finishedBreaks = [[NSMutableArray alloc] init];
    return _finishedBreaks;
}

-(NSInteger)secondaryStarttime{
    if (!_secondaryStarttime) _secondaryStarttime = 0;
    return _secondaryStarttime;
}

-(NSInteger)secondaryModified{
    if (!_secondaryModified) _secondaryModified = 0;
    return _secondaryModified;
}

-(NSInteger)secondaryDbId{
    if (!_secondaryDbId) _secondaryDbId = 0;
    return _secondaryDbId;
}

-(NSInteger)periodType{
    if(self.secondaryStarttime > 0){
        return BREAK;
    }else if (self.starttime > 0){
        return WORK;
    }else{
        return FREE;
    }
}

-(NSInteger)totalBreakSeconds{
    NSInteger total = 0;
    for (id obj in self.finishedBreaks) {
        if([obj isKindOfClass:[Period class]]){
            Period *breakPeriod = (Period *)obj;
            total += breakPeriod.endtime - breakPeriod.starttime;
        }
    }
    return total;
}

-(NSDictionary *)exportCurrentPeriodDictionary{
    NSMutableArray *finishedBreaks = [[NSMutableArray alloc] init];
    for(Period *period in self.finishedBreaks){
        [finishedBreaks addObject:[period exportDictionary]];
    }
    
    return [[NSDictionary alloc] initWithObjectsAndKeys:[[NSNumber alloc] initWithInteger:self.starttime],@"starttime",
                [[NSNumber alloc] initWithInteger:self.endtime],@"endtime",
                [[NSNumber alloc] initWithInteger:self.dbId],@"dbId",
                [[NSNumber alloc] initWithInteger:self.modified],@"modified",
                [[NSNumber alloc] initWithInteger:self.secondaryStarttime],@"secondaryStarttime",
                [[NSNumber alloc] initWithInteger:self.secondaryDbId],@"secondaryDbId",
                [[NSNumber alloc] initWithInteger:self.secondaryModified],@"secondaryModified",
                [finishedBreaks copy], @"finishedBreaks",
                nil];
    
}

-(void)importCurrentPeriod:(NSDictionary *)dictionary{
    [self clearPeriod];
    
    self.secondaryDbId = [[dictionary objectForKey:@"secondaryDbId"] integerValue];
    self.secondaryModified = [[dictionary objectForKey:@"secondaryModified"] integerValue];
    self.secondaryStarttime = [[dictionary objectForKey:@"secondaryStarttime"] integerValue];
    self.starttime = [[dictionary objectForKey:@"starttime"] integerValue];
    self.endtime = [[dictionary objectForKey:@"endtime"] integerValue];
    self.dbId = [[dictionary objectForKey:@"dbId"] integerValue];
    self.modified = [[dictionary objectForKey:@"modified"] integerValue];
    
    for(NSDictionary *dic in (NSArray *)[dictionary objectForKey:@"finishedBreaks"]){
        Period *breakPeriod = [[Period alloc] init];
        breakPeriod.starttime = [[dic objectForKey:@"starttime"] integerValue];
        breakPeriod.endtime = [[dic objectForKey:@"endtime"] integerValue];
        breakPeriod.dbId = [[dic objectForKey:@"dbId"] integerValue];
        breakPeriod.modified = [[dic objectForKey:@"modified"] integerValue];
        [self.finishedBreaks addObject:breakPeriod];
    }
    
}


-(void)clearPeriod{
    self.finishedBreaks = nil;
    self.secondaryDbId = 0;
    self.secondaryModified = 0;
    self.secondaryStarttime = 0;
    self.starttime = 0;
    self.endtime = 0;
    self.dbId = 0;
    self.modified = 0;
}

-(Period *)endBreakWithTimestamp:(NSInteger)timestamp{
    Period *finishedBreak = [[Period alloc] init];
    finishedBreak.starttime = self.secondaryStarttime;
    finishedBreak.endtime = timestamp;
    finishedBreak.dbId = self.secondaryDbId;
    finishedBreak.modified = self.secondaryModified;
    self.secondaryStarttime = 0;
    self.secondaryDbId = 0;
    self.secondaryModified = 0;
    
    [self.finishedBreaks addObject:finishedBreak];
    return finishedBreak;
}

-(Period *)startBreakWithTimestamp:(NSInteger)timestamp{
    Period *newBreak = [[Period alloc] init];
    self.secondaryStarttime = timestamp;
    newBreak.starttime = timestamp;
    newBreak.endtime = 0;
    newBreak.dbId = self.secondaryDbId;
    newBreak.modified = self.secondaryModified;
    return newBreak;
}
-(Period *)startWorkWithTimestamp:(NSInteger)timestamp{
    Period *newWork = [[Period alloc] init];
    self.starttime = timestamp;
    newWork.starttime = timestamp;
    newWork.endtime = 0;
    newWork.dbId = 0;
    newWork.modified = 0;
    return newWork;
}
-(Period *)endWorkWithTimestamp:(NSInteger)timestamp{
    Period *endWork = [[Period alloc] init];
    self.endtime = timestamp;
    endWork.starttime = self.starttime;
    endWork.endtime = self.endtime;
    endWork.dbId = self.dbId;
    endWork.modified = self.modified;
    return endWork;
}

@end
