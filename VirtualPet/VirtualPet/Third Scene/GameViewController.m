//
//  GameViewController.m
//  VirtualPet
//
//  Created by Ezequiel on 11/18/14.
//  Copyright (c) 2014 Ezequiel. All rights reserved.
//

#import "GameViewController.h"
#import "ImagesLoader.h"
#import "NSTimer+TimerWithAutoInvalidate.h"
#import "NetworkAccessObject.h"
#import "NotificationManager.h"
#import "PetListViewController.h"
#import "LocationHandler.h"
#import "ContactsViewController.h"
#import "FightViewController.h"

float const eatAnimationTime = 0.5f;
float const exhaustAnimationTime = 1.2f;
int const eatAnimationIterations = 4;

@interface GameViewController ()

@property (nonatomic, strong) PetFood* myFood;
@property (nonatomic) CGPoint imageViewFoodPosition;

@property (strong, nonatomic) IBOutlet UILabel *lblPetName;
@property (strong, nonatomic) IBOutlet UIImageView *petImageView;
@property (strong, nonatomic) IBOutlet UIProgressView *petEnergyBar;
@property (strong, nonatomic) IBOutlet UIImageView *imgViewFood;
@property (strong, nonatomic) IBOutlet UIView *mouthFrame;
@property (strong, nonatomic) IBOutlet UIButton *btnExcercise;
@property (strong, nonatomic) IBOutlet UIProgressView *petExpProgressBar;
@property (strong, nonatomic) IBOutlet UILabel *lblExperience;

@property (strong, nonatomic) NSTimer* energyTimer;
@property (strong, nonatomic) IBOutlet UIImageView *superSaiyanImgView;

@property (nonatomic, strong) NetworkAccessObject* daoObject;
@property (nonatomic, strong) LocationHandler* locationHandler;

@end

@implementation GameViewController

#pragma mark - Ciclo de Vida

//*************************************************************
// Ciclo de Vida
//*************************************************************

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    // Guardamos nuestro pet en el dispositivo
    
    
    [self.lblPetName setText:[NSString stringWithFormat:@"%@ Lvl: %d", [MyPet sharedInstance].petName, [MyPet sharedInstance].petLevel]];
    [self.petImageView setImage:[UIImage imageNamed:[MyPet sharedInstance].petImageName]];
    
    // Iniciar Barra de energia
    float value = [[MyPet sharedInstance] getEnergy];
    value = value / 100;
    [self updateEnergyProgress:value];
    
    [self setTitle: [MyPet sharedInstance].petName];
    
    self.imageViewFoodPosition = CGPointMake(self.imgViewFood.frame.origin.x, self.imgViewFood.frame.origin.y);
    
    [self.mouthFrame setAlpha:0];
    
    UIButton* button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    [button addTarget:self action:@selector(openContactsView) forControlEvents:UIControlEventTouchUpInside];
    [button setBackgroundImage:[UIImage imageNamed:@"email"] forState:UIControlStateNormal];
    UIBarButtonItem* mailButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    self.navigationItem.rightBarButtonItem = mailButton;
    
    // Personalizacion de progress bar
     [self.petEnergyBar setTransform:CGAffineTransformMakeScale(1.0, 7.0)];
    
    // Cargamos las imagenes en el loader
    [[ImagesLoader sharedInstance] loadPetArraysWithTag:[MyPet sharedInstance].petType];
    
    [self.lblExperience setText:[NSString stringWithFormat:@"%d / %d", [[MyPet sharedInstance] getActualExp], [[MyPet sharedInstance] getNeededExp]]];
    float actualExp = [[MyPet sharedInstance] getActualExp];
    float barValue = actualExp/[[MyPet sharedInstance] getNeededExp];
    [self.petExpProgressBar setProgress:barValue];
    
    // Instanciamos el DAO
    self.daoObject = [[NetworkAccessObject alloc] init];
    
    // Comenzamos el tracking de la mascota
    self.locationHandler = [[LocationHandler alloc] init];
    [self.locationHandler startTracking];
    
    // SUPER SAIYAN MTHFCK
    NSArray* superSaiyan = @[[UIImage imageNamed:[ImagesLoader sharedInstance].imgSuperSaiyan[0]],
                             [UIImage imageNamed:[ImagesLoader sharedInstance].imgSuperSaiyan[1]],
                             [UIImage imageNamed:[ImagesLoader sharedInstance].imgSuperSaiyan[2]]];
    
    [self.superSaiyanImgView setAnimationImages:superSaiyan];
    [self.superSaiyanImgView setAnimationDuration:0.2f];
    [self.superSaiyanImgView setAnimationRepeatCount:0];
    [self.superSaiyanImgView startAnimating];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setTitle:@"Home"];
    
    // Se suscribe la vista para las notificaciones
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePetEnergyInProgressBar:) name:EVENT_UPDATE_ENERGY object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePetExhaust) name:EVENT_SET_EXHAUST object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showLevelUp:) name:EVENT_LEVEL_UP object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateExperience) name:EVENT_UPDATE_EXPERIENCE object:nil];
    
    [self becomeFirstResponder];
    
}

