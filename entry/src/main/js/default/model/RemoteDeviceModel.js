/*
 * Copyright (c) 2021 Huawei Device Co., Ltd.
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

import deviceManager from '@ohos.distributedHardware.deviceManager';
import LogUtil from '../common/utils/LogUtil.js';

var SUBSCRIBE_ID = 100;
let mLogUtil = new LogUtil();
let cameraDeviceId = 'localhost';

export default class RemoteDeviceModel {
    deviceList = [];
    callbackForList;
    callbackForStateChange;
    #deviceManager;

    constructor() {
    }

    registerDeviceManagerOn() {
        mLogUtil.cameraInfo('registerDeviceManagerOn begin.');
        let self = this;
        this.#deviceManager.on('deviceStateChange', (data) => {
            mLogUtil.cameraInfo(`Camera[RemoteDeviceModel] deviceStateChange JSON.stringify data= ${JSON.stringify(data)}`);
            switch (data.action) {
                case 0:
                    self.deviceList[self.deviceList.length] = data.device;
                    mLogUtil.cameraInfo(`Camera[RemoteDeviceModel] online, updated device list= ${JSON.stringify(self.deviceList)}`);
                    self.callbackForList();
                    break;
                case 2:
                    if (self.deviceList.length > 0) {
                        for (var i = 0; i < self.deviceList.length; i++) {
                            if (self.deviceList[i].deviceId === data.device.deviceId) {
                                self.deviceList[i] = data.device;
                                break;
                            }
                        }
                    }
                    mLogUtil.cameraInfo(`Camera[RemoteDeviceModel] change, updated device list= ${JSON.stringify(self.deviceList)}`);
                    self.callbackForList();
                    break;
                case 1:
                    if (self.deviceList.length > 0) {
                        var list = [];
                        for (var i = 0; i < self.deviceList.length; i++) {
                            if (self.deviceList[i].deviceId !== data.device.deviceId) {
                                list[i] = self.deviceList[i];
                            }
                        }
                        self.deviceList = list;
                    }
                    mLogUtil.cameraInfo(`Camera[RemoteDeviceModel] offline, updated device list= ${JSON.stringify(data.device)}`);
                    self.callbackForStateChange('OFFLINE', data.device.deviceId);
                    self.callbackForList();
                    break;
                default:
                    break;
            }
            mLogUtil.cameraInfo('deviceStateChange end.');
        });
        this.#deviceManager.on('deviceFound', (data) => {
            mLogUtil.cameraInfo(`Camera[RemoteDeviceModel] deviceFound data= ${JSON.stringify(data)}`);
            mLogUtil.cameraInfo(`Camera[RemoteDeviceModel] deviceFound self.deviceList= ${self.deviceList}`);
            for (var i = 0; i < self.deviceList.length; i++) {
                if (self.deviceList[i].deviceId === data.device.deviceId) {
                    mLogUtil.cameraInfo('Camera[RemoteDeviceModel] device founded, ignored');
                    return;
                }
            }
            mLogUtil.cameraInfo(`Camera[RemoteDeviceModel] authenticateDevice ${JSON.stringify(data.device)}`);
            self.#deviceManager.authenticateDevice(data.device);
            mLogUtil.cameraInfo('deviceFound end.');
        });
        this.#deviceManager.on('discoverFail', (data) => {
            mLogUtil.cameraInfo('discoverFail begin.');
            mLogUtil.cameraInfo(`Camera[RemoteDeviceModel] discoverFail data= ${JSON.stringify(data)}`);
        });
        this.#deviceManager.on('authResult', (data) => {
            mLogUtil.cameraInfo('authResult begin.');
            mLogUtil.cameraInfo(`Camera[RemoteDeviceModel] authResult data= ${JSON.stringify(data)}`);
        });
        this.#deviceManager.on('serviceDie', () => {
            mLogUtil.cameraInfo('serviceDie begin.');
            self.callbackForStateChange('SERVICEDIE', 0);
            mLogUtil.cameraError('Camera[RemoteDeviceModel] serviceDie');
        });
        SUBSCRIBE_ID = Math.floor(65536 * Math.random());
        var info = {
            subscribeId: SUBSCRIBE_ID,
            mode: 0xAA,
            medium: 2,
            freq: 2,
            isSameAccount: false,
            isWakeRemote: true,
            capability: 0
        };
        mLogUtil.cameraInfo(`Camera[RemoteDeviceModel] startDeviceDiscovery ${SUBSCRIBE_ID}`);
        this.#deviceManager.startDeviceDiscovery(info);
        mLogUtil.cameraInfo('registerDeviceManagerOn end.');
    }

    registerDeviceManagerOff() {
        mLogUtil.cameraInfo('registerDeviceManagerOff begin.');
        this.#deviceManager.stopDeviceDiscovery(SUBSCRIBE_ID);
        this.#deviceManager.off('deviceStateChange');
        this.#deviceManager.off('deviceFound');
        this.#deviceManager.off('discoverFail');
        this.#deviceManager.off('authResult');
        this.#deviceManager.off('serviceDie');
        mLogUtil.cameraInfo('registerDeviceManagerOff end.');
    }

    createDeviceManager(callback) {
        mLogUtil.cameraInfo('createDeviceManager begin.');
        if (typeof (this.#deviceManager) === 'undefined') {
            let self = this;
            deviceManager.createDeviceManager('com.ohos.camera', (error, value) => {
                if (error) {
                    mLogUtil.cameraError('createDeviceManager failed.');
                    return;
                }
                self.#deviceManager = value;
                callback();
                mLogUtil.cameraInfo(`Camera[RemoteDeviceModel] createDeviceManager callback returned, error= ${error} value= ${value}`);
            });
        } else {
            callback();
        }
        mLogUtil.cameraInfo('createDeviceManager end.');
    }

    registerDeviceListCallback(callback) {
        mLogUtil.cameraInfo('Camera[RemoteDeviceModel] registerDeviceListCallback');
        let self = this;
        this.createDeviceManager(() => {
            self.callbackForList = callback;
            if (self.#deviceManager === undefined) {
                mLogUtil.cameraError('Camera[RemoteDeviceModel] deviceManager has not initialized');
                self.callbackForList();
                return;
            }
            var list = self.#deviceManager.getTrustedDeviceListSync();
            mLogUtil.cameraInfo(`Camera[RemoteDeviceModel] getTrustedDeviceListSync end, deviceList= ${JSON.stringify(list)}`);
            if (typeof (list) !== 'undefined' && typeof (list.length) !== 'undefined') {
                self.deviceList = list;
            }
            self.callbackForList();
            self.registerDeviceManagerOff();
            self.registerDeviceManagerOn();
        });
        mLogUtil.cameraInfo('registerDeviceListCallback end.');
    }

    unregisterDeviceListCallback() {
        mLogUtil.cameraInfo('unregisterDeviceListCallback begin.');
        this.callbackForList = null;
        this.registerDeviceManagerOff();
        if (this.callbackForStateChange !== null) {
            this.registerDeviceManagerOn();
        }
        this.deviceList = [];
        mLogUtil.cameraInfo('unregisterDeviceListCallback end.');
    }

    registerDeviceStateChangeCallback(callback) {
        mLogUtil.cameraInfo('registerDeviceStateChangeCallback begin.');
        let self = this;
        this.createDeviceManager(() => {
            self.callbackForStateChange = callback;
            if (self.#deviceManager === undefined) {
                mLogUtil.cameraError('Camera[RemoteDeviceModel] deviceManager has not initialized');
                return;
            }
            self.registerDeviceManagerOff();
            self.registerDeviceManagerOn();
        });
        mLogUtil.cameraInfo('registerDeviceStateChangeCallback end.');
    }

    unregisterDeviceStateChangeCallback() {
        mLogUtil.cameraInfo('unregisterDeviceStateChangeCallback begin.');
        this.callbackForStateChange = null;
        this.registerDeviceManagerOff();
        if (this.callbackForList !== null) {
            this.registerDeviceManagerOn();
        }
        mLogUtil.cameraInfo('unregisterDeviceStateChangeCallback end.');
    }

    setCurrentDeviceId(deviceId) {
        mLogUtil.cameraInfo('setCurrentDeviceId begin.');
        cameraDeviceId = deviceId;
        mLogUtil.cameraInfo(`setCurrentDeviceId end.${cameraDeviceId}`);
    }

    getCurrentDeviceId() {
        mLogUtil.cameraInfo(`getCurrentDeviceId begin.${cameraDeviceId}`);
        return cameraDeviceId;
    }
}