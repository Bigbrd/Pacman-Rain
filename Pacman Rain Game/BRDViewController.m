//
//  BRDViewController.m
//  Pacman Dash Game
//
//  Created by MTSS User on 9/29/14.
//  Copyright (c) 2014 Bryan Dickens. All rights reserved.
//

// Assignment 5
// Grade: 4
// Very nice job.  Great theme.
// Apple recommends pulling motion data for games, rather than pushing (via blocks).  But your solution works very well
// Always a good idea to choose app names that aren't too long (and wind up with "..." displayed on the springboard)



#define yAxisAnimateDistance 300
#define yAxisPacmanStartingSpot 267
#define xAxisPacmanFamilyMovingValue 100
#define fruitSize 70
#define ghostSize 80
#define pacmanSize 60
#define babyPacmanSize 40
#define ghostTag 1
#define fruitTag 2

static const CGFloat emitterCellScale = 0.4;
static const CGFloat emitterCellLifetime = 1.0;
static const CGFloat emitterCellBirthRate = 5.0;
static const CGFloat emitterCellVelocity = 100.0;
static const CGFloat emitterFadeDuration = 0.5;
static const CGFloat minRainTimeWait = 0.5;
static const CGFloat maxRainTimeWait = 1.0;
static const CGFloat kpercentOfGhosts = 0.3;
static const CGFloat linearVelocityMax = 300.0;
static const CGFloat rangeConversionValue = 1000.0;
static const CGFloat kPacmanSpeedValue = 12.0;
static const CGFloat kPacmanDensityValue = 35.0;
static const CGFloat subtleMoveAnimationTime = 0.1;
static const CGFloat animatePieceAwayDuration = 0.3;
static const CGFloat gyroscopeUpdateInterval = (1/40.0);
static const CGFloat accelUpdateInterval = (1/40.0);
static const CGFloat kAnimationDurationForMenu = 0.5;
static const CGFloat kAnimationDurationForPacman = 0.5;
static const CGFloat gameOverImageViewAnimationTime = 1.0;
static const CGFloat gameOverPacmansAnimationTime = 2.0;

#import "BRDViewController.h"
#import <CoreMotion/CoreMotion.h>
#import <QuartzCore/QuartzCore.h>

@interface BRDViewController () <UICollisionBehaviorDelegate, UIDynamicAnimatorDelegate>

@property UIImageView *pacmanImageView;
@property UIImageView *msPacmanImageView;
@property UIImageView *babyPacmanImageView;
@property (weak, nonatomic) IBOutlet UILabel *currentScoreLabel;
@property (weak, nonatomic) IBOutlet UIButton *pauseGameButton;
-(IBAction)pauseButtonPressed:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *tryAgainButton;
-(IBAction)tryAgainButtonPressed:(id)sender;

@property NSInteger currentScore;
@property (strong, nonatomic) CMMotionManager *motionManager;
@property (strong, nonatomic) UIDynamicAnimator *dynamicAnimator;
@property (strong, nonatomic) UIGravityBehavior *gravityBehavior;
@property (strong, nonatomic) UICollisionBehavior *collisionBehavior;
@property (strong, nonatomic) CAAnimationGroup *gameOverGroupAnimation;
@property (strong, nonatomic) CAAnimationGroup *gameOverMsPacmanGroupAnimation;
@property (strong, nonatomic) CAAnimationGroup *gameOverBabyPacmanGroupAnimation;

@property NSArray *fruitImages;
@property NSArray *ghostImages;
@property NSTimer *rainTimer;
@property NSTimer *motionTimer;
@property BOOL isPlaying;
@property UIImageView *gameOverImageView;
@property CAEmitterLayer *emitterLayer;


@property (weak, nonatomic) IBOutlet UIView *menuView;
@property (weak, nonatomic) IBOutlet UILabel *menuScoreLabel;
@property (weak, nonatomic) IBOutlet UILabel *directionsLabel;
@property (weak, nonatomic) IBOutlet UIButton *playMenuButton;
-(IBAction)playButtonPressed:(id)sender;

