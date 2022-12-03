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

import media from '@ohos.multimedia.media'
import fileIO from '@ohos.fileio'

import { Action } from '../../redux/actions/Action'
import { Log } from '../../utils/Log'
import { EventBus } from '../../worker/eventbus/EventBus'
import EventBusManager from '../../worker/eventbus/EventBusManager'
import { SettingManager } from '../../setting/SettingManager'
import { Voice } from '../../setting/settingitem/Voice'

export class PlaySound {
  private TAG: string = '[PlaySound]:'
  private appEventBus: EventBus = EventBusManager.getInstance().getEventBus()
  private settingManager = SettingManager.getInstance()
  private fdNumber: number = 0
  private fdPath
  private mAudioPlayer:media.AudioPlayer

  constructor() {
   this.appEventBus.on(Action.ACTION_CAPTURE, this.playCapture.bind(this))
    this.mAudioPlayer = media.createAudioPlayer()
    this.setAudioCallback()
  }

  setAudioCallback() {
    this.mAudioPlayer.on('error', (err) => {
      Log.info(`${this.TAG} case error called, err is: ${err.message}`)
      Log.info(`${this.TAG} case error called, status is: ${this.mAudioPlayer.state}`)
    })
    this.mAudioPlayer.on('dataLoad', () => {
      Log.info(`${this.TAG} case dataLoad called, status is: ${this.mAudioPlayer.state}`)
      if (this.settingManager.getCaptureMute() == Voice.SOUND) {
        this.mAudioPlayer.play()
      }
    })
    this.mAudioPlayer.on('play', () => {
      Log.info(`${this.TAG} case play called, status is: ${this.mAudioPlayer.state}`)
    })
    this.mAudioPlayer.on('reset', () => {
      Log.info(`${this.TAG} case reset called, status is: ${this.mAudioPlayer.state}`)
      this.mAudioPlayer.src = this.fdPath
    })
    this.mAudioPlayer.on('finish', () => {
      Log.info(`${this.TAG} case finish called, status is: ${this.mAudioPlayer.state}`)
        if (this.fdNumber !== 0) {
          fileIO.closeSync(this.fdNumber)
          Log.info(`${this.TAG} fileIO closeSync success`)
        }
    })
  }

  public static getInstance(): PlaySound {
    if (!globalThis?.sInstancePlaySound) {
      globalThis.sInstancePlaySound = new PlaySound()
    }
    return globalThis.sInstancePlaySound;
  }

  private playRecordStart(data) {
    Log.debug(`${this.TAG} playRecordStart invoke E`)
    if (this.settingManager.getCaptureMute() == Voice.SOUND) {
      this.playSound(Voice.RECORD_START_URI)
    }
    Log.debug(`${this.TAG} playRecordStart invoke X`)
  }

  private playRecordStop(data) {
    Log.debug(`${this.TAG} playRecordStop invoke E`)
    if (this.settingManager.getCaptureMute() == Voice.SOUND) {
      this.playSound(Voice.RECORD_STOP_URI)
    }
    Log.debug(`${this.TAG} playRecordStop invoke X`)
  }

  private playCapture(data) {
    Log.debug(`${this.TAG} playCapture invoke E`)
    if (this.settingManager.getCaptureMute() == Voice.SOUND) {
      this.playSound(Voice.CAPTURE_URI)
    }
    Log.debug(`${this.TAG} playCapture invoke X`)
  }

  private async playSound(soundUri) {
    Log.info(`${this.TAG} playSound invoke E`)
    this.fdPath = 'fd://'
    fileIO.open(Voice.CAPTURE_URI).then((fdData) => {
      this.fdPath = this.fdPath + '' + fdData
      this.fdNumber = fdData
      this.mAudioPlayer.src = this.fdPath
      this.mAudioPlayer.reset()
    }).catch((err) => {
      Log.info(`${this.TAG} open soundUri failed, err: ${err}`)
    })
    Log.info(`${this.TAG} playSound invoke X`)
  }
}