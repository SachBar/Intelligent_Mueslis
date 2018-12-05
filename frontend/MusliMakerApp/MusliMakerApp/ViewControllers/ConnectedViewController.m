//
//  ConnectedViewController.m
//  MusliMakerApp
//
//  Created by Jacob Fiskaali Hertz on 15/11/2018.
//  Copyright © 2018 Jacob Fiskaali Hertz. All rights reserved.
//

#import "ConnectedViewController.h"
#import "Connector.h"

//double const MIN_PRICE = 3.00;
NSString *const SEGUE_ID_SUGGEST = @"SegueSuggestions";
NSString *const SEGUE_ID_PAYMENT = @"SeguePayment";

@interface ConnectedViewController ()

@property (strong,nonatomic) Connector *bluetooth;
@property (strong, nonatomic) MuesliMaker *muesliMaker;

//@property(strong, nonatomic) NSMutableArray *sortedOrder;

@property (weak, nonatomic) IBOutlet UISlider *sliderCerealAmount;
@property (weak, nonatomic) IBOutlet UILabel *lblOrderWeight;
@property (weak, nonatomic) IBOutlet UILabel *lblOrderPrice;
@property (weak, nonatomic) IBOutlet UILabel *lblOrderStatus;
@property (weak, nonatomic) IBOutlet UIButton *btnOrderDone;
@property (weak, nonatomic) IBOutlet UITableView *tableIngredients;

@end

@implementation ConnectedViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"%@",self.navigationController.viewControllers);

    _btnOrderDone.enabled = NO;
    _tableIngredients.allowsSelection = YES;
    
    _bluetooth = [Connector sharedInstance];
}

-(void)viewWillAppear:(BOOL)animated{
    if(_muesliMaker.appState==AppStateOrderDone){
        [self.navigationController popToRootViewControllerAnimated:YES];
    }else{
        [self updateGUI];
    }
}

#pragma mark - Internal UI

-(void)updateGUI{
    [self updateOrderSummary];
    [_tableIngredients reloadData];
}

-(void) updateOrderSummary{
    double price = [self OrderPrice];
    _lblOrderWeight.text = [NSString stringWithFormat:@"%d g",[self OrderWeight]];
    _lblOrderPrice.text = [NSString stringWithFormat:@"%.2f kr",price];
    if(price>=MIN_PRICE) _btnOrderDone.enabled = true;
    else _btnOrderDone.enabled = false;
}
-(double)OrderPrice{
    double sum = 0;
    for (int i =0; i<_muesliMaker.OrderAmounts.count; ++i) {
        sum += [_muesliMaker.OrderAmounts[i] doubleValue]*[_muesliMaker.Prices[i] doubleValue];
    }
    return sum;
}
-(int)OrderWeight{
    double sum = 0;
    for (NSNumber*num in _muesliMaker.OrderAmounts) {
        sum += num.integerValue;
    }
    return sum;
}

-(void)resetOrder{
    [_muesliMaker resetOrder];
    [self updateGUI];
}

#pragma mark - Interface methods
-(void)setMuesliMaker:(MuesliMaker*)muesliMaker{
    _muesliMaker = muesliMaker;
    //_sortedOrder = [NSMutableArray arrayWithArray:muesliMaker.Ingredients];
}

#pragma mark - Notifications

-(void)didDisconnect:(NSNotification*)notification{// TODO no observer added
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - IB methods
- (IBAction)SendRequestPressed:(id)sender {
    #pragma mark (FSM) ui: done
    // IB segue -> PaymentViewController
    if(_muesliMaker.appState==AppStateSubscribed){
        _muesliMaker.appState = AppStatePlaceOrder;
        _tableIngredients.allowsSelection = NO;
        _sliderCerealAmount.enabled = false;
        [_tableIngredients deselectRowAtIndexPath:_tableIngredients.indexPathForSelectedRow animated:YES];
        [_bluetooth sendOrder:_muesliMaker.OrderAmounts];
    }else NSLog(@"FSM error! (%d -> %d)",(int)_muesliMaker.appState,(int)AppStatePlaceOrder);
}

- (IBAction)ResetButtonPressed:(id)sender {
    [self resetOrder];
}

- (IBAction)SliderDidChange:(id)sender {
    NSIndexPath *ip = _tableIngredients.indexPathForSelectedRow;
    if(!ip) return;
//    ((Ingredient*)_sortedOrder[ip.row]).order = [NSNumber numberWithFloat:_sliderCerealAmount.value];

    [_muesliMaker setOrderAmount:_sliderCerealAmount.value At:ip.row];
    //[_muesliMaker ingredientAt:ip.row].order = [NSNumber numberWithFloat:_sliderCerealAmount.value];
    
    [_tableIngredients reloadRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationNone];
    [_tableIngredients selectRowAtIndexPath:ip animated:NO scrollPosition:NO];
    
    [self updateOrderSummary];
}

- (IBAction)SliderDidEnd:(id)sender {
    // TODO is not called if user moves and releases finger out of slider bounds
    //[self sortOrder];
}
/*
-(void)sortOrder{
    NSSortDescriptor *sortByOrderedAmount;
    sortByOrderedAmount = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:NO];
    [_sortedOrder sortUsingDescriptors:@[sortByOrderedAmount]];
    [_tableIngredients reloadData];
}*/

#pragma mark - Table View

- (nonnull UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"IngredientsTableItem";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:simpleTableIdentifier];
    }
    
    //cell.textLabel.text = ((Ingredient*)_sortedOrder[indexPath.row]).productName;
    //float orderAmount = ((Ingredient*)_sortedOrder[indexPath.row]).order.floatValue;
    cell.textLabel.text = _muesliMaker.Products[indexPath.row];
    float orderAmount = [_muesliMaker.OrderAmounts[indexPath.row] floatValue];
     if(orderAmount>0)
     {
     cell.detailTextLabel.text = [NSString stringWithFormat:@"%.2f grams",orderAmount];
     }
     else
     cell.detailTextLabel.text = @"";

    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _muesliMaker.Products.count;
//    return _sortedOrder.count;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    //    if(((Ingredient*)_sortedOrder[indexPath.row]).type==Base)
    if(((Ingredient*)_muesliMaker.Ingredients[indexPath.row]).type==Base)
        [_sliderCerealAmount setMaximumValue:200];
    else
        [_sliderCerealAmount setMaximumValue:30];
    
    //    [_sliderCerealAmount setValue:((Ingredient*)_sortedOrder[indexPath.row]).order.floatValue animated:YES];
    [_sliderCerealAmount setValue:[_muesliMaker.OrderAmounts[indexPath.row] floatValue] animated:YES];
    _sliderCerealAmount.enabled = true;
}

#pragma mark - Navigation
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqual:SEGUE_ID_SUGGEST]){
        NSLog(@"Prepare for segue suggest");
    }else if([segue.identifier isEqual:SEGUE_ID_PAYMENT]){
        NSLog(@"Prepare for segue! Order: %@ Price: %f",_muesliMaker.OrderAmounts,[self OrderPrice]);
        PaymentViewController* pvc = segue.destinationViewController;
        [pvc setPrice:[self OrderPrice]];
        [pvc setMuesliMaker:_muesliMaker];
    }
}

-(void)didCancel{
    NSLog(@"C.VC cancelled");
 //   [self setState:OrderChoosing];
 //   [_bluetooth cancelOrder];
}
-(void)didSucceed{
    NSLog(@"C.VC Succes");
}

-(void)dealloc{
    NSLog(@"Connected dealloc");
}

@end