@end

@implementation BRDViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [self setUpView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setUpView
{
    // Takes background image and fits to screen.
    UIGraphicsBeginImageContext(self.view.frame.size);
    [[UIImage imageNamed:@"pacman_background.png"] drawInRect:self.view.bounds];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // Applies background image into the loading view.
    self.view.backgroundColor = [UIColor colorWithPatternImage:image];
    
    [self setUpMotionManager];
    [self setUpBehaviors];
    [self setUpMsPacmanAndBabyPacman];
    [self setUpPacman];
    [self setUpRainPieces];
    [self setUpMenu];
    [self setUpEmitterLayer];
    [self setUpGameOverGroupAnimation];
    [self setUpPacmansGameOverRunScaredAnimations];
    
}

-(void)setUpPacman
{
    
    CGRect pacmanInitFrame = CGRectMake(self.view.frame.size.width/2 - pacmanSize/2, self.view.frame.size.height-yAxisPacmanStartingSpot, pacmanSize, pacmanSize);
    UIImageView *pacmanImageView = [[UIImageView alloc] initWithFrame:pacmanInitFrame];
    
    // Load images
    NSArray *imageNames = @[@"pacman_0.png", @"pacman_1.png", @"pacman_2.png", @"pacman_3.png"];
    
    NSMutableArray *images = [[NSMutableArray alloc] init];
    for (int i = 0; i < imageNames.count; i++) {
        [images addObject:[UIImage imageNamed:[imageNames objectAtIndex:i]]];
    }
    
    // Animation for pacman images
    pacmanImageView.animationImages = images;
    pacmanImageView.animationDuration = kAnimationDurationForPacman;
    [pacmanImageView startAnimating];
    
    _pacmanImageView = pacmanImageView;
    [self.view addSubview:_pacmanImageView];
    
    //add it to collision behaviors
    [_collisionBehavior addItem:_pacmanImageView];
    
    //dynamic behavior
    UIDynamicItemBehavior *dynamicItemBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[_pacmanImageView]];
    dynamicItemBehavior.allowsRotation = NO;
    dynamicItemBehavior.density = kPacmanDensityValue;
    [self.dynamicAnimator addBehavior:dynamicItemBehavior];
    
}

-(void)setUpMsPacmanAndBabyPacman
{
    //create frame and image for Ms Pacman
    CGRect msPacmanInitFrame = CGRectMake(0.0, self.view.frame.size.height-pacmanSize, pacmanSize, pacmanSize);
    _msPacmanImageView = [[UIImageView alloc] initWithFrame:msPacmanInitFrame];
    _msPacmanImageView.image = [UIImage imageNamed:@"mspacman.png"];
    
    //create frame and image for Baby Pacman
    CGRect babyPacmanInitFrame = CGRectMake(self.view.frame.size.width-babyPacmanSize, self.view.frame.size.height-babyPacmanSize, babyPacmanSize, babyPacmanSize);
    _babyPacmanImageView = [[UIImageView alloc] initWithFrame:babyPacmanInitFrame];
    _babyPacmanImageView.image = [UIImage imageNamed:@"baby_pacman.png"];
    
    //add imageviews to the main view
    [self.view addSubview:_msPacmanImageView];
    [self.view addSubview:_babyPacmanImageView];
}

