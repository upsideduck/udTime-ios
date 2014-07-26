//
//  SyncQueueItemTableViewController.m
//  udTime
//
//  Created by Johan Adell on 11/03/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import "SyncQueueItemTableViewController.h"

@interface SyncQueueItemTableViewController ()
@property (nonatomic) BOOL datePickerIsShowing;
@property (nonatomic) BOOL typePickerIsShowing;
@property (strong, nonatomic) IBOutlet UIPickerView *typePicker;
@property (strong, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (strong, nonatomic) IBOutlet UILabel *typeLabel;
@property (strong, nonatomic) IBOutlet UILabel *dateLabel;
@property (strong, nonatomic) NSArray *syncTypes;
@property (strong, nonatomic) NSDateFormatter *dateTimeFormatter;
@end

@implementation SyncQueueItemTableViewController


#define kTypePickerIndex 1
#define kDatePickerIndex 3
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
    
    self.typeLabel.text = [self.syncItem SyncTypeLabel];
    [self.typePicker selectRow:(self.syncItem.syncType - 1) inComponent:0 animated:YES];
    
    self.dateTimeFormatter = [[NSDateFormatter alloc] init];
    [self.dateTimeFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    NSDate *date = [[NSDate alloc] initWithTimeIntervalSince1970:self.syncItem.time];

    self.dateLabel.text = [NSString stringWithFormat:@"%@",[self.dateTimeFormatter stringFromDate:date]];
    [self.datePicker setDate:date];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)saveUpdates:(UIBarButtonItem *)sender {
    [self.delegate updateSyncQueueWithItem:self.syncItem AtIndex:self.syncQueueIndex];
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == (kDatePickerIndex - 1)){
        if (self.datePickerIsShowing){
            [self hidePickerCellAt:kDatePickerIndex];
        }else {
            [self showPickerCellAt:kDatePickerIndex];
        }
        [self hidePickerCellAt:kTypePickerIndex];
    }else if (indexPath.row == (kTypePickerIndex - 1)){
        if (self.typePickerIsShowing){
            [self hidePickerCellAt:kTypePickerIndex];
        }else {
            [self showPickerCellAt:kTypePickerIndex];
        }
        [self hidePickerCellAt:kDatePickerIndex];
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)showPickerCellAt:(NSInteger)row {
    
    if(row == kDatePickerIndex) self.datePickerIsShowing = YES;
    else if(row == kTypePickerIndex) self.typePickerIsShowing = YES;
    
    [self.tableView beginUpdates];
    
    [self.tableView endUpdates];
    
    UIPickerView *picker;
    if(row == kDatePickerIndex)
        picker = (UIPickerView *)self.datePicker;
    else if(row == kTypePickerIndex)
        picker = (UIPickerView *)self.typePicker;
    
    picker.hidden = NO;
    picker.alpha = 0.0f;
    
    [UIView animateWithDuration:0.25 animations:^{
       picker.alpha = 1.0f;
    }];
}

- (void)hidePickerCellAt:(NSInteger)row{
    
    if(row == kDatePickerIndex) self.datePickerIsShowing = NO;
    else if(row == kTypePickerIndex) self.typePickerIsShowing = NO;
    
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
    
    UIPickerView *picker;
    if(row == kDatePickerIndex)
        picker = (UIPickerView *)self.datePicker;
    else if(row == kTypePickerIndex)
        picker = (UIPickerView *)self.typePicker;

    
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
    
    if (indexPath.row == kDatePickerIndex){
        
        height = self.datePickerIsShowing ? kPickerCellHeight : 0.0f;
        
    }else if(indexPath.row == kTypePickerIndex){
        
        height = self.typePickerIsShowing ? kPickerCellHeight : 0.0f;
    }
    
    return height;
}

- (IBAction)datePickerChanged:(UIDatePicker *)sender {
    self.dateLabel.text = [NSString stringWithFormat:@"%@",[self.dateTimeFormatter stringFromDate:sender.date]];
    
    self.syncItem.time = [sender.date timeIntervalSince1970];
    
}


#pragma mark PickerView DataSource

- (NSInteger)numberOfComponentsInPickerView:
(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView
numberOfRowsInComponent:(NSInteger)component
{
    return [SyncItem syncTypesLabels].count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component
{
    return [SyncItem syncTypesLabels][row];
}

#pragma mark PickerView Delegate
-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row
      inComponent:(NSInteger)component
{
    self.syncItem.syncType = row+1;
    self.typeLabel.text = [self.syncItem SyncTypeLabel];
}

@end
