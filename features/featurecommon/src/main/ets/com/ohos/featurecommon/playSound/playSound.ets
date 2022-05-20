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

import media from '@ohos.multimedia.media';

import {Action} from '../../../../../../../../../common/src/main/ets/default/redux/actions/Action'
import { CLog } from '../../../../../../../../../common/src/main/ets/default/Utils/CLog'
import { EventBus } from '../../../../../../../../../common/src/main/ets/default/Utils/EventBus'
import EventBusManager from '../../../../../../../../../common/src/main/ets/default/Utils/EventBusManager'
import { SettingsUtil } from '../../../../../../../../../common/src/main/ets/default/Utils/SettingsUtil'
import { Voice } from '../../../../../../../../../common/src/main/ets/default/setting/Voice'

let mAudioPlayer = undefined

export class PlaySound {
  private TAG: string = '[PlaySound]:'
  private static sInstance: PlaySound = undefined
  private appEventBus: EventBus = EventBusManager.getInstance().getEventBus()
  private settingsUtil = SettingsUtil.getInstance()
  private readonly UNDEFINED = 'undefined'
  private readonly IDLE = 'idle'

  constructor() {
    this.appEventBus.on(Action.ACTION_RECORD_START, this.playRecordStart.bind(this))
    this.appEventBus.on(Action.ACTION_RECORD_PAUSE, this.playRecordStop.bind(this))
    this.appEventBus.on(Action.ACTION_RECORD_RESUME, this.playRecordStart.bind(this))
    this.appEventBus.on(Action.ACTION_RECORD_STOP, this.playRecordStop.bind(this))
    this.appEventBus.on(Action.ACTION_CAPTURE, this.playCapture.bind(this))
  }

  public static getInstance(): PlaySound {
    if (!PlaySound.sInstance) {
      PlaySound.sInstance = new PlaySound()
    }
    return PlaySound.sInstance;
  }

  private playRecordStart(data) {
    CLog.debug(`${this.TAG} playRecordStart invoke E`)
    if (this.settingsUtil.getCaptureMute() == Voice.SOUND) {
      this.playSound(Voice.RECORD_START_URI)
    }
    CLog.debug(`${this.TAG} playRecordStart invoke X`)
  }

  private playRecordStop(data) {
    CLog.debug(`${this.TAG} playRecordStop invoke E`)
    if (this.settingsUtil.getCaptureMute() == Voice.SOUND) {
      this.playSound(Voice.RECORD_STOP_URI)
    }
    CLog.debug(`${this.TAG} playRecordStop invoke X`)
  }

  private playCapture(data) {
    CLog.debug(`${this.TAG} playCapture invoke E`)
    if (this.settingsUtil.getCaptureMute() == Voice.SOUND) {
      this.playSound(Voice.CAPTURE_URI)
    }
    CLog.debug(`${this.TAG} playCapture invoke X`)
  }

  private playSound(soundUri) {
    CLog.debug(`${this.TAG} playSound invoke E`)
    if (typeof (mAudioPlayer) !== this.UNDEFINED
    && mAudioPlayer.src === soundUri && mAudioPlayer.state !== this.IDLE) {
      mAudioPlayer.play()
    } else {
      CLog.debug(`${this.TAG} playSound createAudioPlayer`)
      if (typeof (mAudioPlayer) !== 'undefined') {
        mAudioPlayer.release()
        mAudioPlayer = undefined
      }
      mAudioPlayer = media.createAudioPlayer()
      mAudioPlayer.on('dataLoad', () => {
        mAudioPlayer.play()
      })
      mAudioPlayer.src = soundUri
    }
    CLog.debug(`${this.TAG} playSound invoke X`)
  }
}