-(void)setUpRainPieces
{
    // Load images
    NSArray *fruitImageNames = @[@"fruit_1.png", @"fruit_2.png", @"fruit_3.png", @"fruit_4.png", @"fruit_5.png"];
    NSArray *ghostImageNames = @[@"ghost_1.png", @"ghost_2.png", @"ghost_3.png", @"ghost_4.jpg"];
    
    NSMutableArray *fruitImagesTemp = [[NSMutableArray alloc] init];
    for (int i = 0; i < fruitImageNames.count; i++) {
        UIImage *fruitImage = [UIImage imageNamed:[fruitImageNames objectAtIndex:i]];
        [fruitImagesTemp addObject:fruitImage];
    }
    NSMutableArray *ghostImagesTemp = [[NSMutableArray alloc] init];
    for (int i = 0; i < ghostImageNames.count; i++) {
        UIImage *ghostImage = [UIImage imageNamed:[ghostImageNames objectAtIndex:i]];
        [ghostImagesTemp addObject:ghostImage];
    }
    
    //final arrays of these images
    _fruitImages = [[NSArray alloc] initWithArray:fruitImagesTemp];
    _ghostImages = [[NSArray alloc] initWithArray:ghostImagesTemp];
    
    //game over image
    UIImage *gameOverImage = [UIImage imageNamed:@"pacman_gameover.png"];
    _gameOverImageView = [[UIImageView alloc] initWithImage:gameOverImage];
    _gameOverImageView.frame = _currentScoreLabel.frame;
}

-(void)setUpEmitterLayer
{
    _emitterLayer = [CAEmitterLayer layer];
    
    //create cells of a fruit explosion
    _emitterLayer.emitterCells =
    @[ [self setUpEmitterCellWithName:@"fruit_explosion_1.png"],
       [self setUpEmitterCellWithName:@"fruit_explosion_2.png"],
       [self setUpEmitterCellWithName:@"fruit_explosion_3.png"],
       [self setUpEmitterCellWithName:@"fruit_explosion_4.png"],
       [self setUpEmitterCellWithName:@"fruit_explosion_5.png"]];
    
    //start with the emitter layer off
    _emitterLayer.speed = 0.0;
    [self.view.layer addSublayer:_emitterLayer];
}

-(CAEmitterCell*)setUpEmitterCellWithName:(NSString*)fileName {
    CAEmitterCell *emitterCell = [CAEmitterCell emitterCell];
    emitterCell.contents = (id)[[UIImage imageNamed:fileName] CGImage];
    
    //configurable variables for the emitter cell
    emitterCell.scale = emitterCellScale;
    emitterCell.scaleRange = 2*emitterCellScale;
    emitterCell.spin = 2*M_PI;
    emitterCell.spinRange = 2*M_PI;
    
    emitterCell.emissionRange = M_PI;
    emitterCell.lifetime = emitterCellLifetime;
    emitterCell.lifetimeRange = emitterCellLifetime/2.0;
    emitterCell.birthRate = emitterCellBirthRate;
    emitterCell.velocity = emitterCellVelocity;
    emitterCell.velocityRange = emitterCellVelocity/2.0;
    emitterCell.yAcceleration = emitterCellVelocity/2.0;
    
    return emitterCell;
}

-(void)setUpMenu
{
    //set initial settings for labels and buttons
    _pauseGameButton.hidden = YES;
    _currentScore = 0;
    _currentScoreLabel.hidden = YES;
    _menuScoreLabel.hidden = YES;
    _isPlaying = NO;
    
    // Takes background image and fits to screen.
    UIGraphicsBeginImageContext(_menuView.frame.size);
    [[UIImage imageNamed:@"pacman_0"] drawInRect:_menuView.bounds];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // Applies background image into the loading view.
    _menuView.backgroundColor = [UIColor colorWithPatternImage:image];
    
    [self setDirections];
}

-(void)setDirections
{
    _directionsLabel.text = @"Welcome to Pacman Dash! Inside this shrunken Pacman world your mission is to defend Ms.Pacman and your son! Collect as much fruit as possible and watch out for those Ghosts!";
}

-(void)setUpMotionManager
{
    _motionManager = [[CMMotionManager alloc] init];
    _motionManager.gyroUpdateInterval = gyroscopeUpdateInterval;
    _motionManager.accelerometerUpdateInterval = accelUpdateInterval;
}

