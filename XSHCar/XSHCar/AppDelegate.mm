//
//  AppDelegate.m
//  XSHCar
//
//  Created by clei on 14/12/18.
//  Copyright (c) 2014年 chenlei. All rights reserved.
//

#import "AppDelegate.h"
#import "HomeViewController.h"
#import "MessageManageViewController.h"
#import "SettingViewController.h"
#import "MeViewController.h"
#import "LoginViewController.h"
#import "UpdateHelper.h"
#import "UMSocial.h"
#import "UMSocialWechatHandler.h"
#import "UMSocialQQHandler.h"
#import "UMSocialSinaHandler.h"

#import "BNCoreServices.h"
#import <AlipaySDK/AlipaySDK.h>

@interface AppDelegate()<BMKGeneralDelegate, UIAlertViewDelegate>
{
    UITabBarController *mainTabbarViewController;
    BMKMapManager *mapManager;
}

@property (nonatomic, strong) CLLocationManager  *locationManager;
@property(nonatomic, strong) NSString *tokenString;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //设置友盟
    [UMSocialData setAppKey:UMSOCIAL_APP_KEY];
    [UMSocialWechatHandler setWXAppId:WECHAT_APP_ID appSecret:WECHAT_APP_SECRET url:@"http://www.xishengheng.com/"];
    [UMSocialQQHandler setQQWithAppId:QQ_APP_ID appKey:QQ_APP_KEY url:@"http://www.xishengheng.com/"];
    [UMSocialSinaHandler openSSOWithRedirectURL:nil];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    //通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didLogout) name:@"DidLogout" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didLogin) name:@"DidLogin" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bindReddot:) name:@"BindReddot" object:nil];
    
    //注册通知
    if (IOS_VERSION_LESS_THAN(@"8.0")) {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeBadge)];
    } else {
        [[UIApplication sharedApplication] registerForRemoteNotifications];
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeBadge|UIUserNotificationTypeSound|UIUserNotificationTypeAlert categories:nil]];
    }
    
    //判断是否由远程消息通知触发应用程序启动
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    if (launchOptions) {
        NSDictionary *pushInfo = [launchOptions objectForKey:@"UIApplicationLaunchOptionsRemoteNotificationKey"];
        NSDictionary *apsInfo = [pushInfo objectForKey:@"aps"];
        NSString *message = [apsInfo objectForKey:@"alert"];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"推送" message:message delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil, nil];
        [alertView show];
    }
    
    //启用定位服务
    if (IOS_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0") && self.locationManager == nil) {
        
        //由于IOS8中定位的授权机制改变，需要进行手动授权
        self.locationManager = [[CLLocationManager alloc] init];
        //获取授权认证
        [self.locationManager requestWhenInUseAuthorization];
        
//        CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
//        if (kCLAuthorizationStatusDenied == status || kCLAuthorizationStatusRestricted == status) {
//            [NSLOG:@"请打开您的位置服务!"];
//        }
    }
    
    //注册百度地图
    mapManager = [[BMKMapManager alloc] init];
    [mapManager start:BMK_APP_KEY generalDelegate:self];
    
    //设置tabbar字颜色
    //[[UITabBar appearance] setBarTintColor:[UIColor lightGrayColor]];
    [[UITabBarItem appearance] setTitleTextAttributes:@{NSFontAttributeName : [UIFont systemFontOfSize:11],NSForegroundColorAttributeName : RGB(113.0, 113.0, 113.0)} forState:UIControlStateNormal];
    [[UITabBarItem appearance] setTitleTextAttributes:@{NSFontAttributeName : [UIFont systemFontOfSize:11],NSForegroundColorAttributeName : APP_MAIN_COLOR} forState:UIControlStateSelected];
    
    //初始化百度导航sdk
//    [[BNCoreServices LocationService] setGpsFromExternal:NO];
//    [BNCoreServices_Location setGpsFromExternal:NO];
//    [BNCoreServices_Location gpsFromExternal];
//    [BNCoreServices_Instance initServices:@"5cmcRPwDqFNfkzxZ9c1YP6Dg"];
//    [BNCoreServices_Instance startServicesAsyn:nil fail:nil];
    //添加主视图
    [self addMainView];
    
    //后台登录
    [self loginInBackground];
    
    //添加引导视图
    //[self addTechView];
    
    //检查更新
    [UpdateHelper checkUpdate:NO];
    
    return YES;
}

