//
//  ViewController.m
//  MusliMakerApp
//
//  Created by Jacob Fiskaali Hertz on 15/11/2018.
//  Copyright © 2018 Jacob Fiskaali Hertz. All rights reserved.
//

#import "ViewController.h"
//#import "ConnectedViewController.h"
#import "SuggestionViewController.h"
#import "MuesliMaker.h"
#import "HistoryViewController.h"

NSString *const SEGUE_ID_CONNECT = @"SegueConnect";
NSString *const SEGUE_ID_MEALS = @"SegeuMeals";

@interface ViewController ()

@property (strong,nonatomic) Connector *bluetooth;
@property (strong,nonatomic) Server *server;
@property (strong,nonatomic) MuesliMaker *muesliMaker;

@property (strong,nonatomic) NSArray *recommendations;
@property (assign,nonatomic) NSInteger chosenRecommendation;
@property (weak, nonatomic) IBOutlet UIButton *btnTryRecommendation;

@property (strong,nonatomic) NSString *muesliMakerName;

@property (weak, nonatomic) IBOutlet UIButton *btnConnect;
@property (weak, nonatomic) IBOutlet UITableView *tableRecommendations;
@property (weak, nonatomic) IBOutlet UILabel *lblRecommendation;

@end

@implementation ViewController
{
    bool _awitingConnectionResponse;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _bluetooth = [Connector sharedInstance];
    _server = [Server sharedInstance];
    _server.delegate = self;
    _muesliMaker = [[MuesliMaker alloc] init];

    [_server getUserRecommendations:@"0"]; // User 0
    _chosenRecommendation = NSNotFound;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFindMuesliMaker:) name:@"didFindMuesliMaker" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didConnect) name:@"didConnect" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(failedToConnect) name:@"failedToConnect" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didDisconnect) name:@"didDisconnect" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ingredientsAreReady:) name:@"ingredientsAreReady" object:nil];
    
    _muesliMaker.appState = AppStateNotAvailable;

    // Auto start
    [_bluetooth startSearch];
}

-(void)updateConnecitonStatus{
    switch (_muesliMaker.appState) {
        case AppStateNotAvailable:
            [_btnConnect setTitle:@"No nearby MuesliMaker available" forState:UIControlStateNormal];
            _btnConnect.enabled = false;
            _btnTryRecommendation.enabled = false;
            break;
            
        case AppStateDiscovered:
            [_btnConnect setTitle:_muesliMakerName forState:UIControlStateNormal];
            _btnConnect.enabled = !_awitingConnectionResponse;
            _btnTryRecommendation.enabled = !_awitingConnectionResponse;
            break;
            
        case AppStateAwaitingIngredients:
            [_btnConnect setTitle:@"Connected" forState:UIControlStateNormal];
            _btnConnect.enabled = false;
            _btnTryRecommendation.enabled = false;
            break;
            
        case AppStateSubscribed:
            [_btnConnect setTitle:@"Connected" forState:UIControlStateNormal];
            _btnConnect.enabled = false;
            _btnTryRecommendation.enabled = false;
            break;
            
        default: // TODO
            break;
    }
}

#pragma mark - IB methods
- (IBAction)ConnectPressed:(id)sender {
    _awitingConnectionResponse=true;
    [self updateConnecitonStatus];
    [_bluetooth connect];
}

- (IBAction)TryRecommendationPressed:(id)sender {
    _chosenRecommendation = _tableRecommendations.indexPathForSelectedRow.row;
    [self ConnectPressed:self];
}

#pragma mark - Bluetooth delegate

- (void) didFindMuesliMaker:(NSNotification *) notification{
    if(_muesliMaker.appState==AppStateNotAvailable)
    {
        _muesliMakerName = notification.userInfo[@"MuesliMaker"];
        _muesliMaker.appState = AppStateDiscovered;
        [self updateConnecitonStatus];
    }
    else NSLog(@"FSM error (%d -> %d)",(int)_muesliMaker.appState,(int)AppStateDiscovered);
}

