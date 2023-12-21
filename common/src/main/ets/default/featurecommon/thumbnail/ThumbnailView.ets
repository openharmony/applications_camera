/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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

import { Log } from '../../utils/Log';
import { Dispatch, OhCombinedState } from '../../redux/store';
import { getStore } from '../../redux/store';
import { Action } from '../../redux/actions/Action';
import { EventBus } from '../../worker/eventbus/EventBus';
import { EventBusManager } from '../../worker/eventbus/EventBusManager';
import ReportUtil from '../../utils/ReportUtil';
import { CameraService } from '../../camera/CameraService';
import { GlobalContext } from '../../utils/GlobalContext';
import Want from '@ohos.app.ability.Want';

class StateStruct {
  thumbnail: Resource = $r('app.media.ic_camera_thumbnail_default_white');
}

class UpdateThumbnailStruct {
  thumbnail: PixelMap | undefined = undefined;
  resourceUri: string = '';
}

class ThumbnailStruct {
  thumbnail: PixelMap | undefined = undefined;
}

class StartAbilityParameterStruct {
  uri: string = '';
}

class ThumbnailViewDispatcher {
  private mDispatch: Dispatch = (data) => data;

  public setDispatch(dispatch: Dispatch) {
    this.mDispatch = dispatch;
  }
}

@Component
export struct ThumbnailView {
  private TAG: string = '[ThumbnailView]:'
  private appEventBus: EventBus = EventBusManager.getInstance().getEventBus()
  @State thumbnailBorder: BorderOptions = {};
  @State state: StateStruct = new StateStruct()
  @State thumbnail: Resource | PixelMap = $r('app.media.ic_camera_thumbnail_default_white')
  @State hasThumbnail: boolean = false
  @State scaleValue: number = 1
  @State tempOpacity: number = 1
  private cameraService = CameraService.getInstance()
  private mAction: ThumbnailViewDispatcher = new ThumbnailViewDispatcher();

  private async onThumbnailUpdate(data: UpdateThumbnailStruct): Promise<void> {
    Log.info(`${this.TAG} onThumbnailUpdate data: ${JSON.stringify(data)} E`)
    this.thumbnail = (data.thumbnail == null ? $r('app.media.ic_camera_thumbnail_default_white') : data.thumbnail)
    this.hasThumbnail = data.thumbnail != undefined
    if (this.hasThumbnail) {
      this.thumbnailBorder = { width: 1, color: Color.White, style: BorderStyle.Solid }
    } else {
      this.thumbnailBorder = { width: 0 }
    }
    this.scaleValue = 1.5
    this.tempOpacity = 0.0
    animateTo({ duration: 100, curve: Curve.Sharp }, () => {
      this.tempOpacity = 1
    })
    animateTo({ duration: 300, curve: Curve.Sharp }, () => {
      this.scaleValue = 1
    })
    Log.info(`${this.TAG} onThumbnailUpdate this.state.thumbnail: ${JSON.stringify(this.thumbnail)} X`)
  }

  private async onThumbnailLoad(data: ThumbnailStruct): Promise<void> {
    Log.info(`${this.TAG} onThumbnailLoad data: ${JSON.stringify(data)} E`)
    this.thumbnail = (data.thumbnail == null ? $r('app.media.ic_camera_thumbnail_default_white') : data.thumbnail)
    this.hasThumbnail = data.thumbnail != undefined
    if (this.hasThumbnail) {
      this.thumbnailBorder = { width: 1, color: Color.White, style: BorderStyle.Solid }
    } else {
      this.thumbnailBorder = { width: 0 }
    }
    this.scaleValue = 1
    this.tempOpacity = 1
    Log.info(`${this.TAG} onThumbnailLoad this.state.thumbnail: ${JSON.stringify(this.thumbnail)} X`)
  }

  aboutToAppear() {
    Log.info(`${this.TAG} aboutToAppear E`)
    getStore().subscribe((state: OhCombinedState) => {
      this.state = {
        thumbnail: state.cameraInitReducer.thumbnail
      };
    }, (dispatch: Dispatch) => {
      this.mAction.setDispatch(dispatch);
    });
    this.appEventBus.on(Action.ACTION_UPDATE_THUMBNAIL, (data: UpdateThumbnailStruct) => this.onThumbnailUpdate(data));
    this.appEventBus.on(Action.ACTION_LOAD_THUMBNAIL, (data: ThumbnailStruct) => this.onThumbnailLoad(data));
    Log.info(`${this.TAG} aboutToAppear X`)
  }

  aboutToDisappear(): void {
    Log.info(`${this.TAG} aboutToDisappear E`)
    this.appEventBus.off(Action.ACTION_UPDATE_THUMBNAIL, (data: UpdateThumbnailStruct) => this.onThumbnailUpdate(data))
    this.appEventBus.off(Action.ACTION_LOAD_THUMBNAIL, (data: ThumbnailStruct) => this.onThumbnailLoad(data));
    Log.info(`${this.TAG} aboutToDisappear X`)
  }

  build() {
    Column() {
      Stack() {
        Image(this.thumbnail)
          .width('100%').aspectRatio(1).borderRadius(22).objectFit(ImageFit.Fill)
      }
      .width('100%').height('100%')
      .enabled(this.hasThumbnail)
      .onClick(async () => {
        Log.info(`${this.TAG} launch bundle com.ohos.photos`)
        ReportUtil.write(ReportUtil.CLICK_THUMBNAIL)
        GlobalContext.get().setObject('keepCameraZoomRatio', true);
        const recentUri: string = this.cameraService.getRecentFileUri();
        Log.info(`${this.TAG} uri === ` + recentUri)
        const abilityParameter: Record<string, string> = { 'uri': recentUri };
        await GlobalContext.get().getCameraAbilityContext().startAbility(this.buildCameraAbilityWant(abilityParameter))
      })
    }
    .width(44)
    .aspectRatio(1)
    .borderRadius(22)
    .border(this.thumbnailBorder)
    .opacity(this.tempOpacity)
    .scale({ x: this.scaleValue, y: this.scaleValue })
  }

  private buildCameraAbilityWant(parameter: Record<string, string>): Want {
    let res: Want = {
      parameters: parameter,
      action: 'ohos.want.action.viewData',
      bundleName: 'com.ohos.photos',
      abilityName: 'com.ohos.photos.MainAbility'
    };
    return res;
  }
}