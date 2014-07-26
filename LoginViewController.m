//
//  LoginViewController.m
//  udTime
//
//  Created by Johan Adell on 15/02/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import "LoginViewController.h"
#import "AFNetworking.h"
#import "UICKeyChainStore.h"
#import "CurrentPeriodViewController.h"
#import "udTimeServer.h"

@interface LoginViewController ()
@property (strong, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *statusIndicator;

@end

@implementation LoginViewController

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
    
    // Create instance of keychain wrapper
    //keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"udTime2Keychain" accessGroup:nil];
    keychain = [UICKeyChainStore keyChainStoreWithService:@"udTime2Keychain"];
    
    self.loginButton.layer.cornerRadius = 3;
    self.loginButton.layer.backgroundColor = [[UIColor colorWithRed:0 green:0.8 blue:0.1 alpha:1.0] CGColor];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)doLogin:(id)sender {
    [self.statusIndicator startAnimating];
    self.statusLabel.text = @"Logging in...";
    self.statusLabel.hidden = NO;
    [self.view endEditing:YES];
    
    NSString *username = self.usernameField.text;
    NSString *password = self.passwordField.text;
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = @{@"action": @"currentperiod2",
                                 @"username": username,
                                 @"password": password,
                                 @"output": @"json"};
    [manager GET:API_URL
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             [self.statusIndicator stopAnimating];
             
             id loginnResult = [responseObject valueForKeyPath:@"results.login"];
             if([loginnResult[0] isEqualToNumber:[[NSNumber alloc] initWithInteger:1]]){
                 [keychain setString:username forKey:@"username"];
                 [keychain setString:password forKey:@"password"];
                 [keychain synchronize];
                 self.statusLabel.hidden = YES;
                 [self dismissViewControllerAnimated:YES completion:nil];
             }else{
                 self.statusLabel.text = @"Login unsuccessful";
             }
             
             
         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             [self.statusIndicator stopAnimating];
             self.statusLabel.text = @"Not able to connect";
         }];

}

@end
