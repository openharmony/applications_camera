/*
 * Copyright (c) 2022 Huawei Device Co., Ltd.
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

import AspectRatio from '../setting/AspectRatio'
import { CameraId } from '../setting/CameraId'
import { CLog } from '../Utils/CLog'
import { Constants } from './Constants'
import DisplayUtil from './DisplayUtil'
import RdbStoreManager from './RdbStoreManager'
import Resolution from '../setting/Resolution'
import SettingItemInfo from './SettingItemInfo'
import AssistiveGrid from '../setting/AssistiveGrid'

export class SettingsUtil {
  private static TAG: string = '[SettingsUtil]:'
  private mRdbStoreManager: RdbStoreManager = RdbStoreManager.getInstance()
  private mSettingAliasList = [AspectRatio.ALIAS, Resolution.ALIAS, AssistiveGrid.ALIAS]
  private mAspectRatio: string
  private mResolution: string
  private mAssistiveGrid: string
  private mIsLoad: boolean = false

  public static getInstance(): SettingsUtil {
    CLog.info(`${this.TAG} getInstance`)
    if (!AppStorage.Has(Constants.APP_KEY_SETTINGS_UTILS)) {
      AppStorage.SetOrCreate(Constants.APP_KEY_SETTINGS_UTILS, new SettingsUtil())
      CLog.info(`${this.TAG} getInstance 'build new SettingsUtil`)
    }
    return AppStorage.Get(Constants.APP_KEY_SETTINGS_UTILS);
  }

  public setSettingValue(settingAlias, itemValue) {
    CLog.info(`${SettingsUtil.TAG} settingAlias = ${settingAlias} itemValue= ${itemValue}`)
    let needCommit = false
    if (settingAlias == AspectRatio.ALIAS) {
      this.mAspectRatio = itemValue
      needCommit = true
    } else if (settingAlias == Resolution.ALIAS) {
      this.mResolution = itemValue
      needCommit = true
    } else if (settingAlias == AssistiveGrid.ALIAS) {
      this.mAssistiveGrid = itemValue
      needCommit = true
    }
    if (needCommit) {
      this.commit(settingAlias, itemValue)
    }
  }

  public async getSettingValue(settingAlias) {
    if (settingAlias == AspectRatio.ALIAS) {
      return this.mAspectRatio
    } else if (settingAlias == Resolution.ALIAS) {
      return this.mResolution
    } else if (settingAlias == AssistiveGrid.ALIAS) {
      return this.mAssistiveGrid
    }
    CLog.info(`${SettingsUtil.TAG}  ${settingAlias} don't have setting value`)
  }

  public async loadAllSetting() {
    CLog.info(`${SettingsUtil.TAG} loadAllSetting E`)
    if (!this.mIsLoad) {
      for (var index = 0; index < this.mSettingAliasList.length; index++) {
        const settingAlias = this.mSettingAliasList[index];
        let resultList: SettingItemInfo[] = await this.mRdbStoreManager.getSettingByItem(settingAlias)
        CLog.info(`${SettingsUtil.TAG} loadAllSetting  settingAlias=${settingAlias} resultList = ${JSON.stringify(resultList)}`)
        if (resultList.length != 0) {
          CLog.info(`${SettingsUtil.TAG} loadAllSetting `)
          for (let i = 0; i < resultList.length; i++) {
            CLog.info(`${SettingsUtil.TAG} loadAllSetting getSettingValue` + +i + ': ' + resultList[i].itemValue)
          }
          let value = resultList[0].itemValue
          if (settingAlias == AspectRatio.ALIAS) {
            this.mAspectRatio = value
          } else if (settingAlias == Resolution.ALIAS) {
            this.mResolution = value
          } else if (settingAlias == AssistiveGrid.ALIAS) {
            CLog.log(SettingsUtil.TAG + " this.mAssistiveGrid " + this.mAssistiveGrid)
            this.mAssistiveGrid = value
          }
        }
      }
      this.setDefault(false)
      this.mIsLoad = true
    }
    CLog.info(`${SettingsUtil.TAG} loadAllSetting X`)
  }

  private setDefault(force: boolean) {
    if (!this.mAspectRatio || force) {
      this.mAspectRatio = AspectRatio.DEFAULT_VALUE
    } else if (!this.mResolution || force) {
      this.mResolution = Resolution.DEFAULT_VALUE
    }
  }

  private async commit(settingAlias, itemValue) {
    CLog.info(`${SettingsUtil.TAG} getInstance  settingAlias: ${settingAlias} itemValue ${itemValue}`)
    let settingItemInfo: SettingItemInfo = new SettingItemInfo()
    settingItemInfo.itemName = settingAlias
    settingItemInfo.itemValue = itemValue
    await this.mRdbStoreManager.updateValue(settingItemInfo)
  }

  private mScreenWidth: number
  private mScreenHeight: number
  private mPlatformCapability
  private mCameraId: CameraId
  private mMode: string

  public setCameraPlatformCapability(platformCapability) {
    this.mPlatformCapability = platformCapability
  }

  public setCameraId(cameraId: CameraId) {
    this.mCameraId = cameraId
  }

  public setMode(mode: string) {
    this.mMode = mode
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

  public getPreviewSize() {
    if (this.mMode == 'VIDEO') {
      return Resolution.getVideoPreviewSize(this.mPlatformCapability, this.mCameraId, this.mResolution)
    } else {
      return AspectRatio.getPhotoPreviewSize(this.mPlatformCapability, this.mCameraId, this.mAspectRatio)
    }
  }

  public getPreviewDisplaySize() {
    let preViewSize = this.getPreviewSize()
    return DisplayUtil.calcSurfaceDisplaySize(this.mScreenWidth, this.mScreenHeight, preViewSize.width, preViewSize.height)
  }

  public getAssistiveGrid() {
    return this.mAssistiveGrid
  }
}