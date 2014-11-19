//
//  FirstViewController.m
//  VirtualPet
//
//  Created by Ezequiel on 11/18/14.
//  Copyright (c) 2014 Ezequiel. All rights reserved.
//

#import "FirstViewController.h"
#import "SelectImgViewController.h"

@interface FirstViewController ()
@property (strong, nonatomic) IBOutlet UITextField *txtPetName;

@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)btnContinueTouch:(id)sender
{
    //[self setPetName:self.txtPetName.text];
    self.petName = self.txtPetName.text;
    SelectImgViewController *selectImgView = [[SelectImgViewController alloc] initWithNibName:@"SelectImgViewController" bundle:[NSBundle mainBundle] andPetName:self.petName];
    [self.navigationController pushViewController:selectImgView animated:YES];
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}

@end
