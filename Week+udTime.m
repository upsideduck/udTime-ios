//
//  Week+udTime.m
//  
//
//  Created by Johan Adell on 24/03/14.
//
//

#import "Week+udTime.h"

@implementation Week (udTime)

+ (Week *)weekWithServerInfo:(NSDictionary *)weekDictionary
        inManagedObjectContext:(NSManagedObjectContext *)context
{
    Week *week = nil;
    
    //Maybe better to use week and year as identified?
    NSNumber *uWeek = [weekDictionary objectForKey:@"week"];
    NSNumber *uYear = [weekDictionary objectForKey:@"year"];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Week"];
    request.predicate = [NSPredicate predicateWithFormat:@"week==%lu AND year==%lu", [uWeek integerValue], [uYear integerValue]];
    
    NSError *error;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    //NSLog(@"%lu",[matches count]);
    if (!matches || error || ([matches count] > 1)) {
        // handle error
    } else if ([matches count]) {   //Update
        week = [matches firstObject];

        NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
        [f setNumberStyle:NSNumberFormatterNoStyle];
        
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        
        week.againstworktime = [f numberFromString:weekDictionary[@"againstworktime"]];
        week.asworktime = [f numberFromString:weekDictionary[@"asworktime"]];
        week.modified = [df dateFromString:weekDictionary[@"modified"]];
        week.towork = [f numberFromString:weekDictionary[@"towork"]];
        week.worked = [f numberFromString:weekDictionary[@"worked"]];
        week.totaldifftime = weekDictionary[@"totaldifftime"];
        week.weekdifftime = weekDictionary[@"weekdifftime"];
        week.workedtime = weekDictionary[@"workedtime"];
        week.modifiedtimestamp = weekDictionary[@"modifiedtimestamp"];
    } else {
        week = [NSEntityDescription insertNewObjectForEntityForName:@"Week"
                                             inManagedObjectContext:context];
        
        NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
        [f setNumberStyle:NSNumberFormatterNoStyle];
        
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        
        week.againstworktime = [f numberFromString:weekDictionary[@"againstworktime"]];
        week.asworktime = [f numberFromString:weekDictionary[@"asworktime"]];
        week.weekid = [f numberFromString:weekDictionary[@"id"]];
        week.modified = [df dateFromString:weekDictionary[@"modified"]];
        week.towork = [f numberFromString:weekDictionary[@"towork"]];
        week.week = [f numberFromString:weekDictionary[@"week"]];
        week.worked = [f numberFromString:weekDictionary[@"worked"]];
        week.year = [f numberFromString:weekDictionary[@"year"]];
        week.totaldifftime = weekDictionary[@"totaldifftime"];
        week.weekdifftime = weekDictionary[@"weekdifftime"];
        week.workedtime = weekDictionary[@"workedtime"];
        week.modifiedtimestamp = weekDictionary[@"modifiedtimestamp"];
    }
    
    //NSLog(@"%@", week);
    return week;
}

+ (Week *)weekOfYearForDate:(NSDate *)date
inManagedObjectContext:(NSManagedObjectContext *)context{
    Week *week = nil;

    // Specify which units we would like to use
    unsigned units = NSYearForWeekOfYearCalendarUnit | NSWeekOfYearCalendarUnit;
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    calendar.firstWeekday = 2;
    NSDateComponents *components = [calendar components:units fromDate:date];
    
    NSInteger yearNumber = [components yearForWeekOfYear];
    NSInteger weekNumber = [components weekOfYear];
    
    if(yearNumber > 1970 && weekNumber > 0){
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Week"];
        request.predicate = [NSPredicate predicateWithFormat:@"year == %lu AND week == %lu", yearNumber, weekNumber];
        
        NSError *error;
        NSArray *matches = [context executeFetchRequest:request error:&error];
        
        if (!matches || ([matches count] > 1)) {
            // handle error
        } else if (![matches count]) {
            week = [NSEntityDescription insertNewObjectForEntityForName:@"Week"
                                                 inManagedObjectContext:context];
            
            NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
            [f setNumberStyle:NSNumberFormatterNoStyle];
            
            NSDateFormatter *df = [[NSDateFormatter alloc] init];
            [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
            
            week.againstworktime = [f numberFromString:@"0"];
            week.asworktime = [f numberFromString:@"0"];
            week.weekid = [f numberFromString:@"0"];
            week.modified = [NSDate dateWithTimeIntervalSince1970:0];
            week.modifiedtimestamp = [f numberFromString:@"0"];
            week.towork = [f numberFromString:@"0"];
            week.week = [[NSNumber alloc] initWithInteger:weekNumber];
            week.worked = [f numberFromString:@"0"];
            week.year = [[NSNumber alloc] initWithInteger:yearNumber];
            week.totaldifftime = @"---";
            week.weekdifftime = @"---";
            week.workedtime = @"---";
        } else {
            week = [matches lastObject];
        }
    }
    
    return week;
}


@end
