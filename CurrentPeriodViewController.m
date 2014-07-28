//
//  ViewController.m
//  udTime
//
//  Created by Johan Adell on 05/01/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import "CurrentPeriodViewController.h"
#import "AFNetworking.h"
#import "AFNetworkActivityIndicatorManager.h"
#import <QuartzCore/QuartzCore.h>
#import "ErrorCodes.h"
#import "UICKeyChainStore.h"
#import "Reachability.h"
#import "udTimeServer.h"
#import "Time.h"

@interface CurrentPeriodViewController ()
@property (strong, nonatomic) IBOutlet UIButton *workButton;
@property (strong, nonatomic) IBOutlet UIButton *breakButton;
@property (strong, nonatomic) IBOutlet UILabel *currentTimer;
@property (strong, nonatomic) IBOutlet UILabel *status;
@property (strong, nonatomic) IBOutlet UILabel *syncStatusLabel;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *syncSpinner;
@property (strong, nonatomic) IBOutlet UILabel *statLabelToday;
@property (strong, nonatomic) IBOutlet UILabel *statLabelThisWeek;
@property (strong, nonatomic) IBOutlet UILabel *statLabelBalanceLastMonth;
@property (strong, nonatomic) IBOutlet UILabel *statLabelBalanceLastWeek;
@property (strong, nonatomic) IBOutlet UITextField *timestampPickerBox;
@property (strong, nonatomic) NSNumber *chosenTimestamp;
@property (strong, nonatomic) UITapGestureRecognizer *tapRecognizer;
@property (nonatomic) BOOL shouldRefreshAfterSync;

@end

@implementation CurrentPeriodViewController

#define BTN_ENABLED_ALPHA 1.0
#define BTN_DISABLED_ALPHA 0.3
#define START @"Start"
#define END @"Stop"
#define NOTIME @"0:00:00"
#define STATUS_FREE @"Free"
#define STATUS_WORKING @"Working"
#define STATUS_BREAK @"On Break"
#define THREE_DASHES @"---"

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.workButton.layer.cornerRadius = 3;
    self.workButton.layer.backgroundColor = [[UIColor colorWithRed:0 green:0.9 blue:0.1 alpha:1.0] CGColor];
    self.breakButton.layer.cornerRadius = 3;
    self.breakButton.layer.backgroundColor = [[UIColor colorWithRed:0 green:0.9 blue:0.1 alpha:1.0] CGColor];
    //KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"udTime2Keychain" accessGroup:nil];
    //§[keychain resetKeychainItem];
    if (![[udTimeServer username] length]) {
        NSLog(@"Should login");
        [self performSegueWithIdentifier: @"login" sender: self];
    }
    
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appHasGoneInBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    //Allocate timepicker
    UIDatePicker *dateAndTimePicker = [[UIDatePicker alloc]init];
    
    [dateAndTimePicker setDatePickerMode:UIDatePickerModeDateAndTime];
    [dateAndTimePicker setDate:[NSDate date]];
    [dateAndTimePicker addTarget:self action:@selector(updateTimestampPickerBox:) forControlEvents:UIControlEventValueChanged];
    [self.timestampPickerBox setInputView:dateAndTimePicker];
    self.timestampPickerBox.delegate = self;
    
    //Initiate tap recognizer that removes time picker
    self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removeDateAndTimePicker:)];
    self.tapRecognizer.numberOfTapsRequired = 1;
    
    
}

- (void)textFieldDidBeginEditing:(UITextField *)textField{
    //When textfield starts to edit prepare recongizer to remove picker on tap outside
    [self.view addGestureRecognizer:self.tapRecognizer];
    UIDatePicker *picker = (UIDatePicker*)self.timestampPickerBox.inputView;
    [picker setDate:[NSDate date]];
}



-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self loadAppState];
    
    if([self.currentPeriod periodType] == BREAK || [self.currentPeriod periodType] == WORK || [self.syncQueue count] > 0){
        NSLog(@"Active/not synced period in app");
    }else{
        [self syncronizeToServer];
    }

    
}

-(void)viewWillDisappear:(BOOL)animated{
    [self saveAppState];
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopSyncQueueTimer];
    [self.timer invalidate];
    self.timer = nil;
    
    
}

-(void)appHasGoneInBackground{
    [self saveAppState];
    [self stopSyncQueueTimer];
}

-(void)appWillEnterForeground{
    [self loadAppState];
    
    if([self.currentPeriod periodType] == BREAK || [self.currentPeriod periodType] == WORK || [self.syncQueue count] > 0){
        NSLog(@"Active/not synced period in app");
    }else{
        [self syncronizeToServer];
    }

}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Make sure your segue name in storyboard is the same as this line
    if ([[segue identifier] isEqualToString:@"syncQueueSegue"])
    {
        [self stopSyncQueueTimer];
        
        // Get reference to the destination view controller
        SyncQueueTableViewController *sqtvc = [segue destinationViewController];
        
        // Pass any objects to the view controller here, like...
        sqtvc.delegete = self;
        sqtvc.syncQueue = self.syncQueue;
        sqtvc.successfullySynced = self.successfullySynced;
    
    }
}

#pragma mark Setters and getters
-(CurrentPeriod *)currentPeriod{
    if (!_currentPeriod) _currentPeriod = [[CurrentPeriod alloc] init];
    return _currentPeriod;
}

-(NSMutableArray *)syncQueue{
    if (!_syncQueue) _syncQueue = [[NSMutableArray alloc] init];
    return _syncQueue;
}

-(NSMutableArray *)successfullySynced{
    if (!_successfullySynced) _successfullySynced = [[NSMutableArray alloc] init];
    return _successfullySynced;
}

-(void)setTimer:(NSTimer *)timer
{
    if([_timer isValid]){
        [_timer invalidate];
        _timer =nil;
    }
    _timer = timer;
}

-(void)setChosenTimestamp:(NSNumber *)chosenTimestamp{
    _chosenTimestamp = chosenTimestamp;

    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[chosenTimestamp integerValue]];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:00"];
    if(chosenTimestamp) self.timestampPickerBox.text = [NSString stringWithFormat:@"%@",[dateFormatter stringFromDate:date]];
    else {
        self.timestampPickerBox.text = nil;
        [self.timestampPickerBox resignFirstResponder];
        [self removeDateAndTimePicker:self.tapRecognizer];
    }
    
}