-(void)didConnect{
    #pragma mark (FSM) ui: connect
    if(_muesliMaker.appState==AppStateDiscovered)
    {
        _muesliMaker.appState = AppStateAwaitingIngredients;
        _awitingConnectionResponse=false;
        [self updateConnecitonStatus];
    }
    else NSLog(@"FSM error (%d -> %d)",(int)_muesliMaker.appState,(int)AppStateAwaitingIngredients);
}
-(void)failedToConnect{
    NSLog(@"failedToConnect (%d -> %d)",(int)_muesliMaker.appState,(int)AppStateDiscovered);
    if(_muesliMaker.appState != AppStateDiscovered) NSLog(@"FSM Error (failed to connect)");
    _muesliMaker.appState = AppStateNotAvailable;
    _awitingConnectionResponse=false;
    [self updateConnecitonStatus];
    [_bluetooth disconnect];
    [_bluetooth reset];
    [_bluetooth performSelector:@selector(startSearch) withObject:nil afterDelay:1];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed to connect"
                                                    message:nil
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}
-(void)didDisconnect{
    NSLog(@"didDisconnect (%d -> %d)",(int)_muesliMaker.appState,(int)AppStateDiscovered);
    if(_muesliMaker.appState==AppStateSubscribed){
        //_muesliMaker.appState = AppStateDiscovered; //TODO
    }
    [self updateConnecitonStatus];
}

-(void)ingredientsAreReady:(NSNotification*)notification{
    #pragma mark (FSM) m: received everything
    if(_muesliMaker.appState==AppStateAwaitingIngredients){
        _muesliMaker.appState = AppStateSubscribed;
        [self proceedToConnected];
    }
    else NSLog(@"FSM error!");
}

#pragma mark - Server callbacks

-(void)ServerDelegate:(id)delegate didGetResponse:(id)response OfType:(ResponseType)type{
    if(type==ServerResponseUserRecommendation){
        
        NSMutableArray* cleaned = [NSMutableArray arrayWithCapacity:((NSArray*)response).count];
        for (NSArray*recom in response) {
            NSMutableArray* clean = [NSMutableArray arrayWithArray:recom];
            [clean removeObject:@""];
            [cleaned addObject:clean];
        }
//        _recommendations = response;
        _recommendations = cleaned;
        NSLog(@"Recommendation: %@",_recommendations);
        [_tableRecommendations reloadData];
    }
}

#pragma mark - Table View

- (nonnull UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"IngredientsTableItem";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:simpleTableIdentifier];
    }
    
    NSArray*ingrs = _recommendations[indexPath.row];
    cell.textLabel.text = [[ingrs valueForKey:@"description"] componentsJoinedByString:@", "];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _recommendations.count;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSArray*ingrs = _recommendations[indexPath.row];
    _lblRecommendation.text = [[ingrs valueForKey:@"description"] componentsJoinedByString:@", "];
    _btnTryRecommendation.hidden = false;
}

#pragma mark - Navigation
-(void)proceedToConnected{
    [self performSegueWithIdentifier:SEGUE_ID_CONNECT sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSLog(@"Prepare for segue");
    if([segue.identifier isEqual:SEGUE_ID_CONNECT]){
        SuggestionViewController *cvc = segue.destinationViewController;
        [cvc setMuesliMaker:_muesliMaker];
        if(_chosenRecommendation!=NSNotFound){
            [_muesliMaker setRecommendation:_recommendations[_chosenRecommendation]];
        }
    }else if([segue.identifier isEqual:SEGUE_ID_MEALS]){
        HistoryViewController *hvc = segue.destinationViewController;
        hvc.history = _muesliMaker.MealsHistory;
    }
}

-(void)viewWillAppear:(BOOL)animated{
    if(_muesliMaker.appState==AppStateOrderDone){
        _muesliMaker.appState = AppStateDiscovered;
    }
    
    [self updateConnecitonStatus];
    _server.delegate = self;
}

@end
