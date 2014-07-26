//
//  SyncQueueTableViewController.h
//  
//
//  Created by Johan Adell on 04/03/14.
//
//

#import <UIKit/UIKit.h>
#import "SyncQueueItemTableViewController.h"

@protocol EditSyncQueueDelegete <NSObject>
-(void)updateSyncQueueWithObject:(NSMutableArray *)queue;
@end

@interface SyncQueueTableViewController : UITableViewController <SyncQueueItemDelegate>
@property (weak, nonatomic) id <EditSyncQueueDelegete> delegete;
@property (strong, nonatomic) NSMutableArray *syncQueue;
@property (strong, nonatomic) NSMutableArray *successfullySynced;
@end
