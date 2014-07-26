//
//  WeekDetailCDTVC.h
//  udTime
//
//  Created by Johan Adell on 31/03/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import "Week.h"

@interface WeekDetailTVC : UITableViewController
@property (nonatomic, strong) Week *week;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@end
