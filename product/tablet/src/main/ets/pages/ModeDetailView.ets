/*
 * Copyright (c) Huawei Device Co., Ltd. 2024-2025. All rights reserved.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import curves from '@ohos.curves';
import { ArrayList } from '@kit.ArkTS';
import { WindowDirection } from '@ohos/common/src/main/ets/utils/WindowDirection';
import { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import lazy { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import lazy { EventBus } from '@ohos/common/src/main/ets/worker/eventbus/EventBus';
import lazy { EventBusManager } from '@ohos/common/src/main/ets/worker/eventbus/EventBusManager';
import display from '@ohos.display';
import { CustomTransition } from '@ohos/common/src/main/ets/animation/CustomNavigationUtils';
import { AnimSpecifications } from '@ohos/common/src/main/ets/animation/AnimSpecifications';
import {
  NavDestinationTitle,
  NAV_DESTINATION_TITLE_HEIGHT
} from '@ohos/common/src/main/ets/component/NavDestinationTitle/NavDestinationTitle';
import { BaseComponent } from '@ohos/common/src/main/ets/worker/BaseComponent';
import { DisplayService } from '@ohos/common/src/main/ets/service/UIAdaptive/DisplayService';
import { WindowActionType } from '@ohos/common/src/main/ets/redux/actions/WindowActionType';

interface MorePageType {
  gridModeType: ModeType[],
  barModeType: ModeType[]
}

const morePageDefaultData: MorePageType = {
  gridModeType: [],
  barModeType: [ModeType.PHOTO, ModeType.VIDEO]
};

const TAG: string = 'ModeDetailView';

const SPACE_CARDS: number = 16;

const PADDING_VERTICAL_LEFT_RIGHT: number = 32;
const TOP_HOLE: number = 36;
const GUTTER_LIST: number = 16;

const ANIMATION_DURATION_IN: number = 200;
const ANIMATION_DURATION_OUT: number = 150;
const ANIMATION_DURATION_840: number = 840;
const ANIMATION_DURATION_420: number = 420;
const ANIMATION_VELOCITY: number = 1;
const ANIMATION_MASS: number = 1;
const ANIMATION_STIFFNESS: number = 328;
const ANIMATION_DAMPING: number = 36;

@Component
export struct ModeDetailView {
  private mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  private pageId: number = 0;
  private currIndex: number = 0;
  private isInitialized: boolean = false;
  private lastRotateAngle: number = 0;
  private defaultHorizontalCardWidth: number = 546;
  private supportedModeTypes: ModeType[] = [];
  private displayOrder: ModeType[] = [];
  private displayInfo: display.Display = DisplayService.getInstance().getDisplay();
  @State isBackgroundBlurred: ArrayList<boolean> = new ArrayList<boolean>();
  @State isCoverPagePresent: ArrayList<boolean> = new ArrayList<boolean>();
  @State windowWidth: number = 0;
  @State windowHeight: number = 0;
  @State geoID: string = '';
  @State isShowDefault: boolean = false;
  @State isShowLandscape: boolean = false;
  @State isShowSemiCollapsed: boolean = false;
  @State mDirection: WindowDirection = WindowDirection.TOP;
  @State @Watch('rotateChange') rotateAngle: number = 0;
  @State rotateAngleDuration: number = 420;
  @State isShowCancelButton: boolean = false;
  @State isShowDetailedContent: boolean = false;
  @StorageLink('isDetailCardMoreButtonClicked') isDetailCardMoreButtonClicked: boolean = false;
  @Consume('pageInfos') pageInfos: NavPathStack;
  private mBase: BaseComponent = new BaseComponent();

  aboutToAppear(): void {
    HiLog.i(TAG, 'aboutToAppear begin.');
    this.mEventBus.on(WindowActionType.REFRESH_UX, () => this.uxInit(), this.mBase.hashCode());
    this.windowWidth = px2vp(this.displayInfo.width);
    this.windowHeight = px2vp(this.displayInfo.height);
    this.init();
    this.pageId = this.pageInfos.getAllPathName().length - 1;
    HiLog.i(TAG, 'pageId' + this.pageId);
    this.initCustomizedTransitionAnim();
    HiLog.i(TAG, 'aboutToAppear end.');
  }

  aboutToDisappear(): void {
    this.mEventBus.clear(this.mBase.hashCode());
  }

  private init(): void {
    this.supportedModeTypes = morePageDefaultData.barModeType.concat(morePageDefaultData.gridModeType);
    this.isInitialized = true;
  }

  private uxInit(): void {
    this.windowWidth = px2vp(this.displayInfo.width);
    this.windowHeight = px2vp(this.displayInfo.height);
  }

  private initCustomizedTransitionAnim(): void {

  }

  private rotateChange(): void {
    HiLog.i(TAG, 'rotateChange begins.');
    if ((this.rotateAngle - this.lastRotateAngle) % AnimSpecifications.ANIM_ROTATE_180 === 0) {
      this.rotateAngleDuration = ANIMATION_DURATION_840;
    } else {
      this.rotateAngleDuration = ANIMATION_DURATION_420;
    }
    this.lastRotateAngle = this.rotateAngle;
    HiLog.i(TAG, 'rotateChange ends.');
  }

  private isVertical(): boolean {
    return this.windowWidth < this.windowHeight;
  }

  private getDescriptionCardSize(): number {
    return 360;
  }

  private getDetailCardWidth(): number {
    return 480;
  }

  private getDetailCardHeight(): number {
    return 560;
  }

  private getListSpace(): number {
    return SPACE_CARDS;
  }

  private getListDirection(): Axis {
    return Axis.Vertical;
  }

  private getListItemMarginBottom(index: number): number {
    if (this.supportedModeTypes.length === 0) {
      return 0;
    }
    if (this.supportedModeTypes.length % 2 === 0) {
      return index === this.supportedModeTypes.length - 1 || index === this.supportedModeTypes.length - 2 ?
        SPACE_CARDS : 0;
    } else {
      return index === this.supportedModeTypes.length - 1 ? SPACE_CARDS : 0;
    }
  }

  private getListPaddingLeftRight(): number {
    return (this.windowWidth - GUTTER_LIST - 2 * this.getDescriptionCardSize()) / 2;
  }

  private getAlignListItem(): ListItemAlign {
    return ListItemAlign.Center;
  }

  private getListHeight(): number {
    return this.windowHeight - NAV_DESTINATION_TITLE_HEIGHT - TOP_HOLE;
  }

  private getPageTop(): number {
    return TOP_HOLE;
  }

  @Builder
  DetailCardCover(mode: ModeType, index: number) {
    Column() {
    }
    .size({ width: '100%', height: '100%' })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onAppear((): void => {
      animateTo({ duration: 100, curve: Curve.Sharp }, () => {
        this.isBackgroundBlurred[index] = true;
      });
      animateTo({ duration: 100, curve: Curve.Sharp }, () => {
        this.isShowCancelButton = true;
      });
      animateTo({ duration: 150, delay: 50, curve: Curve.Sharp }, () => {
        this.isShowDetailedContent = true;
      });
    })
    .transition(TransitionEffect.opacity(0.99))
    .backgroundColor(this.isBackgroundBlurred[index] ? $r('sys.color.ohos_id_color_mask_regular_dark') : Color.Transparent)
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Up) {
        animateTo({ duration: 100, curve: Curve.Sharp }, () => {
          this.isBackgroundBlurred[index] = false;
        });
        animateTo({ duration: 100, curve: Curve.Sharp }, () => {
          this.isShowCancelButton = false;
        });
        animateTo({ duration: 150, curve: Curve.Sharp }, () => {
          this.isShowDetailedContent = false;
        });
        animateTo({
          duration: ANIMATION_DURATION_OUT,
          curve: curves.interpolatingSpring(ANIMATION_VELOCITY, ANIMATION_MASS, ANIMATION_STIFFNESS, ANIMATION_DAMPING)
        },
          () => {
            this.isCoverPagePresent[index] = false;
          })
      }
    })
  }

  @Builder
  DescriptionCard(mode: ModeType, index: number) {
    ListItem() {
    }
    .margin({
      bottom: this.getListItemMarginBottom(index)
    })
    .bindContentCover(this.isCoverPagePresent[index], this.DetailCardCover(mode, index), ModalTransition.NONE)
    .geometryTransition(index.toString(), { follow: true })
    .onClick((): void => {
      this.currIndex = index;
      animateTo({
        duration: ANIMATION_DURATION_IN,
        curve: curves.interpolatingSpring(ANIMATION_VELOCITY, ANIMATION_MASS, ANIMATION_STIFFNESS, ANIMATION_DAMPING),
      }, () => {
        this.isCoverPagePresent[index] = true;
      })
    })
  }

  @Builder
  listView() {
    List({ space: this.getListSpace() }) {
      ForEach(this.displayOrder, (item: ModeType, index: number) => {
        this.DescriptionCard(item, index);
      }, (item: Resource, index: number) => index.toString())
    }
    .size({ width: '100%', height: this.getListHeight() })
    .scrollBar(BarState.Off)
    .alignListItem(this.getAlignListItem())
    .padding({
      top: 8,
      left: this.getListPaddingLeftRight(),
      right: this.getListPaddingLeftRight()
    })
    .listDirection(this.getListDirection())
    .lanes(2, SPACE_CARDS)
  }

  @Builder
  title() {
    NavDestinationTitle({
      titleText: $r('app.string.details'),
      mDirection: this.mDirection,
      isShowLandscape: this.isShowLandscape,
      isShowSemiCollapsed: this.isShowSemiCollapsed,
      isTablet: false,
      clickFunction: () => {
        this.pageInfos?.pop();
      }
    })
  }

  build() {
    NavDestination() {
      this.listView();
    }
    .width(this.windowWidth)
    .height(this.windowHeight)
    .backgroundColor(Color.Black)
    .padding({ top: this.getPageTop() })
    .rotate({ angle: this.rotateAngle })
    .title(this.title())
    .animation(
      {
        duration: this.rotateAngleDuration,
        curve: Curve.Friction,
        iterations: 1,
        playMode: PlayMode.Normal
      })
    .onBackPressed((): boolean => {
      HiLog.i(TAG, 'Back button was pressed.');
      this.pageInfos?.pop();
      return true;
    })
    .onDisAppear((): void => {
      CustomTransition.getInstance().unRegisterNavParam(this.pageId);
    })
  }
}