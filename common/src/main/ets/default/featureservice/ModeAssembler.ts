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

import { Log } from '../utils/Log'
import type { IModeMap } from './IModeMap'
import type { FunctionId } from './FunctionId'

export class ModeAssembler {
  private TAG: string = '[ModeAssembler]:'
  private mNeedAdd: FunctionId[]
  private mNeedDelete: FunctionId[]
  private mMode: IModeMap
  private mFunctionsMap: Map<FunctionId, any>

  constructor(functionsMap: Map<FunctionId, any>, modeMap: IModeMap) {
    this.mFunctionsMap = functionsMap
    this.mMode = modeMap
  }
  public assembler(preMode: string, currentMode: string): void {
    Log.info(`${this.TAG} assembler preMode = ${preMode}  currentMode = ${currentMode} E `)
    this.mNeedAdd = []
    this.mNeedDelete = []
    Log.info(`${this.TAG} assembler preMode = ${this.mMode.getFunctions(preMode)}  currentMode = ${this.mMode.getFunctions(currentMode)} E `)

    let preModeFun: FunctionId[] = this.mMode.getFunctions(preMode)
    let currentModeFun: FunctionId[] = this.mMode.getFunctions(currentMode)

    Log.info(`${this.TAG} assembler preModeFun = ${preModeFun}  currentModeFun = ${currentModeFun}  `)
    if (!preMode) {
      this.mNeedAdd = JSON.parse(JSON.stringify(currentModeFun))
    } else if (preMode != currentMode) {
      this.mNeedAdd = JSON.parse(JSON.stringify(currentModeFun))
      for (let fun of preModeFun) {
        let index = currentModeFun.indexOf(fun)
          if (index == -1) {
            this.mNeedDelete.push(fun)
          } else {
            this.mNeedAdd.splice(index, 1)
          }
      }
    }
    Log.info(`${this.TAG} assembler mNeedAdd = ${this.mNeedAdd}  mNeedDelete = ${this.mNeedDelete}`)
    this.attachFunction(this.mNeedAdd)
    this.detachFunction(this.mNeedDelete)
    Log.info(`${this.TAG} assembler X`)
  }

  private attachFunction(item: FunctionId[]): void {
    for (let fun of item) {
      Log.info(`${this.TAG} attachFunction fun: ${fun}`)
      this.mFunctionsMap.get(fun).load()
    }
  }

  private detachFunction(item: FunctionId[]): void {
    for (let fun of item) {
      Log.info(`${this.TAG} disattachFunction fun: ${fun}`)
      this.mFunctionsMap.get(fun).unload()
    }
  }
}