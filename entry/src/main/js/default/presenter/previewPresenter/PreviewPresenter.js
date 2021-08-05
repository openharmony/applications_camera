/*
 * Copyright (c) 2021 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import LogUtil from '../../common/utils/LogUtil.js';
import FeatureAbility from '@ohos.ability.featureability';
import media from '@ohos.multimedia.media';

let mLogUtil = new LogUtil();
let mPreviewModel;
let mKvStoreModel;
let mRemoteDeviceModel;
let mAudioPlayer;
let mAudioPlayerStatus;

export default class PreviewPresenter {
    constructor(previewModel, kvStoreModel, remoteDeviceModel) {
        mPreviewModel = previewModel;
        mKvStoreModel = kvStoreModel;
        mRemoteDeviceModel = remoteDeviceModel;
        mAudioPlayer = undefined;
        mAudioPlayerStatus = 'unCreated';
    }

    takePhoto(element) {
        mLogUtil.cameraInfo('takePhoto begin.');
        this.playSound();
        return new Promise((resolve, reject) => {
            element.takePhoto({
                quality: mPreviewModel.getPhotoQuality(),
                success: (res) => {
                    mLogUtil.cameraInfo(`takePhoto success: ${JSON.stringify(res)}`);
                    resolve({
                        result: 'success',
                        photoUri: res.uri
                    });
                },
                fail: (res) => {
                    reject({
                        result: 'fail'
                    });
                    mLogUtil.cameraError(`takePhoto fail: ${res.errormsg} ${res.errorcode}`);
                },
                complete: (res) => {
                    mLogUtil.cameraInfo(`takePhoto complete: ${res}`);
                },
            });
        });
        mLogUtil.cameraInfo('takePhoto end.');
    }

    async getPhotoUri() {
        mLogUtil.cameraInfo('getPhotoUri begin.');
        let photoUri = await mPreviewModel.getPhotoUri().then((data) => {
            mLogUtil.cameraInfo(`getPhotoUri: ${JSON.stringify(data)}`);
            return data;
        });
        mLogUtil.cameraInfo(`getPhotoUri: photoUri ${JSON.stringify(photoUri)}`);
        return JSON.stringify(photoUri);
    }

    jumpToAlbum() {
        mLogUtil.cameraInfo('jumpToAlbum begin.');
        let actionData = {
            uri: 'photodetail'
        };
        let paramBundleName = 'com.ohos.photos';
        let paramAbilityName = 'com.ohos.photos.MainAbility';
        let result = FeatureAbility.startAbility({
            want: {
                parameters: actionData,
                bundleName: paramBundleName,
                abilityName: paramAbilityName
            },
        }).then(data => {
            mLogUtil.cameraInfo(`startAbility : success : ${JSON.stringify(data)}`);
        }).catch(error => {
            mLogUtil.cameraInfo(`startAbility : fail : ${JSON.stringify(error)}`);
        });
        mLogUtil.cameraInfo(`jumpToAlbum end: ${result}`);
    }

    previewStartedSuccess(element, callback) {
        mLogUtil.cameraInfo('previewStartedSuccess begin.');
        mKvStoreModel.broadcastMessage(mKvStoreModel.messageData().msgFromResponderReady);
        mKvStoreModel.setOnMessageReceivedListener(
            mKvStoreModel.messageData().msgFromDistributedBack, () => {
                mLogUtil.cameraInfo('OnMessageReceived, previewBack');
                FeatureAbility.terminateAbility();
            });
        mKvStoreModel.setOnMessageReceivedListener(
            mKvStoreModel.messageData().msgFromDistributedTakePhoto, () => {
                mLogUtil.cameraInfo('OnMessageReceived, takePhoto');
                callback();
            });
        mLogUtil.cameraInfo('previewStartedSuccess end.');
    }

    registerDeviceStateChangeCallback(callback) {
        mLogUtil.cameraInfo('registerDeviceStateChangeCallback begin.');
        mRemoteDeviceModel.registerDeviceStateChangeCallback(callback);
        mLogUtil.cameraInfo('registerDeviceStateChangeCallback end.');
    }

    remoteReturnBack() {
        mLogUtil.cameraInfo('remoteReturnBack begin.');
        mKvStoreModel.broadcastMessage(mKvStoreModel.messageData().msgFromResponderBack);
        mLogUtil.cameraInfo('remoteReturnBack end.');
    }

    startRemoteCamera(inputValue, event, deviceList, callback) {
        mLogUtil.cameraInfo('startRemoteCamera begin.');
        mLogUtil.cameraInfo(`startRemoteCamera ${inputValue}, ${event.value}`);
        mRemoteDeviceModel.setCurrentDeviceId(event.value);
        if (inputValue === event.value) {
            if (event.value === 'localhost') {
                callback('backToLocalhost');
                return;
            }
            for (let item of deviceList) {
                if (item.id === event.value) {
                    let deviceId = item.id;
                    mLogUtil.cameraInfo(`FeatureAbility.startAbility deviceId= ${deviceId} deviceName= ${item.name}`);
                    FeatureAbility.startAbility({
                        want: {
                            bundleName: 'com.ohos.camera',
                            abilityName: 'com.ohos.camera.MainAbility',
                            deviceId: deviceId,
                            parameters: {
                                request: 'startPhotoBack'
                            }
                        }
                    }).then((data) => {
                        mLogUtil.cameraInfo(`FeatureAbility.startAbility finished, ${JSON.stringify(data)}`);
                    });
                    let timer = setTimeout(() => {
                        callback('remoteCameraStartedFail');
                        mRemoteDeviceModel.setCurrentDeviceId('localhost');
                    }, 5000);
                    mKvStoreModel.setOnMessageReceivedListener(
                        mKvStoreModel.messageData().msgFromResponderReady, () => {
                                mLogUtil.cameraInfo('OnMessageReceived, remoteAbilityStarted');
                                clearTimeout(timer);
                                callback('remoteCameraStartedSuccess');
                            });
                }
            }
        }
        mLogUtil.cameraInfo('startRemoteCamera end.');
    }

    returnDeviceList() {
        mLogUtil.cameraInfo('returnDeviceList begin.');
        return mRemoteDeviceModel.deviceList;
    }

    getDeviceList(callback) {
        mLogUtil.cameraInfo('getDeviceList begin.');
        mRemoteDeviceModel.registerDeviceListCallback(callback);
        mLogUtil.cameraInfo('getDeviceList end.');
    }

    unregisterDeviceListCallback() {
        mLogUtil.cameraInfo('unregisterDeviceListCallback begin.');
        mRemoteDeviceModel.unregisterDeviceListCallback();
        mLogUtil.cameraInfo('unregisterDeviceListCallback end.');
    }

    getCurrentDeviceId() {
        mLogUtil.cameraInfo('getCurrentDeviceId begin.');
        return mRemoteDeviceModel.getCurrentDeviceId();
        mLogUtil.cameraInfo('getCurrentDeviceId end.');
    }

    playSound() {
        mLogUtil.cameraInfo('playSound begin.');
        mLogUtil.cameraInfo(`mAudioPlayerStatus: ${mAudioPlayerStatus}`);
        switch (mAudioPlayerStatus) {
            case 'unCreated':
                if (typeof (mAudioPlayer) === 'undefined') {
                    mLogUtil.cameraInfo('playSound createAudioPlayer');
                    mAudioPlayer = media.createAudioPlayer();
                }
                mAudioPlayerStatus = 'created';
                mAudioPlayer.on('dataLoad', () => {
                    mLogUtil.cameraInfo('playSound dataLoad callback');
                    mAudioPlayerStatus = 'dataLoaded';
                    mAudioPlayer.play();
                });
                mAudioPlayer.src = 'file://system/etc/capture.ogg';
                break;
            case 'dataLoaded':
                mAudioPlayer.play();
                break;
            default:
                break;
        }
        mLogUtil.cameraInfo('playSound end.');
    }
}