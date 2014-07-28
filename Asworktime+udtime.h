//
//  Asworktime+udtime.h
//  udTime
//
//  Created by Johan Adell on 30/03/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import "Asworktime.h"
#import "AWProtocol.h"

@interface Asworktime (udtime) <accessAsworkAndAgainstworkItems>
+ (Asworktime *)asworktimeWithServerInfo:(NSDictionary *)asworktimeDictionary
                  inManagedObjectContext:(NSManagedObjectContext *)context;

@end
