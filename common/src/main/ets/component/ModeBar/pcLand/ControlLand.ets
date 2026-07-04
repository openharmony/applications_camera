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

import lazy { camera } from '@kit.CameraKit';
import lazy { CameraAction, CameraStartType } from '../../../camera/uithread/CameraAction';
import lazy { ModeListManager } from '../../../mode/ModeListManager';
import lazy { ChangeState, Dispatch, OhCombinedState, reduxSubscribe, Unsubscribe } from '../../../redux';
import lazy { CameraActionType } from '../../../redux/actions/CameraActionType';
import lazy { PersistType, PreferencesService } from '../../../service/preferences/PreferencesService';
import lazy { CommonConstants } from '../../../statistics/CommonConstants';
import lazy { BlurAnimateUtil } from '../../../utils/BlurAnimateUtil';
import lazy { ComponentIdKeys } from '../../../utils/ComponentIdKeys';
import lazy { GlobalContext } from '../../../utils/GlobalContext';
import lazy { BaseComponent } from '../../../worker/BaseComponent';
import lazy { EventBus } from '../../../worker/eventbus/EventBus';
import lazy { EventBusManager } from '../../../worker/eventbus/EventBusManager';
import lazy { curves } from '@kit.ArkUI';
import lazy { VibratorService } from '../../vibration/VibratorService';
import lazy { ModeType } from '../../../../ets/mode/ModeType';
import lazy { HiLog } from '../../../../ets/utils/HiLog';
import lazy { ActionType } from '../../../../ets/redux/actions/ActionType';
import lazy { Action } from '../../../../ets/redux/actions/Action';
import lazy { SwipeChangeNumberData } from '../../../../ets/utils/types';
import lazy { PropTag } from '../../../service/preferences/PropTag';
import lazy { SystemLanguageUtil } from '../../../utils/SystemLanguageUtil';


const TAG: string = 'ControlLand';
const MODE_LIST_MARGIN_TOP: number = 20;

class StateStruct {
  public isThirdPartyCall: boolean = false;
  public cameraPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_FRONT;
}

class ModeBarDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public changeToMode(oldMode: ModeType, newMode: ModeType): void {
    AppStorage.setOrCreate('startOrUserChangeToModeLast', [oldMode, newMode]);
    this.mDispatch(CameraAction.changeMode(newMode));
    this.mDispatch(Action.updateXComponentShot(oldMode, newMode)); // 向底层下发模式切换消息在截图完成后执行
    this.mDispatch(Action.updateShowBigTextFlag(true));
  }

  public changeModePlaySound(): void {
    this.mDispatch(Action.changeModePlaySound());
  }

  public thirdPartyCall(isThirdPartyCall: boolean, action?: string): void {
    this.mDispatch(Action.thirdPartyCall(isThirdPartyCall, action));
  }
}

class CameraStartTypeStruct {
  public type: CameraStartType = CameraStartType.COLD_START;
}

/**
 * 模式显示栏组件: ControlLand
 * */
@Component
export struct ControlLand {
  private mBase: BaseComponent = new BaseComponent();
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  mEventBus: EventBus = EventBusManager.getInstance().getEventBus();
  @State state: StateStruct = new StateStruct();
  @State modeList: ModeType[] = [];
  private action: ModeBarDispatcher = new ModeBarDispatcher();
  protected mPreferencesService: PreferencesService = PreferencesService.getInstance();
  protected modeListManager: ModeListManager = ModeListManager.getInstance();
  @State modeItemWidth: number = 54;
  private readonly modeBarHeight: number = 56;
  private readonly modeListHeight: number = 16;
  private scroller: Scroller = new Scroller();
  @StorageLink('fontSizeScale') fontSizeScale: number = 1;
  @State mode: ModeType = ModeType.NONE;
  @State uiEnable: boolean = false;
  @State currentShowModeIndex: number = 0; // 用于组件显示的Index

