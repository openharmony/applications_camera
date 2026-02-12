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

import lazy { NodeController, FrameNode, RenderNode } from '@ohos.arkui.node'
import lazy { UIContext } from '@ohos.arkui.UIContext';
import lazy { DrawZoomRenderNode } from './DrawZoomRenderNode';
import lazy { HiLog } from '../../utils/HiLog';
import lazy { EntryExitAnimParam } from 'appnative/src/main/cpp/types/libappnative';
import animator, { AnimatorOptions, AnimatorResult } from '@ohos.animator';
import lazy { ZoomOuterStatus } from './ZoomStateType';
import lazy { getStates } from '../../redux';

/* instrument ignore file */
const TAG: string = 'ZoomNodeController';

export class ZoomNodeController extends NodeController {
  private rootNode: FrameNode | null = null;
  private renderNode: RenderNode | null = null;
  private zoomRenderNode: DrawZoomRenderNode | null = null;
  private curDirectionAngle: number = 0;
  private mStateChangeAnimator: AnimatorResult | null = null; // 横竖屏旋转角度native动效下发执行器
  private curLandscapeSlideType: number = 0; // 1: 展开动效, 2: 收起动效, 5: 展开暂态, 0: 其它
  private mLandscapeSlideAnimator: AnimatorResult | null = null; // 横屏滑动展开/归位native动效下发执行器

  constructor(zoomWidth: number, zoomHeight: number, drawHeight: number, collapsStatus: number) {
    super();
    this.zoomRenderNode = new DrawZoomRenderNode(zoomWidth, zoomHeight, drawHeight, collapsStatus);
    this.zoomRenderNode.frame = { x: 0, y: 0, width: zoomWidth, height: zoomHeight };
    this.zoomRenderNode.backgroundColor = Color.White;
  }

  public updateZoomLayout(zoomWidth: number, zoomHeight: number, drawHeight: number, collapsStatus: number,
    directionAngle: number): void {
    let curZoomWidth: number = zoomWidth;
    this.zoomRenderNode?.updateZoomLayout(curZoomWidth, zoomHeight, drawHeight, collapsStatus, directionAngle);
    if (this.zoomRenderNode) {
      this.zoomRenderNode.frame = {
        x: 0,
        y: 0,
        width: zoomWidth,
        height: zoomHeight
      };
    }
  }

  public updateZoomDensityPixels(densityPixels: number): void {
    this.zoomRenderNode?.updateZoomDensityPixels(densityPixels);
  }

  public initNode(mQuickZoomValArr: number[], mQuickEquivalentFocalArr: number[], mOpticalZoomValArr:
    number[], mOpticalZoomDotIndexArr: number[]): void {

    this.zoomRenderNode?.initNode(mQuickZoomValArr, mQuickEquivalentFocalArr, mOpticalZoomValArr,
      mOpticalZoomDotIndexArr, this.getCycleClickZoomArr(mQuickZoomValArr, mOpticalZoomValArr));
  }

  public updateDirection(directionAngle: number): void {
    if (getStates().get<string>('zoomReducer', 'zoomState') !== ZoomOuterStatus.ROULETTE_ZOOM) {
      this.zoomRenderNode?.updateDirection(directionAngle);
      this.curDirectionAngle = directionAngle;
      return;
    }

    this.mStateChangeAnimator?.cancel(); // 横竖屏旋转字体切换动效
    let options: AnimatorOptions = {
      duration: 200,
      easing: 'friction',
      delay: 0,
      fill: 'forwards',
      direction: 'normal',
      iterations: 1,
      begin: this.curDirectionAngle,
      end: directionAngle
    };
    if (this.mStateChangeAnimator !== null) {
      try {
        this.mStateChangeAnimator.reset(options);
      } catch (error) {
        HiLog.e(TAG, `mStateChangeAnimator error: ${error?.code}.`);
      }
    } else {
      this.mStateChangeAnimator = animator.create(options);
    }
    this.mStateChangeAnimator.onFinish = () => {
      this.curDirectionAngle = directionAngle;
      HiLog.i(TAG, `updateDirection finish curDirectionAngle: ${this.curDirectionAngle}.`);
      if (!this.getIsTextParallel2CarmenLine()) {
        let zoomVal = this.zoomRenderNode?.curZoomVal;
        this.execLandscapeSlideExpandAnim(zoomVal ? zoomVal : 1); // 横屏滑动关键刻度展开动效
      }
    };
    this.mStateChangeAnimator.onFrame = (value) => {
      this.curDirectionAngle = value;
      this.zoomRenderNode?.updateDirection(value);
      this.zoomRenderNode?.invalidate();
    };
    this.mStateChangeAnimator?.play();
  }

  makeNode(uiContext: UIContext): FrameNode {
    this.rootNode = new FrameNode(uiContext);
    if (this.rootNode === null) {
      return this.rootNode;
    }
    this.renderNode = this.rootNode.getRenderNode();
    if (this.renderNode !== null) {
      this.renderNode.appendChild(this.zoomRenderNode);
    }
    return this.rootNode;
  }

