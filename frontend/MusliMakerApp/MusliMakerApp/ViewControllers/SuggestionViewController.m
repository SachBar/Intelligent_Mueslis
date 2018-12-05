//
//  SuggestionViewController.m
//  MusliMakerApp
//
//  Created by Jacob Fiskaali Hertz on 25/11/2018.
//  Copyright © 2018 Jacob Fiskaali Hertz. All rights reserved.
//

#import "SuggestionViewController.h"

NSString *const SEGUE_ID_MANUAL = @"SegueManualSelect";

@interface SuggestionViewController ()

@property (strong, nonatomic) MuesliMaker *muesliMaker;
@property (strong,nonatomic) Connector *bluetooth;
@property (strong, nonatomic) Server *server;
@property (strong, nonatomic) NSArray *products; // TODO replace with [_muesliMaker ProductAt:]
@property (strong, nonatomic) NSMutableArray *suggestions;
@property (strong, nonatomic) NSMutableArray *selectedProducts;

@property (weak, nonatomic) IBOutlet UIButton *btnContinue;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentPortionSize;
@property (weak, nonatomic) IBOutlet UITableView *tableSuggestions;
@property (weak, nonatomic) IBOutlet UITableView *tableIngredients;

@end

@implementation SuggestionViewController
{
    bool _willProceed;// used for checking reason for view disappearance
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _bluetooth = [Connector sharedInstance];
    _server = [Server sharedInstance];
    _server.delegate = self; // TODO re-setting of delegate
    
    NSLog(@"Suggestion viewDidLoad");
    
    [self reset];
}

-(void)reset{
    if(_muesliMaker.Recommendation!=nil){
        _selectedProducts = [NSMutableArray arrayWithArray:_muesliMaker.Recommendation];
        [self selectTableProducts];
        [_btnContinue setTitle:@"Continue" forState:UIControlStateNormal];
    }else{
        _selectedProducts = [NSMutableArray array];
        [_btnContinue setTitle:@"Skip" forState:UIControlStateNormal];
    }
    _suggestions = [NSMutableArray array];
    _willProceed = false;
}

-(IBAction)ContinueButtonPressed:(id)sender{
    [_muesliMaker resetOrder];
    if(_selectedProducts.count>0){
        PortionSize p = [self indexToPortionSize:_segmentPortionSize.selectedSegmentIndex];
        [_muesliMaker setOrderPortion:p ForProducts:_selectedProducts];
    }
    [self proceedToManualSelection];
}

-(PortionSize)indexToPortionSize:(NSInteger)index{
    return (PortionSize)(-index-1);
}

-(void)setMuesliMaker:(MuesliMaker*)muesliMaker{
    _muesliMaker = muesliMaker;
    _products = muesliMaker.Products;
}

-(void)selectTableProducts{
    for (NSString*product in _selectedProducts) {
        NSInteger i = [_muesliMaker indexOfProduct:product];
        if(i == NSNotFound) continue;
        [_tableIngredients selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:NO scrollPosition:NO];
    }
    [_server getSuggestions:_selectedProducts];
}

-(void)clearSuggestions{
    [_suggestions removeAllObjects];
    [_tableSuggestions reloadData];
}

#pragma mark - Server Delegate

-(void)ServerDelegate:(id)delegate didGetResponse:(id)response OfType:(ResponseType)type{
    if(type != ServerResponseSuggestion) return;
    
    NSArray * suggestions = response;
    
    NSLog(@"Received %lu suggestions:",(unsigned long)suggestions.count);
    [_suggestions removeAllObjects];
    for (NSDictionary*suggestion in suggestions) {
        NSLog(@"%@",suggestion);
        bool available = true;
        NSMutableArray *addIngredients = [NSMutableArray array];
        for (NSString*product in suggestion[@"item"]) {
            available = available && [_muesliMaker checkIngredient:product Amount:-1];
            if(!available){
                NSLog(@"Item not available: %@",product);
                break;
            }
            if(![_selectedProducts containsObject:product]) [addIngredients addObject:product];
            
        }
        if(available) [_suggestions addObject:addIngredients];
    }
    [_tableSuggestions reloadData];
    _tableSuggestions.userInteractionEnabled = YES;
}
/*
-(void)ServerDelegate:(id)delegate didGetResponseWithSuggestions:(NSArray *)suggestions{
    NSLog(@"Received %lu suggestions:",(unsigned long)suggestions.count);
    [_suggestions removeAllObjects];
    for (NSDictionary*suggestion in suggestions) {
        NSLog(@"%@",suggestion);
        bool available = true;
        NSMutableArray *addIngredients = [NSMutableArray array];
        for (NSString*product in suggestion[@"item"]) {
            available = available && [_muesliMaker checkIngredient:product Amount:-1];
            if(!available){
                NSLog(@"Item not available: %@",product);
                break;
            }
            if(![_selectedProducts containsObject:product]) [addIngredients addObject:product];
            
        }
        if(available) [_suggestions addObject:addIngredients];
    }
    [_tableSuggestions reloadData];
    _tableSuggestions.userInteractionEnabled = YES;
}*/

