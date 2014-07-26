//
//  User.h
//  udTime
//
//  Created by Johan Adell on 23/03/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface udTimeServer : NSObject
+(NSString *)password;
+(NSString *)username;

+(void)synchronizeInternalDBWithServerOn:(NSManagedObjectContext *)context;
+(BOOL)successOnResult:(id)responseObject onAction:(NSString *)action;

#if TARGET_IPHONE_SIMULATOR
#define API_URL @"http://localhost/~johanadell/time/api/call_api.php"
#else
#define API_URL  @"https://manu33.manufrog.com/~phindus/upsideduck/time/api/call_api.php"
#endif

@end