-(BOOL)shouldRefreshAfterSync{
    if(!_shouldRefreshAfterSync) _shouldRefreshAfterSync = NO;
    return _shouldRefreshAfterSync;
}

#pragma mark UI interaction
- (IBAction)optionsButton:(UIBarButtonItem *)sender {
    
    self.chosenTimestamp = nil;     //Remove eventual value
    UIAlertView *alert;
    if([self.syncQueue count] > 0){
        alert = [[UIAlertView alloc] initWithTitle:@"Options"
                                           message:@"Sync updates, edit current period or refresh from server. "
                                          delegate:self
                                 cancelButtonTitle:@"Cancel"
                                 otherButtonTitles:@"Start synchronizaion",@"Current period",@"Refresh",nil];
        alert.tag = WRN_SYNC;
    } else {
        alert = [[UIAlertView alloc] initWithTitle:@"Refresh"
                                           message:@"Refresh from server or edit current period."
                                          delegate:self
                                 cancelButtonTitle:@"Cancel"
                                 otherButtonTitles:@"Current period",@"Refresh",nil];
        alert.tag = WRN_REFRESH;
    }
    [alert show];
}


- (IBAction)workButton:(UIButton *)sender {
    NSInteger timestamp;
    if(!self.chosenTimestamp){
        NSTimeInterval currentTimestampInterval = [[NSDate date] timeIntervalSince1970];
        timestamp = (NSInteger)currentTimestampInterval;
    }else{
        timestamp = [self.chosenTimestamp integerValue];
        self.chosenTimestamp = nil;
    }
    
    if([self.currentPeriod periodType] == WORK || [self.currentPeriod periodType] == BREAK )
    {
        if([self.currentPeriod periodType] == BREAK)
        {
            //End break if active
            Period *endBreak = [self.currentPeriod endBreakWithTimestamp:timestamp];
            [self addItemToSyncQueueWithTime:endBreak.endtime ofType:SYNC_ENDBREAK];
        }
        
        //End work
        Period *endWork = [self.currentPeriod endWorkWithTimestamp:timestamp];
        [self addItemToSyncQueueWithTime:endWork.endtime ofType:SYNC_ENDWORK];
        [self.currentPeriod clearPeriod];
        
    }else if ([self.currentPeriod periodType] == FREE){
        //Start work if not working
        Period *newWork = [self.currentPeriod startWorkWithTimestamp:timestamp];
        [self addItemToSyncQueueWithTime:newWork.starttime ofType:SYNC_STARTWORK];

    }
    [self updateUItoCurrentPeriod];
}
- (IBAction)breakButton:(UIButton *)sender {
    NSInteger timestamp;
    if(!self.chosenTimestamp){
        NSTimeInterval currentTimestampInterval = [[NSDate date] timeIntervalSince1970];
        timestamp = (NSInteger)currentTimestampInterval;
    }else{
        timestamp = [self.chosenTimestamp integerValue];
        self.chosenTimestamp = nil;
    }
    
    if([self.currentPeriod periodType] == WORK )
    {
        //Start break
        Period *newBreak = [self.currentPeriod startBreakWithTimestamp:timestamp];
        [self addItemToSyncQueueWithTime:newBreak.starttime ofType:SYNC_STARTBREAK];
    }else if ([self.currentPeriod periodType] == BREAK){
        //End break
        Period *endBreak = [self.currentPeriod endBreakWithTimestamp:timestamp];
        [self addItemToSyncQueueWithTime:endBreak.endtime ofType:SYNC_ENDBREAK];
    }
    [self updateUItoCurrentPeriod];
}

-(void)disableControls:(BOOL)disable{
    if(!disable){
        [self updateUItoCurrentPeriod];
    }else{
        self.workButton.enabled = NO;
        self.workButton.alpha = BTN_DISABLED_ALPHA;
        self.breakButton.enabled = NO;
        self.breakButton.alpha = BTN_DISABLED_ALPHA;
    }
        
}

-(void)updateUItoCurrentPeriod{
    if(self.currentPeriod.periodType == BREAK){
        self.workButton.layer.backgroundColor = [[UIColor colorWithRed:1
                                                                 green:0
                                                                  blue:0
                                                                 alpha:1.0]
                                                 CGColor];
        self.workButton.alpha = BTN_ENABLED_ALPHA;
        [self.workButton setTitle:END forState:UIControlStateNormal];
        self.workButton.enabled = YES;
        self.breakButton.layer.backgroundColor = [[UIColor colorWithRed:1
                                                                  green:0
                                                                   blue:0
                                                                  alpha:1.0]
                                                  CGColor];
        self.breakButton.alpha = BTN_ENABLED_ALPHA;
        [self.breakButton setTitle:END forState:UIControlStateNormal];
        self.breakButton.enabled = YES;
        [self.timer invalidate];
         NSDictionary *userinfo = @{ @"starttime" : [[NSNumber alloc] initWithInteger:self.currentPeriod.secondaryStarttime],
                                     @"totalbreaktime" :[[NSNumber alloc] initWithInteger:0]};
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                      target:self
                                                    selector:@selector(timerHandler:)
                                                    userInfo:userinfo
                                                    repeats:YES];
        [self.timer fire];      //Fire now
        self.status.text = STATUS_BREAK;
    }else if (self.currentPeriod.periodType == WORK){
        self.workButton.layer.backgroundColor = [[UIColor colorWithRed:1
                                                                 green:0
                                                                  blue:0
                                                                 alpha:1.0] CGColor];
        self.workButton.alpha = BTN_ENABLED_ALPHA;
        [self.workButton setTitle:END forState:UIControlStateNormal];
        self.workButton.enabled = YES;
        self.breakButton.layer.backgroundColor = [[UIColor colorWithRed:0
                                                                  green:0.9
                                                                   blue:0.1
                                                                  alpha:1.0] CGColor];
        self.breakButton.alpha = BTN_ENABLED_ALPHA;
        [self.breakButton setTitle:START forState:UIControlStateNormal];
        self.breakButton.enabled = YES;
        [self.timer invalidate];
    
        NSDictionary *userinfo = @{ @"starttime" : [[NSNumber alloc] initWithInteger:self.currentPeriod.starttime],
                                    @"totalbreaktime" :[[NSNumber alloc] initWithInteger:[self.currentPeriod totalBreakSeconds]]};
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                      target:self
                                                    selector:@selector(timerHandler:)
                                                    userInfo:userinfo
                                                     repeats:YES];
        [self.timer fire];      //Fire now
        self.status.text = STATUS_WORKING;
    }else{
        self.workButton.layer.backgroundColor = [[UIColor colorWithRed:0
                                                                 green:0.9
                                                                  blue:0.1
                                                                 alpha:1.0]
                                                 CGColor];
        self.workButton.alpha = BTN_ENABLED_ALPHA;
        [self.workButton setTitle:START forState:UIControlStateNormal];
        self.workButton.enabled = YES;
        self.breakButton.layer.backgroundColor = [[UIColor colorWithRed:0
                                                                  green:0.9
                                                                   blue:0.1
                                                                  alpha:1.0]
                                                  CGColor];
        self.breakButton.alpha = BTN_DISABLED_ALPHA;
        [self.breakButton setTitle:START forState:UIControlStateNormal];
        self.breakButton.enabled = NO;
        self.currentTimer.text = NOTIME;
        [self.timer invalidate];
        self.status.text = STATUS_FREE;
        
    }
    NSLog(@"%@", self.syncQueue);
}