- (void)ServerDelegate:(id)delegate failedToGetResponseWithError:(NSString*)error{
    NSLog(@"Server error %@",error);
    [_suggestions removeAllObjects];
    [_suggestions addObject:@[@"Server error"]];
    [_tableSuggestions reloadData];
    _tableSuggestions.userInteractionEnabled = NO;
}

#pragma mark - Table View

- (nonnull UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"IngredientsTableItem";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:simpleTableIdentifier];
    }
    
    if([tableView isEqual:_tableSuggestions])
    {
        if([_suggestions[indexPath.row] isEqual:@[@"Server error"]]){ // TODO ugs
            cell.textLabel.text = @"Server error";
        }else{
            cell.textLabel.text = [NSString stringWithFormat:@"Add %@",[[_suggestions[indexPath.row] valueForKey:@"description"] componentsJoinedByString:@", "]];
        }
    }
    else// if([tableView isEqual:_tableBaseIngredients])
    {
        cell.textLabel.text = _products[indexPath.row];
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if([tableView isEqual:_tableSuggestions])
    {
        if(_suggestions==nil) return 0;
        return _suggestions.count;
    }
    else// if([tableView isEqual:_tableBaseIngredients])
    {
        return _products.count;
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if([tableView isEqual:_tableSuggestions])
    {
        NSLog(@"Did tap suggestion!");
        for (NSString*item in _suggestions[indexPath.row]) {
            NSInteger i = [_products indexOfObject:item];
            NSLog(@"i: %d",(int)i);
            [_tableIngredients selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:YES scrollPosition:YES];
            [_selectedProducts addObject:_products[i]];
        }
        [self clearSuggestions];
        [_server getSuggestions:_selectedProducts];
    }
    else// if([tableView isEqual:_tableBaseIngredients])
    {
        NSLog(@"Did tap base ingredient");
        [_selectedProducts addObject:_products[indexPath.row]];
        [_server getSuggestions:_selectedProducts];
        [_btnContinue setTitle:@"Continue" forState:UIControlStateNormal];
    }
}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{
    if([tableView isEqual:_tableSuggestions])
    {
    }
    else// if([tableView isEqual:_tableBaseIngredients])
    {
        [_selectedProducts removeObject:_products[indexPath.row]];
        if(_selectedProducts.count>0) [_server getSuggestions:_selectedProducts];
        else{
            [_btnContinue setTitle:@"Skip" forState:UIControlStateNormal];
            [self clearSuggestions];
        }
    }
}

#pragma mark - Navigation
-(void)proceedToManualSelection{
    NSLog(@"Proceeding with order: %@",_muesliMaker.OrderAmounts);
    [self performSegueWithIdentifier:SEGUE_ID_MANUAL sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqual:SEGUE_ID_MANUAL]){
        ConnectedViewController *cwc = segue.destinationViewController;
        [cwc setMuesliMaker:_muesliMaker];
        _willProceed=true;
    }
}

-(void)viewWillAppear:(BOOL)animated{
    _willProceed=false;
}

-(void)viewWillDisappear:(BOOL)animated{
    NSLog(@"viewWillDisappear");
    if(_willProceed==false){
        #pragma mark (FSM) ui: back
        if(_muesliMaker.appState==AppStateSubscribed){
            _muesliMaker.appState = AppStateDiscovered;
            [_bluetooth disconnect];
            if(_server.delegate==self) _server.delegate = nil;
            NSLog(@"GOING BACK!!");
            // TODO Notify ViewController
        }else NSLog(@"FSM error! (%d -> %d)",(int)_muesliMaker.appState,(int)AppStateDiscovered);
    }
}

-(void)dealloc{
    NSLog(@"Suggestion dealloc");
}

@end