- (void) viewWillDisappear:(BOOL)animated
{
    [self setTitle:@"---"];
    
    // Invalidamos el Timer
    [self.energyTimer autoInvalidate];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.petImageView stopAnimating];
    [self.btnExcercise setTitle:@"Do Excercise" forState:UIControlStateNormal];
    [MyPet sharedInstance].doingExcercise = false;
    
    [self resignFirstResponder];
    [super viewWillDisappear:animated];
}

- (void) viewDidDisappear:(BOOL)animated
{
    //self.imageViewFoodPosition = CGPointMake(246, 427);
    [self.imgViewFood setCenter:self.imageViewFoodPosition];
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

#pragma mark - Metodos Privados

//*************************************************************
// Eventos de Touch
//*************************************************************
- (IBAction)btnLoadDataClicked:(id)sender
{
    [self.daoObject doGETPetInfo:[self getSuccess]];
}

- (IBAction)btnRankClicked:(id)sender
{
    PetListViewController* petList = [[PetListViewController alloc] initWithNibName:@"PetListViewController" bundle:[NSBundle mainBundle]];
    [self.navigationController pushViewController:petList animated:YES];
}

- (IBAction)btnFoodClicked:(id)sender
{
    FoodViewController *myFoodView = [[FoodViewController alloc] initWithNibName:@"FoodViewController" bundle:[NSBundle mainBundle]];
    [myFoodView setFoodDelegate:self];
    [self.navigationController pushViewController:myFoodView animated:YES];
}

- (IBAction)btnDoExcerciseClicked:(id)sender {
    [self animateExcercisingPet];
    
    NSString* btnText = ([MyPet sharedInstance].doingExcercise ? @"Stop" : @"Do Excercise");
    [self.btnExcercise setTitle:btnText forState:UIControlStateNormal];
}

- (IBAction)handleTap:(UITapGestureRecognizer*)sender
{
    if(self.myFood)
    {
        CGPoint tapPoint = [sender locationInView:self.view];
        [UIView animateWithDuration:1.0 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^(void){
            
            
            [self.imgViewFood setCenter:tapPoint];
         }completion:^(BOOL finished){
             if(finished)
             {
                 if(CGRectContainsPoint([self.mouthFrame frame], tapPoint))
                 {
                     self.imgViewFood.image = nil;
                     [self.btnExcercise setEnabled:NO];
                     [self animateEatingPet];
                     NSLog(@"Morfando como un Campeon");
                 }
             }
             
         }];
    }
}

//***************************************************************************
// Animaciones
//***************************************************************************

#pragma mark - Animations

-(void) animateEatingPet
{
    NSArray *img = @[[UIImage imageNamed:[ImagesLoader sharedInstance].imgPetComiendo[0]],
                     [UIImage imageNamed:[ImagesLoader sharedInstance].imgPetComiendo[1]],
                     [UIImage imageNamed:[ImagesLoader sharedInstance].imgPetComiendo[2]],
                     [UIImage imageNamed:[ImagesLoader sharedInstance].imgPetComiendo[3]]];
    [self.petImageView setAnimationImages:img];
    [self.petImageView setAnimationDuration:eatAnimationTime];
    [self.petImageView setAnimationRepeatCount:eatAnimationIterations];
    [self setNormalStatePetImage];
    [self.petImageView startAnimating];
    [[MyPet sharedInstance] doEat: self.myFood.foodEnergyValue];
    [self.superSaiyanImgView startAnimating];
}

-(void) animateExcercisingPet
{
    NSArray *img = @[[UIImage imageNamed:[ImagesLoader sharedInstance].imgPetEjercicio[0]],
                     [UIImage imageNamed:[ImagesLoader sharedInstance].imgPetEjercicio[1]],
                     [UIImage imageNamed:[ImagesLoader sharedInstance].imgPetEjercicio[2]],
                     [UIImage imageNamed:[ImagesLoader sharedInstance].imgPetEjercicio[3]],
                     [UIImage imageNamed:[ImagesLoader sharedInstance].imgPetEjercicio[4]]];
    
    [self.petImageView setAnimationImages:img];
    [self.petImageView setAnimationDuration:eatAnimationTime];
    [self.petImageView setAnimationRepeatCount:0];
    
    if([MyPet sharedInstance].doingExcercise)
    {
        [self.petImageView stopAnimating];
        
        // Invalidamos el Timer
        [self.energyTimer autoInvalidate];
        [MyPet sharedInstance].doingExcercise = NO;
    }
    else
    {
        [self.petImageView startAnimating];
        self.energyTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateEnergyByExcercise) userInfo:nil repeats:YES];
        [MyPet sharedInstance].doingExcercise = YES;
    }
}