-(void)timerHandler:(NSTimer *)timer {
    NSTimeInterval currentTimestamp = [[NSDate date] timeIntervalSince1970];
    int counterTimestamp = currentTimestamp - [[[timer userInfo] objectForKey:@"starttime"] integerValue] - [[[timer userInfo] objectForKey:@"totalbreaktime"] integerValue];
    
    self.currentTimer.text = [Time secondsToReadableTime:[[NSNumber alloc] initWithInt:counterTimestamp]];
    //NSLog(@"%d", [[[timer userInfo] objectForKey:@"totalbreaktime"] integerValue]);
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    switch(alertView.tag){
        case WRN_SYNC:
            if(buttonIndex == 1){
                [self verifyAndGoNextInSynchQueue];
            }else if (buttonIndex == 2){
                if([[AFNetworkActivityIndicatorManager sharedManager] isNetworkActivityIndicatorVisible]){
                    [self errorRaisedWithCode:ERR_BUSY];
                }else{
                    [self performSegueWithIdentifier:@"syncQueueSegue" sender:self];
                }
            }else if (buttonIndex == 3){
                [self syncronizeToServer];
            }
            break;
        case WRN_REFRESH:
            if(buttonIndex == 1){
                [self performSegueWithIdentifier:@"syncQueueSegue" sender:self];
            }
            else if(buttonIndex == 2){
                [self syncronizeToServer];
            }
            break;
        case ERR_START_WORK:
            if(buttonIndex == 1){
                [self performSegueWithIdentifier:@"syncQueueSegue" sender:self];
            }
            break;
        case ERR_END_WORK:
            if(buttonIndex == 1){
                [self performSegueWithIdentifier:@"syncQueueSegue" sender:self];
            }
            break;
        case ERR_START_BREAK:
            if(buttonIndex == 1){
                [self performSegueWithIdentifier:@"syncQueueSegue" sender:self];
            }
            break;
        case ERR_END_BREAK:
            if(buttonIndex == 1){
                [self performSegueWithIdentifier:@"syncQueueSegue" sender:self];
            }
            break;
        case ERR_COULD_NOT_SYNC:
            if(buttonIndex == 1){
                [self performSegueWithIdentifier:@"syncQueueSegue" sender:self];
            }
            break;
        case ERR_NOT_IN_SYNC:
            if(buttonIndex == 1){
                [self syncronizeToServer];
            }
            break;
        default:
            break;
    }
}

- (void)fadeOut:(UILabel *)label withText:(NSString *)text{
    label.text = text;
    [UIView animateWithDuration:0.5
                          delay:3.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         label.alpha = 0.0;
                     }
                     completion:^ (BOOL finished) {
                         label.text = nil;
                         //Speceial case, show sync queue again if label is syncstatuslabel
                         if([self.syncQueue count] > 0 && [label isEqual:self.syncStatusLabel]) self.syncStatusLabel.text = [NSString stringWithFormat:@"- %lu to sync", (long)[self.syncQueue count]];
                         label.alpha = 1;
                     }
     ];
}

-(void)updateTimestampPickerBox:(id)sender
{
    UIDatePicker *picker = (UIDatePicker*)self.timestampPickerBox.inputView;   
    self.chosenTimestamp = [NSNumber numberWithInteger:[picker.date timeIntervalSince1970]];
}

- (void)removeDateAndTimePicker:(UIGestureRecognizer *)gestureRecognizer {
    NSLog(@"Remove time picker");
    [self.timestampPickerBox resignFirstResponder];
    [self.view removeGestureRecognizer:gestureRecognizer];
}

#pragma mark Manipulate current period
-(void)updateCurrentPeriodWithServerValues:(NSDictionary *)currentPeriodFromServer{
    [self.currentPeriod clearPeriod];           // first one have to check for conficts
    for (NSString* key in currentPeriodFromServer) {
        NSDictionary *period = [currentPeriodFromServer objectForKey:key];
       // NSLog(@"%@",period);
        if ([[period valueForKeyPath:@"type"] isEqualToString:@"work"]) {
            self.currentPeriod.starttime = [(NSString *)[period valueForKeyPath:@"starttime"] integerValue];
            self.currentPeriod.dbId = [(NSString *)[period valueForKeyPath:@"id"] integerValue];
            self.currentPeriod.modified = [(NSString *)[period valueForKeyPath:@"modified"] integerValue];
        }else if ([[period valueForKeyPath:@"type"] isEqualToString:@"break"]){
            if([[period valueForKeyPath:@"endtime"] isKindOfClass:[NSNull class]]){
                self.currentPeriod.secondaryStarttime = [(NSString *)[period valueForKeyPath:@"starttime"] integerValue];
                self.currentPeriod.secondaryDbId = [(NSString *)[period valueForKeyPath:@"id"] integerValue];
                self.currentPeriod.secondaryModified = [(NSString *)[period valueForKeyPath:@"modified"] integerValue];
            }else{
                Period *breakPeriod = [[Period alloc] init];
                breakPeriod.starttime = [(NSString *)[period valueForKeyPath:@"starttime"] integerValue];
                if(![[period valueForKeyPath:@"endtime"] isKindOfClass:[NSNull class]]) breakPeriod.endtime = [(NSString *)[period valueForKeyPath:@"endtime"] integerValue];
                breakPeriod.dbId = [(NSString *)[period valueForKeyPath:@"id"] integerValue];
                breakPeriod.modified = [(NSString *)[period valueForKeyPath:@"modified"] integerValue];
                [self.currentPeriod.finishedBreaks addObject:breakPeriod];
            }
            
        }
        
    }
    //Save appstate when refreshing from server
    [self saveAppState];
    [self updateUItoCurrentPeriod];
    
}

