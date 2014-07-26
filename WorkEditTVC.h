//
//  WorkEditTVC.h
//  udTime
//
//  Created by Johan Adell on 19/07/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Work.h"

@interface WorkEditTVC : UITableViewController
@property (nonatomic, strong) Work *work;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@end
