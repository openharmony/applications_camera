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

import { Log } from '../../utils/Log'

type Callback = (args: any) => void

export class EventBus {
  private TAG = '[EventBus]:'
  private events: Map<string, Set<Callback>> = new Map()

  constructor() {
  }

  /**
    * Register events and handlers
    *
    * @param event event to handle.
    * @param callback event related callbacck
    */
  public on(event: string | string[], callback: Callback) {
    Log.info(`${this.TAG} on event = ${JSON.stringify(event)}  ${JSON.stringify(callback)}`)
    if (Array.isArray(event)) {
      for (let i = 0, l = event.length; i < l; i++) {
        this.on(event[i], callback)
      }
    } else {
      let callbacks = this.events.get(event)
      if (!callbacks) {
        callbacks = new Set()
      }
      callbacks.add(callback)
      this.events.set(event, callbacks)
      Log.info(`${this.TAG} on event = ${JSON.stringify(event)}  ${JSON.stringify(this.events.get(event))}`)
    }
  }

  /**
    * Register events and processing functions, and destroy them after triggering once
    *
    * @param event event to handle
    * @param callback event related callback
    */
  public once(event: string | string[], callback: Callback) {
    const _self = this

    function handler() {
      const args: any = arguments;
      _self.off(event, handler);
      callback.apply(_self, args); // When called in emit, it will pass parameters to the on method
    }

    handler.callback = callback; // off determines the destruction event based on this
    _self.on(event, handler);
  }

  /**
    * Destroy events and handlers
    *
    * @param event event to handle
    * @param callback event related callback
    */
  public off(event: string | string[], callback: Callback | undefined) {
    // Array cyclic emptying
    if (Array.isArray(event)) {
      for (let i = 0, l = event.length; i < l; i++) {
        this.off(event[i], callback)
      }
      return;
    }
    const callbacks = this.events.get(event);
    if (callback == undefined) {
      callbacks?.clear()
      return
    }
    let cb = null
    callbacks.forEach((item) => {
      if (item.name === callback.name) {
        cb = item
      }
    })
    callbacks?.delete(cb);
    Log.info(`${this.TAG} off event = ${JSON.stringify(event)}  ${JSON.stringify(this.events.get(event))}`)
  }

  /**
    * Trigger all callbacks of an event with parameters
    *
    * @param event event to handle
    * @param argument parameter for the related callback
    */
  public emit(event: string, argument: any) {
    // once deleting the event will cause this in the following loop this._events moves forward in fn,
    // so it is copied here as a new array
    const _self = this
    Log.info(`${this.TAG} emit event = ${JSON.stringify(event)}  ${JSON.stringify(this.events.get(event))}`)
    const tempCall = _self.events.get(event);
    if (!tempCall) {
      return
    }
    const callbacks = [...tempCall];
    if (callbacks) {
      for (let i = 0, l = callbacks.length; i < l; i++) {
        try {
          callbacks[i].apply(_self, argument)
        } catch (e: any) {
          new Error(e)
        }
      }
    }
  }
}