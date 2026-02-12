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

import lazy { image } from '@kit.ImageKit';
import lazy { photoAccessHelper } from '@kit.MediaLibraryKit';
import lazy { FeatureManager } from '../function/core/FeatureManager';
import lazy { FunctionId } from '../function/core/functionproperty/FunctionId';
import lazy { OutputOperation } from '../function/outputswitcher/OutputOperation';
import lazy { OutputSwitcher } from '../function/outputswitcher/OutputSwitcher';
import lazy { ModeType } from '../mode/ModeType';
import lazy { getStates } from '../redux/Store';
import lazy { HiLog } from './HiLog';

const TAG: string = 'PhotoBrowserOperation';

export class PhotoBrowserOperation {

  /*
   * 传递captureId/mediaUri给大图
   * @param l157 captureId或mediaUri
   * @param pixmap 快速缩略图 可选参数
   */
  public static setCurrentMediaUri(browserController, l157?: string, pixmap?: image.PixelMap): void {
    let curMode = getStates().get<ModeType>('modeReducer', 'mode');
    HiLog.i(TAG, `setCurrentMediaUri l157: ${l157},pixmap: ${pixmap}, pixmap=${pixmap ===
      null} isEditable: ${pixmap?.isEditable}.`);
    if (!OutputOperation.isPanPhotoOutput(curMode, OutputSwitcher.getInstance().getOutput(curMode)) ||
      pixmap === null || pixmap?.isEditable === undefined) {
      HiLog.i(TAG, `setCurrentMediaUri captureid: ${l157}.`);
      browserController?.setCurrentMediaUri(l157);
      return;
    }
    HiLog.i(TAG, `setCurrentMediaUri l157: ${l157}, isEditable: ${pixmap?.isEditable}.`);
    browserController?.setCurrentMediaUri(l157, pixmap);
  }

  /**
   * 增加缩略图（注：相机需保证按序调用此接口新增缩略图）
   *
   * @param captureId 缩略图ID
   * @param pixmap 真正的缩略图
   */
  public static addThumbnail(browserController, captureId: string, pixmap: image.PixelMap): void {
    let params = new Map<string, string>();
    params.set('cameraMode', getStates().get<ModeType>('modeReducer', 'mode'));
    browserController?.addThumbnail(captureId, pixmap, false, params);
  }

  /**
   * 更新缩略图
   *
   * @param captureId 缩略图ID
   * @param photoAsset 图片基本信息
   */
  public static updateThumbnail(browserController, captureId: string, photoAsset: photoAccessHelper.PhotoAsset): void {
    browserController?.updateThumbnail(captureId, photoAsset);
  }

  /**
   * 删除缩略图（用于连拍场景的删除）
   *
   * @param captureId 缩略图ID
   */
  public static removeThumbnail(browserController, captureId: string): void {
    browserController?.removeThumbnail(captureId);
  }

}