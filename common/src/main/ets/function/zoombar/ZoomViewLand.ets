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

import lazy { HiLog } from '../../utils/HiLog';
import lazy { OhCombinedState, Dispatch, reduxSubscribe } from '../../redux';
import lazy { Action } from '../../redux/actions/Action';
import lazy { RecordingState } from '../recordcontrol/RecordAction';
import lazy { ZoomAction } from './ZoomAction';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { AnimSpecifications } from '../../animation/AnimSpecifications';
import camera from '@ohos.multimedia.camera';
import lazy { OutputOperation } from '../outputswitcher/OutputOperation';
import lazy { FunctionAction } from '../core/FunctionAction';
import lazy { FunctionId } from '../core/functionproperty/FunctionId';
import lazy { UIOperationType } from '../../component/uicomponent/UIOperationType';
import lazy { ChangeState, Unsubscribe } from '../../redux/Store';
import lazy { FeatureManager } from '../core/FeatureManager';
import lazy { ZoomParam } from './ZoomParam';

/* instrument ignore file */
const TAG: string = 'ZoomViewLand';

class StateStruct {
  public mode: ModeType = ModeType.NONE;
  public uiEnable: boolean = false;
  public videoState: RecordingState = RecordingState.READY;
  public cameraPosition: camera.CameraPosition = camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED;
  public zoomRatio: number = 0;
  public isShowZoomView: boolean = false;
  public isShowZoomText: boolean = false;
  public minZoomRatio: number = 0;
  public maxZoomRatio: number = 0;
}

class ZoomFuncValueStruct {
  public zoomRatio?: number = 1;
  public isPrepareZoom?: boolean = false;
  public isUnprepareZoom?: boolean = false;
  public isSmoothZoom?: boolean = false;
  public unprepareDelay?: number;
}

class ZoomViewDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }

  public changeFunctionValue(id: FunctionId, zoomFuncValue: ZoomFuncValueStruct): void {
    this.mDispatch(FunctionAction.changeFunctionValue(id, zoomFuncValue));
  }

  public updateShowZoomTextFlag(flag: boolean): void {
    this.mDispatch(ZoomAction.updateShowZoomTextFlag(flag));
  }

  public updateShowZoomViewFlag(flag: boolean): void {
    this.mDispatch(ZoomAction.updateShowZoomViewFlag(flag));
  }

  public isEnterImmersive(isEnterImmersive: boolean): void {
    this.mDispatch(Action.isEnterImmersive(isEnterImmersive, UIOperationType.ZOOM_BAR));
  }

  public updateShowBigTextFlag(isShowBigTxt: boolean): void {
    this.mDispatch(Action.updateShowBigTextFlag(isShowBigTxt));
  }
}

class ZoomRatioData {
  public zoomRatio: number = 0;
}

enum ShowFlodCanvasEnum {
  SHOW_COLLAPS_CANVAS,
  SHOW_NOT_TAKE_VIDEO_CANVAS,
  SHOW_TAKING_VIDEO_CANVAS,
}

const SHOW_COLLAPS_CANVAS = ShowFlodCanvasEnum.SHOW_COLLAPS_CANVAS;
const SHOW_NOT_TAKE_VIDEO_CANVAS = ShowFlodCanvasEnum.SHOW_NOT_TAKE_VIDEO_CANVAS;
const SHOW_TAKING_VIDEO_CANVAS = ShowFlodCanvasEnum.SHOW_TAKING_VIDEO_CANVAS;