-(void)setUpBehaviors
{
    
    _dynamicAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    _gravityBehavior = [[UIGravityBehavior alloc] init];
    
    _collisionBehavior = [[UICollisionBehavior alloc] init];
    _collisionBehavior.translatesReferenceBoundsIntoBoundary = YES;
    _collisionBehavior.collisionDelegate = self;
    
    //add bottom barrier
    CGPoint bottomEdgeStart = CGPointMake(0.0, self.view.frame.size.height);
    CGPoint bottomEdgeEnd = CGPointMake(self.view.frame.size.width, self.view.frame.size.height);
    [_collisionBehavior addBoundaryWithIdentifier:@"bottom"
                                fromPoint:bottomEdgeStart
                                  toPoint:bottomEdgeEnd];
    
    [_dynamicAnimator addBehavior:_collisionBehavior];
    [_dynamicAnimator addBehavior:_gravityBehavior];
    
}

-(void)setUpGameOverGroupAnimation
{
    //Animation 1 = Rotation
    CAKeyframeAnimation* rotationAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation"];
    NSArray* rotationValues = [NSArray arrayWithObjects:@0, @120.0, @240, @360, nil];
    rotationAnimation.values = rotationValues;
    rotationAnimation.calculationMode = kCAAnimationPaced;
    
    //Animation 2 = Scaling
    CAKeyframeAnimation* scalingAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    NSArray* scaleValues = [NSArray arrayWithObjects:@1, @1.5, @2, @2.5, @2, @1.5, @1, nil];
    scalingAnimation.values = scaleValues;
    scalingAnimation.calculationMode = kCAAnimationPaced;
    
    //Animation 3 = Translation
    CAKeyframeAnimation* translationAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.y"];
    NSArray* translationValues = [NSArray arrayWithObjects:@0, @50, @100, @150, @100, @50, @0, nil];
    translationAnimation.values = translationValues;
    translationAnimation.calculationMode = kCAAnimationPaced;
    
    //Animation group
    _gameOverGroupAnimation = [CAAnimationGroup animation];
    _gameOverGroupAnimation.animations = [NSArray arrayWithObjects:rotationAnimation, scalingAnimation, translationAnimation, nil];
    _gameOverGroupAnimation.duration = gameOverImageViewAnimationTime;
}

-(void)setUpPacmansGameOverRunScaredAnimations
{
    //Animation 1 = Translation.y Ms Pacman
    CAKeyframeAnimation* translationAnimationMsPacmanYAxis = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.y"];
    NSArray* translationValuesMsYAxis = [NSArray arrayWithObjects:@0, @-200, @0, @-200, @0, @-200, @0, @-200, @0, @-200, @0, @-200, @0, nil];
    translationAnimationMsPacmanYAxis.values = translationValuesMsYAxis;
    translationAnimationMsPacmanYAxis.calculationMode = kCAAnimationPaced;
    
    //Animation 2 = Translation.x Ms Pacman
    CAKeyframeAnimation* translationAnimationMsPacmanXAxis = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
    NSArray* translationValuesMsXAxis = [NSArray arrayWithObjects:@0, @100, @200, @300, @400, @500, @600, @500, @400, @300, @200, @100, @0, nil];
    translationAnimationMsPacmanXAxis.values = translationValuesMsXAxis;
    translationAnimationMsPacmanXAxis.calculationMode = kCAAnimationPaced;
    
    //Animation 1 = Translation.y Baby Pacman
    CAKeyframeAnimation* translationAnimationBabyPacmanYAxis = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.y"];
    NSArray* translationValuesBabyYAxis = [NSArray arrayWithObjects:@0, @-100, @0, @-100, @0, @-100, @0, @-100, @0, @-100, @0, @-100, @0, nil];
    translationAnimationBabyPacmanYAxis.values = translationValuesBabyYAxis;
    translationAnimationBabyPacmanYAxis.calculationMode = kCAAnimationPaced;
    
    //Animation 2 = Translation.x Baby Pacman
    CAKeyframeAnimation* translationAnimationBabyPacmanXAxis = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
    NSArray* translationValuesBabyXAxis = [NSArray arrayWithObjects:@0, @-100, @-200, @-300, @-400, @-500, @-600, @-500, @-400, @-300, @-200, @-100, @0, nil];
    translationAnimationBabyPacmanXAxis.values = translationValuesBabyXAxis;
    translationAnimationBabyPacmanXAxis.calculationMode = kCAAnimationPaced;
    
    //Animation groups
    _gameOverMsPacmanGroupAnimation = [CAAnimationGroup animation];
    _gameOverMsPacmanGroupAnimation.animations = [NSArray arrayWithObjects:translationAnimationMsPacmanYAxis, translationAnimationMsPacmanXAxis, nil];
    _gameOverMsPacmanGroupAnimation.duration = gameOverPacmansAnimationTime;
    
    _gameOverBabyPacmanGroupAnimation = [CAAnimationGroup animation];
    _gameOverBabyPacmanGroupAnimation.animations = [NSArray arrayWithObjects:translationAnimationBabyPacmanYAxis, translationAnimationBabyPacmanXAxis, nil];
    _gameOverBabyPacmanGroupAnimation.duration = gameOverPacmansAnimationTime;

}

