//
//  WeekStatsCDTVC.h
//  udTime
//
//  Created by Johan Adell on 20/03/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import "CoreDataTableViewController.h"

@interface WeekStatsCDTVC : CoreDataTableViewController <UIActionSheetDelegate>
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@end
