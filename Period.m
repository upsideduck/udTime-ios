//
//  Period.m
//  udTime
//
//  Created by Johan Adell on 05/01/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import "Period.h"


@implementation Period


-(NSDictionary *)exportDictionary{
    return [[NSDictionary alloc] initWithObjectsAndKeys:[[NSNumber alloc] initWithInteger:self.starttime],@"starttime",
     [[NSNumber alloc] initWithInteger:self.endtime],@"endtime",
     [[NSNumber alloc] initWithInteger:self.dbId],@"dbId",
     [[NSNumber alloc] initWithInteger:self.modified],@"modified",nil];
}

-(void)import:(NSDictionary *)dictionary{
    self.starttime = [[dictionary objectForKey:@"starttime"] integerValue];
    self.endtime = [[dictionary objectForKey:@"endtime"] integerValue];
    self.dbId = [[dictionary objectForKey:@"dbId"] integerValue];
    self.modified = [[dictionary objectForKey:@"modified"] integerValue];
}

-(id)copyWithZone:(NSZone *)zone
{
    // We'll ignore the zone for now
    Period *aCopy = [[Period alloc] init];
    aCopy.starttime = self.starttime;
    aCopy.endtime = self.endtime;
    aCopy.dbId = self.dbId;
    aCopy.modified = self.modified;
    
    return aCopy;
}
@end