#pragma mark - Button Actions
-(void)playButtonPressed:(id)sender
{
    //animate the menu View up and call the begin game method
    CGPoint newOrigin = CGPointMake(_menuView.center.x, -yAxisAnimateDistance);
    [UIView animateWithDuration:kAnimationDurationForMenu animations:^
     {
         _menuView.center = newOrigin;
         
     }completion:^(BOOL finished)
     {
         //game mode settings after menu is gone
         [_menuView setHidden:YES];
         _pauseGameButton.hidden = NO;
         _currentScoreLabel.hidden = NO;
         _currentScoreLabel.text = [NSString stringWithFormat:@"%ld",(long)_currentScore];
     }
     ];
    
    _isPlaying = YES;
    [self pacmansRunOffScreen];
    [self beginGame];
}

-(void)pauseButtonPressed:(id)sender
{
    _isPlaying = NO;
    
    //set back up the menu
    _pauseGameButton.hidden = YES;
    _currentScoreLabel.hidden = YES;
    _menuScoreLabel.hidden = NO;
    _menuView.center = CGPointMake(_menuView.center.x, -yAxisAnimateDistance);
    [_menuView setHidden:NO];
    _menuScoreLabel.text = [NSString stringWithFormat:@"%ld",(long)_currentScore];
    _directionsLabel.text = @"Game is Paused..";
    [self.view bringSubviewToFront:_menuView];
    
    //stop the game
    [self disableMotion];
    [self disableRainOfObjects];
    
    
    //animate the menu view down
    CGPoint newOrigin = CGPointMake(_menuView.center.x, self.view.center.y);
    [UIView animateWithDuration:kAnimationDurationForMenu animations:^
     {
         _menuView.center = newOrigin;
     }];
    
    [self pacmansRunOnScreen];
    
}

-(void)tryAgainButtonPressed:(id)sender
{
    [self setUpPacman];
    _currentScore = 0;
    _menuScoreLabel.hidden = YES;
    
    //remove old pieces
    NSArray *oldRainPieces = [self.gravityBehavior items];
    for( UIImageView *view in oldRainPieces)
    {
        [self removePiece:view];
    }
    
    [_gameOverImageView removeFromSuperview];
    _tryAgainButton.hidden = YES;
    _playMenuButton.hidden = NO;
    [self setDirections];
    
    [_msPacmanImageView.layer removeAnimationForKey:@"MsPacmanGameOver"];
    [_babyPacmanImageView.layer removeAnimationForKey:@"BabyPacmanGameOver"];
}


