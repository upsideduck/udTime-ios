//
//  Work+udTime.h
//  udTime
//
//  Created by Johan Adell on 30/03/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import "Work.h"

@interface Work (udTime)
+ (Work *)workWithServerInfo:(NSDictionary *)workDictionary
      inManagedObjectContext:(NSManagedObjectContext *)context;

+ (Work *)workWithUniqeId:(NSNumber *)uniqe
     inManagedObjectContext:(NSManagedObjectContext *)context;

@end