-(void)updateSuccessfullSyncItemsQueue:(NSDictionary *)currentPeriodFromServer{
    self.successfullySynced = nil;
    NSMutableArray *syncItemsArray = [[NSMutableArray alloc] init];
    for (NSString* key in currentPeriodFromServer) {
        NSDictionary *period = [currentPeriodFromServer objectForKey:key];
             // NSLog(@"%@",period);
        if ([[period valueForKeyPath:@"type"] isEqualToString:@"work"]) {
            SyncItem *syncItem = [[SyncItem alloc] initWithSyncType:SYNC_STARTWORK
                                                  andTime:[(NSString *)[period valueForKeyPath:@"starttime"] integerValue]];
            [syncItemsArray addObject:syncItem];
        }else if ([[period valueForKeyPath:@"type"] isEqualToString:@"break"]){
            if([[period valueForKeyPath:@"endtime"] isKindOfClass:[NSNull class]]){
                SyncItem *syncItem = [[SyncItem alloc] initWithSyncType:SYNC_STARTBREAK
                                                                andTime:[(NSString *)[period valueForKeyPath:@"starttime"] integerValue]];
                [syncItemsArray addObject:syncItem];
            }else{
                SyncItem *syncItem = [[SyncItem alloc] initWithSyncType:SYNC_STARTBREAK
                                                                andTime:[(NSString *)[period valueForKeyPath:@"starttime"] integerValue]];
                [syncItemsArray addObject:syncItem];
                if(![[period valueForKeyPath:@"endtime"] isKindOfClass:[NSNull class]]){
                    SyncItem *syncItem = [[SyncItem alloc] initWithSyncType:SYNC_ENDBREAK
                                                                    andTime:[(NSString *)[period valueForKeyPath:@"endtime"] integerValue]];
                    [syncItemsArray addObject:syncItem];
                }
            }
            
        }
        
    }
    NSSortDescriptor *descriptorTime = [[NSSortDescriptor alloc] initWithKey:@"time"  ascending:YES];
    NSSortDescriptor *descriptorType = [[NSSortDescriptor alloc] initWithKey:@"syncType"  ascending:YES];
    
    self.successfullySynced = [[syncItemsArray sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptorTime, descriptorType,nil]] mutableCopy];
 
    
}


-(void)updateStatisticsWithServerValues:(NSDictionary *)statistics{
    
    if ([[statistics objectForKey:@"thisweek"] isKindOfClass:[NSDictionary class]]){
        NSDictionary *thisWeekStatisticsDictionary = (NSDictionary *)[statistics objectForKey:@"thisweek"];
        self.statLabelThisWeek.text = [Time secondsToReadableTime:[thisWeekStatisticsDictionary objectForKey:@"worktime"]];
    }
    if ([[statistics objectForKey:@"today"] isKindOfClass:[NSDictionary class]]){
        NSDictionary *todayStatisticsDictionary = (NSDictionary *)[statistics objectForKey:@"today"];
        self.statLabelToday.text = [Time secondsToReadableTime:[todayStatisticsDictionary objectForKey:@"worktime"]];
    }
    if ([[statistics objectForKey:@"weekbalance"] isKindOfClass:[NSDictionary class]]){
        NSDictionary *weekBalanceStatisticsDictionary = (NSDictionary *)[statistics objectForKey:@"weekbalance"];
        self.statLabelBalanceLastWeek.text = (NSString *)[weekBalanceStatisticsDictionary objectForKey:@"totaldifftime"];
    }
    if ([[statistics objectForKey:@"monthbalance"] isKindOfClass:[NSDictionary class]]){
        NSDictionary *monthBalanceStatisticsDictionary = (NSDictionary *)[statistics objectForKey:@"monthbalance"];
        self.statLabelBalanceLastMonth.text = (NSString *)[monthBalanceStatisticsDictionary objectForKey:@"totaldifftime"];
    }
    
}

- (void)syncronizeToServer {
    if (![udTimeServer username]) return;
    [self disableControls:YES];
    self.syncStatusLabel.text = @"- Refreshing";
    [self.syncSpinner startAnimating];  
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = @{@"action": @"currentperiod2,statistics",
                                 @"username": [udTimeServer username],
                                 @"password": [udTimeServer password],
                                 @"stattype": @"today,thisweek,weekbalance,monthbalance",
                                 @"statyearforweekofyear": [[[self lastWeek] objectForKey:@"yearForWeekOfYear"] stringValue],
                                 @"statweek": [[[self lastWeek] objectForKey:@"week"] stringValue],
                                 @"statyear": [[[self lastMonth] objectForKey:@"year"] stringValue],
                                 @"statmonth": [[[self lastMonth] objectForKey:@"month"] stringValue],
                                 @"output": @"json"};
    [manager GET:API_URL
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             
             //NSLog(@"JSON: %@", responseObject);
             self.shouldRefreshAfterSync = NO;
             NSNumber *lastModified = (NSNumber *)[responseObject valueForKeyPath:@"arrays.info.lastmodified"];
             [self setLatestSyncedPeriodTimestamp:[lastModified integerValue]];
             id currentPeriodFromServer = [responseObject valueForKeyPath:@"arrays.current"];
             if ([currentPeriodFromServer isKindOfClass:[NSDictionary class]]){
                 [self updateCurrentPeriodWithServerValues:(NSDictionary *)currentPeriodFromServer];
                 [self updateSuccessfullSyncItemsQueue:(NSDictionary *)currentPeriodFromServer];
                 //[self clearSyncQueue];
             }else if (![udTimeServer successOnResult:responseObject onAction:@"results.currentperiod"] && [udTimeServer successOnResult:responseObject onAction:@"results.login"]){
                 //[self clearSyncQueue];
                 [self.currentPeriod clearPeriod];
                 [self saveAppState];
                 [self updateUItoCurrentPeriod];
             }else{          // wrong!!!!!!!!!!!!!
                 [self errorRaisedWithCode:ERR_COULD_NOT_SYNC];
             }
             if([udTimeServer successOnResult:responseObject onAction:@"results.statistics"]){
                 id statistics = [responseObject valueForKeyPath:@"arrays.stats"];
                 if ([statistics isKindOfClass:[NSDictionary class]]){
                     [self updateStatisticsWithServerValues:(NSDictionary *)statistics];
                 }
             }
             [self fadeOut:self.syncStatusLabel withText:@"- Refresh successful"];
             
             [self.syncSpinner stopAnimating];
             [self disableControls:NO];
         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             [self fadeOut:self.syncStatusLabel withText:@"- Refresh unsuccessful"];
             [self errorRaisedWithCode:ERR_NO_CONNECTION];
             NSLog(@"Error: %@", error);
             [self.syncSpinner stopAnimating];
             [self disableControls:NO];
         }];
}


