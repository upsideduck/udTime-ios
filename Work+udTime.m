//
//  Work+udTime.m
//  udTime
//
//  Created by Johan Adell on 30/03/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import "Work+udTime.h"
#import "Week+udTime.h"
#import "Month+udtime.h"

@implementation Work (udTime)
+ (Work *)workWithServerInfo:(NSDictionary *)workDictionary
      inManagedObjectContext:(NSManagedObjectContext *)context{
    
    Work *work = nil;
    
    NSNumber *unique = [workDictionary objectForKey:@"id"];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Work"];
    request.predicate = [NSPredicate predicateWithFormat:@"workid==%lu", [unique integerValue]];
    
    NSError *error;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    //NSLog(@"%lu",[matches count]);
    if (!matches || error || ([matches count] > 1)) {
        // handle error
    } else if ([matches count]) {   //Update
        work = [matches firstObject];
    } else if (![workDictionary[@"endtime"] isKindOfClass:[NSNull class]]) {         //only create new work if work is finished
        work = [NSEntityDescription insertNewObjectForEntityForName:@"Work"
                                             inManagedObjectContext:context];
    }else {
        return nil;
    }
    NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterNoStyle];
    
    
    work.workid = [f numberFromString:workDictionary[@"id"]];
    work.starttime = [NSDate dateWithTimeIntervalSince1970:[[f numberFromString:workDictionary[@"starttime"]] integerValue]];
    work.endtime = [NSDate dateWithTimeIntervalSince1970:[[f numberFromString:workDictionary[@"endtime"]] integerValue]];
    work.modified = [NSDate dateWithTimeIntervalSince1970:[[f numberFromString:workDictionary[@"modified"]] integerValue]];
    //§ = workDictionary[@"comment"];
    
    work.parentweek = [Week weekOfYearForDate:work.starttime inManagedObjectContext:context];
    work.parentMonth = [Month monthOfYearForDate:work.starttime inManagedObjectContext:context];
    
    return work;
}

+ (Work *)workWithUniqeId:(NSNumber *)uniqe
   inManagedObjectContext:(NSManagedObjectContext *)context{
    Work *work = nil;
    
    // Specify which units we would like to use
    
    if([uniqe integerValue] > 0){
        NSInteger uniqeValue = [uniqe integerValue];
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Work"];
        request.predicate = [NSPredicate predicateWithFormat:@"workid == %lu", uniqeValue];
        
        NSError *error;
        NSArray *matches = [context executeFetchRequest:request error:&error];
        
        if (!matches || ([matches count] > 1)) {
            // handle error
        } else if (![matches count]) {
            return nil;
        } else {
            work = [matches lastObject];
        }
    }
    
    return work;
}
@end
