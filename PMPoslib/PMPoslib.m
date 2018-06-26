//
//  CreditCardListViewController.m
//  PMPos
//
//  Created by lyg on 16/7/26.
//  Copyright © 2016年 Vbill Payment Co., Ltd. All rights reserved.
//

#import "CreditCardListViewController.h"
#import "CreditCardTableViewCell.h"
#import "BindCreditModel.h"
#import "JGPopView.h"
@interface CreditCardListViewController ()<UITableViewDelegate,UITableViewDataSource>
{
    UITableView             *_tableView;
    UIButton                *_addCardBtn;
    NSMutableArray          *bindListArray;
    UIView                  *downView;
}
@end

@implementation CreditCardListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setTitle:@"信用卡认证"];
    [self initLayout];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(commmitNotification) name:Refresh_CreditCard_List object:nil];

}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [self set_RightBackButtonWith:[UIImage imageNamed:@"tianjia_blue"]];
    [self getBindCreditList];
    [UserDefaults setObject:@"" forKey:@"bankName"];
    [UserDefaults synchronize];
}
- (void)initLayout {
    
    bindListArray = [[NSMutableArray alloc] init];
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.tableFooterView = [[UIView alloc] init];
    [self.view addSubview:_tableView];
    __weak typeof(self)weakSelf = self;
    [_tableView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(weakSelf.view);
    }];
    
    
}

#pragma mark 左边按钮返回事件
- (void)navigationLeftButtonAction:(UIButton *)sender
{
    if (_gotoSwipeCardBlock) {
        _gotoSwipeCardBlock(YES);
        return;
    }
    [super navigationLeftButtonAction:sender];
}

#pragma mark 右边导航栏按钮的点击触发事件
- (void)navigationRightButtonAction:(UIButton *)sender
{
    [self touchActionOfNavigationRightButtonAction:sender];
}

- (void)touchActionOfNavigationRightButtonAction:(UIButton *)sender
{
    sender.selected = !sender.selected;
    if (sender.selected) {//选中后
        CGPoint point;
        //转换屏幕坐标
        UIWindow * window=[[[UIApplication sharedApplication] delegate] window];
        CGRect rect=[sender convertRect: sender.bounds toView:window];
        point = CGPointMake(rect.origin.x+rect.size.width/2.0, SAFE_AREA_STATUS+SAFE_AREA_NAVI);
        
        JGPopView *popView = [[JGPopView alloc] initWithOrigin:point Width:162 Height:50 * 2 Type:JGTypeOfUpRight Color:RGB(57, 56, 58)];
        popView.dataArray = @[@"添加我的信用卡",@"添加常用信用卡"];
        
        popView.fontSize = 15;
        popView.row_height = 50;
        popView.titleTextColor = [UIColor whiteColor];
        __weak typeof(UIButton *)weakSender = sender;
        popView.dismissHandle = ^{
            weakSender.selected = NO;
        };
        popView.delegate = self;
        [popView popView];
    }
}

#pragma mark selectIndexPathDelegate
- (void)selectIndexPathRow:(NSInteger )index
{

    if (0 == index) {//添加我的信用卡
        UIViewController *vc = YwwQueckVC(@"WTCameraViewController");
        YwwQueckKVC(vc, @"isOwenBankCard", @(1));
        YwwQueckPush(vc);
    }else if (1== index){//点击添加常用信用卡，需要先判断是否有我的卡
        if (!bindListArray || bindListArray.count == 0) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"只有认证了“我的信用卡”\r\n 才可以认证“常用信用卡”" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alert show];
        }else{
            UIViewController *vc = YwwQueckVC(@"WTCameraViewController");
            YwwQueckKVC(vc, @"isOwenBankCard", @(0));
            YwwQueckPush(vc);
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    UIViewController *vc = YwwQueckVC(@"WTCameraViewController");
    YwwQueckKVC(vc, @"isOwenBankCard", @(1));
    YwwQueckPush(vc);
}


/**
 *  获取绑定的信用卡 卡片达到10张 隐藏添加卡片的按钮
 */
