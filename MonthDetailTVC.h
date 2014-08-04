//
//  MonthDetailTVC.h
//  udTime
//
//  Created by Johan Adell on 10/04/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Month.h"


@interface MonthDetailTVC : UITableViewController <UIActionSheetDelegate>
@property (nonatomic, strong) Month *month;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@end
