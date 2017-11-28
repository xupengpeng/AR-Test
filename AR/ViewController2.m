//
//  ViewController2.m
//  AR
//
//  Created by 徐鹏鹏 on 2017/11/15.
//  Copyright © 2017年 三网科技. All rights reserved.
//

#import "ViewController2.h"
#import <SceneKit/SceneKit.h>
#import <ARKit/ARKit.h>

#ifdef DEBUG
#define NSLog(...) printf("%f %s\n",[[NSDate date]timeIntervalSince1970],[[NSString stringWithFormat:__VA_ARGS__]UTF8String]);
#else
#define NSLog(format, ...)
#endif

@interface ViewController2 ()<ARSCNViewDelegate, ARSessionDelegate>

@property (nonatomic, strong) ARSession *session;

//ARSessionConfigutation  AR会话跟踪配置
@property (nonatomic, strong) ARConfiguration *configuration;

//ARSCNView    AR视图
@property (nonatomic, strong) ARSCNView *scnView;

//SCNNode   一个节点（模型）
@property (nonatomic, strong) SCNNode *planeNode;

@end

@implementation ViewController2

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
}

- (ARSession *)session {
    if (!_session) {
        _session = [[ARSession alloc] init];
        _session.delegate = self;
    }
    return _session;
}

//创建会话追踪配置
- (ARConfiguration *)configuration {
    if (!_configuration) {
        
        ARWorldTrackingConfiguration *worldConfiguration = [[ARWorldTrackingConfiguration alloc] init];
        //设置检测平面，不需要检测的话不用设置
        worldConfiguration.planeDetection = ARPlaneDetectionHorizontal;
        
        _configuration = worldConfiguration;
        //设置自适应灯光
        _configuration.lightEstimationEnabled = YES;
    }
    return _configuration;
}

//创建AR视图
- (ARSCNView *)scnView {

    if (!_scnView) {

        _scnView = [[ARSCNView alloc] initWithFrame:self.view.bounds];
        _scnView.backgroundColor = [UIColor darkGrayColor];
        _scnView.delegate = self;
        //指定会话
        _scnView.session = self.session;
        //自动调节灯光
        _scnView.automaticallyUpdatesLighting = YES;
        //显示状态信息
        _scnView.showsStatistics = YES;
        //设置debug选项，
        //ARSCNDebugOptionShowFeaturePoints     显示捕捉到的特征点（小黄点）
        //ARSCNDebugOptionShowWorldOrigin       显示世界坐标原点（相机位置，3D坐标系）
        _scnView.debugOptions = ARSCNDebugOptionShowFeaturePoints;
          SCNScene *scene = [SCNScene sceneNamed:@"1.scn"];
        _scnView.scene = scene;
    }
    return _scnView;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    //把AR视图添加到当前视图上
    [self.view addSubview:self.scnView];
    //运行AR会话，摄像头开始追踪现实场景
    [self.session runWithConfiguration:self.configuration];
}

- (void)addNode {
    
    //通过场景来加载3D模型文件
    SCNScene *scene = [SCNScene sceneNamed:@"art.scnassets/ship.scn"];
    
    //获取场景中的飞机节点
    SCNNode *node = scene.rootNode.childNodes[0];
    
    //设置节点的位置，单位是米 长宽高
    node.position = SCNVector3Make(0.1, 0.1, 0.1);
    //缩放
    node.scale = SCNVector3Make(0.5, 0.5, 0.5);
    self.planeNode = node;
    
    //添加到当前场景中
    [self.scnView.scene.rootNode addChildNode:node];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


//添加节点时候调用（当开启平地捕捉模式之后，如果捕捉到平地，ARKit会自动添加一个平地节点）
- (void)renderer:(id <SCNSceneRenderer>)renderer didAddNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor
{
    
    if ([anchor isMemberOfClass:[ARPlaneAnchor class]]) {
        NSLog(@"捕捉到平地");
        
        //添加一个3D平面模型，ARKit只有捕捉能力，锚点只是一个空间位置，要想更加清楚看到这个空间，我们需要给空间添加一个平地的3D模型来渲染他
        
        //1.获取捕捉到的平地锚点
        ARPlaneAnchor *planeAnchor = (ARPlaneAnchor *)anchor;
        //2.创建一个3D物体模型    （系统捕捉到的平地是一个不规则大小的长方形，这里笔者将其变成一个长方形，并且是否对平地做了一个缩放效果）
        //参数分别是长宽高和圆角
        SCNBox *plane = [SCNBox boxWithWidth:planeAnchor.extent.x*0.3 height:0 length:planeAnchor.extent.x*0.3 chamferRadius:0];
        //3.使用Material渲染3D模型（默认模型是白色的，这里笔者改成红色）
        plane.firstMaterial.diffuse.contents = [UIColor redColor];
        
        //4.创建一个基于3D物体模型的节点
        SCNNode *planeNode = [SCNNode nodeWithGeometry:plane];
        //5.设置节点的位置为捕捉到的平地的锚点的中心位置  SceneKit框架中节点的位置position是一个基于3D坐标系的矢量坐标SCNVector3Make
        planeNode.position =SCNVector3Make(planeAnchor.center.x, 0, planeAnchor.center.z);
        
        //self.planeNode = planeNode;
        [node addChildNode:planeNode];
        
        
        //2.当捕捉到平地时，2s之后开始在平地上添加一个3D模型
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            //1.创建一个花瓶场景
            SCNScene *scene = [SCNScene sceneNamed:@"art.scnassets/ship.scn"];
            //2.获取花瓶节点（一个场景会有多个节点，此处我们只写，花瓶节点则默认是场景子节点的第一个）
            //所有的场景有且只有一个根节点，其他所有节点都是根节点的子节点
            SCNNode *vaseNode = scene.rootNode.childNodes[0];
            
            //4.设置花瓶节点的位置为捕捉到的平地的位置，如果不设置，则默认为原点位置，也就是相机位置
            vaseNode.position = SCNVector3Make(planeAnchor.center.x, 0, planeAnchor.center.z);
            vaseNode.scale = SCNVector3Make(0.02, 0.02, 0.02);
            
            
            //5.将花瓶节点添加到当前屏幕中
            //!!!此处一定要注意：花瓶节点是添加到代理捕捉到的节点中，而不是AR试图的根节点。因为捕捉到的平地锚点是一个本地坐标系，而不是世界坐标系
            [node addChildNode:vaseNode];
        });
    }
}

// ------------------

- (nullable SCNNode *)renderer:(id <SCNSceneRenderer>)renderer nodeForAnchor:(ARAnchor *)anchor
{
    SCNNode *node = [[SCNNode alloc] init];
    return node;
    
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
