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

import geolocation from '@ohos.geolocation'

import AspectRatio from '../setting/settingitem/AspectRatio'
import AssistiveGrid from '../setting/settingitem/AssistiveGrid'
import { CameraId } from './settingitem/CameraId'
import { Log } from '../utils/Log'
import { Constants } from '../utils/Constants'
import DisplayCalculator from '../setting/DisplayCalculator'
import { RdbStoreManager } from '../setting/storage/RdbStoreManager'
import Resolution from '../setting/settingitem/Resolution'
import SaveGeoLocation from '../setting/settingitem/SaveGeoLocation'
import SelfMirror from '../setting/settingitem/SelfMirror'
import SettingItemInfo from '../setting/storage/SettingItemInfo'
import Timer from '../setting/settingitem/Timer'
import VideoCodec from '../setting/settingitem/VideoCodec'
import { Voice } from '../setting/settingitem/Voice'
import { EventBusManager } from '../worker/eventbus/EventBusManager';

export class SettingManager {
  private static TAG = '[SettingManager]:'
  private mRdbStoreManager: RdbStoreManager = RdbStoreManager.getInstance()
  private mEventBus = EventBusManager.getInstance().getEventBus()
  private mSettingsList = [
    AspectRatio,
    Resolution,
    AssistiveGrid,
    Timer,
    SelfMirror,
    SaveGeoLocation,
    VideoCodec,
    Voice
  ]
  private mAspectRatio: Resource
  private mResolution: Resource
  private mAssistiveGrid: string
  private mIsLoad = false
  private mTimer: Resource
  private mSelfMirror: string
  private mSaveGeoLocation: string
  private mCurGeoLocation = undefined
  private mVideoCodec: string
  private mCaptureMute: string

  public static getInstance(): SettingManager {
    Log.info(`${this.TAG} getInstance`)
    if (!AppStorage.Has(Constants.APP_KEY_SETTINGS_UTILS)) {
      AppStorage.SetOrCreate(Constants.APP_KEY_SETTINGS_UTILS, new SettingManager())
      Log.info(`${this.TAG} getInstance 'build new SettingManager`)
    }
    return AppStorage.Get(Constants.APP_KEY_SETTINGS_UTILS)
  }

  public setSettingValue(settingAlias, itemValue, mode: string) {
    Log.info(`${SettingManager.TAG} settingAlias = ${settingAlias} itemValue= ${itemValue}`)
    let needCommit = false
    if (settingAlias == AspectRatio.ALIAS) {
      this.mAspectRatio = itemValue
      this.mEventBus.emit("AspectRatio", [this.getPreviewDisplaySize(mode)])
      needCommit = true
    } else if (settingAlias == Resolution.ALIAS) {
      this.mResolution = itemValue
      this.mEventBus.emit("Resolution", [this.getPreviewDisplaySize(mode)])
      needCommit = true
    } else if (settingAlias == AssistiveGrid.ALIAS) {
      this.mAssistiveGrid = itemValue
      this.mEventBus.emit("AssistiveGrid", [this.mAssistiveGrid])
      needCommit = true
    } else if (settingAlias == Timer.ALIAS) {
      this.mTimer = itemValue
      needCommit = true
    } else if (settingAlias == SelfMirror.ALIAS) {
      this.mSelfMirror = itemValue
      needCommit = true
    } else if (settingAlias == SaveGeoLocation.ALIAS) {
      this.mSaveGeoLocation = itemValue
      needCommit = true
    } else if (settingAlias == VideoCodec.ALIAS) {
      this.mVideoCodec = itemValue
      needCommit = true
    } else if (settingAlias == Voice.ALIAS) {
      this.mCaptureMute = itemValue
      needCommit = true
    }
    const value = this.convertToString(settingAlias, itemValue)
    if (needCommit) {
      this.commit(settingAlias, value)
    }
  }

  public getSettingValue(settingAlias) {
    if (settingAlias == AspectRatio.ALIAS) {
      return this.mAspectRatio
    } else if (settingAlias == Resolution.ALIAS) {
      return this.mResolution
    } else if (settingAlias == Timer.ALIAS) {
      return this.mTimer
    } else if (settingAlias == AssistiveGrid.ALIAS) {
      return this.mAssistiveGrid
    } else if (settingAlias == SelfMirror.ALIAS) {
      return this.mSelfMirror
    } else if (settingAlias == SaveGeoLocation.ALIAS) {
      return this.mSaveGeoLocation
    } else if (settingAlias == VideoCodec.ALIAS) {
      return this.mVideoCodec
    } else if (settingAlias == Voice.ALIAS) {
      return this.mCaptureMute
    }
    Log.info(`${SettingManager.TAG}  ${settingAlias} don't have setting value`)
  }

