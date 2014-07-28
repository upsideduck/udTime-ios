//
//  Asworktime+udtime.m
//  udTime
//
//  Created by Johan Adell on 30/03/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import "Asworktime+udtime.h"
#import "Week+udTime.h"
#import "Month+udtime.h"

@implementation Asworktime (udtime)
+ (Asworktime *)asworktimeWithServerInfo:(NSDictionary *)asworktimeDictionary
                            inManagedObjectContext:(NSManagedObjectContext *)context{
    
    Asworktime *asworktime = nil;
    
    NSNumber *unique = [asworktimeDictionary objectForKey:@"id"];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Asworktime"];
    request.predicate = [NSPredicate predicateWithFormat:@"asworktimeid==%lu", [unique integerValue]];
    
    NSError *error;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    //NSLog(@"%lu",[matches count]);
    if (!matches || error || ([matches count] > 1)) {
        // handle error
    } else if ([matches count]) {   //Update
        asworktime = [matches firstObject];
    } else {
        asworktime = [NSEntityDescription insertNewObjectForEntityForName:@"Asworktime"
                                                        inManagedObjectContext:context];
    }
    NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterNoStyle];
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy-MM-dd"];
    
    asworktime.date = [df dateFromString:asworktimeDictionary[@"date"]];
    asworktime.time = [f numberFromString:asworktimeDictionary[@"time"]];
    asworktime.modified = [NSDate dateWithTimeIntervalSince1970:[[f numberFromString:asworktimeDictionary[@"modified"]] integerValue]];
    asworktime.type = asworktimeDictionary[@"name"];
    asworktime.asworktimeid = [f numberFromString:asworktimeDictionary[@"id"]];
    
    asworktime.parentweek = [Week weekOfYearForDate:asworktime.date inManagedObjectContext:context];
    asworktime.parentMonth = [Month monthOfYearForDate:asworktime.date inManagedObjectContext:context];

    return asworktime;
}

-(NSString *)accessType{
    return self.type;
}
-(NSNumber *)accessTime{
    return self.time;
}
-(NSNumber *)accessId{
    return self.asworktimeid;
}
-(void)setAccessTime:(NSNumber *)time{
    self.time = time;
}
@end
