//
//  MonthStatsCDTVC.m
//  udTime
//
//  Created by Johan Adell on 08/04/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import "MonthStatsCDTVC.h"
#import "MonthDetailTVC.h"
#import "Month.h"
#import "AppDelegate.h"
#import "AFNetworking.h"
#import "udTimeServer.h"
#import "Month+udTime.h"
#import "Work+udTime.h"
#import "Break+udtime.h"
#import "Asworktime+udtime.h"
#import "Againstworktime+udtime.h"
#import "StatsTotalsTableViewCell.h"
#import "Work.h"
#import "Break.h"
#import "Againstworktime.h"
#import "Asworktime.h"
#import "Time.h"

@interface MonthStatsCDTVC ()

@end

@implementation MonthStatsCDTVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UIManagedDocument *document = [(AppDelegate *)[[UIApplication sharedApplication] delegate] document];
    if (document.documentState == UIDocumentStateNormal) {
        self.managedObjectContext = document.managedObjectContext;
        
    }
    [self.refreshControl addTarget:self action:@selector(refreshView:) forControlEvents:UIControlEventValueChanged];

    
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if (self.managedObjectContext) {
        [udTimeServer synchronizeInternalDBWithServerOn:self.managedObjectContext];
    }
    [self stopRefreshControl:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(stopRefreshControl:)                                                     name:@"stopLoading"
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Make sure your segue name in storyboard is the same as this line
    if ([[segue identifier] isEqualToString:@"MonthDetailSegue"])
    {
        // Get reference to the destination view controller
        MonthDetailTVC *mditvc = [segue destinationViewController];
        
        // Pass any objects to the view controller here, like...
        
        if([sender isKindOfClass:[UITableViewCell class]]) {
            NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
            Month *month = [self.fetchedResultsController objectAtIndexPath:indexPath];
            mditvc.month = month;
            mditvc.managedObjectContext = self.managedObjectContext;
        }
        
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    _managedObjectContext = managedObjectContext;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Month"];
    request.predicate = nil;
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"year"
                                                              ascending:NO
                                 ],[NSSortDescriptor sortDescriptorWithKey:@"month"
                                                                 ascending:NO
                                    ]];
    
    
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:managedObjectContext
                                                                          sectionNameKeyPath:@"year"
                                                                                   cacheName:nil];
    //[self startMonthFetch];
}




#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    StatsTotalsTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Month Cell"];
    
    Month *month = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    NSString *monthName = [[df monthSymbols] objectAtIndex:([month.month intValue]-1)];
    
    cell.statPeriod.text = [NSString stringWithFormat:@"%@", monthName];
    cell.worked.text = [NSString stringWithFormat:@"%@", [Time secondsToReadableTime:month.worked]];
    cell.periodDifference.text = [NSString stringWithFormat:@"%@", month.monthdifftime];
    if([[month.monthdifftime substringToIndex:1] isEqualToString:@"-"]){
        cell.periodDifference.textColor = [UIColor colorWithRed:253.0f/255.0f green:134.0f/255.0f blue:9.0f/255.0f alpha:1.0f];
    }else{
        cell.periodDifference.textColor = [UIColor colorWithRed:137.0f/255.0f green:197.0f/255.0f blue:6.0f/255.0f alpha:1.0f];
    }
    
    cell.totalDifference.text = [NSString stringWithFormat:@"%@", month.totaldifftime];
    return cell;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    if ([[self.fetchedResultsController sections] count] > 0) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
        return [sectionInfo numberOfObjects];
    } else
        return 0;
    
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([[self.fetchedResultsController sections] count] > 0) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
        return [sectionInfo name];
    } else
        return nil;
}

- (void)refreshView:(UIRefreshControl *)sender {
    // Do something...
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"forceRefreshStats"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    if (self.managedObjectContext) {
        [udTimeServer synchronizeInternalDBWithServerOn:self.managedObjectContext];
    }
    //[sender endRefreshing];
}

- (void)stopRefreshControl:(NSNotification *)note {
    
    [self.refreshControl endRefreshing];
}
/*
 
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

#pragma mark Helper methods
@end
