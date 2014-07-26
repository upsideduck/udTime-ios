//
//  Break.h
//  udTime
//
//  Created by Johan Adell on 08/04/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Work;

@interface Break : NSManagedObject

@property (nonatomic, retain) NSNumber * breakid;
@property (nonatomic, retain) NSString * comment;
@property (nonatomic, retain) NSDate * endtime;
@property (nonatomic, retain) NSDate * modified;
@property (nonatomic, retain) NSDate * starttime;
@property (nonatomic, retain) Work *parentework;

@end
