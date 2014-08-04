//
//  User.m
//  udTime
//
//  Created by Johan Adell on 23/03/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import "udTimeServer.h"
#import "AppDelegate.h"
#import "UICKeyChainStore.h"
#import "AFNetworking.h"
#import "Work+udTime.h"
#import "Break+udtime.h"
#import "Asworktime+udtime.h"
#import "Againstworktime+udtime.h"
#import "Month+udtime.h"
#import "Week+udtime.h"

@implementation udTimeServer

+(NSString *)password{
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:@"udTime2Keychain"];
    return (NSString *)[keychain stringForKey:@"password"];
}

+(NSString *)username{
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:@"udTime2Keychain"];
    return (NSString *)[keychain stringForKey:@"username"];
}

+(void)synchronizeInternalDBWithServerOn:(NSManagedObjectContext *)context{
    
    //Get last modifications to database.
    //This way only added or updated items will be remembered. If nothing is added, delete might be repeated
    
    NSString *modafter;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"forceRefreshStats"]){
        modafter = @"0";
    }else{
        modafter = [NSString stringWithFormat:@"%d", (int)[[self timestampOfLastUpdatedPeriodOn:context] timeIntervalSince1970]];
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = @{@"action": @"serverupdates,monthtotals,weektotals",
                                 @"username": [udTimeServer username],
                                 @"password": [udTimeServer password],
                                 @"modafter": modafter,
                                 @"output": @"json"};
    [manager GET:API_URL
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
                 NSPersistentStoreCoordinator *mainThreadContextStoreCoordinator = [context persistentStoreCoordinator];
                 dispatch_queue_t request_queue = dispatch_queue_create("com.udtime.AddWorkToDatabase", NULL);
                 NSLog(@"Sending to thread");
                 dispatch_async(request_queue, ^{
                     // Create a new managed object context
                     // Set its persistent store coordinator
                     NSManagedObjectContext *threadMOC = [[NSManagedObjectContext alloc] init];
                     [threadMOC setPersistentStoreCoordinator:mainThreadContextStoreCoordinator];
                     
                     // Register for context save changes notification
                     NSNotificationCenter *notify = [NSNotificationCenter defaultCenter];
                     [notify addObserver:self
                                selector:@selector(mergeChanges:)
                                    name:NSManagedObjectContextDidSaveNotification
                                  object:threadMOC];
                     
                     
                     [udTimeServer updateWithServerResponse:responseObject on:threadMOC];
                     NSError *error;
                     NSLog(@"Start save");
                     [threadMOC save:&error];
                     NSLog(@"End Save");
                  
             
                 });
             
         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             
             [[NSNotificationCenter defaultCenter] postNotificationName:@"stopLoading" object:self];        //just in case
         }];
}

