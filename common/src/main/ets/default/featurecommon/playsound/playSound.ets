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

import media from '@ohos.multimedia.media'
import fileIO from '@ohos.fileio'

import { Action } from '../../redux/actions/Action'
import { Log } from '../../utils/Log'
import { EventBus } from '../../worker/eventbus/EventBus'
import { EventBusManager } from '../../worker/eventbus/EventBusManager'
import { SettingManager } from '../../setting/SettingManager'
import { Voice } from '../../setting/settingitem/Voice'

export class PlaySound {
  private TAG: string = '[PlaySound]:'
  private appEventBus: EventBus = EventBusManager.getInstance().getEventBus()
  private settingManager = SettingManager.getInstance()
  private fdNumber: number = 0
  private fdPath
    // @ts-ignore
  private mAVPlayer: media.AVPlayer

  constructor() {
    Log.info(`${this.TAG} constructor start, enroll playCapture to ACTION_CAPTURE`)
    this.appEventBus.on(Action.ACTION_CAPTURE, this.playCapture.bind(this))
      // @ts-ignore
    media.createAVPlayer().then((avPlayer) => {
      Log.info(`${this.TAG} createAVPlayer then ${avPlayer}`)
      this.mAVPlayer = avPlayer;
      this.setAVPlayerCallback();
    })
  }

  setAVPlayerCallback() {
    Log.info(`${this.TAG} setAudioCallback`)
    this.mAVPlayer.on('stateChange', async (state, reason) => {
      switch (state) {
        case 'idle':
          Log.info(`${this.TAG} stateChange idle state`)
          break;
        case 'initialized':
          Log.info(`${this.TAG} stateChange initialized state`)
          this.mAVPlayer.prepare().then(() => {}, (err) => {
            Log.error(`${this.TAG} case prepare error`)
          })
          break;
        case 'prepared':
          Log.info(`${this.TAG} stateChange prepared state`)
          if (this.settingManager.getCaptureMute() == Voice.SOUND) {
            this.mAVPlayer.play()
          }
          break;
        case 'playing':
          Log.info(`${this.TAG} stateChange playing state`)
          break;
        case 'completed':
          Log.info(`${this.TAG} stateChange completed state`)
          if (this.fdNumber !== 0) {
            fileIO.closeSync(this.fdNumber)
            Log.info(`${this.TAG} fileIO closeSync success`)
          }
          this.mAVPlayer.stop()
          break;
        case 'stopped':
          Log.info(`${this.TAG} stateChange stopped state`)
          this.mAVPlayer.reset()
          break;
        case 'error':
          Log.info(`${this.TAG} case error called, err is: ${reason}`)
          break;
        default:
          Log.info(`${this.TAG} unknow state: ${state}`)
          break;
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
      this.mAVPlayer.url = this.fdPath
      this.fdNumber = fdData
      Log.debug(`${this.TAG} fileIO open then ${this.fdPath}`)
    }).catch((err) => {
      Log.info(`${this.TAG} open soundUri failed, err: ${err}`)
    })
    Log.info(`${this.TAG} playSound invoke X`)
  }
}