#pragma mark - Login In Background
- (void)loginInBackground {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    if ([userDefaults objectForKey:@"isExit"] == nil) { //旧版本
        [self addLoginViewWithAnimation:NO];
        return;
    }
    
    if ([[userDefaults objectForKey:@"isExit"] boolValue]) { //新版本退出
        [self addLoginViewWithAnimation:NO];
        return;
    }
    
    if ([userDefaults objectForKey:@"UserName"] == nil || [userDefaults objectForKey:@"PassWord"] == nil) { //没有记录用户名或密码
        [self addLoginViewWithAnimation:NO];
        return;
    }

    NSString *username = [userDefaults valueForKey:@"UserName"];
    NSString *password = [userDefaults valueForKey:@"PassWord"];
    
    [SVProgressHUD showWithStatus:LOGINING_TIP];
    RequestTool *requestTool = [[RequestTool alloc]init];
    
    NSDictionary *dictParas = @{@"s_name":username,@"s_password":[[CommonTool md5:password] uppercaseString]};
    [requestTool requestJsonWithUrl:URL_LOGIN requestParamas:dictParas requestType:RequestTypeAsynchronous requestSucess:^(AFHTTPRequestOperation *operation, id responseDict) {
        NSLog(@"loginResponseDic===%@",responseDict);
        if (responseDict && [responseDict isKindOfClass:[NSDictionary class]] && [responseDict isKindOfClass:[NSMutableDictionary class]])
        {
            [[XSH_Application shareXshApplication] setLoginDic:responseDict];
            [[XSH_Application shareXshApplication] setShopID:[[responseDict objectForKey:@"shop_id"] intValue]];
            [[XSH_Application shareXshApplication] setUserID:[[responseDict objectForKey:@"user_id"] intValue]];
            [[XSH_Application shareXshApplication] setCarID:[[responseDict objectForKey:@"car_id"] intValue]];
            [[XSH_Application shareXshApplication] setAppName:[responseDict valueForKey:@"s_appname"]];
            [[XSH_Application shareXshApplication] setFourSServiceName:[responseDict valueForKey:@"s_4sservicename"]];
            
            //保存登录信息
            [userDefaults setValue:username forKey:@"UserName"];
            [userDefaults setValue:password forKey:@"PassWord"];
            [userDefaults setObject:[NSNumber numberWithBool:NO] forKey:@"isExit"];
            
            [SVProgressHUD showSuccessWithStatus:LOGIN_SUCCESS_TIP];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DidLogin" object:nil];
            
            NSDictionary *userInfo = @{@"activity_count":[responseDict objectForKey:@"activity_count"], @"accdention_count":[responseDict objectForKey:@"accdention_count"], @"message_count":[responseDict objectForKey:@"message_count"]};
            [[NSNotificationCenter defaultCenter] postNotificationName:@"BindReddot" object:userInfo];
        }
        else
        {
            [userDefaults setObject:[NSNumber numberWithBool:YES] forKey:@"isExit"];
            [SVProgressHUD dismiss];
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"" message:LOGIN_FAILED_MESSAGE delegate:self cancelButtonTitle:@"登录" otherButtonTitles:nil];
            [alert show];
        }
    } requestFail:^(AFHTTPRequestOperation *operation, NSError *error) {
        [userDefaults setObject:[NSNumber numberWithBool:YES] forKey:@"isExit"];
        [SVProgressHUD dismiss];
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"" message:LOGIN_FAILED_MESSAGE delegate:self cancelButtonTitle:@"登录" otherButtonTitles:nil];
        [alert show];
    }];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self addLoginViewWithAnimation:NO];
    }
}

#pragma  mark - For Notifications
- (void)bindReddot:(NSNotification *)notification {
    if (notification) {
        //显示消息小红点
        NSDictionary *userInfo = notification.object;
        
        if (userInfo) {
            NSInteger messageCount = [[userInfo objectForKey:@"message_count"] integerValue];
            
            if (messageCount > 0) {
                UIImageView *reddot = (UIImageView *)[mainTabbarViewController.tabBar viewWithTag:TAG_REDDOT];
                reddot.hidden = NO;
            }
        }
    }
}

- (void)didLogin {
    //sendToken
    NSNumber *userID = [NSNumber numberWithInt:[[XSH_Application shareXshApplication] userID]];
    RequestTool *request = [[RequestTool alloc] init];
    
    if (self.tokenString && ![self.tokenString isEqualToString:@""]) {
        NSDictionary *requestDic = @{@"user_id":userID,@"flag":[NSNumber numberWithInt:APPLICATION_PLATFORM],@"dervidetoken":self.tokenString};
        [request requestPlainWithUrl:URL_SEND_TOKEN requestParamas:requestDic requestType:RequestTypeAsynchronous
                       requestSucess:^(AFHTTPRequestOperation *operation,id responseDic)
         {
             NSLog(@"loginResponseDic===%@",responseDic);
         }
                         requestFail:^(AFHTTPRequestOperation *operation,NSError *error)
         {
             NSLog(@"error===%@",error);
         }];
    }
}

- (void)didLogout
{
    [self addLoginViewWithAnimation:YES];
}


#pragma mark - 添加登录界面
- (void)addLoginViewWithAnimation:(BOOL)animated
{
//    LoginViewController *loginViewController = [[LoginViewController alloc] init];
//    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:loginViewController];
//    [mainTabbarViewController presentViewController:nav animated:animated completion:^{
//        if(animated){
//            mainTabbarViewController.selectedIndex = 0;
//        }
//    }];
    
    LoginViewController *loginViewController = [[LoginViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc]initWithRootViewController:loginViewController];
    [mainTabbarViewController presentViewController:navController animated:animated completion:^{
        if(animated){
            mainTabbarViewController.selectedIndex = 0;
        }
    }];
    
}