#pragma mark Sync queue
-(void)setLatestSyncedPeriodTimestamp:(NSInteger)timestamp{
    [[NSUserDefaults standardUserDefaults] setInteger:timestamp forKey:@"latestSyncedPeriodTimestamp"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSInteger)latestSyncedPeriodTimestamp{
    return [[NSUserDefaults standardUserDefaults] integerForKey:@"latestSyncedPeriodTimestamp"];
}

-(void)addItemToSyncQueueWithTime:(NSInteger)time ofType:(NSInteger)type{
    [self.syncQueue addObject:[[SyncItem alloc] initWithSyncType:type andTime:time]];
    self.syncStatusLabel.text = [NSString stringWithFormat:@"- %lu to sync", (long)[self.syncQueue count]];
    //self.syncStatusLabel.hidden = NO;
    
    //First stop sync queue timer if active so we dont tries to start queue twice
    [self stopSyncQueueTimer];
    self.syncQueueTimer = [NSTimer scheduledTimerWithTimeInterval:2.0f
                                                           target:self
                                                         selector:@selector(verifyAndGoNextInSynchQueue)
                                                         userInfo:nil
                                                          repeats:NO];
    [self saveAppState];
}



/*-(void)removeFirstFromSyncQueue{
    [self.syncQueue removeObjectAtIndex:0];
    self.syncStatusLabel.text = [NSString stringWithFormat:@"- %lu to sync", (long)[self.syncQueue count]];
    if([self.syncQueue count] == 0) {
        if(self.shouldRefreshAfterSync) [self syncronizeToServer];
        else [self fadeOut:self.syncStatusLabel withText:@"- Sync successfull"];
    }
}*/

-(BOOL)removeFromSyncQueue:(SyncItem *)item{
    NSUInteger index = [self.syncQueue indexOfObject:item];
    if(index <= [self.syncQueue count]){
        [self.syncQueue removeObjectAtIndex:index];
        self.syncStatusLabel.text = [NSString stringWithFormat:@"- %lu to sync", (long)[self.syncQueue count]];
        if([self.syncQueue count] == 0) {
            if(self.shouldRefreshAfterSync) [self syncronizeToServer];
            else [self fadeOut:self.syncStatusLabel withText:@"- Sync successfull"];
        }
        return YES;
    }else{
        return NO;
    }
    [self saveAppState];
}

-(void)updateSyncQueueWithObject:(NSMutableArray *)queue{
    [self clearSyncQueue];
    self.syncQueue = queue;
    self.shouldRefreshAfterSync = YES;
    [self saveAppState];
    if([self.syncQueue count] == 0)
        self.syncStatusLabel.text = @"";
    else
        self.syncStatusLabel.text = [NSString stringWithFormat:@"- %lu to sync", (long)[self.syncQueue count]];
}

-(void)clearSyncQueue{
    self.syncQueue = nil;
    if([self.syncQueue count] == 0){
        //self.syncStatusLabel.hidden = YES;
        self.syncStatusLabel.text = nil;
    }
    [self saveAppState];
}

-(void)stopSyncQueueTimer{
    if (self.syncQueueTimer != nil)
    {
        [self.syncQueueTimer invalidate];
        self.syncQueueTimer = nil;
    }
}

-(void)verifyAndGoNextInSynchQueue{
    
#if !TARGET_IPHONE_SIMULATOR
    Reachability* reach = [Reachability reachabilityForInternetConnection];
    if([reach currentReachabilityStatus] == NotReachable){
        NSLog(@"No internet");
        return;
    }
#endif
    
    [self.syncSpinner startAnimating];
    if(self.syncQueue.count < 1) {
        [self.syncSpinner stopAnimating];
        return;
    }     //Exit if queue empty
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = @{@"action": @"currentperiod2",
                                 @"username": [udTimeServer username],
                                 @"password": [udTimeServer password],
                                 @"output": @"json"};

    SyncItem *item = [self.syncQueue objectAtIndex:0];
    if (item.syncType == SYNC_STARTWORK){
        [manager GET:API_URL
          parameters:parameters
             success:^(AFHTTPRequestOperation *operation, id responseObject) {
                 //NSLog(@"%@", responseObject);
                 if(![udTimeServer successOnResult:responseObject onAction:@"results.login"]) {
                     [self errorRaisedWithCode:ERR_NOT_LOGGED_IN];
                     return;
                 }
                 
                 id currentPeriodResult = [responseObject valueForKeyPath:@"results.currentperiod"];
                 if([currentPeriodResult[0] isEqualToNumber:[[NSNumber alloc] initWithInteger:0]]) {
                     NSLog(@"Verification OK, start sync");
                     [self nextInSynchQueue];
                 }
                 else {
                     NSLog(@"Period already active, please refresh from server");
                     [self errorRaisedWithCode:ERR_NOT_IN_SYNC];
                 }
             } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                 NSLog(@"Error: %@", error);
                 [self errorRaisedWithCode:ERR_NO_CONNECTION];
             }];
    }else if (item.syncType == SYNC_ENDWORK || item.syncType == SYNC_STARTBREAK || item.syncType == SYNC_ENDBREAK){
        [manager GET:API_URL
          parameters:parameters
             success:^(AFHTTPRequestOperation *operation, id responseObject) {
                 if(![udTimeServer successOnResult:responseObject onAction:@"results.login"]) {
                     [self errorRaisedWithCode:ERR_NOT_LOGGED_IN];
                     return;
                 }
                 NSNumber *lastModifiedServer = (NSNumber *)[responseObject valueForKeyPath:@"arrays.info.lastmodified"];
                 if([lastModifiedServer isEqualToNumber:[[NSNumber alloc] initWithInteger:[self latestSyncedPeriodTimestamp]]]){
                     NSLog(@"Verification OK, start sync");
                     [self nextInSynchQueue];
                 } else {
                     NSLog(@"Verification did not verify");
                     [self errorRaisedWithCode:ERR_NOT_IN_SYNC];
                 }
             } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                 NSLog(@"Error: %@", error);
                 [self errorRaisedWithCode:ERR_NO_CONNECTION];
             }];
    }
}

