//
//  HBSegmentContentView.m
//  HBTabView
//
//  Created by DylanHu on 2016/6/21.
//  Copyright © 2016年 DylanHu. All rights reserved.
//

#import "HBSegmentContentView.h"

static NSString * const reusedIdentifier = @"hb_segment_content_cell";

@interface HBSegmentContentView () <UICollectionViewDelegate,UICollectionViewDataSource>
/// 内容展示，这里使用CollectionView
@property (nonatomic, strong) HBCollectionView *collectionView;
/// 存储显示View的容器
@property (nonatomic, strong) NSMutableArray <UIViewController *> *containers;
/// UICollectionView布局，这里使用流式布局
@property (nonatomic, strong) UICollectionViewFlowLayout *flowLayout;
/// UICollectionView起始拖拽Offset
@property (nonatomic, assign) CGPoint startDragingOffset;
/// UICollectionCell当前索引(indexPath.row)
@property (nonatomic, assign) NSInteger currentIndex;
/// UICollectionCell前一个索引(indexPath.row)
@property (nonatomic, assign) NSInteger preIndex;
@property (nonatomic, assign) HBTabViewShowType showType;

@end

@implementation HBSegmentContentView

#pragma mark - Properties
- (NSMutableArray<UIViewController *> *)containers {
    if (!_containers) {
        _containers = @[].mutableCopy;
    }
    return _containers;
}

- (UICollectionViewFlowLayout *)flowLayout {
    if (!_flowLayout) {
        _flowLayout = [[UICollectionViewFlowLayout alloc] init];
        _flowLayout.minimumLineSpacing = 0.0;
        _flowLayout.minimumInteritemSpacing = 0.0;
    }
    return _flowLayout;
}

#pragma mark - 初始化方法
- (instancetype)initWithFrame:(CGRect)frame showType:(HBTabViewShowType)showType{
    if (self = [super initWithFrame:frame]) {
        self.showType = showType;
        [self _commonInit];
    }
    return self;
}

- (void)_commonInit {
    if (self.showType == HBTabViewShowTypeVertical) {
        self.flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    } else {
        self.flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    }
    self.backgroundColor = [UIColor whiteColor];
    _collectionView = [[HBCollectionView alloc] initWithFrame:self.bounds collectionViewLayout:self.flowLayout];
    _collectionView.backgroundColor = [UIColor whiteColor];
    [self addSubview:_collectionView];
    _collectionView.bounces = NO;
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    _collectionView.pagingEnabled = YES;
    self.flowLayout.itemSize = _collectionView.bounds.size;
    [_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reusedIdentifier];
    __weak typeof(self) weakSelf = self;
    _collectionView.panGestureShouldBeginBlock = ^BOOL(UICollectionView *collectionView, UIPanGestureRecognizer *panGesture) {
        CGFloat transionX = [panGesture translationInView:panGesture.view].x;
        BOOL canPop = NO;
        if (collectionView.contentOffset.x == 0 && transionX > 0) {
            canPop = YES;
        }
        !weakSelf.segmentContentViewPanGestureBlock ?: weakSelf.segmentContentViewPanGestureBlock(canPop);
        return YES;
    };
}

#pragma mark 添加单个控制器
- (void)addContainerViewWithViewController:(UIViewController *)viewController {
    [self.containers addObject:viewController];
}

#pragma mark 添加批量控制器
- (void)addContainerViewsWithViewControllers:(NSArray <UIViewController *> *)viewControllers {
    [self.containers addObjectsFromArray:viewControllers];
}

- (void)reloadData {
    [self.collectionView reloadData];
}

#pragma mark - UICollectionViewDataSource方法
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reusedIdentifier forIndexPath:indexPath];
    [cell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self setContainerViewForCell:cell atIndexPath:indexPath];
    return  cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.containers.count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

