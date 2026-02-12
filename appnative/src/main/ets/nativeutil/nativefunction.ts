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

import native, { EntryExitAnimParam, AnimType } from 'libappnative.so';
import { DrawContext } from '@ohos.arkui.node';
import hilog from '@ohos.hilog';

const TAG: string = 'NativeFunction';

export class NativeFunction {
  public static initNode(id: number, width: number, height: number, drawHeight: number,
    collapsStatus: number, directionAngle: number, densityPixels: number,
    quickZoomValArr: number[], quickEquivalentFocalArr: number[],
    opticalZoomValArr: number[], opticalZoomDotIndexArr: number[],cycleClickZoomArr: number[]): void {

    native?.initNode(id, width, height, drawHeight, collapsStatus, directionAngle, densityPixels,
      quickZoomValArr, quickEquivalentFocalArr, opticalZoomValArr, opticalZoomDotIndexArr, cycleClickZoomArr);
  }

  public static updateDirection(direction: number): void {
    try {
      native?.updateDirection(direction);
    } catch (err) {
      hilog.error(0x00D00, TAG, `updateDirection: ${direction}.`);
    }
  }

  public static setCameraAppCapabilityParams(isNovaProduct: boolean, isSupportedEquivalentFocalBigText: boolean,
    isSupportedCycleClickZoom: boolean): void {
    try {
      native?.setCameraAppCapabilityParams(isNovaProduct, isSupportedEquivalentFocalBigText, isSupportedCycleClickZoom);
    } catch (err) {
      hilog.error(0x00D00, TAG, `setCameraAppCapabilityParams: ${isNovaProduct}, ${isSupportedEquivalentFocalBigText},
       ${isSupportedCycleClickZoom}`);
    }
  }

  public static execLandscapeSlideAnim(zoomIndex: number, displacementDistance: number, animType: number): void {
    try {
      native?.execLandscapeSlideAnim(zoomIndex, displacementDistance, animType);
    } catch (err) {
      hilog.error(0x00D00, TAG, `execLandscapeSlideAnim: ${zoomIndex}, ${displacementDistance}.`);
    }
  }

  public static onDraw(id: number, context: DrawContext, curZoomVal: number, curZoomAngle: number,
    animParam?: EntryExitAnimParam): void {
    try {
      hilog.info(0x00D00, TAG, `onDraw id: ${id}, curZoomVal: ${curZoomVal}, curZoomAngle: ${curZoomAngle}.`)
      native?.onDraw(id, context, curZoomVal, curZoomAngle, animParam);
    } catch (err) {
      hilog.error(0x00D00, TAG, `onDraw id: ${id}, curZoomVal: ${curZoomVal}, curZoomAngle: ${curZoomAngle}.`);
    }
  }

  public static async createMemory(): Promise<number> {
    return await native?.createMem();
  }

  public static async destroyAlgoMem(memoryHandler: number): Promise<number> {
    return await native?.destroyMem(memoryHandler);
  }

  public static async sendGyroscopeData(algoHandler: number, axisX: number, axisY: number, axisZ: number,
                                  timestamp: number, sensorType: number): Promise<number> {
    await native?.sendGyroscopeData(algoHandler, axisX, axisY, axisZ, timestamp, sensorType);
    return 0;
  }

  public static async jsProcessFrameDataCollBack(algoHandler: number, obj: Object, func: Function): Promise<number> {
    return await native?.jsProcessFrameDataCollBack(algoHandler, obj, func);
  }

  /**
   * Send frame data to algorithm to process.
   *
   * @param frameBytes The new frame data.
   * @return The process result.
   */
  public static async jsProcessFrameData(algoHandler: number, frameBytes: []): Promise<number> {
    return await native?.jsProcessFrameData(algoHandler, frameBytes);
  }

  /**
   * 初始化 imageReceiver
   * @returns
   */
  public static imageReceiverInit(width: number, height: number, capacity: number): number {
    return native?.imageReceiverInit(width, height, capacity);
  }

  /**
   * 获取imageReceiverSufferId
   */

  public static getImageReceiverSufferId(): string | undefined {
   return native?.getImageReceiverSufferId();
  }

  /**
   * 销毁 imageReceiverDestroy
   * @returns
   */
  public static imageReceiverDestroy(): number {
    return native?.imageReceiverDestroy();
  }

  public static async createNativeRoot(content: Object, bool: number): Promise<void> {
    await native?.createNativeRoot(content, bool);
  }

  public static async destroyNativeRoot(): Promise<void> {
    await native?.destroyNativeRoot();
  }

  public static async updateNativeRoot(width: number, height: number, offsetX: number, offsetY: number, visibility: number): Promise<void> {
    await native?.updateNativeRoot(width, height, offsetX, offsetY, visibility);
  }

}