@Component
export struct ZoomViewLand {
  @State state: StateStruct = new StateStruct();
  private mSubscriber: Unsubscribe = {
    destroy: () => {
    }
  };
  @State @Watch('videoStateOnChange') videoState: RecordingState = RecordingState.READY;
  @State @Watch('onZoomRatioRefresh') zoomRatio: number = 1;
  @State offsetX: number = 0;
  @State addButtonOffsetX: number = 0;
  @State subButtonOffsetX: number = 0;
  @State zoomBtnCenterX: number = 0;
  @State @Watch('expendOnChange') isShowZoomView: boolean = false;
  @State isShowExpend: boolean = false;
  @State isShowCollapser: boolean = true;
  @State isShowRecord: boolean = false;
  @State expendOpacity: number = 1;
  @State recordOpacity: number = 1;
  @State collapserOpacity: number = 1;
  @State recordTranslate: TranslateOptions = { y: 0 };
  private readonly extendCanvasWidth = 360;
  private readonly takingVideoExtCanvasWidth = 196;
  private readonly collapsCanvasWidth = 210;
  private readonly canvasHeight = 82;
  private readonly mainDotRadius: number = 1.5;
  private readonly secDotRadius: number = 0.75;
  private readonly centerDotRadius: number = 1.5;
  private readonly dotSpacing: number = 4;
  private readonly zoomCoefficient: number = 0.045;
  private readonly zoomGear: number = 5;
  private mAction: ZoomViewDispatcher = new ZoomViewDispatcher();
  private canvasSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private photoExtendCanvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.canvasSettings);
  private videoExtendCanvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.canvasSettings);
  private collapsCanvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.canvasSettings);
  private photoExtendOffCanvasContext: OffscreenCanvasRenderingContext2D = new OffscreenCanvasRenderingContext2D(
    this.extendCanvasWidth, this.canvasHeight, this.canvasSettings);
  private videoExtendOffCanvasContext: OffscreenCanvasRenderingContext2D = new OffscreenCanvasRenderingContext2D(
    this.takingVideoExtCanvasWidth, this.canvasHeight, this.canvasSettings);
  private collapsOffCanvasContext: OffscreenCanvasRenderingContext2D = new OffscreenCanvasRenderingContext2D(
    this.collapsCanvasWidth, this.canvasHeight, this.canvasSettings);
  private lpgTimer: number = 0;
  private pgTimer: number = 0;
  private zoomLpTimer: number = 0;
  private mouseTouchTimer: number = 0;
  private lpgExp: boolean = false;
  private pgExp: boolean = false;
  private videoPgExp: boolean = false;
  private baseZoomRatio: number = 1;
  private touchedOffsetX: number = this.takingVideoExtCanvasWidth / 2;
  private startOffsetX: number = 0;
  private mFastZoomValueMap: Map<number, number> = new Map();
  private refreshSwitchCanvas: number = -1;
  @StorageLink('isPanGestureDoing') isPanGestureDoing: boolean = false;

  aboutToAppear(): void {
    this.mSubscriber = reduxSubscribe((state: OhCombinedState, changeState: ChangeState<StateStruct>) => {
      this.videoState = state.get<RecordingState>('recordReducer', 'recordingState');
      this.isShowZoomView = state.get<boolean>('zoomReducer', 'isShowZoomView');
      changeState(this.state, {
        mode: state.get<ModeType>('modeReducer', 'mode'),
        uiEnable: state.get<boolean>('contextReducer', 'uiEnable'),
        videoState: state.get<RecordingState>('recordReducer', 'recordingState'),
        cameraPosition: state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition'),
        zoomRatio: state.get<number>('zoomReducer', 'zoomRatio'),
        isShowZoomView: state.get<boolean>('zoomReducer', 'isShowZoomView'),
        isShowZoomText: state.get<boolean>('zoomReducer', 'isShowZoomText'),
        minZoomRatio: state.get<number>('zoomReducer', 'minZoomRatio'),
        maxZoomRatio: state.get<number>('zoomReducer', 'maxZoomRatio'),
      });
      this.zoomRatio = state.get<number>('zoomReducer', 'zoomRatio');
    }, (dispatch: Dispatch): void => {
      this.mAction.setDispatch(dispatch);
    });
  }

  aboutToDisappear(): void {
    this.mSubscriber.destroy();
  }

  private expendOnChange() {
    HiLog.d(TAG, `expendOnChange isShowZoomView:${this.isShowZoomView}`);
    this.isShowExpend = this.isShowZoomView;
    this.isShowCollapser = !this.isShowExpend;
  }

  private videoStateOnChange() {
    HiLog.d(TAG, `videoStateOnChange videoState:${this.videoState}.`);
    this.clearTimer();
    if (this.videoState === RecordingState.READY) {
      this.mAction.updateShowZoomViewFlag(false);
      this.mAction.updateShowZoomTextFlag(false);
      this.lpgExp = false;
      this.pgExp = false;
    }
    if (this.videoState === RecordingState.STARTING) {
      this.recordStartAnim();
    } else if (this.videoState === RecordingState.STOPPING) {
      this.recordEndAnim();
    }
  }

  private recordStartAnim() {
    HiLog.d(TAG, 'recordStartAnim');
    this.expendOpacity = 1;
    this.collapserOpacity = 1;
    this.recordOpacity = 0;
    this.recordTranslate = { y: 0 };
    this.isShowRecord = true;
    animateToImmediately(
      {
        duration: AnimSpecifications.ANIM_VIDEO_START_DURATION,
        curve: Curve.Sharp,
        onFinish: () => {
          this.recordOpacity = 1;
          this.expendOpacity = 1;
          this.collapserOpacity = 1;
          this.isShowExpend = false;
          this.isShowCollapser = false;
        }
      },
      () => {
        this.recordOpacity = 1;
        this.expendOpacity = 0;
        this.collapserOpacity = 0;
      }
    )
    animateToImmediately(
      {
        duration: AnimSpecifications.ANIM_DELAY_150,
        curve: Curve.Sharp,
        onFinish: () => {
        }
      },
      () => {
        this.recordTranslate = { y: 48 };
      }
    )
  }

  private recordEndAnim() {
    HiLog.d(TAG, 'recordEndAnim');
    this.recordOpacity = 1;
    this.collapserOpacity = 0;
    this.isShowCollapser = true;
    animateToImmediately(
      {
        duration: AnimSpecifications.ANIM_VIDEO_START_DURATION,
        curve: Curve.Sharp,
        onFinish: () => {
          this.isShowRecord = false;
          this.recordOpacity = 1;
          this.collapserOpacity = 1;
        }
      },
      () => {
        this.recordOpacity = 0;
        this.collapserOpacity = 1;
      }
    )

    animateToImmediately(
      {
        duration: AnimSpecifications.ANIM_DELAY_150,
        curve: Curve.Sharp,
        onFinish: () => {
        }
      },
      () => {
        this.recordTranslate = { y: 0 };
      }
    )
  }

  @Builder
  expendCanvas() {
    Canvas(this.photoExtendCanvasContext)
      .width(this.extendCanvasWidth)
      .height(this.canvasHeight)
      .onReady(() => this.canvasInit(SHOW_NOT_TAKE_VIDEO_CANVAS))
      .opacity(this.expendOpacity)
      .gesture(
        GestureGroup(
          GestureMode.Parallel,
          PanGesture({ fingers: 1, distance: 1, direction: PanDirection.Horizontal })
            .onActionStart((event?: GestureEvent) => {
              if (!event) {
                return;
              }
              return this.pgOnActionStart(event);
            })
            .onActionUpdate((event?: GestureEvent) => {
              if (!event) {
                return;
              }
              return this.pgOnActionUpdate(event);
            })
            .onActionEnd((event?: GestureEvent) => {
              if (!event) {
                return;
              }
              return this.pgOnActionEnd(event);
            })
            .onActionCancel((event?: GestureEvent) => {
              if (!event) {
                return;
              }
              return this.pgOnActionEnd(event);
            })
        )
      )
      .onTouch((event?: TouchEvent) => {
        if (!event) {
          return;
        }
        return this.mOnTouch(event);
      })
  }

  @Builder
  recordCanvas() {
    Row() {
      Stack({ alignContent: Alignment.End }) {
        Image($r('app.media.ic_camera_public_focus_ev_bright_subtract'))
          .width(24)
          .height(24)
          .fillColor(Color.White)
          .onTouch((event?: TouchEvent) => {
            if (!event) {
              return;
            }
            return this.subtractTouched(event);
          })
          .draggable(false)
          .gesture(
            GestureGroup(
              GestureMode.Parallel,
              LongPressGesture({ repeat: false, duration: 300 })
                .onAction((event?: GestureEvent) => {
                  if (!event) {
                    return;
                  }
                  return this.subtractLongOnAction(event);
                })
                .onActionEnd(() => this.subtractLongOnActionEnd())
                .onActionCancel(() => this.subtractLongOnActionEnd()),
            )
          )
      }.width(48).padding({ right: this.subButtonOffsetX })

      Stack({ alignContent: Alignment.Center }) {
        Stack({ alignContent: Alignment.Center }) {
          if (this.state.isShowZoomText) {
            Column()
              .width(this.centerDotRadius * 2)
              .height(this.centerDotRadius * 2)
              .border({
                width: this.centerDotRadius,
                color: Color.White,
                radius: this.centerDotRadius,
                style: BorderStyle.Solid
              })
          } else {
            Text(this.getZoomText())
              .fontSize($r('sys.float.Caption_M'))
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
              .textAlign(TextAlign.Center)
              .width('100%')
              .fontFeature('\"ss01\" on')
          }
          Column()
            .width(this.getZoomBtnRadius() * 2)
            .height(this.getZoomBtnRadius() * 2)
            .border({ width: 1.5, color: Color.White, radius: this.getZoomBtnRadius(), style: BorderStyle.Solid })
        }
        .width(this.getZoomBtnRadius() * 2)
        .height(this.canvasHeight).position({ x: this.getZoomBtnCenterX() - this.getZoomBtnRadius() })

        Stack({ alignContent: Alignment.End }) {
          Column() {
          }
          .width(this.getLeftLineWidth())
          .height(1.5)
          .backgroundColor(Color.White)
        }
        .width(this.takingVideoExtCanvasWidth / 2).height(this.canvasHeight).position({ x: 0 })

        Stack({ alignContent: Alignment.Start }) {
          Column() {
          }
          .width(this.getRightLineWidth())
          .height(1.5)
          .backgroundColor(Color.White)
        }
        .width(this.takingVideoExtCanvasWidth / 2)
        .height(this.canvasHeight)
        .position({ x: this.takingVideoExtCanvasWidth / 2 })

        Canvas(this.videoExtendCanvasContext)
          .width(this.takingVideoExtCanvasWidth)
          .height(this.canvasHeight)
          .onReady(() => this.canvasInit(SHOW_TAKING_VIDEO_CANVAS))
          .gesture(
            GestureGroup(
              GestureMode.Parallel,
              PanGesture({ fingers: 1, distance: 1, direction: PanDirection.Horizontal })
                .onActionStart((event?: GestureEvent) => {
                  HiLog.i(TAG, 'isPanGestureDoing true, onActionStart 1');
                  this.isPanGestureDoing = true;
                  if (!event) {
                    return;
                  }
                  return this.takingVideoExtPgActionStart(event);
                })
                .onActionUpdate((event?: GestureEvent) => {
                  HiLog.i(TAG, 'isPanGestureDoing false, onActionUpdate');
                  this.isPanGestureDoing = false;
                  if (!event) {
                    return;
                  }
                  return this.takingVideoExtPgActionUpdate(event);
                })
                .onActionEnd((event?: GestureEvent) => {
                  if (!event) {
                    return;
                  }
                  return this.takingVideoExtPgActionEnd(event);
                })
                .onActionCancel((event?: GestureEvent) => {
                  if (!event) {
                    return;
                  }
                  return this.takingVideoExtPgActionEnd(event);
                })
            ))
          .onTouch((event?: TouchEvent) => {
            if (!event) {
              return;
            }
            return this.takingVideoExtTouched(event);
          })
      }
      .width(this.takingVideoExtCanvasWidth)
      .height(this.canvasHeight)

      Stack({ alignContent: Alignment.Start }) {
        Image($r('app.media.ic_camera_public_focus_ev_bright_add'))
          .width(24)
          .height(24)
          .fillColor(Color.White)
          .onTouch((event?: TouchEvent) => {
            if (!event) {
              return;
            }
            return this.addTouched(event);
          })
          .draggable(false)
          .gesture(
            GestureGroup(
              GestureMode.Parallel,
              LongPressGesture({ repeat: false, duration: 300 })
                .onAction((event?: GestureEvent) => {
                  if (!event) {
                    return;
                  }
                  return this.addLongOnAction(event);
                })
                .onActionEnd(() => this.addLongOnActionEnd())
                .onActionCancel(() => this.addLongOnActionEnd()),
            )
          )
      }.width(48).padding({ left: this.addButtonOffsetX })
    }
    .width(this.extendCanvasWidth)
    .height(this.canvasHeight)
    .padding({ left: 34, right: 34 })
    .translate(this.recordTranslate)
    .opacity(this.recordOpacity)
    .enabled(this.state.uiEnable)
    .onClick((): void => {
    })
  }

  @Builder
  collapserCanvas() {
    Canvas(this.collapsCanvasContext)
      .width(this.collapsCanvasWidth)
      .height(this.canvasHeight)
      .opacity(this.collapserOpacity)
      .onReady(() => this.canvasInit(SHOW_COLLAPS_CANVAS))
      .gesture(
        GestureGroup(
          GestureMode.Exclusive,
          LongPressGesture({ repeat: true })
            .onAction((event?: GestureEvent) => {
              if (!event) {
                return;
              }
              return this.lpgOnAction(event);
            })
            .onActionEnd(() => this.lpgOnActionEnd())
            .onActionCancel(() => this.lpgOnActionEnd()),
          PanGesture({ fingers: 1, distance: 1, direction: PanDirection.Horizontal })
            .onActionStart((event?: GestureEvent) => {
              HiLog.i(TAG, 'isPanGestureDoing true, onActionStart 1');
              this.isPanGestureDoing = true;
              if (!event) {
                return;
              }
              return this.pgOnActionStart(event);
            })
            .onActionEnd((event?: GestureEvent) => {
              HiLog.i(TAG, 'isPanGestureDoing false, onActionEnd');
              this.isPanGestureDoing = false;
              if (!event) {
                return;
              }
              return this.pgOnActionEnd(event);
            })
            .onActionCancel((event?: GestureEvent) => {
              HiLog.i(TAG, 'isPanGestureDoing false, onActionCancel');
              this.isPanGestureDoing = false;
              if (!event) {
                return;
              }
              return this.pgOnActionEnd(event);
            }),
        )
      )
      .onTouch((event?: TouchEvent) => {
        if (!event) {
          return;
        }
        return this.onQuickZoomChoice(event);
      })
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      if (this.isShowExpend) {
        this.expendCanvas();
      }
      if (this.isShowRecord) {
        this.recordCanvas();
      }
      if (this.isShowCollapser) {
        this.collapserCanvas();
      }
    }
    .width('100%')
    .height(this.canvasHeight)
    .onDisAppear((): void => {
      this.mAction.updateShowZoomViewFlag(false);
    })
  }

  private getCurrentCanvasType(): number {
    if (this.state.isShowZoomView && (this.state.videoState === RecordingState.READY &&
      (this.state.mode === ModeType.PHOTO ||
        this.state.mode === ModeType.VIDEO ||
        (this.state.mode === ModeType.PORTRAIT || this.state.mode === ModeType.APERTURE)))) {
      return SHOW_NOT_TAKE_VIDEO_CANVAS;
    } else if (this.state.mode === ModeType.VIDEO &&
      (this.state.isShowZoomView || this.state.videoState !== RecordingState.READY)) {
      return SHOW_TAKING_VIDEO_CANVAS;
    } else {
      return SHOW_COLLAPS_CANVAS;
    }
  }

  private lpgOnAction(event: GestureEvent): void {
    this.clearTimer();
    this.mAction.updateShowZoomTextFlag(true);
    this.mAction.updateShowZoomViewFlag(true);
    this.baseZoomRatio = this.zoomRatio;
    this.offsetX = (this.zoomRatio - 1) * this.getZoomOffsetUnit();
    this.lpgExp = true;
  }

  private lpgOnActionEnd(): void {
    this.mAction.updateShowZoomTextFlag(false);
    this.lpgExp = false;
    this.lpgTimer = setTimeout((): void => {
      if (!this.lpgExp && !this.pgExp) {
        this.mAction.updateShowZoomViewFlag(false);
      }
    }, 3000);
  }

  private changeZoomRatioOnTakingVideoExt(): void {
    if (this.touchedOffsetX > this.takingVideoExtCanvasWidth / 2) {
      this.addZoomRatio();
    } else if (this.touchedOffsetX < this.takingVideoExtCanvasWidth / 2) {
      this.subtractZoomRatio();
    } else {
      this.mAction.updateShowZoomTextFlag(false);
    }
    this.playButtonAnimationIfNeed();
  }

  private playButtonAnimationIfNeed(): void {
    let currentZoomBtnPositionX = this.touchedOffsetX;
    let maxLimitX = this.takingVideoExtCanvasWidth - this.getZoomBtnRadius() - this.secDotRadius;
    let minLimitX = this.getZoomBtnRadius() + this.secDotRadius;
    if (this.addButtonOffsetX === 0 && currentZoomBtnPositionX === maxLimitX) {
      this.addButtonMove();
    }
    if (this.addButtonOffsetX !== 0 && currentZoomBtnPositionX !== maxLimitX) {
      this.addButtonReset();
    }
    if (this.subButtonOffsetX === 0 && currentZoomBtnPositionX === minLimitX) {
      this.subButtonMove();
    }
    if (this.subButtonOffsetX !== 0 && currentZoomBtnPositionX !== minLimitX) {
      this.subButtonReset();
    }
  }

  private addButtonMove(): void {
    animateToImmediately(
      { duration: 200, curve: Curve.Friction, delay: 0 },
      () => {
        this.addButtonOffsetX = 11;
      });
  }

  private addButtonReset(): void {
    animateToImmediately(
      { duration: 300, curve: Curve.Friction, delay: 0 },
      () => {
        this.addButtonOffsetX = 0;
      });
  }

  private subButtonMove(): void {
    animateToImmediately(
      { duration: 200, curve: Curve.Friction, delay: 0 },
      () => {
        this.subButtonOffsetX = 11;
      });
  }

  private subButtonReset(): void {
    animateToImmediately(
      { duration: 300, curve: Curve.Friction, delay: 0 },
      () => {
        this.subButtonOffsetX = 0;
      });
  }

  private zoomButtonReset(): void {
    this.zoomBtnCenterX = this.touchedOffsetX;
    animateToImmediately({
      duration: 300, curve: Curve.Friction, delay: 100,
      onFinish: () => {
        this.zoomBtnCenterX = 0;
      }
    }, () => {
      this.zoomBtnCenterX = this.takingVideoExtCanvasWidth / 2;
    });
  }

  private addZoomRatio(): void {
    let curZoomRatio = this.zoomRatio * (1 + this.zoomCoefficient / this.zoomGear);
    if (curZoomRatio > this.state.maxZoomRatio) {
      curZoomRatio = this.state.maxZoomRatio;
    }
    this.mAction.changeFunctionValue(FunctionId.ZOOM, { zoomRatio: curZoomRatio });
    this.mAction.updateShowZoomTextFlag(true);
  }

  private subtractZoomRatio(): void {
    let curZoomRatio = this.zoomRatio * (1 - this.zoomCoefficient / this.zoomGear);
    if (curZoomRatio < this.state.minZoomRatio) {
      curZoomRatio = this.state.minZoomRatio;
    }
    this.mAction.changeFunctionValue(FunctionId.ZOOM, { zoomRatio: curZoomRatio });
    this.mAction.updateShowZoomTextFlag(true);
  }

  private takingVideoExtTouched(event: TouchEvent): void {
    if (event.type === TouchType.Down || event.type === TouchType.Move) {
      //手指点击会不停的触发onTouch事件，而鼠标一次点击只会触发两次onTouch事件
      //鼠标左击按下时会触发一次onTouch事件, 所以添加一个改变变焦倍率的定时器
      //鼠标左击按下弹起时会触发一次onTouch事件, 在这时候注销改变变焦倍率的定时器
      if (event.type === TouchType.Down) {
        this.mAction.changeFunctionValue(FunctionId.ZOOM, { zoomRatio: undefined, isPrepareZoom: true });
      }
      if (this.videoPgExp) {
        return;
      }
      if (this.mouseTouchTimer > 0) {
        clearInterval(this.mouseTouchTimer);
      }
      this.mouseTouchTimer = setInterval(() => this.changeZoomRatioOnTakingVideoExt(), 50);
      this.touchedOffsetX = event.touches[0].x;
      this.startOffsetX = event.touches[0].x;
      let takingVideoExtMaxOffsetX = this.takingVideoExtCanvasWidth - this.getZoomBtnRadius() - this.secDotRadius;
      let takingVideoExtMinOffsetX = this.getZoomBtnRadius() + this.secDotRadius;
      if (this.touchedOffsetX > takingVideoExtMaxOffsetX) {
        this.touchedOffsetX = takingVideoExtMaxOffsetX;
      } else if (this.touchedOffsetX < takingVideoExtMinOffsetX) {
        this.touchedOffsetX = takingVideoExtMinOffsetX;
      }
      this.changeZoomRatioOnTakingVideoExt();
    }
    if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
      if (this.videoPgExp) {
        this.mAction.changeFunctionValue(FunctionId.ZOOM,
          { zoomRatio: undefined, isUnprepareZoom: true, unprepareDelay: ZoomParam.UNPREPARE_DELAY_TIME });
        return;
      }
      this.touchedOffsetX = this.takingVideoExtCanvasWidth / 2;
      this.changeZoomRatioOnTakingVideoExt();
      clearInterval(this.mouseTouchTimer);
      this.mAction.changeFunctionValue(FunctionId.ZOOM,
        { zoomRatio: undefined, isUnprepareZoom: true, unprepareDelay: ZoomParam.UNPREPARE_DELAY_TIME });
    }
  }

  private takingVideoExtLongPgAction(event: GestureEvent): void {
    this.touchedOffsetX = event.fingerList[0].localX;
    this.changeZoomRatioOnTakingVideoExt();
  }

  private takingVideoExtLongPgActionEnd(): void {
    this.touchedOffsetX = this.takingVideoExtCanvasWidth / 2;
    this.changeZoomRatioOnTakingVideoExt();
  }

  private takingVideoExtPgActionStart(event: GestureEvent): void {
    this.videoPgExp = true;
    this.touchedOffsetX = this.startOffsetX + event.offsetX;
    this.changeZoomRatioOnTakingVideoExt();
  }

  private takingVideoExtPgActionUpdate(event: GestureEvent): void {
    //当触发PanGesture时重置计时器
    clearInterval(this.mouseTouchTimer);
    this.mouseTouchTimer = setInterval(() => this.changeZoomRatioOnTakingVideoExt(), 50);
    this.touchedOffsetX = this.startOffsetX + event.offsetX;
    let takingVideoExtMaxOffsetX = this.takingVideoExtCanvasWidth - this.getZoomBtnRadius() - this.secDotRadius;
    let takingVideoExtMinOffsetX = this.getZoomBtnRadius() + this.secDotRadius;
    if (this.touchedOffsetX > takingVideoExtMaxOffsetX) {
      this.touchedOffsetX = takingVideoExtMaxOffsetX;
    } else if (this.touchedOffsetX < takingVideoExtMinOffsetX) {
      this.touchedOffsetX = takingVideoExtMinOffsetX;
    }
    this.changeZoomRatioOnTakingVideoExt();
  }

  private takingVideoExtPgActionEnd(event: GestureEvent): void {
    this.videoPgExp = false;
    this.touchedOffsetX = this.takingVideoExtCanvasWidth / 2;
    this.startOffsetX = 0;
    this.changeZoomRatioOnTakingVideoExt();
    clearInterval(this.mouseTouchTimer);
  }

  private subtractTouched(event: TouchEvent) {
    if (event.type === TouchType.Down) {
      this.mAction.changeFunctionValue(FunctionId.ZOOM, { zoomRatio: undefined, isPrepareZoom: true });
      this.subtractZoomRatio();
    }
    if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
      this.mAction.changeFunctionValue(FunctionId.ZOOM, { zoomRatio: undefined, isUnprepareZoom: true });
      this.mAction.updateShowZoomTextFlag(false);
    }
  }

  private subtractLongOnAction(event: GestureEvent) {
    this.mAction.changeFunctionValue(FunctionId.ZOOM, { zoomRatio: undefined, isPrepareZoom: true });
    this.mAction.isEnterImmersive(true);
    clearInterval(this.zoomLpTimer);
    this.zoomLpTimer = setInterval(() => {
      this.subtractZoomRatio();
    }, 16);
  }

  private subtractLongOnActionEnd() {
    this.mAction.changeFunctionValue(FunctionId.ZOOM, { zoomRatio: undefined, isUnprepareZoom: true });
    this.mAction.isEnterImmersive(false);
    clearInterval(this.zoomLpTimer);
    this.mAction.updateShowZoomTextFlag(false);
  }

  private addTouched(event: TouchEvent) {
    if (event.type === TouchType.Down) {
      this.mAction.changeFunctionValue(FunctionId.ZOOM, { zoomRatio: undefined, isPrepareZoom: true });
      this.addZoomRatio();
    }
    if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
      this.mAction.changeFunctionValue(FunctionId.ZOOM, { zoomRatio: undefined, isUnprepareZoom: true });
      this.mAction.updateShowZoomTextFlag(false);
    }
  }

  private addLongOnAction(event: GestureEvent) {
    this.mAction.changeFunctionValue(FunctionId.ZOOM, { zoomRatio: undefined, isPrepareZoom: true });
    this.mAction.isEnterImmersive(true);
    clearInterval(this.zoomLpTimer);
    this.zoomLpTimer = setInterval(() => {
      this.addZoomRatio();
    }, 16);
  }

  private addLongOnActionEnd() {
    this.mAction.isEnterImmersive(false);
    clearInterval(this.zoomLpTimer);
    this.mAction.updateShowZoomTextFlag(false);
    this.mAction.changeFunctionValue(FunctionId.ZOOM, { zoomRatio: undefined, isUnprepareZoom: true });
  }

  private pgOnActionStart(event: GestureEvent): void {
    this.mAction.updateShowBigTextFlag(false);
    this.clearTimer();
    this.mAction.updateShowZoomTextFlag(true);
    this.mAction.updateShowZoomViewFlag(true);
    this.mAction.isEnterImmersive(true);
    this.baseZoomRatio = this.zoomRatio;
    this.pgExp = true;
  }

  private pgOnActionUpdate(event: GestureEvent): void {
    this.offsetX = (this.baseZoomRatio - this.state.minZoomRatio) * this.getZoomOffsetUnit() + event.offsetX;
    this.updateZoomRatio();
  }

  private pgOnActionEnd(event: GestureEvent): void {
    this.mAction.isEnterImmersive(false);
    this.mAction.updateShowZoomTextFlag(false);
    this.pgExp = false;
    this.clearTimer();
    this.pgTimer = setTimeout((): void => {
      if (!this.pgExp && !this.lpgExp) {
        this.mAction.updateShowZoomViewFlag(false);
      }
    }, 3000);
  }

  private mOnTouch(event: TouchEvent): void {
    if (event.type === TouchType.Down) {
      this.clearTimer();
      this.mAction.changeFunctionValue(FunctionId.ZOOM, { zoomRatio:undefined, isPrepareZoom: true });
      this.mAction.updateShowZoomTextFlag(true);
      let x = event.touches[0].x;
      let zoomRatio = this.zoomRatio;
      if (this.state.videoState === RecordingState.READY &&
        this.getCurrentCanvasType() === SHOW_NOT_TAKE_VIDEO_CANVAS) {
        if (x < this.getPadding()) {
          zoomRatio = this.state.minZoomRatio;
        }
        if (x > this.extendCanvasWidth - this.getPadding()) {
          zoomRatio = this.state.maxZoomRatio;
        }
        if (x > this.getPadding() && x < this.extendCanvasWidth - this.getPadding()) {
          this.offsetX = x - this.getPadding() - this.mainDotRadius;
          this.updateZoomRatio();
          return;
        }
      }
      this.offsetX = (zoomRatio - 1) * this.getZoomOffsetUnit();
      this.updateZoomRatio();
    } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
      this.mAction.updateShowZoomTextFlag(false);
      this.clearTimer();
      this.pgTimer = setTimeout((): void => {
        if (!this.pgExp && !this.lpgExp) {
          this.mAction.updateShowZoomViewFlag(false);
        }
      }, 3000);
      this.mAction.changeFunctionValue(FunctionId.ZOOM, { zoomRatio:undefined, isUnprepareZoom: true });
    }
  }

  private onQuickZoomChoice(event: TouchEvent): void {
    if (event.type === TouchType.Down) {
      this.mAction.changeFunctionValue(FunctionId.ZOOM, { zoomRatio:undefined, isPrepareZoom: true });
      return;
    }
    if (event.type === TouchType.Up) {
      let x = event.touches[0].x;
      let zoomRatio = this.zoomRatio;
      if (this.state.videoState === RecordingState.READY && this.getCurrentCanvasType() === SHOW_COLLAPS_CANVAS) {
        let minZoomRatio: number = this.mFastZoomValueMap.get(this.state.minZoomRatio) as number;
        if (this.isInHotArea(x, minZoomRatio)) {
          zoomRatio = this.state.minZoomRatio;
        }
        if (this.isInHotArea(x, this.mFastZoomValueMap.get(this.state.maxZoomRatio) as number)) {
          zoomRatio = this.state.maxZoomRatio;
        }
      }
      this.mAction.changeFunctionValue(FunctionId.ZOOM, { zoomRatio: zoomRatio, isUnprepareZoom: true });
      this.mAction.updateShowZoomTextFlag(true);
      setTimeout((): void => {
        this.mAction.updateShowZoomTextFlag(false);
      }, 100);
    }
  }

  private isInHotArea(touchedX: number, fastZoomPointX: number): boolean {
    if (Math.abs(touchedX - fastZoomPointX) < 16) {
      return true;
    }
    return false;
  }

  private getZoomBtnCenterX(): number {
    if (this.getCurrentCanvasType() === SHOW_TAKING_VIDEO_CANVAS) {
      return this.touchedOffsetX;
    }
    if (this.offsetX === 0 && this.zoomRatio !== 1) {
      this.offsetX = (this.zoomRatio - this.state.minZoomRatio) * this.getZoomOffsetUnit();
    }
    if (this.zoomRatio === 1 && this.offsetX !== 0) {
      this.offsetX = 0;
    }
    let padding = this.getPadding();
    let result = this.offsetX + padding + this.mainDotRadius;
    if (result > this.extendCanvasWidth - padding - this.mainDotRadius) {
      result = this.extendCanvasWidth - padding - this.mainDotRadius;
    }
    if (result < padding + this.mainDotRadius) {
      result = padding + this.mainDotRadius;
    }
    return result;
  }

  private getRightLineWidth(): number {
    if (this.getZoomBtnCenterX() - this.getZoomBtnRadius() - this.takingVideoExtCanvasWidth / 2 > 0) {
      return this.getZoomBtnCenterX() - this.getZoomBtnRadius() - this.takingVideoExtCanvasWidth / 2;
    }
    return 0;
  }

  private getLeftLineWidth(): number {
    if (this.takingVideoExtCanvasWidth / 2 - this.getZoomBtnCenterX() - this.getZoomBtnRadius() > 0) {
      return this.takingVideoExtCanvasWidth / 2 - this.getZoomBtnCenterX() - this.getZoomBtnRadius();
    }
    return 0;
  }

  private getZoomOffsetUnit(): number {
    let padding = this.getPadding();
    let fullWidth = this.extendCanvasWidth - padding * 2 - this.mainDotRadius * 2;
    return fullWidth / (this.state.maxZoomRatio - this.state.minZoomRatio);
  }

  private updateZoomOffset(data: ZoomRatioData): void {
    let padding = this.getPadding();
    let offset = (data.zoomRatio - this.state.minZoomRatio) * this.getZoomOffsetUnit();
    this.offsetX = offset;
  }

  private clearTimer(): void {
    if (this.pgTimer) {
      clearTimeout(this.pgTimer);
    }
    if (this.lpgTimer) {
      clearTimeout(this.lpgTimer);
    }
  }

  private updateZoomRatio(): void {
    let padding = this.getPadding();
    let fullWidth = this.extendCanvasWidth - padding * 2 - this.mainDotRadius * 2;
    let curZoomRatio = (this.offsetX / fullWidth) *
      (this.state.maxZoomRatio - this.state.minZoomRatio) + this.state.minZoomRatio;
    if (curZoomRatio > this.state.maxZoomRatio) {
      curZoomRatio = this.state.maxZoomRatio;
    }
    if (curZoomRatio < this.state.minZoomRatio) {
      curZoomRatio = this.state.minZoomRatio;
    }
    this.mAction.changeFunctionValue(FunctionId.ZOOM, { zoomRatio: curZoomRatio });
  }

  private getPadding(): number {
    let padding = 32;
    if (OutputOperation.isPanPhotoOutput(this.state.mode)) {
      padding = 32;
    } else if (OutputOperation.isPanVideoOutput(this.state.mode)) {
      padding = 43;
    }
    return padding;
  }

  private getZoomText() {
    return `${Number(this.zoomRatio.toFixed(1))}x`;
  }

  private getZoomBtnRadius(): number {
    if (this.lpgExp || this.pgExp) {
      return 18;
    } else {
      return 16;
    }
  }

  private onZoomRatioRefresh() {
    HiLog.d(TAG, 'onZoomRatioRefresh.');
    if (this.getCurrentCanvasType() === this.refreshSwitchCanvas) {
      this.refreshCanvas(this.refreshSwitchCanvas);
    }
  }

  private canvasInit(mType: number) {
    HiLog.d(TAG, `canvasInit mType:${mType}.`);
    this.refreshSwitchCanvas = mType;
    this.refreshCanvas(mType);
  }

  private refreshCanvas(mType: number) {
    switch (mType) {
      case SHOW_COLLAPS_CANVAS:
        this.collapsCanvasRefresh();
        break;
      case SHOW_NOT_TAKE_VIDEO_CANVAS:
        this.notTakingVideoCanvasRefresh();
        break;
      default:
        this.takingVideoCanvasRefresh();
    }
  }

  private notTakingVideoCanvasRefresh() {
    HiLog.d(TAG, 'notTakingVideoCanvasRefresh.');
    this.photoExtendCanvasContext.clearRect(0, 0, this.extendCanvasWidth, this.canvasHeight);
    this.photoExtendOffCanvasContext.clearRect(0, 0, this.extendCanvasWidth, this.canvasHeight);
    this.photoExtendOffCanvasContext.strokeStyle = '#ffffff';
    this.photoExtendOffCanvasContext.fillStyle = '#ffffff';
    this.photoExtendOffCanvasContext.lineWidth = 2;
    this.photoExtendOffCanvasContext.beginPath();
    this.photoExtendOffCanvasContext.arc(this.getZoomBtnCenterX(),
      this.canvasHeight / 2, this.getZoomBtnRadius(), 0, 6.28);
    this.photoExtendOffCanvasContext.stroke();
    this.photoExtendOffCanvasContext.beginPath();
    this.photoExtendOffCanvasContext.font = '10';
    this.photoExtendOffCanvasContext.textAlign = 'center';
    this.photoExtendOffCanvasContext.fillText(this.getZoomText(), this.getZoomBtnCenterX(), this.canvasHeight / 2 + 3);

    let spotCount = (this.extendCanvasWidth - this.getPadding() * 2 - this.mainDotRadius * 4 - this.dotSpacing) /
      (this.dotSpacing + this.secDotRadius * 2) + 2;
    for (let i = 0; i < spotCount; i++) {
      let spotCenter = 0;
      let spotRadius = 0;
      if (i === 0) {
        spotRadius = this.mainDotRadius;
        spotCenter = this.getPadding() + spotRadius;
        this.photoExtendOffCanvasContext.font = `bold ${vp2px(11)}px`;
        this.photoExtendOffCanvasContext.textAlign = 'center';
        this.photoExtendOffCanvasContext.fillText(`${this.state.minZoomRatio}x`,
          spotCenter, this.canvasHeight / 2 - 24);
      } else if (i === spotCount - 1) {
        spotRadius = this.mainDotRadius;
        spotCenter = this.extendCanvasWidth - this.getPadding() - spotRadius;
        this.photoExtendOffCanvasContext.font = `bold ${vp2px(11)}px`;
        this.photoExtendOffCanvasContext.textAlign = 'center';
        this.photoExtendOffCanvasContext.fillText(`${this.state.maxZoomRatio}x`,
          spotCenter, this.canvasHeight / 2 - 24);
      } else {
        spotRadius = this.secDotRadius;
        spotCenter = this.getPadding() + this.mainDotRadius + (2 * i - 1) * this.secDotRadius + i * this.dotSpacing;
      }
      if (spotCenter < this.getZoomBtnCenterX() - this.getZoomBtnRadius() ||
        spotCenter > this.getZoomBtnCenterX() + this.getZoomBtnRadius()) {
        this.photoExtendOffCanvasContext.beginPath();
        this.photoExtendOffCanvasContext.arc(spotCenter, this.canvasHeight / 2, spotRadius, 0, 6.28);
        this.photoExtendOffCanvasContext.fill();
      }
      this.photoExtendCanvasContext.transferFromImageBitmap(this.photoExtendOffCanvasContext.transferToImageBitmap());
    }
  }

  private takingVideoCanvasRefresh() {
    this.videoExtendCanvasContext.clearRect(0, 0, this.takingVideoExtCanvasWidth, this.canvasHeight);
    this.videoExtendOffCanvasContext.clearRect(0, 0, this.takingVideoExtCanvasWidth, this.canvasHeight);
    this.videoExtendOffCanvasContext.fillStyle = '#ffffff';
    let spotCount = 30;
    for (let i = 0; i < spotCount; i++) {
      let spotCenter = 0;
      let spotRadius = 0;
      spotRadius = this.secDotRadius;
      spotCenter = this.getPadding() + (2 * i + 1) * this.secDotRadius + i * this.dotSpacing;
      this.videoExtendOffCanvasContext.globalAlpha = 0.2;
      if (spotCenter < this.getZoomBtnCenterX() - this.getZoomBtnRadius() ||
        spotCenter > this.getZoomBtnCenterX() + this.getZoomBtnRadius()) {
        this.videoExtendOffCanvasContext.beginPath();
        this.videoExtendOffCanvasContext.arc(spotCenter, this.canvasHeight / 2, spotRadius, 0, 6.28);
        this.videoExtendOffCanvasContext.fill();
      }
      this.videoExtendOffCanvasContext.globalAlpha = 1;
    }

    this.videoExtendCanvasContext.transferFromImageBitmap(this.videoExtendOffCanvasContext.transferToImageBitmap());
  }

  private collapsCanvasRefresh() {
    this.collapsCanvasContext.clearRect(0, 0, this.collapsCanvasWidth, this.canvasHeight);
    this.collapsOffCanvasContext.clearRect(0, 0, this.collapsCanvasWidth, this.canvasHeight);
    this.collapsOffCanvasContext.strokeStyle = '#ffffff';
    this.collapsOffCanvasContext.fillStyle = '#ffffff';
    this.collapsOffCanvasContext.lineWidth = 2;
    this.collapsOffCanvasContext.beginPath();
    this.collapsOffCanvasContext.arc(this.collapsCanvasWidth / 2, this.canvasHeight / 2, this.getZoomBtnRadius(), 0, 6.28);
    this.collapsOffCanvasContext.stroke();
    this.collapsOffCanvasContext.font = `bold ${vp2px(10)}px`;
    this.collapsOffCanvasContext.textAlign = 'center';
    this.collapsOffCanvasContext.fillText(this.getZoomText(), this.collapsCanvasWidth / 2, this.canvasHeight / 2 + 3);

    let fullWidth = this.collapsCanvasWidth / 2 - this.mainDotRadius;
    let spotCount = Math.floor((fullWidth - this.mainDotRadius * 2 - this.dotSpacing) /
      (this.dotSpacing + this.secDotRadius * 2)) + 2;
    let spotOffset = this.zoomRatio === this.state.maxZoomRatio ? this.collapsCanvasWidth / 2 - fullWidth
      : this.collapsCanvasWidth / 2;
    HiLog.d(TAG, `track debug fullWidth: ${fullWidth}, spotCount: ${spotCount}, spotOffset: ${spotOffset}.`);
    for (let i = 0; i < spotCount; i++) {
      let spotCenter = 0;
      let spotRadius = 0;
      if (i === 0) {
        spotRadius = this.mainDotRadius;
        spotCenter = spotOffset + spotRadius;
        this.mFastZoomValueMap.set(this.state.minZoomRatio, spotCenter);
        HiLog.d(TAG, `track debug E spotCenter: ${spotCenter}.`);
      } else if (i === spotCount - 1) {
        spotRadius = this.mainDotRadius;
        spotCenter = spotOffset + this.mainDotRadius * 2 + (i - 1) * this.dotSpacing +
          (2 * i - 1) * this.secDotRadius - this.secDotRadius + spotRadius;
        this.mFastZoomValueMap.set(this.state.maxZoomRatio, spotCenter);
        HiLog.d(TAG, `track debug X spotCenter: ${spotCenter}.`);
      } else {
        spotRadius = this.secDotRadius;
        spotCenter = spotOffset + this.mainDotRadius * 2 + (i - 1) * this.dotSpacing +
          (2 * i - 1) * this.secDotRadius + spotRadius;
      }
      if (spotCenter < this.collapsCanvasWidth / 2 - this.getZoomBtnRadius() ||
        spotCenter > this.collapsCanvasWidth / 2 + this.getZoomBtnRadius()) {
        this.collapsOffCanvasContext.beginPath();
        this.collapsOffCanvasContext.arc(spotCenter, this.canvasHeight / 2, spotRadius, 0, 6.28);
        this.collapsOffCanvasContext.fill();
      }
    }
    this.collapsCanvasContext.transferFromImageBitmap(this.collapsOffCanvasContext.transferToImageBitmap());
  }
}