+ (void)updateWithServerResponse:(id)responseObject on:context{
    id loginResult = [responseObject valueForKeyPath:@"results.login"];
    if(![loginResult[0] isEqualToNumber:[[NSNumber alloc] initWithInteger:1]]) return;

    //****************************
    //Update month stats
    //*******
    NSLog(@"Updating month stats");
    id actionResultMS = [responseObject valueForKeyPath:@"results.monthstats"];
    if([actionResultMS[0] isEqualToNumber:[[NSNumber alloc] initWithInteger:1]]){
        id monthTotals = [responseObject valueForKeyPath:@"stats.monthtotal"];
        
        //Fetch last modified in database
        NSFetchRequest *latestmodifiedRequest = [NSFetchRequest fetchRequestWithEntityName:@"Month"];
        latestmodifiedRequest.predicate = nil;
        latestmodifiedRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"modifiedtimestamp"
                                                                                ascending:NO
                                                   ]];
        latestmodifiedRequest.fetchLimit = 1;
        NSError *error;
        NSArray *latestModifiedMonthArray = [context executeFetchRequest:latestmodifiedRequest error:&error];
        
        //Sort month totals array from server
        Month *latestModifiedMonth = [latestModifiedMonthArray firstObject];
        NSArray *newOrUpdatedMonthsTotals;
        if(latestModifiedMonth == nil){
            newOrUpdatedMonthsTotals = [NSArray arrayWithArray:monthTotals];
        }else if ([[NSUserDefaults standardUserDefaults] boolForKey:@"forceRefreshStats"]){
            NSPredicate *monthTotalsPredicate = [NSPredicate predicateWithFormat:@"modifiedtimestamp >= %@",[NSNumber numberWithDouble:0]];
            newOrUpdatedMonthsTotals = [monthTotals filteredArrayUsingPredicate:monthTotalsPredicate];
        }else{
            NSPredicate *monthTotalsPredicate = [NSPredicate predicateWithFormat:@"modifiedtimestamp >= %@",latestModifiedMonth.modifiedtimestamp ];
            newOrUpdatedMonthsTotals = [monthTotals filteredArrayUsingPredicate:monthTotalsPredicate];
        }
        for (NSDictionary *monthDict in newOrUpdatedMonthsTotals) {
            [Month monthWithServerInfo:monthDict inManagedObjectContext:context];
        }
     }
    
    //****************************
    //Update week stats
    //*******
    NSLog(@"Updating week stats");
    
    id actionResultWS = [responseObject valueForKeyPath:@"results.weekstats"];
    if([actionResultWS[0] isEqualToNumber:[[NSNumber alloc] initWithInteger:1]]){
        id weekTotals = [responseObject valueForKeyPath:@"stats.weektotal"];
        
        //Fetch last modified in database
        NSFetchRequest *latestmodifiedRequest = [NSFetchRequest fetchRequestWithEntityName:@"Week"];
        latestmodifiedRequest.predicate = nil;
        latestmodifiedRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"modifiedtimestamp"
                                                                                ascending:NO
                                                   ]];
        latestmodifiedRequest.fetchLimit = 1;
        NSError *error;
        NSArray *latestModifiedWeekArray = [context executeFetchRequest:latestmodifiedRequest error:&error];
        
        //Sort week totals array from server
        Week *latestModifiedWeek = [latestModifiedWeekArray firstObject];
        NSArray *newOrUpdatedWeeksTotals;
        if(latestModifiedWeek == nil){
            newOrUpdatedWeeksTotals = [NSArray arrayWithArray:weekTotals];
        }else if ([[NSUserDefaults standardUserDefaults] boolForKey:@"forceRefreshStats"]){
            NSPredicate *weekTotalsPredicate = [NSPredicate predicateWithFormat:@"modifiedtimestamp >= %@",[NSNumber numberWithDouble:0] ];
            newOrUpdatedWeeksTotals = [weekTotals filteredArrayUsingPredicate:weekTotalsPredicate];
        }else{
            NSPredicate *weekTotalsPredicate = [NSPredicate predicateWithFormat:@"modifiedtimestamp >= %@",latestModifiedWeek.modifiedtimestamp ];
            newOrUpdatedWeeksTotals = [weekTotals filteredArrayUsingPredicate:weekTotalsPredicate];
        }
        for (NSDictionary *weekDict in newOrUpdatedWeeksTotals) {
            [Week weekWithServerInfo:weekDict inManagedObjectContext:context];
        }
        
    }
    
    
    //****************************
    //Update periods
    //*******
    NSLog(@"Updating periods");
    id actionResultSU = [responseObject valueForKeyPath:@"results.serverupdates"];
    if([actionResultSU[0] isEqualToNumber:[[NSNumber alloc] initWithInteger:1]]){
        id workDicts = [responseObject valueForKeyPath:@"arrays.work"];
        for (NSDictionary *workDict in workDicts) {
            [Work workWithServerInfo:workDict inManagedObjectContext:context];
        }
        
        id breakDicts = [responseObject valueForKeyPath:@"arrays.break"];
        for (NSDictionary *breakDict in breakDicts) {
            [Break breakWithServerInfo:breakDict inManagedObjectContext:context];
        }
        
        id asworktimeDicts = [responseObject valueForKeyPath:@"arrays.asworktime"];
        for (NSDictionary *asworktimeDict in asworktimeDicts) {
            [Asworktime asworktimeWithServerInfo:asworktimeDict inManagedObjectContext:context];
        }
        
        id againstworktimeDicts = [responseObject valueForKeyPath:@"arrays.againstworktime"];
        for (NSDictionary *againstworktimeDict in againstworktimeDicts) {
            [Againstworktime againstworktimeWithServerInfo:againstworktimeDict inManagedObjectContext:context];
        }
        
        id deletedDicts = [responseObject valueForKeyPath:@"arrays.deleted"];
        for (NSDictionary *deletedDict in deletedDicts) {
            NSNumber *unique = [deletedDict objectForKey:@"original_id"];
            NSFetchRequest *request;
            NSError *error;
            
            if ([deletedDict[@"type"] isEqualToString:@"work"]) {
                request = [NSFetchRequest fetchRequestWithEntityName:@"Work"];
                request.predicate = [NSPredicate predicateWithFormat:@"workid==%lu", [unique integerValue]];
            }else if ([deletedDict[@"type"] isEqualToString:@"break"]){
                request = [NSFetchRequest fetchRequestWithEntityName:@"Break"];
                request.predicate = [NSPredicate predicateWithFormat:@"breakid==%lu", [unique integerValue]];
            }else if ([deletedDict[@"type"] isEqualToString:@"asworktime"]){
                request = [NSFetchRequest fetchRequestWithEntityName:@"Asworktime"];
                request.predicate = [NSPredicate predicateWithFormat:@"asworktimeid==%lu", [unique integerValue]];
            }else if ([deletedDict[@"type"] isEqualToString:@"againstworktime"]){
                request = [NSFetchRequest fetchRequestWithEntityName:@"Againstworktime"];
                request.predicate = [NSPredicate predicateWithFormat:@"againstworktimeid==%lu", [unique integerValue]];
            }
            NSArray *matches = [context executeFetchRequest:request error:&error];
            
            if (!matches || error || ([matches count] > 1) || ([matches count] < 1)) {
                // handle error
            } else  {   //Update
                id toBeDeleted = [matches firstObject];
                [context deleteObject:toBeDeleted];
            }
        }
    }
}

