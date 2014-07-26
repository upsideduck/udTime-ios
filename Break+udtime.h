//
//  Break+udtime.h
//  udTime
//
//  Created by Johan Adell on 30/03/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import "Break.h"

@interface Break (udtime)
+ (Break *)breakWithServerInfo:(NSDictionary *)workDictionary
      inManagedObjectContext:(NSManagedObjectContext *)context;

@end