  aboutToAppear(): void {
    HiLog.i(TAG, 'aboutToAppear E.');
    this.mSubscriber = reduxSubscribe((state: OhCombinedState, changeState: ChangeState<StateStruct>) => {
      changeState(this.state, {
        isThirdPartyCall: state.get<boolean>('contextReducer', 'isThirdPartyCall'),
        cameraPosition: state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition'),
      });
      this.uiEnable = state.get<boolean>('contextReducer', 'uiEnable');
      this.mode = state.get<ModeType>('modeReducer', 'mode');
    }, (dispatch: Dispatch): void => {
      this.action.setDispatch(dispatch);
    });
    let startWantAction: string | undefined = GlobalContext.get().getCameraAbilityWant().action;
    let startWant = GlobalContext.get().getCameraAbilityWant();
    HiLog.i(TAG, `Camera MainAbility lanuchWant action: ${startWantAction}.`);
    if (!!startWant.parameters?.callBundleName) {
      HiLog.i(TAG, 'thirdParty called.');
      this.action.thirdPartyCall(true, startWantAction);
    } else if (startWant.parameters?.callBundleName === undefined) {
      this.action.thirdPartyCall(false);
    }
    this.modeList = this.modeListManager.getModeList();
    this.currentShowModeIndex = this.modeList.indexOf(this.mode);
    this.mEventBus.on(ActionType.ACTION_SWIPE_CHANGE_MODE, this.onSwipeChangeMode.bind(this), this.mBase.hashCode());
    this.mEventBus.on(CameraActionType.STARTED, this.modeBarOnChange.bind(this), this.mBase.hashCode());
    HiLog.i(TAG, 'aboutToAppear X.');
  }

  aboutToDisappear(): void {
    this.mEventBus.clear(this.mBase.hashCode());
    this.mSubscriber.destroy();
  }

  @Builder
  ModeListItemBuilder(item: ModeType, index: number) {
    ListItem() {
      Text(this.modeListManager.getModeName(item))
        .fontColor(Color.White)
        .textShadow({
          radius: 3,
          color: '#33000000',
          offsetX: 0,
          offsetY: 0
        })
        .textCase(TextCase.UpperCase)
        .fontSize($r('sys.float.Subtitle_S'))
        .fontWeight(this.mode === item ? FontWeight.Bold : FontWeight.Regular)
        .textAlign(TextAlign.Center)
        .key(ComponentIdKeys.getInstance().getKey('ControlModeText', item))
        .fontFeature('\"ss01\" on')
        .onClick((): void => {
          this.onModeItemClicked(item, index);
        })
    }
    .key(index === this.modeList.indexOf(this.mode) ?
      ComponentIdKeys.getInstance().getKey('ControlModeText', item) + '-choose' : '')
    .height('100%')
    .onTouch((event: TouchEvent) => {
      this.onModeListTouch();
    })
  }

  @Builder
  ModeListBuilder() {
    Column() {
      List({
        initialIndex: this.currentShowModeIndex,
        scroller: this.scroller,
        space: 24 * Math.min(this.fontSizeScale, CommonConstants.TEXT_SIZE_HUGE)
      }) {
        ForEach(Array.from(this.modeList), (item: ModeType, index: number) => {
          this.ModeListItemBuilder(item, index);
        })
      }
      .listDirection(Axis.Horizontal)
      .edgeEffect(EdgeEffect.None)
      .chainAnimation(false)
      .hitTestBehavior(HitTestMode.None)
      .scrollBar(BarState.Off)
      .scrollSnapAlign(ScrollSnapAlign.CENTER)
      .clip(false)
      .onScrollIndex((start, end, center) => {
        this.onModeListScrollIndex(start, end, center);
      })
    }
    .handleScrollBarMode()
    .id('Column')
    .alignRules({
      middle: { anchor: '__container__', align: HorizontalAlign.Center },
      top: { anchor: '__container__', align: VerticalAlign.Top },
    })
  }

  @Builder
  RedPointBuilder() {
    Row() {
    }
    .width($r('app.float.control_point_size'))
    .height($r('app.float.control_point_size'))
    .borderRadius($r('app.float.control_point_radius'))
    .hitTestBehavior(HitTestMode.Transparent)
    .backgroundColor(Color.Red)
    .margin({ top: 6 })
    .id('Row')
    .alignRules({
      middle: { anchor: 'Column', align: HorizontalAlign.Center },
    })
    .offset({ // 适老化适配，随系统字体放大，维持两者间距
      y: this.modeListHeight + MODE_LIST_MARGIN_TOP * Math.min(this.fontSizeScale, CommonConstants.TEXT_SIZE_HUGE)
    })
  }

