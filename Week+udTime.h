//
//  Week+udTime.h
//  
//
//  Created by Johan Adell on 24/03/14.
//
//

#import "Week.h"

@interface Week (udTime)
+ (Week *)weekWithServerInfo:(NSDictionary *)weekDictionary
      inManagedObjectContext:(NSManagedObjectContext *)context;


+ (Week *)weekOfYearForDate:(NSDate *)date
     inManagedObjectContext:(NSManagedObjectContext *)context;

@end
