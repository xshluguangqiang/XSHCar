//
//  XSWeather.h
//  XSHCar
//
//  Created by Frank Du on 15/4/14.
//  Copyright (c) 2015年 chenlei. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XSWeather : NSObject
@property (nonatomic, strong) NSString *date;
@property (nonatomic, strong) NSString *dayPictureUrl;
@property (nonatomic, strong) NSString *nightPictureUrl;
@property (nonatomic, strong) NSString *temperature;
@property (nonatomic, strong) NSString *weather;
@property (nonatomic, strong) NSString *wind;
@property (nonatomic, strong) NSString *pm25;
@property (nonatomic, strong) NSString *currentCity;
@end
