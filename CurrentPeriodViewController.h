//
//  ViewController.h
//  udTime
//
//  Created by Johan Adell on 05/01/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CurrentPeriod.h"
#import "SyncItem.h"
#import "SyncQueueTableViewController.h"


@interface CurrentPeriodViewController : UIViewController <UIAlertViewDelegate,UITextFieldDelegate,EditSyncQueueDelegete>
@property (nonatomic, strong) CurrentPeriod *currentPeriod;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSMutableArray *syncQueue;
@property (nonatomic, strong) NSMutableArray *successfullySynced;
@property (nonatomic, strong) NSTimer *syncQueueTimer;

@end
