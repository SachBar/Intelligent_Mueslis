//
//  HistoryViewController.m
//  MusliMakerApp
//
//  Created by Jacob Fiskaali Hertz on 26/11/2018.
//  Copyright © 2018 Jacob Fiskaali Hertz. All rights reserved.
//

#import "HistoryViewController.h"
#import "Ingredient.h"

@interface HistoryViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableMeals;

@end

@implementation HistoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(void)viewWillAppear:(BOOL)animated{
    [_tableMeals reloadData];
}

#pragma mark - Table View

- (nonnull UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"MealsTableItem";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
    }
    
    NSInteger i = _history.meals.count-indexPath.row-1; // Last meals first
    cell.textLabel.text = _history.productDescriptions[i];
    cell.detailTextLabel.text = _history.dateDescriptions[i];
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _history.meals.count;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
