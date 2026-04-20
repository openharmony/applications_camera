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
/* instrument ignore file */

import lazy { RenderNode, DrawContext } from '@ohos.arkui.node';
import lazy { NativeFunction } from 'appnative/src/main/ets/nativeutil/nativefunction';
import lazy { HiLog } from '../../utils/HiLog';
import lazy { EntryExitAnimParam } from 'appnative/src/main/cpp/types/libappnative';
import lazy { ZoomParam } from './ZoomParam';
import lazy { CameraAppCapability } from '../../camera/CameraAppCapability';
import lazy { DisplayService } from '../../service/UIAdaptive/DisplayService';

const TAG: string = 'DrawZoomRenderNode';

export class DrawZoomRenderNode extends RenderNode {
  private zoomWidth: number = 0;
  private zoomHeight: number = 0;
  private drawHeight: number = 0;
  private densityPixels: number = 3.25;
  private quickZoomValArr: number[] = undefined;
  private quickEquivalentFocalArr: number[] = undefined;
  private opticalZoomValArr: number[] = undefined;
  private opticalZoomDotIndexArr: number[] = undefined;
  private cycleClickZoomArr: number[] = undefined;
  private isPrintEntryExitAnimParam: boolean = false;

  public curZoomVal: number = 1;
  public curZoomAngle: number = 1000;
  public curCollapsStatus: number = 0; // 定义(state.isShowDefault && isPhone()) ? 0 : state.isShowSemiCollapsed ? 2 : 1
  private curDirectionAngle: number = 0; // 定义rotateAngle - (state.isShowSemiCollapsed ? 180 : isShowLandscape ? 90 : 0)
  public entryExitAnimParam: EntryExitAnimParam = undefined;

  constructor(zoomWidth: number, zoomHeight: number, drawHeight: number, collapsStatus: number) {
    super();
    this.zoomWidth = zoomWidth;
    this.zoomHeight = zoomHeight;
    this.drawHeight = drawHeight;
    this.curCollapsStatus = collapsStatus;
    this.densityPixels = vp2px(1);
    HiLog.i(TAG, `constructor zoomWidth: ${zoomWidth}, zoomHeight: ${zoomHeight}, drawHeight: ${drawHeight},
     curCollapsStatus: ${collapsStatus}, densityPixels: ${this.densityPixels}.`);
    NativeFunction.setCameraAppCapabilityParams(CameraAppCapability.getInstance().getIsNovaProduct(),
      CameraAppCapability.getInstance().getIsSupportedEquivalentFocalBigText(),
      CameraAppCapability.getInstance().getIsSupportedCycleClickZoom());
  }

  public updateZoomLayout(zoomWidth: number, zoomHeight: number, drawHeight: number, collapsStatus: number,
    directionAngle: number): void {
    this.zoomWidth = zoomWidth;
    this.zoomHeight = zoomHeight;
    this.drawHeight = drawHeight;
    this.curCollapsStatus = collapsStatus;
    this.curDirectionAngle = directionAngle;
    HiLog.i(TAG, `updateZoomLayout zoomWidth: ${this.zoomWidth}, zoomHeight: ${this.zoomHeight},
     drawHeight: ${this.drawHeight}, collapsStatus: ${collapsStatus}.`);
    this.initNativeNodeData();
  }

  public updateZoomDensityPixels(densityPixels: number): void {
    this.densityPixels = densityPixels;
    HiLog.i(TAG, `updateZoomDensityPixels densityPixels: ${this.densityPixels}.`);
  }

  public initNode(mQuickZoomValArr: number[], mQuickEquivalentFocalArr: number[], mOpticalZoomValArr:
    number[], mOpticalZoomDotIndexArr: number[], mCycleClickZoomArr: number[]): void {
    const cycleArr: number[] = mCycleClickZoomArr ?? [];
    if (!this.isZoomArraySetValid(mQuickZoomValArr, mQuickEquivalentFocalArr, mOpticalZoomValArr,
      mOpticalZoomDotIndexArr)) {
      HiLog.w(TAG, 'initNode: invalid zoom arrays, skip native init and clear cache.');
      this.quickZoomValArr = [];
      this.quickEquivalentFocalArr = [];
      this.opticalZoomValArr = [];
      this.opticalZoomDotIndexArr = [];
      this.cycleClickZoomArr = [];
      return;
    }
    this.quickZoomValArr = mQuickZoomValArr;
    this.quickEquivalentFocalArr = mQuickEquivalentFocalArr;
    this.opticalZoomValArr = mOpticalZoomValArr;
    this.opticalZoomDotIndexArr = mOpticalZoomDotIndexArr;
    this.cycleClickZoomArr = cycleArr;
    HiLog.i(TAG, `quickZoomValArr: ${this.quickZoomValArr.toString()},
      quickEquivalentFocalArr: ${this.quickEquivalentFocalArr.toString()},
      opticalZoomValArr: ${this.opticalZoomValArr.toString()},
      opticalZoomDotIndexArr: ${this.opticalZoomDotIndexArr.toString()}.`);
    this.initNativeNodeData();
  }

