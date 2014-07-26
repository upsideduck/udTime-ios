//
//  Month+udtime.h
//  udTime
//
//  Created by Johan Adell on 08/04/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import "Month.h"

@interface Month (udtime)
+ (Month *)monthWithServerInfo:(NSDictionary *)monthDictionary
      inManagedObjectContext:(NSManagedObjectContext *)context;


+ (Month *)monthOfYearForDate:(NSDate *)date
     inManagedObjectContext:(NSManagedObjectContext *)context;

@end
