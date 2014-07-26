//
//  Month+udtime.m
//  udTime
//
//  Created by Johan Adell on 08/04/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import "Month+udtime.h"

@implementation Month (udtime)


+ (Month *)monthWithServerInfo:(NSDictionary *)monthDictionary
      inManagedObjectContext:(NSManagedObjectContext *)context
{
    Month *month = nil;
    
    //Maybe better to use week and year as identified?
    NSNumber *uMonth = [monthDictionary objectForKey:@"month"];
    NSNumber *uYear = [monthDictionary objectForKey:@"year"];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Month"];
    request.predicate = [NSPredicate predicateWithFormat:@"month==%lu AND year==%lu", [uMonth integerValue], [uYear integerValue]];
    
    NSError *error;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    //NSLog(@"%lu",[matches count]);
    if (!matches || error || ([matches count] > 1)) {
        // handle error
    } else if ([matches count]) {   //Update
        month = [matches firstObject];
        
        NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
        [f setNumberStyle:NSNumberFormatterNoStyle];
        
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        
        month.againstworktime = [f numberFromString:monthDictionary[@"againstworktime"]];
        month.asworktime = [f numberFromString:monthDictionary[@"asworktime"]];
        month.modified = [df dateFromString:monthDictionary[@"modified"]];
        month.towork = [f numberFromString:monthDictionary[@"towork"]];
        month.worked = [f numberFromString:monthDictionary[@"worked"]];
        month.totaldifftime = monthDictionary[@"totaldifftime"];
        month.monthdifftime = monthDictionary[@"monthdifftime"];
        month.workedtime = monthDictionary[@"workedtime"];
        month.modifiedtimestamp = monthDictionary[@"modifiedtimestamp"];
    } else {
        month = [NSEntityDescription insertNewObjectForEntityForName:@"Month"
                                             inManagedObjectContext:context];
        
        NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
        [f setNumberStyle:NSNumberFormatterNoStyle];
        
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        
        month.againstworktime = [f numberFromString:monthDictionary[@"againstworktime"]];
        month.asworktime = [f numberFromString:monthDictionary[@"asworktime"]];
        month.monthid = [f numberFromString:monthDictionary[@"id"]];
        month.modified = [df dateFromString:monthDictionary[@"modified"]];
        month.towork = [f numberFromString:monthDictionary[@"towork"]];
        month.month = [f numberFromString:monthDictionary[@"month"]];
        month.worked = [f numberFromString:monthDictionary[@"worked"]];
        month.year = [f numberFromString:monthDictionary[@"year"]];
        month.totaldifftime = monthDictionary[@"totaldifftime"];
        month.monthdifftime = monthDictionary[@"monthdifftime"];
        month.workedtime = monthDictionary[@"workedtime"];
        month.modifiedtimestamp = monthDictionary[@"modifiedtimestamp"];
    }
    
    //NSLog(@"%@", week);
    return month;
}

+ (Month *)monthOfYearForDate:(NSDate *)date
     inManagedObjectContext:(NSManagedObjectContext *)context{
    Month *month = nil;
    
    // Specify which units we would like to use
    unsigned units = NSYearCalendarUnit | NSMonthCalendarUnit;
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    calendar.firstWeekday = 2;
    NSDateComponents *components = [calendar components:units fromDate:date];
    
    NSInteger yearNumber = [components year];
    NSInteger monthNumber = [components month];
    
    if(yearNumber > 1970 && monthNumber > 0){
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Month"];
        request.predicate = [NSPredicate predicateWithFormat:@"year == %lu AND month == %lu", yearNumber, monthNumber];
        
        NSError *error;
        NSArray *matches = [context executeFetchRequest:request error:&error];
        
        if (!matches || ([matches count] > 1)) {
            // handle error
        } else if (![matches count]) {
            month = [NSEntityDescription insertNewObjectForEntityForName:@"Month"
                                                 inManagedObjectContext:context];
            
            NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
            [f setNumberStyle:NSNumberFormatterNoStyle];
            
            NSDateFormatter *df = [[NSDateFormatter alloc] init];
            [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
            
            month.againstworktime = [f numberFromString:@"0"];
            month.asworktime = [f numberFromString:@"0"];
            month.monthid = [f numberFromString:@"0"];
            month.modified = [NSDate dateWithTimeIntervalSince1970:0];
            month.modifiedtimestamp = [f numberFromString:@"0"];
            month.towork = [f numberFromString:@"0"];
            month.month = [[NSNumber alloc] initWithInteger:monthNumber];
            month.worked = [f numberFromString:@"0"];
            month.year = [[NSNumber alloc] initWithInteger:yearNumber];
            month.totaldifftime = @"---";
            month.monthdifftime = @"---";
            month.workedtime = @"---";
        } else {
            month = [matches lastObject];
        }
    }
    
    return month;
}


@end