  /** 与 native 约定：快捷/等效、光学/dot 下标须非空且两两长度一致，避免 native 越界 */
  private isZoomArraySetValid(quick: number[], quickEq: number[], optical: number[], opticalDot: number[]): boolean {
    if (!quick || !quickEq || !optical || !opticalDot) {
      return false;
    }
    if (quick.length === 0 || quickEq.length === 0 || optical.length === 0 || opticalDot.length === 0) {
      return false;
    }
    return quick.length === quickEq.length && optical.length === opticalDot.length;
  }

  public updateDirection(directionAngle: number): void {
    if (directionAngle === undefined || directionAngle === null) {
      return;
    }
    this.curDirectionAngle = directionAngle;
    NativeFunction.updateDirection(directionAngle);
  }

  private initNativeNodeData(): void {
    if (!this.checkParamIsSecure()) {
      return;
    }
    NativeFunction.initNode(1, this.zoomWidth, this.zoomHeight, this.drawHeight,
      this.curCollapsStatus, this.curDirectionAngle, this.densityPixels,
      Array.from(this.quickZoomValArr), Array.from(this.quickEquivalentFocalArr),
      Array.from(this.opticalZoomValArr), Array.from(this.opticalZoomDotIndexArr), Array.from(this.cycleClickZoomArr));
  }

  private checkParamIsSecure(): boolean {
    if (!this.zoomWidth || !this.zoomHeight || !this.drawHeight || !this.densityPixels) {
      return false;
    }
    return this.isZoomArraySetValid(this.quickZoomValArr, this.quickEquivalentFocalArr, this.opticalZoomValArr,
      this.opticalZoomDotIndexArr);
  }

  public execLandscapeSlideAnim(zoomValue: number, displacementDistance: number, animType: number): void {
    if (!this.opticalZoomValArr || this.opticalZoomValArr.length <= 0) {
      HiLog.i(TAG, 'opticalZoomValArr is undefined or null.');
      return;
    }
    NativeFunction.execLandscapeSlideAnim(
      this.opticalZoomValArr.findIndex((value: number, index: number) => {
        return value === zoomValue;
      }),
      displacementDistance,
      animType
    );
  }

  /*
   * RenderNode层均以vp单位
   * */
  draw(context: DrawContext): void {
    if (!this.checkParamIsSecure()) {
      return;
    }
    if (this.isPrintEntryExitAnimParam && this.entryExitAnimParam) { // 动效参数下发测试
      HiLog.i(TAG, `longCurveHaloMatteScale: ${this.entryExitAnimParam.longCurveHaloMatteScale},
        longCurveHaloOpacity: ${this.entryExitAnimParam.longCurveHaloOpacity},
        spherePosition: ${this.entryExitAnimParam.spherePosition}.`);
      HiLog.i(TAG, `sphereScale: ${this.entryExitAnimParam?.sphereScale},
        sphereColor: ${this.entryExitAnimParam?.sphereColor},
        sphereHaloOpacity: ${this.entryExitAnimParam?.sphereHaloOpacity}.`);
      HiLog.i(TAG, `redLineAndTextOpacity: ${this.entryExitAnimParam.redLineAndTextOpacity},
        scaleAllMatteScale: ${this.entryExitAnimParam.scaleAllMatteScale},
        scaleAllOpacity: ${this.entryExitAnimParam.scaleAllOpacity}.`);
      HiLog.i(TAG, `carmenLineMatteScale: ${this.entryExitAnimParam.carmenLineMatteScale},
        carmenLineOpacity: ${this.entryExitAnimParam.carmenLineOpacity},
        animType: ${this.entryExitAnimParam.animType}.`);
    }

    try {
      // ts层与native层每帧仅调用一次,避免多次调用加重上下文切换性能
      NativeFunction.onDraw(1, context, this.curZoomVal, this.curZoomAngle, this.entryExitAnimParam);
    } catch (err) {
      HiLog.e(TAG, `NativeFunction onDraw error: ${err}.`);
    }
  }

  public setCurZoomVal(curZoomVal: number): void {
    this.curZoomVal = curZoomVal;
  }

  public setCurZoomAngle(curZoomAngle: number): void {
    this.curZoomAngle = curZoomAngle;
  }

  public setEntryExitAnimParam(animParam: EntryExitAnimParam): void {
    this.entryExitAnimParam = animParam;
  }

  /**
   * 获取设备当前状态、旋转状态 是否为 字体与卡门线平行(即卡门线、刻度环、关键刻度字体、等效焦距字体4行平行状态)
   */
  public getIsTextParallel2CarmenLine(): boolean {
    let directionAngle =
      (this.curDirectionAngle % ZoomParam.THREE_HUNDRED_AND_SIXTY + ZoomParam.THREE_HUNDRED_AND_SIXTY) %
      ZoomParam.THREE_HUNDRED_AND_SIXTY;
    if ((this.curCollapsStatus === 0 || this.curCollapsStatus === 2) &&
      (directionAngle === 0 || directionAngle === ZoomParam.ONE_HUNDRED_AND_EIGHTY)) {
      return true;
    }
    if (this.curCollapsStatus === 1 && (directionAngle === 0 || directionAngle === ZoomParam.ONE_HUNDRED_AND_EIGHTY)) {
      return true;
    }
    return false;
  }
}