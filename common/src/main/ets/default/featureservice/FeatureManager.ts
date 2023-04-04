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

import { Action } from '../redux/actions/Action'
import { CameraBasicFunction } from '../function/CameraBasicFunction'
import { CaptureFunction } from '../function/CaptureFunction'
import { Log } from '../utils/Log'
import { FunctionId } from './FunctionId'
import { EventBus } from '../worker/eventbus/EventBus'
import { EventBusManager } from '../worker/eventbus/EventBusManager'
import { ModeAssembler } from './ModeAssembler'
import { RecordFunction } from '../function/RecordFunction'
import { WorkerManager } from '../worker/WorkerManager'
import { ZoomFunction } from '../function/ZoomFunction'
import { IModeMap } from './IModeMap'
export class FeatureManager {
  private TAG: string = '[FeatureManager]:'
  private mModeAssembler: ModeAssembler
  private mPreMode: string = 'PHOTO'
  public mCurrentMode: string = this.mPreMode
  appEventBus: EventBus = EventBusManager.getInstance().getEventBus()
  private mFunctionsMap = new Map()

  constructor(mode: string, modeMap: IModeMap) {
    Log.info(`${this.TAG} constructor`)
    this.initFunctionsMap()
    this.mModeAssembler = new ModeAssembler(this.mFunctionsMap, modeMap)
    this.mPreMode = mode
    this.mCurrentMode = mode
    this.mFunctionsMap.get(FunctionId.CAMERA_BASIC_FUNCTION).load()
    this.mModeAssembler.assembler(null, this.mPreMode)
    // 接收到modeChange的消息，调用changeMode做处理
    this.appEventBus.on(Action.ACTION_CHANGE_MODE, this.changeMode.bind(this))
  }

  public changeMode(data: any): void {
    // 外部条件触发mode切换，传入下一个mode名称
    Log.info(`${this.TAG} changeMode start data:  ${JSON.stringify(data)}`)
    this.mModeAssembler.assembler(this.mPreMode, data.mode)
    this.mPreMode = data.mode
  }

  private initFunctionsMap(): void {
    Log.info(`${this.TAG} initFunctionsMap invoke E.`)
    this.mFunctionsMap.set(FunctionId.CAMERA_BASIC_FUNCTION, CameraBasicFunction.getInstance())
    this.mFunctionsMap.set(FunctionId.CAPTURE_FUNCTION, new CaptureFunction())
    this.mFunctionsMap.set(FunctionId.RECORDING_FUNCTION, new RecordFunction())
    this.mFunctionsMap.set(FunctionId.ZOOM_FUNCTION, new ZoomFunction())
    Log.info(`${this.TAG} initFunctionsMap invoke X.`)
  }
}