#pragma mark - UIScrollViewDelegate方法
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    NSInteger index = targetContentOffset -> x / self.bounds.size.width;
    if (self.showType == HBTabViewShowTypeVertical) {
        index = targetContentOffset -> y / self.bounds.size.height;
    }
    self.preIndex = self.currentIndex;
    self.currentIndex = index;

    !self.segmentContentViewDidEndDragingBlock ?: self.segmentContentViewDidEndDragingBlock(self.currentIndex);

//    NSLog(@"contentSize : %@ contentOffset : %@\n currentIndex: %zd",NSStringFromCGSize(scrollView.contentSize),NSStringFromCGPoint(scrollView.contentOffset),self.currentIndex);
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.startDragingOffset = scrollView.contentOffset;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    CGFloat tempProgress = scrollView.contentOffset.x / self.bounds.size.width;
    CGFloat moveDistance = scrollView.contentOffset.x - self.startDragingOffset.x;
    if (self.showType == HBTabViewShowTypeVertical) {
        tempProgress = scrollView.contentOffset.y / self.bounds.size.height;
        moveDistance = scrollView.contentOffset.y - self.startDragingOffset.y;
    }
    CGFloat progress = tempProgress - floorf(tempProgress);
    NSInteger tempIndex = tempProgress;

    
    if (moveDistance > 0) { // 向左或向上滑动
        if (progress == 0.0) {
            return;
        }
        self.currentIndex = tempIndex + 1;
        self.preIndex = tempIndex;
    } else if (moveDistance < 0) {
        progress = 1.0 - progress;
        self.currentIndex = tempIndex;
        self.preIndex = tempIndex + 1;
    }
    
    !self.segmentContentViewDidScrollBlock ?: self.segmentContentViewDidScrollBlock(scrollView,self.preIndex,self.currentIndex,progress);
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    NSInteger currentIndex = (scrollView.contentOffset.x / self.bounds.size.width);
    if (self.showType == HBTabViewShowTypeVertical) {
        currentIndex = scrollView.contentOffset.y / self.bounds.size.height;
    }
    
    !self.segmentContentViewDidEndDeceleratingBlock ?: self.segmentContentViewDidEndDeceleratingBlock(currentIndex);
}

#pragma mark - UICollectionViewDelegate方法
- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger index = collectionView.contentOffset.x / self.bounds.size.width;
    if (self.showType == HBTabViewShowTypeVertical) {
        index = collectionView.contentOffset.y / self.bounds.size.height;
    }
    
//    NSLog(@"contentOffset : %@\n currentIndex: %zd",NSStringFromCGPoint(collectionView.contentOffset),index);
//    if (self.collectionViewDidEndDisplayingCellBlock) {
//        self.collectionViewDidEndDisplayingCellBlock(index);
//    }
}

#pragma mark 滚到标签对应索引页面
- (void)scrollToPageWithIndex:(NSInteger)index {
    if (self.showType == HBTabViewShowTypeVertical) {
        [self.collectionView setContentOffset:CGPointMake(0, index * self.bounds.size.height) animated:NO];
    } else {
        [self.collectionView setContentOffset:CGPointMake(index * self.bounds.size.width, 0) animated:NO];
    }
}

#pragma mark 设置cell内容
- (void)setContainerViewForCell:(UICollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    if (self.containers.count) {
        UIViewController *containerVC = self.containers[indexPath.row];
        [cell.contentView addSubview:containerVC.view];
        containerVC.view.frame = cell.contentView.bounds;
    }
}

- (void)removeAllContainerViews {
    [self.containers enumerateObjectsUsingBlock:^(UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj.view removeFromSuperview];
        [obj removeFromParentViewController];
    }];
    [self.containers removeAllObjects];
    self.containers = nil;
    [self.collectionView reloadData];
}

@end

@interface HBCollectionView ()

@end

@implementation HBCollectionView

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (self.panGestureShouldBeginBlock && gestureRecognizer == self.panGestureRecognizer) {
        return self.panGestureShouldBeginBlock(self,self.panGestureRecognizer);
    }
    return [super gestureRecognizerShouldBegin:gestureRecognizer];
}

@end


