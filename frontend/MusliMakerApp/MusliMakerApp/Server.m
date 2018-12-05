//
//  Server.m
//  MusliMakerApp
//
//  Created by Jacob Fiskaali Hertz on 19/11/2018.
//  Copyright © 2018 Jacob Fiskaali Hertz. All rights reserved.
//

#import "Server.h"

NSString *const SERV_URL = @"https://intelligentmueslis.herokuapp.com";
NSTimeInterval const WAIT_TIME = 3.0;

@interface Server()

@property (assign,nonatomic) ResponseType expectedResponse;
@property (strong, nonatomic) NSTimer *responseTimer;
@property (strong, nonatomic) NSURL *currentUrl;

@end

@implementation Server

+ (instancetype)sharedInstance
{
    static Server *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[Server alloc] init];
        // Do any other initialisation stuff here
    });
    return sharedInstance;
}

-(void)getSuggestions:(NSArray *)products{
    NSString * arr_str = [products componentsJoinedByString:@"-"];
    _expectedResponse = ServerResponseSuggestion;
    [self callServer:[NSString stringWithFormat:@"app/%@",arr_str]];
}

-(void)getUserRecommendations:(NSString *)userID{
    _expectedResponse = ServerResponseUserRecommendation;
    [self callServer:[NSString stringWithFormat:@"recommend/%@",userID]];
}

-(void)callTimedOut{
    [_responseTimer invalidate];
    _responseTimer = nil;
    if([self.delegate respondsToSelector:@selector(ServerDelegate:failedToGetResponseWithError:)])
        [self.delegate ServerDelegate:self failedToGetResponseWithError:@"Timed out"];
}

-(void)callServer:(NSString*)word{
    NSURL*url = [self assembleUrl:word];
    //NSLog(@"Server call: %@",url);

    if(_currentUrl!=nil){ // Response pending
        if(_responseTimer==nil){
            _responseTimer = [NSTimer scheduledTimerWithTimeInterval:WAIT_TIME target:self selector:@selector(callTimedOut) userInfo:nil repeats:NO];
        }
    }
    _currentUrl = url;

    NSURLSession *session = [NSURLSession sharedSession];
    
    [[session dataTaskWithURL:url
            completionHandler:^(NSData *data,
                                NSURLResponse *response,
                                NSError *error){
                
                if(response.URL != self.currentUrl){ // TODO does not seem to work
                    NSLog(@"IGNORE SERVER RESPONSE");
                    return;
                }
                
                // handle response:
                if (![response isKindOfClass:[NSHTTPURLResponse class]]){
                    NSLog(@"SERVER: no response");
                    return;
                }
                
                NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
                if(statusCode != 200){
                    //NSLog(@"SERVER: status: %li",(long)statusCode);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if(self.responseTimer != nil){
                            [self performSelector:@selector(callServer:) withObject:word afterDelay:0.2];
                        }
                    });
                    return;
                }
                
                self.currentUrl = nil;
                [self.responseTimer invalidate];
                self.responseTimer = nil;

                NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSLog(@"redponse: %@",str);
                
                NSArray* decoded = [self decodeResponse:data];
                
                if(decoded == nil){
                    NSLog(@"GT: json error");
                    return;
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    /*if([self.delegate respondsToSelector:@selector(ServerDelegate:didGetResponseWithSuggestions:)]){
                        [self.delegate ServerDelegate:self didGetResponseWithSuggestions:decoded];
                    }*/
                    if([self.delegate respondsToSelector:@selector(ServerDelegate:didGetResponse:OfType:)])
                    {
                        [self.delegate ServerDelegate:self didGetResponse:decoded OfType:self.expectedResponse];
                    }
                });
                
            }] resume];
}

-(NSURL*)assembleUrl:(NSString*)text{
    NSString *url_str;
    //url_str = [NSString stringWithFormat:SERV_URL,text];
    url_str = [NSString stringWithFormat:@"%@/%@",SERV_URL,text];
//    NSLog(@"url_str: %@",url_str);
//    return [NSURL URLWithString:url_str];

    return [NSURL URLWithString:[url_str stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
}

-(NSArray*)decodeResponse:(NSData*)responseData{
    NSError *error;
    NSArray* jsonArray = (NSArray*)[NSJSONSerialization
                                    JSONObjectWithData:responseData
                                    options:0
                                    error:&error];
    if(error){
        NSLog(@"%@",error.description);
        return nil;
        
    } // JSON was malformed, act appropriately here
    
    NSLog(@"%@",jsonArray);
    
    return jsonArray;
}


@end
