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

import {CLog} from '../../../../../../../../../common/src/main/ets/default/Utils/CLog'
import {Constants} from '../Constants'
import {Mode} from '../Mode'

export class ModeAssembler {
  private TAG: string = '[ModeAssembler]:'
  private mNeedAdd: string[]
  private mNeedDelete: string[]
  private mMode = new Mode()
  private mFunctionsMap: Map<string, any>

  constructor(functionsMap: Map<string, any>) {
    this.mFunctionsMap = functionsMap
  }
  public assembler(preMode: string, currentMode: string): void {
    CLog.info(`${this.TAG} assembler preMode = ${preMode}  currentMode = ${currentMode} E `)
    this.mNeedAdd = []
    this.mNeedDelete = []
    let preModeFun: string[] = this.mMode.getFunctions(preMode)
    let currentModeFun: string[] = this.mMode.getFunctions(currentMode)

    CLog.info(`${this.TAG} assembler preModeFun = ${preModeFun}  currentModeFun = ${currentModeFun}  `)
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
    CLog.info(`${this.TAG} assembler mNeedAdd = ${this.mNeedAdd}  mNeedDelete = ${this.mNeedDelete}`)
    this.attachFunction(this.mNeedAdd)
    this.detachFunction(this.mNeedDelete)
    CLog.info(`${this.TAG} assembler X`)
  }

  private attachFunction(item: string[]): void {
    for (let fun of item) {
      CLog.info(`${this.TAG} attachFunction fun: ${fun}`)
      this.mFunctionsMap.get(fun).load()
    }
  }

  private detachFunction(item: string[]): void {
    for (let fun of item) {
      CLog.info(`${this.TAG} disattachFunction fun: ${fun}`)
      this.mFunctionsMap.get(fun).unload()
    }
  }
}