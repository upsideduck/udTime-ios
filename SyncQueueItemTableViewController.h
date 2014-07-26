//
//  SyncQueueItemTableViewController.h
//  udTime
//
//  Created by Johan Adell on 11/03/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SyncItem.h"

@protocol SyncQueueItemDelegate <NSObject>
@required
-(void)updateSyncQueueWithItem:(SyncItem *)syncItem AtIndex:(NSIndexPath *)indexPath;
@end

@interface SyncQueueItemTableViewController : UITableViewController <UIPickerViewDelegate, UIPickerViewDataSource>
@property (strong, nonatomic) SyncItem *syncItem;
@property (strong, nonatomic) NSIndexPath *syncQueueIndex;
@property (weak, nonatomic) id<SyncQueueItemDelegate> delegate;
@end