- (void) animateExhaustPet
{
    NSArray *img = @[[UIImage imageNamed:[ImagesLoader sharedInstance].imgPetExhausto[0]],
                     [UIImage imageNamed:[ImagesLoader sharedInstance].imgPetExhausto[1]],
                     [UIImage imageNamed:[ImagesLoader sharedInstance].imgPetExhausto[2]],
                     [UIImage imageNamed:[ImagesLoader sharedInstance].imgPetExhausto[3]]];
    
    [self.petImageView setAnimationImages:img];
    [self.petImageView setAnimationDuration:exhaustAnimationTime];
    [self.petImageView setAnimationRepeatCount:1];
    [self setExhaustFinishImage];
    [self.petImageView startAnimating];
    
}

#pragma mark - Update Energy

- (void) updateEnergyByExcercise
{
    [[MyPet sharedInstance] doExcercise];
    [[MyPet sharedInstance] gainExperience];
}

#pragma mark - Food Delegate Metodos
//*************************************************************
// Food Delegate
//*************************************************************

- (void) didSelectFood:(PetFood *)food
{
    self.myFood = food;
    [self.imgViewFood setImage:[UIImage imageNamed:self.myFood.imagePath]];
}
//*************************************************************
// Metodos del Pet
//*************************************************************
#pragma  mark - Eventos del Pet

- (void) updatePetEnergyInProgressBar :(NSNotification*) notif
{
    float varValue = ((NSNumber*)notif.object).intValue;
    varValue = varValue / 100;
    
    [self updateEnergyProgress:varValue];
}

- (void) updateEnergyProgress: (float) value
{
    [UIView animateWithDuration:1.0 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^(void)
     {
         [self.petEnergyBar setProgress:value animated:YES];
     }completion:^(BOOL finished)
     {
         if(finished)
         {
             [self.btnExcercise setEnabled:YES];
         }
     }];
}

- (void) updatePetExhaust
{
    [self.energyTimer autoInvalidate];
    [self.btnExcercise setEnabled:NO];
    [self.btnExcercise setTitle:@"Do Excercise" forState:UIControlStateNormal];
    [self animateExhaustPet];
}

- (void) setExhaustFinishImage
{
    [self.petImageView setImage:[UIImage imageNamed:[ImagesLoader sharedInstance].imgPetExhausto[3]]];
    [UIView animateWithDuration:1.0 delay:0 options:UIViewAnimationOptionCurveLinear animations:^(void){
        
        self.superSaiyanImgView.alpha = 0;
    }completion:^(BOOL finished){
        [self.superSaiyanImgView stopAnimating];
        self.superSaiyanImgView.alpha = 1;
    }];
}

- (void) setNormalStatePetImage
{
    [self.petImageView setImage:[UIImage imageNamed:[ImagesLoader sharedInstance].imgPetComiendo[0]]];
}

