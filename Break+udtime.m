//
//  Break+udtime.m
//  udTime
//
//  Created by Johan Adell on 30/03/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import "Break+udtime.h"
#import "Work+udTime.h"

@implementation Break (udtime)
+ (Break *)breakWithServerInfo:(NSDictionary *)breakDictionary
      inManagedObjectContext:(NSManagedObjectContext *)context{
    
    Break *breakPeriod = nil;
    
    NSNumber *unique = [breakDictionary objectForKey:@"id"];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Break"];
    request.predicate = [NSPredicate predicateWithFormat:@"breakid==%lu", [unique integerValue]];
    
    NSError *error;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    //NSLog(@"%lu",[matches count]);
    if (!matches || error || ([matches count] > 1)) {
        // handle error
    } else if ([matches count]) {   //Update
        breakPeriod = [matches firstObject];
    } else {
        breakPeriod = [NSEntityDescription insertNewObjectForEntityForName:@"Break"
                                                    inManagedObjectContext:context];
    }
    NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterNoStyle];
    
    breakPeriod.starttime = [NSDate dateWithTimeIntervalSince1970:[[f numberFromString:breakDictionary[@"starttime"]] integerValue]];
    breakPeriod.endtime = [NSDate dateWithTimeIntervalSince1970:[[f numberFromString:breakDictionary[@"endtime"]] integerValue]];
    breakPeriod.modified = [NSDate dateWithTimeIntervalSince1970:[[f numberFromString:breakDictionary[@"modified"]] integerValue]];
    //breakPeriod.comment = breakDictionary[@"comment"];
    breakPeriod.breakid = [f numberFromString:breakDictionary[@"id"]];
    
    breakPeriod.parentework = [Work workWithUniqeId:[f numberFromString:breakDictionary[@"parent_id"]] inManagedObjectContext:context];
    
    return breakPeriod;
}
@end
