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

import {Action} from '../../../../../../../../../common/src/main/ets/default/redux/actions/Action'
import {CameraBasicFunction} from '../../../../../../../../../common/src/main/ets/default/function/CameraBasicFunction'
import {CaptureFunction} from '../../../../../../../../../common/src/main/ets/default/function/CaptureFunction'
import {CLog} from '../../../../../../../../../common/src/main/ets/default/Utils/CLog'
import {Constants} from '../Constants'
import {EventBus} from '../../../../../../../../../common/src/main/ets/default/Utils/EventBus'
import EventBusManager from '../../../../../../../../../common/src/main/ets/default/Utils/EventBusManager'
import {ModeAssembler} from './ModeAssembler'
import {RecordFunction} from '../../../../../../../../../common/src/main/ets/default/function/RecordFunction'
import {WorkerManager} from '../../../../../../../../../common/src/main/ets/default/Utils/WorkerManager'
import {ZoomFunction} from '../../../../../../../../../common/src/main/ets/default/function/ZoomFunction'

export class FeatureManager {
  private TAG: string = '[FeatureManager]:'
  private mModeAssembler: ModeAssembler
  private mPreMode: string = 'PHOTO'
  public mCurrentMode: string = this.mPreMode
  appEventBus: EventBus = EventBusManager.getInstance().getEventBus()
  private mFunctionsMap = new Map()

  constructor(mode: string) {
    CLog.info(`${this.TAG} constructor`)
    this.initFunctionsMap()
    this.mModeAssembler = new ModeAssembler(this.mFunctionsMap)
    this.mPreMode = mode
    this.mCurrentMode = mode
    this.mFunctionsMap.get(Constants.CAMERA_BASIC_FUNCTION).load()
    this.mModeAssembler.assembler(null, this.mPreMode)
    // 接收到modeChange的消息，调用changeMode做处理
    this.appEventBus.on(Action.ACTION_CHANGE_MODE, this.changeMode.bind(this))
  }

  public changeMode(data: any): void {
    // 外部条件触发mode切换，传入下一个mode名称
    CLog.info(`${this.TAG} changeMode start data:  ${JSON.stringify(data)}`)
    this.mModeAssembler.assembler(this.mPreMode, data.mode)
    this.mPreMode = data.mode
  }

  private initFunctionsMap(): void {
    CLog.info(`${this.TAG} initFunctionsMap invoke E.`)
    this.mFunctionsMap.set(Constants.CAMERA_BASIC_FUNCTION, new CameraBasicFunction())
    this.mFunctionsMap.set(Constants.CAPTURE_FUNCTION, new CaptureFunction())
    this.mFunctionsMap.set(Constants.RECORDING_FUNCTION, new RecordFunction())
    this.mFunctionsMap.set(Constants.ZOOM_FUNCTION, new ZoomFunction())
    CLog.info(`${this.TAG} initFunctionsMap invoke X.`)
  }
}