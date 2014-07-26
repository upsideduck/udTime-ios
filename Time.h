//
//  Time.h
//  udTime
//
//  Created by Johan Adell on 19/07/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Time : NSObject
+(NSString *)secondsToReadableTime:(NSNumber *)seconds;
@end
