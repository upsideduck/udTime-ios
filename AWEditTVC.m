//
//  AWEditTVC.m
//  udTime
//
//  Created by Johan Adell on 27/07/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import "AWEditTVC.h"
#import "Asworktime.h"
#import "Againstworktime.h"
#import "AFNetworking.h"
#import "udTimeServer.h"

@interface AWEditTVC ()
@property (strong, nonatomic) IBOutlet UITableViewCell *timeCell;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *saveButton;
@property (strong, nonatomic) IBOutlet UIDatePicker *timePicker;
@property (nonatomic) BOOL timePickerIsShowing;
@end

@implementation AWEditTVC

#define kTimePickerIndex 1
#define kPickerCellHeight 162

NSString *asworktime = @"asworktime";
NSString *againstworktime = @"againstworktime";

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.title = [self.awItem accessType];
    [self reloadStats];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [self.timePicker setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    [self.timePicker setDate:[NSDate dateWithTimeIntervalSince1970:[[self.awItem accessTime] doubleValue]]];
}

-(void)reloadStats{
    NSDateFormatter *dateTimeformatter = [[NSDateFormatter alloc] init];
    [dateTimeformatter setDateFormat:@"HH:mm:ss"];
    [dateTimeformatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    
    self.timeCell.detailTextLabel.text = [dateTimeformatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:[[self.awItem accessTime] doubleValue]]];
}

- (IBAction)delteAW:(UIButton *)sender{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = @{@"action": [NSString stringWithFormat:@"remove%@",self.type],
                                 @"itemid": [[self.awItem accessId] stringValue],
                                 @"username": [udTimeServer username],
                                 @"password": [udTimeServer password],
                                 @"output": @"json"};
    [manager GET:API_URL
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             //NSLog(@"%@", responseObject);
             if(![udTimeServer successOnResult:responseObject onAction:@"results.login"]) {
                 NSLog(@"Login error");
                 return;
             }else if(![udTimeServer successOnResult:responseObject onAction:[NSString stringWithFormat:@"results.remove%@",self.type]]) {
                 NSLog(@"Remove error");
                 return;
             }
             [self.managedObjectContext deleteObject:self.awItem];
             if (self.managedObjectContext) {
                 [udTimeServer synchronizeInternalDBWithServerOn:self.managedObjectContext];
             }
             [self.navigationController popViewControllerAnimated:YES];
             
         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             
             NSLog(@"Major failure");
         }];
}

- (IBAction)saveAW:(UIBarButtonItem *)sender{
    NSDateFormatter *dateTimeformatter = [[NSDateFormatter alloc] init];
    [dateTimeformatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSNumber *newTime = [NSNumber numberWithDouble:[self.timePicker.date timeIntervalSince1970]];

    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = @{@"action": [NSString stringWithFormat:@"update%@",self.type],
                                 @"id": [[self.awItem accessId] stringValue],
                                 @"time": [NSString stringWithFormat:@"%ld",(long)[newTime integerValue]],
                                 @"username": [udTimeServer username],
                                 @"password": [udTimeServer password],
                                 @"output": @"json"};
    [manager GET:API_URL
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             //NSLog(@"%@", responseObject);
             if(![udTimeServer successOnResult:responseObject onAction:@"results.login"]) {
                 NSLog(@"Login error");
                 return;
             }else if(![udTimeServer successOnResult:responseObject onAction:[NSString stringWithFormat:@"results.update%@",self.type]]) {
                 NSLog(@"Update error");
                 return;
             }
             
             //First do a manual update if eveything successfull then sync with server
             [self.awItem setAccessTime:newTime];
             if (self.managedObjectContext) {
                 [udTimeServer synchronizeInternalDBWithServerOn:self.managedObjectContext];
             }
             [self.navigationController popViewControllerAnimated:YES];
             
         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             
             NSLog(@"Major failure");
         }];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == (kTimePickerIndex - 1)){
        if (self.timePickerIsShowing){
            [self hidePickerCellAt:kTimePickerIndex];
        }else {
            [self showPickerCellAt:kTimePickerIndex];
        }
    /*    [self hidePickerCellAt:kEndtimePickerIndex];
    }else if (indexPath.row == (kEndtimePickerIndex - 1)){
        if (self.endtimePickerIsShowing){
            [self hidePickerCellAt:kEndtimePickerIndex];
        }else {
            [self showPickerCellAt:kEndtimePickerIndex];
        }
        [self hidePickerCellAt:kTimePickerIndex];
     */
    }
     
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)showPickerCellAt:(NSInteger)row {
    
    if(row == kTimePickerIndex) self.timePickerIsShowing = YES;
    //else if(row == kEndtimePickerIndex) self.endtimePickerIsShowing = YES;
    
    [self.tableView beginUpdates];
    
    [self.tableView endUpdates];
    
    UIPickerView *picker;
    if(row == kTimePickerIndex)
        picker = (UIPickerView *)self.timePicker;
    //else if(row == kEndtimePickerIndex)
    //    picker = (UIPickerView *)self.endtimePicker;
    
    picker.hidden = NO;
    picker.alpha = 0.0f;
    
    [UIView animateWithDuration:0.25 animations:^{
        picker.alpha = 1.0f;
    }];
}

- (void)hidePickerCellAt:(NSInteger)row{
    
    if(row == kTimePickerIndex) self.timePickerIsShowing = NO;
    //else if(row == kEndtimePickerIndex) self.endtimePickerIsShowing = NO;
    
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
    
    UIPickerView *picker;
    if(row == kTimePickerIndex)
        picker = (UIPickerView *)self.timePicker;
    //else if(row == kEndtimePickerIndex)
    //    picker = (UIPickerView *)self.endtimePicker;
    
    
    [UIView animateWithDuration:0.25
                     animations:^{
                         picker.alpha = 0.0f;
                     }
                     completion:^(BOOL finished){
                         picker.hidden = YES;
                     }];
}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CGFloat height = self.tableView.rowHeight;
    
    if (indexPath.row == kTimePickerIndex)
        height = self.timePickerIsShowing ? kPickerCellHeight : 0.0f;
    /*else if(indexPath.row == kEndtimePickerIndex){
        
        height = self.endtimePickerIsShowing ? kPickerCellHeight : 0.0f;
    }
    */
    return height;
}


- (IBAction)timePickerChanged:(UIDatePicker *)sender {
    NSDateFormatter *dateTimeformatter = [[NSDateFormatter alloc] init];
    [dateTimeformatter setDateFormat:@"HH:mm:ss"];
    [dateTimeformatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    
    self.timeCell.detailTextLabel.text = [dateTimeformatter stringFromDate:sender.date];
    
    NSNumber *newTime = [NSNumber numberWithDouble:[self.timePicker.date timeIntervalSince1970]];
    
    if ([newTime doubleValue] == [[self.awItem accessTime] doubleValue])
        self.saveButton.enabled = NO;
    else
        self.saveButton.enabled = YES;
    
}


@end
