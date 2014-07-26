//
//  LoginViewController.h
//  udTime
//
//  Created by Johan Adell on 15/02/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import "UICKeyChainStore.h"
#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController{
    //KeychainItemWrapper *keychain;
    UICKeyChainStore *keychain;
}
@property (strong, nonatomic) IBOutlet UIButton *loginButton;
@property (strong, nonatomic) IBOutlet UITextField *usernameField;
@property (strong, nonatomic) IBOutlet UITextField *passwordField;



@end