  build() {
    RelativeContainer() {
      this.ModeListBuilder();
      this.RedPointBuilder();
    }
    .width('100%')
    .height(this.modeBarHeight)
  }

  // 触摸模式条时截图
  private onModeListTouch(): void {
    try {
      BlurAnimateUtil.generatePixelMapFromSurface();
    } catch (e) {
      HiLog.e(TAG, `execScreenshotThumbnail err: ${JSON.stringify(e)}.`);
    }
  }

  // 滑动模式条的ui索引
  private slideAnimate(index: number) {
    HiLog.i(TAG, `anim event changeToMode:  ${index}`);
    animateToImmediately(
      { curve: curves.interpolatingSpring(1, 1, 228, 30) },
      () => {
        this.scroller.scrollToIndex(index, false, ScrollAlign.CENTER);
      });
  }

  // 存储模式缓存
  private prefService(mode: ModeType): void {
    this.mPreferencesService.putPropValue(PersistType.FOR_AWHILE, PropTag.MODE, mode);
  }

  // 模式切换音效震动以及索引变更统一处理，模式条动了触发该事件
  private onModeListScrollIndex(start: number, end: number, center: number): void {
    if (this.currentShowModeIndex !== center) {
      HiLog.d(TAG, `onScrollIndex center: ${center} start: ${start} end: ${end}`);
      this.currentShowModeIndex = center;
      this.action.changeModePlaySound();
      VibratorService.getInstance().triggerVibrator(VibratorService.CAMERA_CLICK_EFFECT_ID);
    }
  }

  // 实际下发气流
  private changeModeIndex(newIndex: number) {
    if (newIndex !== this.modeList.indexOf(this.mode)) {
      let newMode = this.modeList[newIndex];
      HiLog.i(TAG, `changeToMode state.mode: ${this.mode} ==> newMode: ${newMode} E.`);
      this.slideAnimate(newIndex);
      this.action.changeToMode(this.mode, newMode);
      this.prefService(newMode);
    }
    HiLog.i(TAG, 'changeToMode X.');
  }

  // 模式条点击
  private onModeItemClicked(item: ModeType, index: number): void {
    if (this.currentShowModeIndex === index || !this.uiEnable) {
      return;
    }
    HiLog.i(TAG, `ListItem onclick changeToMode modeType: ${item}.`);
    this.changeModeIndex(index);
  }

  @Styles
  private handleScrollBarMode() {
    .gesture(
      GestureGroup(
        GestureMode.Exclusive,
        PanGesture({
          fingers: 1,
          direction: SystemLanguageUtil.isRTL() ? PanDirection.Right : PanDirection.Left,
          distance: 10
        })
          .onActionStart((): void => {
            this.onSwipeChangeMode({ swipe: 1 })
          }),
        PanGesture({
          fingers: 1,
          direction: SystemLanguageUtil.isRTL() ? PanDirection.Left : PanDirection.Right,
          distance: 10
        })
          .onActionStart((): void => {
            this.onSwipeChangeMode({ swipe: -1 })
          })
      )
    )
  }

  // 预览区域滑动以及模式Bar上滑动，单个索引模式切换
  private onSwipeChangeMode(data: SwipeChangeNumberData) {
    if (!this.uiEnable) {
      return;
    }
    let nextIndex = -1;
    nextIndex = this.currentShowModeIndex + data.swipe; //左滑-1，右滑+1
    HiLog.i(TAG, `swipeOnly: ${data.swipe}, onSwipeChangeMode: ${nextIndex},curIndex:${this.currentShowModeIndex}.`);
    if (nextIndex < 0 || nextIndex > this.modeList.length - 1) {
      return;
    }
    this.changeModeIndex(nextIndex);
  }

  // 组件外部调用chaneMode起流直接进行模式条切换
  private modeBarOnChange(data: CameraStartTypeStruct) {
    if (data.type !== CameraStartType.CHANGE_MODE) {
      return;
    }
    const modeIndex = this.modeList.indexOf(this.mode);
    HiLog.i(TAG, `modeBarOnChange state.mode: ${modeIndex}, currentShowModeIndex:${this.currentShowModeIndex}`);
    if (this.currentShowModeIndex !== modeIndex) {
      this.currentShowModeIndex = modeIndex;
      this.slideAnimate(this.currentShowModeIndex);
      this.prefService(this.mode);
    }
  }
}