-(void)nextInSynchQueue{
    [self.syncSpinner startAnimating];
    if(self.syncQueue.count < 1) {
        [self.syncSpinner stopAnimating];
        return;
    }     //Exit if queue empty
    
    SyncItem *item = [self.syncQueue objectAtIndex:0];
    if (item.syncType == SYNC_STARTWORK){
        [self syncStartWork:item];
    }else if (item.syncType == SYNC_ENDWORK){
        [self syncEndWork:item];
    }else if (item.syncType == SYNC_STARTBREAK){
        [self syncStartBreak:item];
    }else if (item.syncType == SYNC_ENDBREAK){
        [self syncEndBreak:item];
    }
            
    
}

-(void)syncStartWork:(SyncItem *)syncItem{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = @{@"action": @"newperiod",
                                 @"username": [udTimeServer username],
                                 @"password": [udTimeServer password],
                                 @"type":@"work",
                                 @"timestamp": [[NSNumber alloc] initWithInteger:syncItem.time],
                                 @"output": @"json"};
    [manager POST:API_URL
       parameters:parameters
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              //NSLog(@"%@", responseObject);
              if(![udTimeServer successOnResult:responseObject onAction:@"results.login"]) {
                  [self errorRaisedWithCode:ERR_NOT_LOGGED_IN];
                  return;
              }
              if([udTimeServer successOnResult:responseObject onAction:@"results.newperiod"]) {
                  NSNumber *lastmodified = (NSNumber *)[responseObject valueForKeyPath:@"arrays.info.lastmodified"];
                  [self setLatestSyncedPeriodTimestamp:[lastmodified integerValue]];
                  
                  id currentPeriodFromServer = [responseObject valueForKeyPath:@"arrays.current"];
                  if ([currentPeriodFromServer isKindOfClass:[NSDictionary class]]){
                      [self updateSuccessfullSyncItemsQueue:(NSDictionary *)currentPeriodFromServer];
                  }
                  
                  if(![self removeFromSyncQueue:syncItem]) {
                      [self errorRaisedWithCode:ERR_UNKNOWN];
                      return;
                  }
                  
                  NSLog(@"Sync complete");
                  [self saveAppState];
                  [self verifyAndGoNextInSynchQueue];
              }else [self errorRaisedWithCode:ERR_START_WORK];
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              NSLog(@"Error: %@", error);
              [self errorRaisedWithCode:ERR_NO_CONNECTION];
          }
     ];
}

-(void)syncEndWork:(SyncItem *)syncItem{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = @{@"action": @"ongoingperiod,statistics",
                                 @"username": [udTimeServer username],
                                 @"password": [udTimeServer password],
                                 @"type":@"work",
                                 @"stattype": @"today,thisweek,weekbalance,monthbalance",
                                 @"statyearforweekofyear": [[[self lastWeek] objectForKey:@"yearForWeekOfYear"] stringValue],
                                 @"statweek": [[[self lastWeek] objectForKey:@"week"] stringValue],
                                 @"statyear": [[[self lastMonth] objectForKey:@"year"] stringValue],
                                 @"statmonth": [[[self lastMonth] objectForKey:@"month"] stringValue],
                                 @"timestamp": [[NSNumber alloc] initWithInteger:syncItem.time],
                                 @"output": @"json"};
    [manager POST:API_URL
       parameters:parameters
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
               //NSLog(@"%@", responseObject);
              if(![udTimeServer successOnResult:responseObject onAction:@"results.login"]) {
                  [self errorRaisedWithCode:ERR_NOT_LOGGED_IN];
                  return;
              }
              if([udTimeServer successOnResult:responseObject onAction:@"results.endwork"]){
                  NSNumber *lastmodified = (NSNumber *)[responseObject valueForKeyPath:@"arrays.info.lastmodified"];
                  [self setLatestSyncedPeriodTimestamp:[lastmodified integerValue]];
                  
                  self.successfullySynced = nil;
                  
                  if(![self removeFromSyncQueue:syncItem]) {
                     [self errorRaisedWithCode:ERR_UNKNOWN];
                      return;
                  }
                  
                  NSLog(@"Sync complete");
                  [self saveAppState];
                  [self verifyAndGoNextInSynchQueue];
              } else [self errorRaisedWithCode:ERR_END_WORK];
              if([udTimeServer successOnResult:responseObject onAction:@"results.statistics"]){
                  id statistics = [responseObject valueForKeyPath:@"arrays.stats"];
                  if ([statistics isKindOfClass:[NSDictionary class]]){
                      [self updateStatisticsWithServerValues:(NSDictionary *)statistics];
                  }
              }
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Error: %@", error);
              [self errorRaisedWithCode:ERR_NO_CONNECTION];
          }
     ];
}