#pragma mark - Game Mechanics
-(void)beginGame
{
    [self enableMotion];
    
    [self enableRainObjectTimer];
}


-(void)gameOver
{
    _isPlaying = NO;
    
    //stop the game
    [self disableMotion];
    [self disableRainOfObjects];
    
    [self.view addSubview:_gameOverImageView];
    [_gameOverImageView.layer addAnimation:self.gameOverGroupAnimation forKey:nil];
    [self pacmansGameOverRunScared];
    
    //set back up the menu
    _pauseGameButton.hidden = YES;
    _currentScoreLabel.hidden = YES;
    _menuScoreLabel.hidden = NO;
    _menuView.center = CGPointMake(_menuView.center.x, -yAxisAnimateDistance);
    [_menuView setHidden:NO];
    _menuScoreLabel.text = [NSString stringWithFormat:@"%ld",(long)_currentScore];
    _directionsLabel.text = @"You got:";
    _playMenuButton.hidden = YES;
    _tryAgainButton.hidden = NO;
    
    //animate the menu view down
    CGPoint newOrigin = CGPointMake(_menuView.center.x, self.view.center.y);
    [UIView animateWithDuration:kAnimationDurationForMenu animations:^
     {
         _menuView.center = newOrigin;
     }];
    
}

-(void)enableRainObjectTimer
{
    //randomize the timer
    CGFloat randomDelta = [self randomFloatBetween:minRainTimeWait and:maxRainTimeWait];
    
    //schedule it
    _rainTimer = [NSTimer scheduledTimerWithTimeInterval:randomDelta target:self selector:@selector(rainObjectOnTimerFired:) userInfo:nil repeats:NO];
    
}

-(void)rainObjectOnTimerFired:(NSTimer*)timer
{
    //select image to drop
    UIImageView *rainObject;
    CGRect frame;
    
    CGFloat fruitOrGhostValue = [self randomFloatBetween:0.0 and:1.0];
    if (fruitOrGhostValue < kpercentOfGhosts) {
        //select random imageview from ghosts
        NSUInteger randomIndex = arc4random_uniform((u_int32_t)[_ghostImages count]);
        rainObject = [[UIImageView alloc] initWithImage:[_ghostImages objectAtIndex:randomIndex]];
        rainObject.tag = ghostTag;
        //set frame here
        frame = CGRectMake(0.0, 0.0, ghostSize, ghostSize);
    }
    else
    {
        //select random imageview from fruit
        NSUInteger randomIndex = arc4random_uniform((u_int32_t)[_fruitImages count]);
        rainObject = [[UIImageView alloc] initWithImage:[_fruitImages objectAtIndex:randomIndex]];
        rainObject.tag = fruitTag;
        //set frame here
        frame = CGRectMake(0.0, 0.0, fruitSize, fruitSize);
    }
    rainObject.frame = frame;
    
    //randomize the image start from y=0 x=0 to y=0 x=self.width
    NSInteger width = self.view.bounds.size.width;
    CGPoint startImageLocation = CGPointMake(arc4random_uniform((u_int32_t)width), 0.0);
    
    //add to subview at the new location
    rainObject.center = startImageLocation;
    [self.view addSubview:rainObject];
    
    //add it to gravity and collision behaviors
    [_gravityBehavior addItem:rainObject];
    [_collisionBehavior addItem:rainObject];
    
    //randomize the left to right or right to left trajectory
    // get random number between -1 and 1
    CGFloat alphaX = [self randomFloatBetween:-linearVelocityMax and:linearVelocityMax];
    CGFloat alphaY = [self randomFloatBetween:-linearVelocityMax and:linearVelocityMax];
    CGPoint alpha = CGPointMake(alphaX, alphaY);
    
    //dynamic behavior
    UIDynamicItemBehavior *dynamicItemBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[rainObject]];
    [dynamicItemBehavior addLinearVelocity:alpha forItem:rainObject];
    [self.dynamicAnimator addBehavior:dynamicItemBehavior];
    
    //run again for a new timer
    [timer invalidate];
    [self enableRainObjectTimer];
}

