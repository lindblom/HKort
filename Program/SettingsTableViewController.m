//
//  SettingsTableViewController.m
//  Program
//
//  Created by Christopher Lindblom on 2012-01-06.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SettingsTableViewController.h"


@interface SettingsTableViewController() <UITextFieldDelegate>

-(NSString *) prefix19ToUsernameIfLengthIs10:(NSString *) username;

@end

@implementation SettingsTableViewController

@synthesize userNameTextField = _userNameTextField;
@synthesize passwordTextField = _passwordTextField;

#pragma mark - View lifecycle

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.userNameTextField.text = [self prefix19ToUsernameIfLengthIs10:self.userNameTextField.text];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.userNameTextField.delegate = self;

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [self setUserNameTextField:nil];
    [self setPasswordTextField:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSUserDefaults * defults = [NSUserDefaults standardUserDefaults];
    if (defults) {
        self.userNameTextField.text = [defults objectForKey:@"username"];
        self.passwordTextField.text = [defults objectForKey:@"password"];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    NSUserDefaults * defults = [NSUserDefaults standardUserDefaults];
    if (defults) {
        [defults setObject:[self prefix19ToUsernameIfLengthIs10:self.userNameTextField.text] forKey:@"username"]; 
        [defults setObject:self.passwordTextField.text forKey:@"password"];
        [defults synchronize];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

#pragma mark - Helper methods

-(NSString *) prefix19ToUsernameIfLengthIs10:(NSString *) username {
    if (username.length == 10)
        username = [@"19" stringByAppendingString:username];
    return username;
}

@end