  public async invalidate(toZoomValue: number, toZoomAngle: number, animParam?: EntryExitAnimParam): Promise<void> {
    this.zoomRenderNode?.setCurZoomVal(toZoomValue);
    this.zoomRenderNode?.setCurZoomAngle(toZoomAngle);
    this.zoomRenderNode?.setEntryExitAnimParam(animParam);
    this.zoomRenderNode?.invalidate();
    if (this.curLandscapeSlideType === 5) {
      this.execLandscapeSlideRepositionAnim();
    }
  }

  public getIsTextParallel2CarmenLine(): boolean {
    return this.zoomRenderNode?.getIsTextParallel2CarmenLine() ? true : false;
  }

  public execLandscapeSlideExpandAnim(zoomValue: number): void { // 横屏滑动关键刻度展开动效
    HiLog.i(TAG, 'execLandscapeSlideExpandAnim E.');
    this.mLandscapeSlideAnimator?.cancel();
    this.curLandscapeSlideType = 1; // 准备进入展开动效
    let options: AnimatorOptions = {
      duration: 150,
      easing: 'friction',
      delay: 0,
      fill: 'forwards',
      direction: 'normal',
      iterations: 1,
      begin: 0,
      end: 1
    };
    if (this.mLandscapeSlideAnimator !== null) {
      try {
        this.mLandscapeSlideAnimator.reset(options);
      } catch (error) {
        HiLog.e(TAG, `mLandscapeSlideAnimator error: ${error?.code}.`);
      }
    } else {
      this.mLandscapeSlideAnimator = animator.create(options);
    }
    this.mLandscapeSlideAnimator.onFinish = () => {
      HiLog.i(TAG, 'execLandscapeSlideExpandAnim finish.');
      this.curLandscapeSlideType = 5; // 进入暂态
    };
    this.mLandscapeSlideAnimator.onFrame = (value) => {
      this.zoomRenderNode?.execLandscapeSlideAnim(zoomValue, value, this.curLandscapeSlideType);
      HiLog.i(TAG, `execLandscapeSlideExpandAnim onFrame zoomValue: ${zoomValue}, value: ${value}, 1.`);
      this.zoomRenderNode?.invalidate();
    };
    this.mLandscapeSlideAnimator?.play();
  }

  public execLandscapeSlideRepositionAnim(): void { // 横屏滑动关键刻度点收起动效
    HiLog.i(TAG, `execLandscapeSlideRepositionAnim E.`);
    this.mLandscapeSlideAnimator?.cancel();
    this.curLandscapeSlideType = 2; // 准备进入收起动效
    let options: AnimatorOptions = {
      duration: 150,
      easing: 'friction',
      delay: 0,
      fill: 'forwards',
      direction: 'normal',
      iterations: 1,
      begin: 1,
      end: 0
    };
    if (this.mLandscapeSlideAnimator !== null) {
      try {
        this.mLandscapeSlideAnimator.reset(options);
      } catch (error) {
        HiLog.e(TAG, `mLandscapeSlideAnimator error: ${error?.code}.`);
      }
    } else {
      this.mLandscapeSlideAnimator = animator.create(options);
    }
    this.mLandscapeSlideAnimator.onFinish = () => {
      HiLog.i(TAG, 'execLandscapeSlideRepositionAnim finish.');
      this.curLandscapeSlideType = 0; // 结束
      this.zoomRenderNode?.execLandscapeSlideAnim(0, 0, this.curLandscapeSlideType);
    };
    this.mLandscapeSlideAnimator.onFrame = (value) => {
      this.zoomRenderNode?.execLandscapeSlideAnim(0, value, this.curLandscapeSlideType);
      HiLog.i(TAG, `execLandscapeSlideRepositionAnim onFrame zoomValue: ${0}, value: ${value}, 2.`);
      this.zoomRenderNode?.invalidate();
    };
    this.mLandscapeSlideAnimator?.play();
  }

  // 更新当前模式的循环点切数组，除了最后一个光学变焦点的值，和快捷变焦点的差值就支持循环点切的值
  private getCycleClickZoomArr(quickZoomValArr: number[], opticalZoomValArr: number[]): number[] {
    let cycleClickZoomArr: number[] = [];
    if (opticalZoomValArr.length < 1) {
      return [];
    }
    opticalZoomValArr.forEach((zoomValue: number) => {
      if (quickZoomValArr.indexOf(zoomValue) === -1 &&
        zoomValue < opticalZoomValArr[opticalZoomValArr.length -1]) {
        cycleClickZoomArr.push(zoomValue);
      }
    })
    HiLog.i(TAG, `get cycleClickZoomArr ${cycleClickZoomArr}`);
    return cycleClickZoomArr;
  }

}