-(CGFloat)randomFloatBetween:(CGFloat)low and:(CGFloat)high
{
    u_int32_t delta = (u_int32_t) (ABS(high-low)*rangeConversionValue);
    CGFloat randomDelta = arc4random_uniform(delta)/rangeConversionValue;

    return randomDelta + low;
}

-(void)disableRainOfObjects
{
    [_rainTimer invalidate];
    _rainTimer = nil;
}

-(void)removePiece:(UIView*)piece
{
    [self.collisionBehavior removeItem:piece];
    [self.gravityBehavior removeItem:piece];
    [UIView animateWithDuration:animatePieceAwayDuration animations:^
     {
         piece.alpha = 0.0;
     } completion:^(BOOL finished)
     {
         [piece removeFromSuperview];
     }];
}

#pragma mark - CMMotion
-(void)enableMotion
{
    [_motionManager startDeviceMotionUpdates];

    if(_motionManager.deviceMotionAvailable)
    {
        [_motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^ (CMDeviceMotion *motionData, NSError *error)
        {
            [self updateImageWithDeviceMotion:motionData];
        }];
    }

}

-(void)updateImageWithDeviceMotion:(CMDeviceMotion*)motion
{
    CMAcceleration acceleration = motion.userAcceleration;
    CMRotationRate rotation = motion.rotationRate;
    
    CGFloat newX = _pacmanImageView.frame.origin.x + rotation.y*kPacmanSpeedValue + acceleration.y*kPacmanSpeedValue;
    CGFloat newY = _pacmanImageView.frame.origin.y + rotation.x*kPacmanSpeedValue + acceleration.x*kPacmanSpeedValue;
    
    //check frame jumping bounds
    newX = newX < 0.0 ? 0.0 : newX;
    newY = newY < 0.0 ? 0.0 : newY;
    newX = newX > self.view.frame.size.width - _pacmanImageView.frame.size.width ? self.view.frame.size.width - _pacmanImageView.frame.size.width : newX;
    newY = newY > self.view.frame.size.height - _pacmanImageView.frame.size.height ? self.view.frame.size.height - _pacmanImageView.frame.size.height : newY;
    
    CGRect newFrame = CGRectMake(newX, newY, _pacmanImageView.frame.size.width, _pacmanImageView.frame.size.height);
    [UIView animateWithDuration:subtleMoveAnimationTime animations:^
     {
         [_pacmanImageView setFrame:newFrame];
         [_dynamicAnimator updateItemUsingCurrentState:_pacmanImageView];
     }];
}

-(void)disableMotion
{
    
    [_motionManager stopGyroUpdates];
    [_motionManager stopAccelerometerUpdates];
    [_motionManager stopDeviceMotionUpdates];
    
}

#pragma mark - Collision Delegate
-(void)collisionBehavior:(UICollisionBehavior *)behavior beganContactForItem:(id<UIDynamicItem>)item1 withItem:(id<UIDynamicItem>)item2 atPoint:(CGPoint)p
{
    UIView *view1 = (UIView*)item1;
    UIView *view2 = (UIView*)item2;
    
    if (view1 == _pacmanImageView && view2.tag == fruitTag)
    {
        //animate away the fruit and increment the count
        [self removePiece:view2];
        //create and send a particle emitter here
        [self blowUpFruitAtPoint:p];
        _currentScore++;
        
    }
    else if (view1 == _pacmanImageView && view2.tag == ghostTag)
    {
        //game over
        [self removePiece:view1];
        [self gameOver];
    }
    else{}
    _currentScoreLabel.text = [NSString stringWithFormat:@"%ld",(long)_currentScore];
    
}
- (void)collisionBehavior:(UICollisionBehavior *)behavior beganContactForItem:(id<UIDynamicItem>)item
   withBoundaryIdentifier:(id<NSCopying>)identifier atPoint:(CGPoint)p {
    UIView *view = (UIView*)item;
    id boundary = identifier;
    
    if(view.tag == ghostTag && [boundary isEqualToString:@"bottom"])
    {
        //animate away the piece
        [self removePiece:view];
    }
}