-(void)syncStartBreak:(SyncItem *)syncItem{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = @{@"action": @"ongoingperiod",
                                 @"username": [udTimeServer username],
                                 @"password": [udTimeServer password],
                                 @"type":@"break",
                                 @"timestamp": [[NSNumber alloc] initWithInteger:syncItem.time],
                                 @"output": @"json"};
    [manager POST:API_URL
       parameters:parameters
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              if(![udTimeServer successOnResult:responseObject onAction:@"results.login"]) {
                  [self errorRaisedWithCode:ERR_NOT_LOGGED_IN];
                  return;
              }
              if([udTimeServer successOnResult:responseObject onAction:@"results.newbreak"]){
                  NSNumber *lastmodified = (NSNumber *)[responseObject valueForKeyPath:@"arrays.info.lastmodified"];
                  [self setLatestSyncedPeriodTimestamp:[lastmodified integerValue]];
                  
                  id currentPeriodFromServer = [responseObject valueForKeyPath:@"arrays.current"];
                  if ([currentPeriodFromServer isKindOfClass:[NSDictionary class]]){
                      [self updateSuccessfullSyncItemsQueue:(NSDictionary *)currentPeriodFromServer];
                  }
                  
                  if(![self removeFromSyncQueue:syncItem]) {
                      [self errorRaisedWithCode:ERR_UNKNOWN];
                      return;
                  }
                  
                  NSLog(@"Sync complete");
                  [self saveAppState];
                  [self verifyAndGoNextInSynchQueue];
              } else [self errorRaisedWithCode:ERR_START_BREAK];
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              NSLog(@"Error: %@", error);
              [self errorRaisedWithCode:ERR_NO_CONNECTION];
          }
     ];
}

-(void)syncEndBreak:(SyncItem *)syncItem{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = @{@"action": @"endbreak",
                                 @"username": [udTimeServer username],
                                 @"password": [udTimeServer password],
                                 @"type":@"break",
                                 @"timestamp": [[NSNumber alloc] initWithInteger:syncItem.time],
                                 @"output": @"json"};
    [manager POST:API_URL
       parameters:parameters
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              //NSLog(@"%@", responseObject);
              if(![udTimeServer successOnResult:responseObject onAction:@"results.login"]) {
                  [self errorRaisedWithCode:ERR_NOT_LOGGED_IN];
                  return;
              }
              if([udTimeServer successOnResult:responseObject onAction:@"results.endbreak"]){
                  NSNumber *lastmodified = (NSNumber *)[responseObject valueForKeyPath:@"arrays.info.lastmodified"];
                  [self setLatestSyncedPeriodTimestamp:[lastmodified integerValue]];

                  id currentPeriodFromServer = [responseObject valueForKeyPath:@"arrays.current"];
                  if ([currentPeriodFromServer isKindOfClass:[NSDictionary class]]){
                      [self updateSuccessfullSyncItemsQueue:(NSDictionary *)currentPeriodFromServer];
                  }
                  
                  if(![self removeFromSyncQueue:syncItem]) {
                      [self errorRaisedWithCode:ERR_UNKNOWN];
                      return;
                  }

                  NSLog(@"Sync complete");
                  [self saveAppState];
                  [self verifyAndGoNextInSynchQueue];
              } else [self errorRaisedWithCode:ERR_END_BREAK];
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              NSLog(@"Error: %@", error);
              [self errorRaisedWithCode:ERR_NO_CONNECTION];
          }
     ];
}

#pragma mark App state

-(void)saveAppState{
    // Current period
    NSDictionary *currentPeriodToSave = [self.currentPeriod exportCurrentPeriodDictionary];
    
    
    //Sync Queue
    NSMutableArray *syncQueueArrayToSave = [[NSMutableArray alloc] init];
    for(SyncItem *item in self.syncQueue){
        NSDictionary *syncItemDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:[[NSNumber alloc] initWithInteger:item.syncType], @"syncType",[[NSNumber alloc] initWithInteger:item.time], @"time",/*[item.periodToSync exportDictionary], @"periodToSync",*/ nil];
        [syncQueueArrayToSave addObject:syncItemDictionary];
    }
    
    //Successfully synced
    NSMutableArray *successfullySyncedArrayToSave = [[NSMutableArray alloc] init];
    for(SyncItem *item in self.successfullySynced){
        NSDictionary *successfullySyncItemDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:[[NSNumber alloc] initWithInteger:item.syncType], @"syncType",[[NSNumber alloc] initWithInteger:item.time], @"time",/*[item.periodToSync exportDictionary], @"periodToSync",*/ nil];
        [successfullySyncedArrayToSave addObject:successfullySyncItemDictionary];
    }
    
    
    [[NSUserDefaults standardUserDefaults] setObject:[syncQueueArrayToSave copy] forKey:@"syncQueueBackup"];
    [[NSUserDefaults standardUserDefaults] setObject:[successfullySyncedArrayToSave copy] forKey:@"successfullySyncedBackup"];
    [[NSUserDefaults standardUserDefaults] setObject:[currentPeriodToSave copy] forKey:@"currentPeriodBackup"];
    [[NSUserDefaults standardUserDefaults] setObject:self.statLabelBalanceLastMonth.text forKey:@"statLabelBalanceLastMonth"];
    [[NSUserDefaults standardUserDefaults] setObject:self.statLabelBalanceLastWeek.text forKey:@"statLabelBalanceLastWeek"];
    [[NSUserDefaults standardUserDefaults] setObject:self.statLabelToday.text forKey:@"statLabelToday"];
    [[NSUserDefaults standardUserDefaults] setObject:self.statLabelThisWeek.text forKey:@"statLabelThisWeek"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)loadAppState{
    NSDictionary *currentPeriodToLoad = [[NSUserDefaults standardUserDefaults] objectForKey:@"currentPeriodBackup"];
    NSArray *syncQueueArrayToLoad = [[NSUserDefaults standardUserDefaults] objectForKey:@"syncQueueBackup"];
    NSArray *successfullySyncedArrayToLoad = [[NSUserDefaults standardUserDefaults] objectForKey:@"successfullySyncedBackup"];
 
    //Load statistics
    NSString *statLabelBalanceLastMonth = (NSString *)[[NSUserDefaults standardUserDefaults] objectForKey:@"statLabelBalanceLastMonth"];
    NSString *statLabelBalanceLastWeek = [[NSUserDefaults standardUserDefaults] objectForKey:@"statLabelBalanceLastWeek"];
    NSString *statLabelToday = [[NSUserDefaults standardUserDefaults] objectForKey:@"statLabelToday"];
    NSString *statLabelThisWeek = [[NSUserDefaults standardUserDefaults] objectForKey:@"statLabelThisWeek"];
    
    if(statLabelBalanceLastMonth == nil) self.statLabelBalanceLastMonth.text = THREE_DASHES;
    else self.statLabelBalanceLastMonth.text = statLabelBalanceLastMonth;
    if(statLabelBalanceLastWeek == nil) self.statLabelBalanceLastWeek.text = THREE_DASHES;
    else self.statLabelBalanceLastWeek.text = statLabelBalanceLastWeek;
    if(statLabelToday == nil) self.statLabelToday.text = THREE_DASHES;
    else self.statLabelToday.text = statLabelToday;
    if(statLabelThisWeek == nil) self.statLabelThisWeek.text = THREE_DASHES;
    else self.statLabelThisWeek.text = statLabelThisWeek;
    
    //Load current period
    [self clearSyncQueue];
    self.successfullySynced = nil;
    [self.currentPeriod importCurrentPeriod:currentPeriodToLoad];
    //self.currentSyncedPeriod = [[NSUserDefaults standardUserDefaults] objectForKey:@"currentSyncedPeriodBackup"];
   
    //Load sync Queue
    for(NSDictionary *syncItemDictionary in syncQueueArrayToLoad){
        [self addItemToSyncQueueWithTime:[[syncItemDictionary objectForKey:@"time"] integerValue] ofType:[[syncItemDictionary objectForKey:@"syncType"] integerValue]];
    }
    
    //Load successfully synced
    for(NSDictionary *syncedItemDictionary in successfullySyncedArrayToLoad){
        [self.successfullySynced addObject:[[SyncItem alloc] initWithSyncType:[[syncedItemDictionary objectForKey:@"syncType"] integerValue] andTime:[[syncedItemDictionary objectForKey:@"time"] integerValue]]];
    }
    [self updateUItoCurrentPeriod];
}