#pragma mark - 添加主界面
//添加主界面
- (void)addMainView
{
    mainTabbarViewController =[[UITabBarController alloc]init];

    MeViewController *meViewController = [[MeViewController alloc]init];
    HomeViewController *homeViewController = [[HomeViewController alloc]init];
    SettingViewController *settingViewController = [[SettingViewController alloc]init];
    MessageManageViewController *messageManageViewController = [[MessageManageViewController alloc]init];
    UINavigationController *homeNavViewController = [[UINavigationController alloc]initWithRootViewController:homeViewController];
    homeNavViewController.navigationBar.hidden=YES;
    UINavigationController *messageManageNavViewController = [[UINavigationController alloc]initWithRootViewController:messageManageViewController];
    UINavigationController *settingNavViewController = [[UINavigationController alloc]initWithRootViewController:settingViewController];
    UINavigationController *meNavViewController = [[UINavigationController alloc]initWithRootViewController:meViewController];
    UIImage *image1 = [UIImage imageNamed:@"tabbar_home1"];

    UITabBarItem *homeTabBarItem = [[UITabBarItem alloc]initWithTitle:@"首页" image:image1 selectedImage:[UIImage imageNamed:@"tabbar_home1"]];
    UITabBarItem *messageManageTabBarItem = [[UITabBarItem alloc]initWithTitle:@"消息管理" image:[UIImage imageNamed:@"tabbar_message1"] selectedImage:[UIImage imageNamed:@"tabbar_message1"]];
    UITabBarItem *settingTabBarItem = [[UITabBarItem alloc]initWithTitle:@"设置" image:[UIImage imageNamed:@"tabbar_setting1"] selectedImage:[UIImage imageNamed:@"tabbar_setting1"]];
    UITabBarItem *meTabBarItem = [[UITabBarItem alloc]initWithTitle:@"我" image:[UIImage imageNamed:@"tabbar_mine1"] selectedImage:[UIImage imageNamed:@"tabbar_mine1"]];
    mainTabbarViewController.tabBar.tintColor = APP_MAIN_COLOR;
    [homeNavViewController setTabBarItem:homeTabBarItem];
    [messageManageNavViewController setTabBarItem:messageManageTabBarItem];
    [settingNavViewController setTabBarItem:settingTabBarItem];
    [meNavViewController setTabBarItem:meTabBarItem];
    mainTabbarViewController.viewControllers = [NSArray arrayWithObjects:homeNavViewController,messageManageNavViewController,settingNavViewController,meNavViewController,nil];
    self.window.rootViewController = mainTabbarViewController;
    
    //添加消息小红点
    UIImageView *reddot = [[UIImageView alloc]initWithFrame:CGRectMake(130, 6, 6, 6)];
    reddot.image = [UIImage imageNamed:@"Reddot"];
    reddot.tag = TAG_REDDOT;
    reddot.hidden = YES;
    [mainTabbarViewController.tabBar addSubview:reddot];
}

#pragma mark - APNs
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    self.tokenString = [[[[NSString stringWithFormat:@"%@",deviceToken]stringByReplacingOccurrencesOfString:@"<" withString:@""]
                         stringByReplacingOccurrencesOfString:@">" withString:@""]stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSLog(@"deviceToken: %@====tokenString=====%@", deviceToken,self.tokenString.description);
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
//    NSString *error_str = [NSString stringWithFormat: @"%@", error];
//    NSLog(@"Failed to get token, error:%@", error_str);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    application.applicationIconBadgeNumber = 0;
    
    NSDictionary *apsInfo = [userInfo objectForKey:@"aps"];
    NSString *message = [apsInfo objectForKey:@"alert"];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"推送" message:message delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil, nil];
    [alertView show];
}

#pragma mark - UMSocial
//友盟微信分享必须要实现
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    return [UMSocialSnsService handleOpenURL:url];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    //跳转支付宝钱包进行支付，需要将支付宝钱包的支付结果回传给SDK
    if ([url.host isEqualToString:@"safepay"]) {
        [[AlipaySDK defaultService]
         processOrderWithPaymentResult:url
         standbyCallback:^(NSDictionary *resultDic) {
             NSLog(@"result = %@", resultDic);
         }];
        return YES;
    }
    return [UMSocialSnsService handleOpenURL:url];
}


//#pragma mark - BMKGeneralDelegate
//- (void)onGetNetworkState:(int)iError
//{
//    if (0 == iError)
//    {
//        NSLog(@"联网成功");
//    }
//    else
//    {
//        NSLog(@"onGetNetworkState %d",iError);
//    }
//    
//}
//
//- (void)onGetPermissionState:(int)iError
//{
//    if (0 == iError)
//    {
//        NSLog(@"授权成功");
//    }
//    else
//    {
//        NSLog(@"onGetPermissionState %d",iError);
//    }
//}



- (void)applicationWillResignActive:(UIApplication *)application
{
    [BMKMapView willBackGround];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{

}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    application.applicationIconBadgeNumber = 0;
    
    [BMKMapView didForeGround];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [mapManager stop];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
