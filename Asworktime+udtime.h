//
//  Asworktime+udtime.h
//  udTime
//
//  Created by Johan Adell on 30/03/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import "Asworktime.h"

@interface Asworktime (udtime)
+ (Asworktime *)asworktimeWithServerInfo:(NSDictionary *)asworktimeDictionary
                  inManagedObjectContext:(NSManagedObjectContext *)context;

@end