#pragma mark Error handeling

-(void)errorRaisedWithCode:(int)code{
    UIAlertView *alert;
    switch(code) {
        case ERR_NOT_LOGGED_IN:
            alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                               message:@"Not logged in"
                                              delegate:self
                                     cancelButtonTitle:@"OK"
                                     otherButtonTitles:nil];
            alert.tag=ERR_NOT_LOGGED_IN;
            break;
        case ERR_UNSUCCESSULL_LOGIN:
            alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                               message:@"Unsuccessful login attempt"
                                              delegate:self
                                     cancelButtonTitle:@"OK"
                                     otherButtonTitles:nil];
            alert.tag=ERR_UNSUCCESSULL_LOGIN;
            break;
        case ERR_START_WORK:
            alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                               message:@"Could not start work"
                                              delegate:self
                                     cancelButtonTitle:@"OK"
                                     otherButtonTitles:@"Current period",nil];
            alert.tag=ERR_START_WORK;
            break;
        case ERR_END_WORK:
            alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                               message:@"Could not end work"
                                              delegate:self
                                     cancelButtonTitle:@"OK"
                                     otherButtonTitles:@"Current period",nil];
            alert.tag=ERR_END_WORK;
            break;
        case ERR_START_BREAK:
            alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                               message:@"Could not start break"
                                              delegate:self
                                     cancelButtonTitle:@"OK"
                                     otherButtonTitles:@"Current period",nil];
            alert.tag=ERR_START_BREAK;
            break;
        case ERR_END_BREAK:
            alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                               message:@"Could not end break"
                                              delegate:self
                                     cancelButtonTitle:@"OK"
                                     otherButtonTitles:@"Current period",nil];
            alert.tag=ERR_START_BREAK;
            break;
        case ERR_NOT_IN_SYNC:
            alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                               message:@"Your status has updated outside this app. You should refresh from server."
                                              delegate:self
                                     cancelButtonTitle:@"OK"
                                     otherButtonTitles:@"Refresh", nil];
            alert.tag=ERR_NOT_IN_SYNC;
            break;
        case ERR_COULD_NOT_SYNC:
            alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                               message:@"Sync was unsuccessful"
                                              delegate:self
                                     cancelButtonTitle:@"OK"
                                     otherButtonTitles:@"Current period",nil];
            alert.tag=ERR_COULD_NOT_SYNC;
            break;
        case ERR_NO_CONNECTION :
            alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                               message:@"No connection"
                                              delegate:self
                                     cancelButtonTitle:@"OK"
                                     otherButtonTitles:nil];
            alert.tag=ERR_NO_CONNECTION;
            break;
        case ERR_BUSY :
            alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                               message:@"Busy, sync queue might be running"
                                              delegate:self
                                     cancelButtonTitle:@"OK"
                                     otherButtonTitles:nil];
            alert.tag=ERR_BUSY;
            break;
        default:
            alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                               message:@"Unknown error occured"
                                              delegate:self
                                     cancelButtonTitle:@"OK"
                                     otherButtonTitles:nil];
            alert.tag=999;
            break;
    }
    [alert show];
    [self.syncSpinner stopAnimating];
}

#pragma mark Helper methods
-(NSDictionary *)lastWeek{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *comps = [NSDateComponents new];
    comps.weekOfYear = -1;
    NSDate *date = [calendar dateByAddingComponents:comps toDate:[NSDate date] options:0];
    NSDateComponents *components = [calendar components:NSWeekOfYearCalendarUnit|NSYearForWeekOfYearCalendarUnit fromDate:date]; // Get necessary date components
    return [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInteger:components.yearForWeekOfYear], @"yearForWeekOfYear",[NSNumber numberWithInteger:components.weekOfYear], @"week", nil];
}

-(NSDictionary *)lastMonth{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *comps = [NSDateComponents new];
    comps.month = -1;
    NSDate *date = [calendar dateByAddingComponents:comps toDate:[NSDate date] options:0];
    NSDateComponents *components = [calendar components:NSMonthCalendarUnit|NSYearCalendarUnit fromDate:date]; // Get necessary date components
    return [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInteger:components.year], @"year",[NSNumber numberWithInteger:components.month], @"month", nil];
}
@end
