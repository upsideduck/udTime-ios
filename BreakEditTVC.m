//
//  BreakEditTVC.m
//  udTime
//
//  Created by Johan Adell on 19/07/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import "BreakEditTVC.h"
#import "AFNetworking.h"
#import "udTimeServer.h"

@interface BreakEditTVC ()
@property (strong, nonatomic) IBOutlet UITableViewCell *starttimeCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *endtimeCell;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *saveButton;
@property (strong, nonatomic) IBOutlet UIDatePicker *starttimePicker;
@property (strong, nonatomic) IBOutlet UIDatePicker *endtimePicker;
@property (nonatomic) BOOL starttimePickerIsShowing;
@property (nonatomic) BOOL endtimePickerIsShowing;
@end

@implementation BreakEditTVC

#define kStarttimePickerIndex 1
#define kEndtimePickerIndex 3
#define kPickerCellHeight 162

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [self.starttimePicker setDate:self.breakItem.starttime];
    [self.endtimePicker setDate:self.breakItem.endtime];
}

- (void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self reloadStats];
}


-(void)reloadStats{
    NSDateFormatter *dateTimeformatter = [[NSDateFormatter alloc] init];
    [dateTimeformatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    self.starttimeCell.detailTextLabel.text = [dateTimeformatter stringFromDate:self.breakItem.starttime];
    self.endtimeCell.detailTextLabel.text = [dateTimeformatter stringFromDate:self.breakItem.endtime];
    
}


- (IBAction)delteBreak:(UIButton *)sender{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = @{@"action": @"removebreak",
                                 @"id": [self.breakItem.breakid stringValue],
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
             }else if(![udTimeServer successOnResult:responseObject onAction:@"results.removebreak"]) {
                 NSLog(@"Remove error");
                 return;
             }
             [self.managedObjectContext deleteObject:self.breakItem];
             if (self.managedObjectContext) {
                 [udTimeServer synchronizeInternalDBWithServerOn:self.managedObjectContext];
             }
             [self.navigationController popViewControllerAnimated:YES];
            
         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
  
             NSLog(@"Major failure");
         }];
}



- (IBAction)saveBreak:(UIBarButtonItem *)sender{
    NSDateFormatter *dateTimeformatter = [[NSDateFormatter alloc] init];
    [dateTimeformatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *starttime = [dateTimeformatter dateFromString:self.starttimeCell.detailTextLabel.text];
    NSDate *endtime = [dateTimeformatter dateFromString:self.endtimeCell.detailTextLabel.text];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = @{@"action": @"updatebreak",
                                 @"id": [self.breakItem.breakid stringValue],
                                 @"start_time": [NSString stringWithFormat:@"%.f", [starttime timeIntervalSince1970]],
                                 @"end_time": [NSString stringWithFormat:@"%.f", [endtime timeIntervalSince1970]],
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
             }else if(![udTimeServer successOnResult:responseObject onAction:@"results.updatebreak"]) {
                 NSLog(@"Update error");
                 return;
             }
            
             //First do a manual update if eveything successfull then sync with server
             self.breakItem.starttime = starttime;
             self.breakItem.endtime = endtime;
             if (self.managedObjectContext) {
                 [udTimeServer synchronizeInternalDBWithServerOn:self.managedObjectContext];
             }
             [self.navigationController popViewControllerAnimated:YES];
             
         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             
             NSLog(@"Major failure");
         }];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == (kStarttimePickerIndex - 1)){
        if (self.starttimePickerIsShowing){
            [self hidePickerCellAt:kStarttimePickerIndex];
        }else {
            [self showPickerCellAt:kStarttimePickerIndex];
        }
        [self hidePickerCellAt:kEndtimePickerIndex];
    }else if (indexPath.row == (kEndtimePickerIndex - 1)){
        if (self.endtimePickerIsShowing){
            [self hidePickerCellAt:kEndtimePickerIndex];
        }else {
            [self showPickerCellAt:kEndtimePickerIndex];
        }
        [self hidePickerCellAt:kStarttimePickerIndex];
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)showPickerCellAt:(NSInteger)row {
    
    if(row == kStarttimePickerIndex) self.starttimePickerIsShowing = YES;
    else if(row == kEndtimePickerIndex) self.endtimePickerIsShowing = YES;
    
    [self.tableView beginUpdates];
    
    [self.tableView endUpdates];
    
    UIPickerView *picker;
    if(row == kStarttimePickerIndex)
        picker = (UIPickerView *)self.starttimePicker;
    else if(row == kEndtimePickerIndex)
        picker = (UIPickerView *)self.endtimePicker;
    
    picker.hidden = NO;
    picker.alpha = 0.0f;
    
    [UIView animateWithDuration:0.25 animations:^{
        picker.alpha = 1.0f;
    }];
}

- (void)hidePickerCellAt:(NSInteger)row{
    
    if(row == kStarttimePickerIndex) self.starttimePickerIsShowing = NO;
    else if(row == kEndtimePickerIndex) self.endtimePickerIsShowing = NO;
    
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
    
    UIPickerView *picker;
    if(row == kStarttimePickerIndex)
        picker = (UIPickerView *)self.starttimePicker;
    else if(row == kEndtimePickerIndex)
        picker = (UIPickerView *)self.endtimePicker;
    
    
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
    
    if (indexPath.row == kStarttimePickerIndex){
        
        height = self.starttimePickerIsShowing ? kPickerCellHeight : 0.0f;
        
    }else if(indexPath.row == kEndtimePickerIndex){
        
        height = self.endtimePickerIsShowing ? kPickerCellHeight : 0.0f;
    }
    
    return height;
}

- (IBAction)starttimePickerChanged:(UIDatePicker *)sender {
    NSDateFormatter *dateTimeformatter = [[NSDateFormatter alloc] init];
    [dateTimeformatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    self.starttimeCell.detailTextLabel.text = [dateTimeformatter stringFromDate:sender.date];
    
    if ([self.starttimePicker.date isEqualToDate:self.breakItem.starttime] && [self.endtimePicker.date isEqualToDate:self.breakItem.endtime]) self.saveButton.enabled = NO;
    else
        self.saveButton.enabled = YES;
    
}

- (IBAction)endttimePickerChanged:(UIDatePicker *)sender {
    NSDateFormatter *dateTimeformatter = [[NSDateFormatter alloc] init];
    [dateTimeformatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    self.endtimeCell.detailTextLabel.text = [dateTimeformatter stringFromDate:sender.date];
    
    if ([self.starttimePicker.date isEqualToDate:self.breakItem.starttime] && [self.endtimePicker.date isEqualToDate:self.breakItem.endtime]) self.saveButton.enabled = NO;
    else
        self.saveButton.enabled = YES;

    
}
@end