#pragma mark - CAParticleEmitter Game Mechanic
-(void)blowUpFruitAtPoint:(CGPoint)collisionPoint
{
    //start the emitter at our collision point
    _emitterLayer.emitterPosition = collisionPoint;
    _emitterLayer.speed = 1.0;
    _emitterLayer.opacity = 1.0;
    
    //fade out the emitter
    CABasicAnimation* fadeAnim = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeAnim.fromValue = [NSNumber numberWithFloat:1.0];
    fadeAnim.toValue = [NSNumber numberWithFloat:0.0];
    fadeAnim.duration = emitterFadeDuration;
    
    _emitterLayer.opacity = 0.0;
    [_emitterLayer addAnimation:fadeAnim forKey:@"opacity"];
    
    //stop the emitter
    [NSTimer scheduledTimerWithTimeInterval:emitterFadeDuration target:self selector:@selector(stopBlowingUpFruitTimerFired:) userInfo:nil repeats:NO];
    
}

-(void)stopBlowingUpFruitTimerFired:(NSTimer*)timer
{
    _emitterLayer.speed = 0.0;
}

#pragma mark - Ms and baby Pacman animations
-(void)pacmansRunOffScreen
{
    //animate ms pacman left a little off screen
    CGPoint newMsPacmanPoint = CGPointMake(_msPacmanImageView.center.x-xAxisPacmanFamilyMovingValue, _msPacmanImageView.center.y);
    [UIView animateWithDuration:subtleMoveAnimationTime animations:^
     {
         [_msPacmanImageView setCenter:newMsPacmanPoint];
     }];
    //animate baby pacman right
    CGPoint newBabyPacmanPoint = CGPointMake(_babyPacmanImageView.center.x+xAxisPacmanFamilyMovingValue, _babyPacmanImageView.center.y);
    [UIView animateWithDuration:subtleMoveAnimationTime animations:^
     {
         [_babyPacmanImageView setCenter:newBabyPacmanPoint];
     }];
}
-(void)pacmansRunOnScreen
{
    //animate mspacman right a little on screen
    CGPoint newMsPacmanPoint = CGPointMake(_msPacmanImageView.center.x+xAxisPacmanFamilyMovingValue, _msPacmanImageView.center.y);
    [UIView animateWithDuration:subtleMoveAnimationTime animations:^
     {
         [_msPacmanImageView setCenter:newMsPacmanPoint];
     }];
    //animate baby pacman left
    CGPoint newBabyPacmanPoint = CGPointMake(_babyPacmanImageView.center.x-xAxisPacmanFamilyMovingValue, _babyPacmanImageView.center.y);
    [UIView animateWithDuration:subtleMoveAnimationTime animations:^
     {
         [_babyPacmanImageView setCenter:newBabyPacmanPoint];
     }];
}
-(void)pacmansGameOverRunScared
{
    //bring images to front first
    [self.view bringSubviewToFront:_msPacmanImageView];
    [self.view bringSubviewToFront:_babyPacmanImageView];
    [self pacmansRunOnScreen];
    
    //animate mspacman and baby pacman to bounce up and down while moving across the bottom of the screen
    [_msPacmanImageView.layer addAnimation:self.gameOverMsPacmanGroupAnimation forKey:@"MsPacmanGameOver"];
    [_babyPacmanImageView.layer addAnimation:self.gameOverBabyPacmanGroupAnimation forKey:@"BabyPacmanGameOver"];
}
@end