- (void)getBindCreditList { // 如果信用卡数为0  直接进入下个页面
    
    NSMutableDictionary *paramters = [[NSMutableDictionary alloc]init];
    [paramters setObject:MCode_Bind_Credit_CardList forKey:@"TRDE_CODE"];
    [paramters setObject:[UserLoginStatus getInMno] forKey:@"mno"];
    [paramters setObject:[UserLoginStatus getTokenValue] forKey:@"TOKEN_ID"];
    
    /**2.1.5对原有接口改造,需要区别是不是无卡支付的卡*/
    [paramters setObject:@"01" forKey:@"type"];
    
    [self startSpinner];
    
    [AFOSClient AFOSClientHost:kRootUrl parameters:paramters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self stopSpinner];
        
        NSError *error;
        id jsonObj=[NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:&error];
        if (!jsonObj||error) {
            [MyCommonUtilty showAlertView:@"请检查用户名密码是否正确!"];
            return;
        }
        MyNSLog(@"result %@",jsonObj);
        NSString *RETURNCODE = [MyCommonUtilty getReturnCodeOrRETRUNCODE:jsonObj[@"returnCode"] CODE:jsonObj[@"RETURNCODE"]];
        if ([RETURNCODE isEqualToString:CODE_SUCCESS]) {
            NSArray *bindList = jsonObj[@"bindList"];
            if (bindList.count > 0) {//如果用户名下有卡，并且有我的卡，则
                [bindListArray removeAllObjects]; // 先清空原有的数据
                for (NSDictionary *dic in bindList) {
                    BindCreditModel *model = [[BindCreditModel alloc] init];
                    [model setValuesForKeysWithDictionary:dic];
                    [bindListArray addObject:model];
                }
                [self showNodataViewWith:YES];
                [_tableView reloadData];
            }else{
                [bindListArray removeAllObjects]; // 先清空原有的数据
                [_tableView reloadData];
                [self showNodataViewWith:NO];
            }
        }else {
            [AppDelegate viewModelAlertWith:nil andTitle:nil andMassge:jsonObj[@"RETURNCON"] andCompletion:nil andCancleButton:@"确定" andOtherButtons:nil];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self stopSpinner];
        [MyCommonUtilty showAlertView:error.localizedDescription];
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - TableView Delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return bindListArray.count;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    BindCreditModel *model = bindListArray[indexPath.row];
    CGFloat height = model.showCancel?(kVariableHeight+45+20):(kVariableHeight+20);
    return height;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CreditCardTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell_credit"];
    
    if (!cell) {
        cell = [[CreditCardTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell_credit"];
    }
    
    if (bindListArray.count > 0) {
        BindCreditModel *model = bindListArray[indexPath.row];
        [cell setData:model];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

#pragma mark 刷新数据
- (void)CreditCardShouldReloadViewWithIndex:(BindCreditModel *)cellModel
{
    if (!cellModel) {//点击取消
        for (BindCreditModel *model in bindListArray) {
            if (model.showCancel) {
                model.showCancel = NO;
                NSInteger index = [bindListArray indexOfObject:model];
                [self reloadCellAtIndex:index];
            }
        }
        return;
    }
    for (BindCreditModel *model in bindListArray) {
        if (model.showCancel &&model!=cellModel) {
            model.showCancel = NO;
            NSInteger index = [bindListArray indexOfObject:model];
            [self reloadCellAtIndex:index];
            cellModel.showCancel = YES;
            NSInteger newIndex = [bindListArray indexOfObject:cellModel];
            [self reloadCellAtIndex:newIndex];
            return;
        }else if (model.showCancel && model ==cellModel){
            model.showCancel = NO;
            NSInteger index = [bindListArray indexOfObject:model];
            [self reloadCellAtIndex:index];
            return;
        }
    }
    cellModel.showCancel = YES;
    NSInteger newIndex = [bindListArray indexOfObject:cellModel];
    [self reloadCellAtIndex:newIndex];
    
}
#pragma mark 上传服务器删除某一条数据
- (void)userCancellCreditCardWith:(BindCreditModel *)cellModel
{
    NSMutableDictionary *params = [NSMutableDictionary new];
    params[@"TRDE_CODE"] = @"M814";
    if (cellModel.isQuick.length>0) {
        params[@"isQuick"] = cellModel.isQuick;
    }
    [params setObject:@"ios" forKey:@"MOBILESYSTEM"];
    [params setObject:[MyCommonUtilty getAppVersion] forKey:@"VERSION"];
    [params setObject:@"mposApp" forKey:@"MPOSTYPE"];
    [params setObject:[UserLoginStatus getTokenValue] forKey:@"TOKEN_ID"];
    
    params[@"inMno"] = [UserLoginStatus getInMno];
    params[@"cardNo"] = cellModel.actNo;
    YWWWeakSelf(self);
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"正在加载...";
    hud.mode = MBProgressHUDModeText;
    [URLCenter URLHost:kRootUrl andParams:params withCompletionHandle:^(NSURLResponse *response, id responseObject, NSError *error) {
        
        //神策   信用卡解绑
        
        [AppDelegate SensorsAnalyticsTrack:SA_UnbundCreditCard withProperties:^NSDictionary *{
            NSMutableDictionary *mutableDic = [NSMutableDictionary new];
            [mutableDic setUnNullObject:@"信用卡列表页面" forKey:SA_item_entry];
            [mutableDic setUnNullObject:cellModel.actNo forKey:SA_item_bankCardNum];
            [mutableDic setUnNullObject:[cellModel.bindType isEqualToString:@"01"]?@(YES):@(NO) forKey:SA_item_belong];
            [mutableDic setUnNullObject:@(URLCenter_SensorsAnalyticsCheck(response, responseObject, error)) forKey:SA_item_isSuccess];
            [mutableDic setUnNullObject:URLCenter_SensorsAnalytics_error(response, responseObject, error) forKey:SA_item_failCause];
            return [NSDictionary dictionaryWithDictionary:mutableDic];
        }];
        
        [hud hide:YES];
        if (!RequsesSesess(URLRequestSecsess(error), URL_error_block,error)) return ;
        if (!ResponseObjectExist(URLResponseObjectExist(responseObject), URL_error_block)) return;
        if (![NSObject viewModelShouldCheckBody:responseObject andError:error]) return;
        [AppDelegate viewModelAlertWith:nil andTitle:nil andMassge:[responseObject objectForKey:@"msg"] andCompletion:^(NSInteger index) {
            [weakself getBindCreditList];//从新刷新数据
        } andCancleButton:@"确定" andOtherButtons:nil];
        
    }];
}
- (void)reloadCellAtIndex:(NSInteger)index
{
    NSIndexPath *path = [NSIndexPath indexPathForRow:index inSection:0];
    [_tableView reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark 懒加载

- (void)showNodataViewWith:(BOOL)hasData
{
    if (!hasData) {
        [self.view addSubview:self.errorShowView];
        [self.view addSubview:self.errorTitle];
        [self.view addSubview:self.errorString];
        YWWWeakSelf(self);
        UIImage *img = [SuperImage imageNamed:@"meiyouka"];
        [self.errorShowView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@(45));
            make.centerX.equalTo(weakself.view);
            make.size.mas_equalTo(img.size);
        }];
        [self.errorTitle mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(weakself.errorShowView.mas_bottom).offset(15);
            make.centerX.equalTo(weakself.view);
            make.height.equalTo(15);
            make.width.greaterThanOrEqualTo(@(20));
        }];
        [self.errorString mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(weakself.errorTitle.mas_bottom).offset(7);
            make.centerX.equalTo(weakself.view);
            make.height.equalTo(12);
            make.width.greaterThanOrEqualTo(@(20));
        }];
        self.errorShowView.hidden = hasData;
        self.errorTitle.hidden = hasData;
        self.errorString.hidden = hasData;
    }else{
        [self.errorShowView removeFromSuperview];
        [self.errorTitle removeFromSuperview];
        [self.errorString removeFromSuperview];
    }
}

-(UIImageView *)errorShowView
{
    if (!_errorShowView) {
        _errorShowView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _errorShowView.image = [SuperImage imageNamed:@"meiyouka"];
    }
    return _errorShowView;
}

- (UILabel *)errorTitle
{
    if (!_errorTitle) {
        _errorTitle = [[UILabel alloc] initWithFrame:CGRectZero];
        _errorTitle.font = YwwFont(15);
        _errorTitle.textAlignment = NSTextAlignmentCenter;
        _errorTitle.textColor = HEXCOLOR(0x333333);
        _errorTitle.text = @"还未添加信用卡";
    }
    return _errorTitle;
}

- (UILabel *)errorString
{
    if (!_errorString) {
        _errorString = [[UILabel alloc] initWithFrame:CGRectZero];
        _errorString.font = YwwFont(12);
        _errorString.textAlignment = NSTextAlignmentCenter;
        _errorString.textColor = HEXCOLOR(0x86919d);
        _errorString.text = @"请添加右上角“+”添加我的信用卡";
    }
    return _errorString;
}

/**
 *  执行通知－－刷新信用卡列表
 */
- (void)commmitNotification {
    [[NSNotificationCenter defaultCenter]removeObserver:self name:Refresh_CreditCard_List object:nil];
    [self getBindCreditList];
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:Refresh_CreditCard_List object:nil];
}


@end