- (void) updateExperience
{
    [self.lblExperience setText:[NSString stringWithFormat:@"%d / %d", [[MyPet sharedInstance] getActualExp], [[MyPet sharedInstance] getNeededExp]]];
    float actualExp = [[MyPet sharedInstance] getActualExp];
    float barValue = actualExp/[[MyPet sharedInstance] getNeededExp];
    [self.petExpProgressBar setProgress:barValue];
}

- (void) showLevelUp :(NSNotification*) notification
{
    int level = ((NSNumber*)notification.object).intValue;
    //[[[UIAlertView alloc] initWithTitle:@"Congratulations" message:[NSString stringWithFormat:@"You raised level %d", level] delegate:self cancelButtonTitle:@"CONTINUE" otherButtonTitles:nil, nil] show];
    
    [self.lblPetName setText:[NSString stringWithFormat:@"%@ Lvl: %d", [MyPet sharedInstance].petName, level]];
    
    CGRect rect = self.superSaiyanImgView.frame;
    CGPoint center = self.superSaiyanImgView.center;
    float originY = self.superSaiyanImgView.center.y - self.superSaiyanImgView.frame.size.height/2;
    
    [self.superSaiyanImgView setFrame:CGRectMake(rect.origin.x, originY, rect.size.width + 200, rect.size.height + 200)];
    [self.superSaiyanImgView setCenter:center];
    [UIView animateWithDuration:1.0f delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^(void){
        [self.superSaiyanImgView setFrame:rect];

    }completion:^(BOOL finished) {
        
    }];
    
    // Enviamos la notificacion de level up
    NSDictionary* dic = @{@"code": CODE_IDENTIFIER,
                          @"name": [MyPet sharedInstance].petName,
                          @"level": [NSNumber numberWithInt:[MyPet sharedInstance].petLevel]
                        };
    [NotificationManager sendNotification:dic];
    [MyPet saveDataToDisk];
}

//********************************************
// Block para info del server
//********************************************

- (Success) getSuccess {
    
    __weak typeof(self) weakerSelf = self;
    
    return ^(NSURLSessionDataTask *task, id responseObject){
        NSLog(@"JSON: %@", responseObject);
        NSString* name = [responseObject objectForKey:@"name"];
        int level = ((NSNumber*)[responseObject objectForKey:@"level"]).intValue;
        int actualExp = ((NSNumber*)[responseObject objectForKey:@"experience"]).intValue;
        int energy = ((NSNumber*)[responseObject objectForKey:@"energy"]).intValue;
        PetType type = ((NSNumber*)[responseObject objectForKey:@"pet_type"]).intValue;
        
        [[MyPet sharedInstance] reloadDataName:name level:level actualExp:actualExp energy:energy andPetType:type];
        [[ImagesLoader sharedInstance] loadPetArraysWithTag:type];
        
        [weakerSelf.lblPetName setText:[NSString stringWithFormat:@"%@ Lvl: %d", name, level]];
        [weakerSelf updateExperience];
        [weakerSelf.petImageView setImage:[UIImage imageNamed:[MyPet sharedInstance].petImageName]];
        float barEnergy = energy;
        barEnergy = barEnergy / 100;
        [weakerSelf updateEnergyProgress:barEnergy];
    };
}

//********************************************
// Go to contact view
//********************************************

- (void) openContactsView
{
    ContactsViewController* view = [[ContactsViewController alloc] initWithNibName:@"ContactsViewController" bundle:[NSBundle mainBundle]];
    [self.navigationController pushViewController:view animated:YES];
}

//********************************************
// Motion - Accelerometer
//********************************************

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if(motion == UIEventSubtypeMotionShake)
    {
        // Entrenar
        /*if(![MyPet sharedInstance].isTired)
        {
            [self animateExcercisingPet];
            
            NSString* btnText = ([MyPet sharedInstance].doingExcercise ? @"Stop" : @"Do Excercise");
            [self.btnExcercise setTitle:btnText forState:UIControlStateNormal];
        }*/
        
        // Push FIGHT!!!!!!!
        [MyPet sharedInstance].health = 100;
        FightViewController* view = [[FightViewController alloc] init];
        [self.navigationController pushViewController:view animated:YES];
    }
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}


@end
