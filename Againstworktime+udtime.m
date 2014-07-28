//
//  Againstworktime+udtime.m
//  udTime
//
//  Created by Johan Adell on 30/03/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import "Againstworktime+udtime.h"
#import "Week+udTime.h"
#import "Month+udtime.h"

@implementation Againstworktime (udtime)
+ (Againstworktime *)againstworktimeWithServerInfo:(NSDictionary *)againstworktimeDictionary
                            inManagedObjectContext:(NSManagedObjectContext *)context{
    
    Againstworktime *againstworktime = nil;
    
    NSNumber *unique = [againstworktimeDictionary objectForKey:@"id"];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Againstworktime"];
    request.predicate = [NSPredicate predicateWithFormat:@"againstworktimeid==%lu", [unique integerValue]];
    
    NSError *error;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    //NSLog(@"%lu",[matches count]);
    if (!matches || error || ([matches count] > 1)) {
        // handle error
    } else if ([matches count]) {   //Update
        againstworktime = [matches firstObject];
    } else {
        againstworktime = [NSEntityDescription insertNewObjectForEntityForName:@"Againstworktime"
                                                        inManagedObjectContext:context];
    }
    NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterNoStyle];
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy-MM-dd"];
    
    againstworktime.date = [df dateFromString:againstworktimeDictionary[@"date"]];
    againstworktime.time = [f numberFromString:againstworktimeDictionary[@"time"]];
    againstworktime.modified = [NSDate dateWithTimeIntervalSince1970:[[f numberFromString:againstworktimeDictionary[@"modified"]] integerValue]];
    againstworktime.type = againstworktimeDictionary[@"name"];
    againstworktime.againstworktimeid = [f numberFromString:againstworktimeDictionary[@"id"]];
    
    againstworktime.parentweek = [Week weekOfYearForDate:againstworktime.date inManagedObjectContext:context];
    againstworktime.parentMonth = [Month monthOfYearForDate:againstworktime.date inManagedObjectContext:context];

    
    return againstworktime;
}

-(NSString *)accessType{
    return self.type;
}
-(NSNumber *)accessTime{
    return self.time;
}
-(NSNumber *)accessId{
    return self.againstworktimeid;
}
-(void)setAccessTime:(NSNumber *)time{
    self.time = time;
}
@end