+ (void)mergeChanges:(NSNotification*)notification
{
    UIManagedDocument *document = [(AppDelegate *)[[UIApplication sharedApplication] delegate] document];
    NSManagedObjectContext *moc;
    if (document.documentState == UIDocumentStateNormal) {
        moc = document.managedObjectContext;
        
    }

    NSLog(@"Merging");
    dispatch_async(dispatch_get_main_queue(), ^{
        [moc mergeChangesFromContextDidSaveNotification:notification];
        NSLog(@"Merged");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"monthStatsUpdated" object:self];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"weekStatsUpdated" object:self];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"periodsStatsUpdated" object:self];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"serverSynched" object:self];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"stopLoading" object:self];
    });

    
}


+ (NSDate *)timestampOfLastUpdatedPeriodOn:(NSManagedObjectContext *)context{
    NSArray *entityNames = @[@"Work",@"Break",@"Asworktime",@"Againstworktime"];
    NSDate *timestamp = [NSDate dateWithTimeIntervalSince1970:0];
    for (NSString *entityName in entityNames) {
        NSFetchRequest *latestmodifiedRequest = [NSFetchRequest fetchRequestWithEntityName:entityName];
        latestmodifiedRequest.predicate = nil;
        latestmodifiedRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"modified"
                                                                                ascending:NO
                                                   ]];
        latestmodifiedRequest.fetchLimit = 1;
        NSError *error;
        NSArray *latestModifiedArray = [context executeFetchRequest:latestmodifiedRequest error:&error];
        id latestModifiedInEntity = [latestModifiedArray firstObject];
        NSDate *modified;
        if([entityName isEqualToString:@"Work"]){
            modified = ((Work *)latestModifiedInEntity).modified;
        }else if([entityName isEqualToString:@"Break"]){
            modified = ((Break *)latestModifiedInEntity).modified;
        }else if([entityName isEqualToString:@"Asworktime"]){
            modified = ((Work *)latestModifiedInEntity).modified;
        }else{
            modified = ((Work *)latestModifiedInEntity).modified;
        }
        if ([modified compare:timestamp] == NSOrderedDescending) {
            timestamp = modified;
        }
    }
    return timestamp;
}

+(BOOL)successOnResult:(id)responseObject onAction:(NSString *)action{
    id actionResult = [responseObject valueForKeyPath:action];
    if([actionResult[0] isEqualToNumber:[[NSNumber alloc] initWithInteger:1]]) return YES;
    else return NO;
}

+(void)showServerMessage:(NSString *)message{
    
    UIAlertView *alert;
    alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                       message:message
                                      delegate:self
                             cancelButtonTitle:@"OK"
                             otherButtonTitles:nil];
    [alert show];
}
@end
