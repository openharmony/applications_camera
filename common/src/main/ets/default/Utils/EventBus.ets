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

import {CLog} from '../Utils/CLog'

export class EventBus {
  private TAG: string = '[EventBus]:'
  _events = []

  constructor() {
  }

  /**
    * Register events and handlers
    * @param event
    * @param fn
    */
  public on(event, fn) {
    if (Array.isArray(event)) {
      for (let i = 0, l = event.length; i < l; i++) {
        this.on(event[i], fn)
      }
    } else {
      (this._events[event] || (this._events[event] = [])).push(fn)
    }

    CLog.info(`${this.TAG} on event = ${JSON.stringify(event)}  ${JSON.stringify(this._events[event])}`)
  }

  /**
    * Register events and processing functions, and destroy them after triggering once
    * @param event
    * @param fn
    */
  public once(event, fn) {
    let _self = this;

    function handler() {
      _self.off(event, handler);
      fn.apply(null, [event, fn]); // When called in emit, it will pass parameters to the on method
    }

    handler.fn = fn; // off determines the destruction event based on this
    _self.on(event, handler);
  }

  /**
    * Destroy events and handlers
    * @param event
    * @param fn
    */
  public off(event, fn) {
    // event is null, clear all
    if (event == null) {
      this._events = [];
    }
    // Array cyclic emptying
    if (Array.isArray(event)) {
      for (let i = 0, l = event.length; i < l; i++) {
        this.off(event[i], fn)
      }
    }
    const cbs = this._events[event];
    if (!cbs) {
      return;
    }
    // Not passing the second parameter means clearing all listening functions for an event
    if (fn == null) {
      this._events[event] = null
    }
    let cb, i = cbs.length
    while (i--) {
      cb = cbs[i]
      if (cb === fn || cb.fn === fn) { // cb.fn===fn used to remove once registration
        cbs.splice(i, 1)
        break
      }
    }
    CLog.info(`${this.TAG} off event = ${JSON.stringify(event)}  ${JSON.stringify(this._events[event])}`)
  }

  /**
    * Trigger all callbacks of an event with parameters
    * @param event
    */
  public emit(event, argument: any[]) {
    // once deleting the event will cause this in the following loop this._events moves forward in fn,
    // so it is copied here as a new array
    let _self = this
    if (!_self._events[event]) {
      return
    }
    let cbs = [..._self._events[event]];
    if (cbs) {
      for (let i = 0, l = cbs.length; i < l; i++) {
        try {
          cbs[i].apply(_self, argument)
        } catch (e) {
          new Error(e)
        }
      }
    }
  }
}