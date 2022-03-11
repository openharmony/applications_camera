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

export class EventBus {
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
      fn.apply(null, [event, fn]);
    }

    handler.fn = fn;
    _self.on(event, handler);
  }

  /**
    * Destroy events and handlers
    * @param event
    * @param fn
    */
  public off(event, fn) {
    if (event == null) {
      this._events = [];
    }
    if (Array.isArray(event)) {
      for (let i = 0, l = event.length; i < l; i++) {
        this.off(event[i], fn)
      }
    }
    const cbs = this._events[event];
    if (!cbs) {
      return;
    }
    if (fn == null) {
      this._events[event] = null
    }
    let cb, i = cbs.length
    while (i--) {
      cb = cbs[i]
      if (cb === fn || cb.fn === fn) {
        cbs.splice(i, 1)
        break
      }
    }
  }

  /**
    * Trigger all callbacks of an event with parameters
    * @param event
    */
  public emit(event, argument: any[]) {

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