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

import type { ActionData } from '../../redux/actions/Action';
import type image from '@ohos.multimedia.image';
import lazy { photoAccessHelper } from '@kit.MediaLibraryKit';
import lazy { ThumbnailActionType } from '../../redux/actions/ThumbnailActionType';

const PREFIX: string = 'THUMBNAIL_ACTION_';

export enum ThumbnailUpdateScene {
  REFRESH = 'REFRESH',
  CAPTURE = 'CAPTURE',
  RECORD = 'RECORD',
  BURST = 'BURST',
  MIRROR = 'MIRROR'
}

export class ThumbnailAction {

  // 刷新缩略图，场景包括：首次打开相机，后台切前台等
  public static refresh(isRefreshDefaultThumbnail?: boolean): ActionData {
    return {
      isEvent: true,
      type: ThumbnailActionType.REFRESH,
      data: { isRefreshDefaultThumbnail: isRefreshDefaultThumbnail }
    };
  }

  // 从媒体库或框架获得缩略图
  public static received(thumbnailPixelMap: image.PixelMap, scene: ThumbnailUpdateScene): ActionData {
    return {
      isEvent: true,
      type: ThumbnailActionType.RECEIVED,
      data: { thumbnail: thumbnailPixelMap, scene: scene }
    };
  }

  public static animation(): ActionData {
    return {
      isEvent: true,
      type: ThumbnailActionType.ANIMATION,
      data: {}
    };
  }

  // 更新打开大图状态
  public static updatePhotoBrowser(photoBrowserStatus: boolean, isTriggeredByBack: boolean = false): ActionData {
    return {
      isEvent: true,
      type: ThumbnailActionType.PHOTOBROWSER_STATUS,
      data: { photoBrowserStatus: photoBrowserStatus, isTriggeredByBack: isTriggeredByBack }
    };
  }

  public static updatePhotoBrowserTouch(photoBrowserTouchStatus: boolean): ActionData {
    return {
      isEvent: true,
      type: ThumbnailActionType.PHOTOBROWSER_TOUCH_STATUS,
      data: { photoBrowserTouchStatus : photoBrowserTouchStatus}
    };
  }

  public static browserAddThumbnail(captureId: string, thumbnail: image.PixelMap): ActionData {
    return {
      isEvent: true,
      type: ThumbnailActionType.BROWSER_ADD_THUMBNAIL,
      data: { captureId: captureId, thumbnail: thumbnail }
    };
  }

  public static browserUpdateThumbnailAsset(captureId: string, photoAsset: photoAccessHelper.PhotoAsset): ActionData {
    return {
      isEvent: true,
      type: ThumbnailActionType.BROWSER_UPDATE_THUMBNAIL_ASSET,
      data: { captureId: captureId, photoAsset: photoAsset }
    };
  }

  // 回退缩略图到上一张，在删除照片时触发
  public static rollBack(lastThumbnail: image.PixelMap | undefined): ActionData {
    return {
      isEvent: true,
      type: ThumbnailActionType.ROLL_BACK,
      data: { lastThumbnail : lastThumbnail }
    };
  }

  public static changeThumbnail(thumbnail: image.PixelMap | undefined, hasAnimate: boolean): ActionData {
    return {
      isEvent: true,
      type: ThumbnailActionType.CHANGE_THUMBNAIL,
      data: { thumbnail : thumbnail, hasAnimate: hasAnimate }
    };
  }

  public static pcPickerReceived(pcPickerPhotoMap: Map<string, image.PixelMap>): ActionData {
    return {
      isEvent: true,
      type: ThumbnailActionType.PC_PICKER_RECEIVED,
      data: { pcPickerPhotoMap: pcPickerPhotoMap }
    };
  }
}