  public async loadAllSetting() {
    Log.info(`${SettingManager.TAG} loadAllSetting E`)
    if (!this.mIsLoad) {
      for (let index = 0; index < this.mSettingsList.length; index++) {
        const settingAlias = this.mSettingsList[index].ALIAS
        const resultList: SettingItemInfo[] = await this.mRdbStoreManager.getSettingByItem(settingAlias)
        Log.info(`${SettingManager.TAG} loadAllSetting  settingAlias=${settingAlias} resultList = ${JSON.stringify(resultList)}`)
        if (resultList.length != 0) {
          Log.info(`${SettingManager.TAG} loadAllSetting `)
          for (let i = 0; i < resultList.length; i++) {
            Log.info(`${SettingManager.TAG} loadAllSetting getSettingValue` + +i + ': ' + resultList[i].itemValue)
          }
          const value = this.convertToResource(settingAlias, resultList[0].itemValue)
          if (settingAlias == AspectRatio.ALIAS) {
            this.mAspectRatio = value
          } else if (settingAlias == Resolution.ALIAS) {
            this.mResolution = value
          } else if (settingAlias == AssistiveGrid.ALIAS) {
            Log.log(SettingManager.TAG + ' this.mAssistiveGrid ' + this.mAssistiveGrid)
            this.mAssistiveGrid = value
          } else if (settingAlias == Timer.ALIAS) {
            this.mTimer = value
          } else if (settingAlias == SelfMirror.ALIAS) {
            this.mSelfMirror = value
          } else if (settingAlias == SaveGeoLocation.ALIAS) {
            this.mSaveGeoLocation = value
          } else if (settingAlias == VideoCodec.ALIAS) {
            this.mVideoCodec = value
          } else if (settingAlias == Voice.ALIAS) {
            this.mCaptureMute = value
          }
        }
      }
      this.setDefault(false)
      this.mIsLoad = true
    }
    Log.info(`${SettingManager.TAG} loadAllSetting X`)
  }

  private setDefault(force: boolean) {
    if (!this.mAspectRatio || force) {
      this.mAspectRatio = AspectRatio.DEFAULT_VALUE
    }
    if (!this.mResolution || force) {
      this.mResolution = Resolution.DEFAULT_VALUE
    }
    if (!this.mAssistiveGrid || force) {
      this.mAssistiveGrid = AssistiveGrid.DEFAULT_VALUE
    }
    if (!this.mTimer || force) {
      this.mTimer = Timer.DEFAULT_VALUE
    }
    if (!this.mSaveGeoLocation || force) {
      this.mSaveGeoLocation = '1'
    }
    if (!this.mCaptureMute || force) {
      this.mCaptureMute = Voice.MUTE
    }
  }

  public restoreValues(mode: string) {
    for (let i = 0; i < this.mSettingsList.length; i++) {
      this.setSettingValue(this.mSettingsList[i].ALIAS, this.mSettingsList[i].DEFAULT_VALUE, mode)
    }
  }

  private async commit(settingAlias, itemValue) {
    Log.info(`${SettingManager.TAG} getInstance  settingAlias: ${settingAlias} itemValue ${itemValue}`)
    const settingItemInfo: SettingItemInfo = new SettingItemInfo()
    settingItemInfo.itemName = settingAlias
    settingItemInfo.itemValue = itemValue
    await this.mRdbStoreManager.updateValue(settingItemInfo)
  }

  public mScreenWidth: number
  public mScreenHeight: number
  private mPlatformCapability
  private mCameraId: string

  public setCameraPlatformCapability(platformCapability) {
    this.mPlatformCapability = platformCapability
  }

  public setCameraId(cameraId: string) {
    this.mCameraId = cameraId
  }

  public getImageSize() {
    return AspectRatio.getImageSize(this.mPlatformCapability, this.mCameraId, this.mAspectRatio)
  }

  public getVideoSize() {
    return Resolution.getVideoFrameSize(this.mPlatformCapability, this.mCameraId, this.mResolution)
  }

  public setScreenWidth(width: number) {
    this.mScreenWidth = width
  }

  public setScreenHeight(height: number) {
    this.mScreenHeight = height
  }

  public getPreviewSize(mode: string) {
    if (mode == 'VIDEO') {
      return Resolution.getVideoPreviewSize(this.mPlatformCapability, this.mCameraId, this.mResolution)
    } else {
      return AspectRatio.getPhotoPreviewSize(this.mPlatformCapability, this.mCameraId, this.mAspectRatio)
    }
  }

  public getPreviewDisplaySize(mode: string) {
    const preViewSize = this.getPreviewSize(mode)
    return DisplayCalculator.calcSurfaceDisplaySize(this.mScreenWidth, this.mScreenHeight, preViewSize.width, preViewSize.height)
  }

  public getAssistiveGrid() {
    return this.mAssistiveGrid
  }

  public getTimeLapse() {
    return this.mTimer
  }

  public getSelfMirror() {
    return this.mSelfMirror === '1'
  }

  public getSaveGeoLocation() {
    return this.mSaveGeoLocation === '1'
  }

  public setCurGeoLocation(location) {
    this.mCurGeoLocation = location
  }

  public getCurGeoLocation() {
    if (this.getSaveGeoLocation()) {
      return this.mCurGeoLocation
    } else {
      return undefined
    }
  }

  public getVideoCodec() {
    if (this.mVideoCodec === '1') {
      return 'video/mp4v-es'
    } else {
      return 'video/mp4v-es'
    }
  }

  public getCaptureMute() {
    return this.mCaptureMute
  }

  private convertToString(settingAlias, itemValue) {
    if (settingAlias == AspectRatio.ALIAS) {
      return AspectRatio.convertToString(itemValue)
    } else if (settingAlias == Resolution.ALIAS) {
      return Resolution.convertToString(itemValue)
    } else if (settingAlias == Timer.ALIAS) {
      return Timer.convertToString(itemValue)
    } else {
      return itemValue
    }
  }

  private convertToResource(settingAlias, value) {
    if (settingAlias == AspectRatio.ALIAS) {
      return AspectRatio.convertToResource(value)
    } else if (settingAlias == Resolution.ALIAS) {
      return Resolution.convertToResource(value)
    } else if (settingAlias == Timer.ALIAS) {
      return Timer.convertToResource(value)
    } else {
      return value
    }
  }
}