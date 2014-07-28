//
//  Againstworktime+udtime.h
//  udTime
//
//  Created by Johan Adell on 30/03/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import "Againstworktime.h"
#import "AWProtocol.h"

@interface Againstworktime (udtime) <accessAsworkAndAgainstworkItems>
+ (Againstworktime *)againstworktimeWithServerInfo:(NSDictionary *)againstworktimeDictionary
                            inManagedObjectContext:(NSManagedObjectContext *)context;

@end
