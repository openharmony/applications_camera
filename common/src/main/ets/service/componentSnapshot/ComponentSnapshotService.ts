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

import type { ModeType } from '../../mode/ModeType';
import lazy { image } from '../../utils/LazyImportUtil';
import camera from '@ohos.multimedia.camera';
import lazy { OutputOperation } from '../../function/outputswitcher/OutputOperation'
import lazy { FeatureManager } from '../../function/core/FeatureManager'
import lazy { FunctionId } from '../../function/core/functionproperty/FunctionId'
import lazy { VideoResolutionOperation } from '../../function/videoresolution/VideoResolutionOperation';
import lazy { AspectRatioOperation } from '../../function/aspectratio/AspectRatioOperation';
import lazy { HiLog } from '../../utils/HiLog';
import lazy { XComponentService } from '../../component/xcomponent/XComponentService';
import lazy { getStates } from '../../redux'
import lazy { componentSnapshot } from '@kit.ArkUI'

const TAG = 'ComponentSnapshotService';

export class ComponentSnapshotService {
  private static sInstanceSnapshotService: ComponentSnapshotService;
  private isInSnapshot: boolean = false;

  private constructor() {
  }

  public static getInstance(): ComponentSnapshotService {
    if (ComponentSnapshotService.sInstanceSnapshotService == null) {
      ComponentSnapshotService.sInstanceSnapshotService = new ComponentSnapshotService();
    }
    return ComponentSnapshotService.sInstanceSnapshotService;
  }

  public generateSnapshotImg(currentMode: ModeType): null | image.PixelMap {
    let previewProfile: camera.Profile;
    const cameraPosition: camera.CameraPosition =
      getStates().get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
    if (OutputOperation.isPanPhotoOutput(currentMode)) {
      let videoResolution: number = FeatureManager.getInstance().getFunction(FunctionId.VIDEO_RESOLUTION)?.getValue();
      previewProfile = VideoResolutionOperation.getPreviewProfile(videoResolution, cameraPosition, currentMode);
    } else {
      let aspectRation: number = FeatureManager.getInstance().getFunction(FunctionId.ASPECT_RATIO)?.getValue();
      previewProfile = AspectRatioOperation.getPreviewProfile(aspectRation, cameraPosition, currentMode);
    }
    const surface = XComponentService.getInstance().getSurface();
    let screenshotPixMap: image.PixelMap | undefined = undefined;
    try {
      HiLog.begin(TAG, 'createPixelMapFromSurface');
      screenshotPixMap = image.createPixelMapFromSurfaceSync(surface, {
        size: { width: previewProfile.size.width, height: previewProfile.size.height }, x: 0, y: 0
      })
    } catch (error) {
      HiLog.e(TAG, 'generateSnapshotImg createPixelMapFromSurfaceSync error: ' + JSON.stringify(error));
      return null;
    }
    try {
      if (screenshotPixMap !== undefined) {
        screenshotPixMap.setMemoryNameSync(TAG);
      }
      HiLog.end(TAG, 'createPixelMapFromSurface')
    } catch (error) {
      HiLog.e(TAG, 'generateSnapshotImg setMemoryNameSync error: ' + JSON.stringify(error));
    }
    return screenshotPixMap;
  }

  public setIsInSnapshot(isInSnapshot: boolean) {
    this.isInSnapshot = isInSnapshot;
  }

  public getInSnapshot() {
    return this.isInSnapshot;
  }

  public getInSnapshotByComponentId(id: string) {
    return componentSnapshot.getSync(id);
  }
}