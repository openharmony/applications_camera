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

import LogUtil from '../../common/utils/LogUtil.js';
import PreviewPresenter from '../../presenter/previewPresenter/PreviewPresenter.js';
import featureAbility from '@ohos.ability.featureability';
import Prompt from '@system.prompt';
import RouterUtil from '../../common/utils/RouterUtil.js';
import PageData from '../../common/constants/PageData.js';

const DISTRIBUTED_VIEW = PageData.DISTRIBUTED_PAGE;
let mLogUtil = new LogUtil();
let mPreviewPresenter;

export default {
    data: {
        isTouchPhoto: false,
        photoUri: '/common/media/ic_camera_thumbnail_default_white.svg',
        isAnimationState: false,
        isShowFlashingState: false,
        whichPage: 'DistributedPreview',
        cameraStatus: 'DistributedPreview',
        modeIndex: '0',
        mode: 'PHOTO',
        scrollValue: 0,
        photoShootButton: true,
        dialogMessage: '',
        isPromptDialogShow: false,
        isDeviceListDialogOpen: false
    },
    onInit() {
        mLogUtil.cameraInfo('PreviewView onInit begin.');
        mPreviewPresenter = new PreviewPresenter(
            this.$app.$def.data.previewModel,
            this.$app.$def.data.kvStoreModel,
            this.$app.$def.data.remoteDeviceModel);
        featureAbility.getWant().then((want) => {
            mLogUtil.cameraInfo(`onInit Camera featureAbility.getWant = ${JSON.stringify(want.parameters)}`);
            switch (want.parameters.request) {
                case 'startPhotoBack':
                    this.whichPage = 'ResponderPreview';
                    this.cameraStatus = 'ResponderPreview';
                    mLogUtil.cameraInfo('Camera featureAbility.getWant success');
                    break;
                default:
                    this.cameraStatus = 'DistributedPreview';
                    break;
            }
            mLogUtil.cameraInfo('onInit getWant success');
            this.responderPreviewStartedSuccess();
        }).catch((error) => {
            mLogUtil.cameraError(`Camera featureAbility.getWant fail ${error}`);
        });
        mLogUtil.cameraInfo('PreviewView onInit end.');
    },
    onReady() {

    },
    onShow() {
        mLogUtil.cameraInfo('PreviewView onShow begin.');
        this.isAnimationState = false;
        let self = this;
        this.photoUri = '/common/media/ic_camera_thumbnail_default_white.svg';
        mPreviewPresenter.getPhotoUri().then((data) => {
            if (data !== "") {
                self.photoUri = data.replace('"', '').replace('"', '')
            }
            mLogUtil.cameraInfo(`PreviewView onShow photoUri: ${this.photoUri}`);
        });
        mLogUtil.cameraInfo('PreviewView onShow end.');
    },
    onDestroy() {
        mLogUtil.cameraInfo('PreviewView onDestroy begin.');
        if (this.cameraStatus === 'ResponderPreview') {
            mPreviewPresenter.remoteReturnBack();
        }
        mLogUtil.cameraInfo('PreviewView onDestroy end.');
    },
    onBackPress() {
        mLogUtil.cameraInfo('PreviewView onBackPress start.' + 'testMessage:' + this.isPromptDialogShow + 'isDeviceListDialogOpen:' + this.isDeviceListDialogOpen);
        if (this.isPromptDialogShow) {
            mLogUtil.cameraInfo('PreviewView isPromptDialogShow exist')
            return true;
        } else if (this.isDeviceListDialogOpen) {
            mLogUtil.cameraInfo('PreviewView closeDialogComponent');
            this.isDeviceListDialogOpen = false;
            return true;
        } else {
            mLogUtil.cameraInfo('PreviewView onBackPress withoutDialog');
            return false;
        }
        mLogUtil.cameraInfo('PreviewView onBackPress end.')
    },
    onNewRequest() {
        mLogUtil.cameraInfo('PreviewView onNewRequest begin.');
        featureAbility.getWant().then((want) => {
            mLogUtil.cameraInfo(`onNewRequest Camera featureAbility.getWant = ${JSON.stringify(want.parameters)}`);
            switch (want.parameters.request) {
                case 'startPhotoBack':
                    this.whichPage = 'ResponderPreview';
                    this.cameraStatus = 'ResponderPreview';
                    mLogUtil.cameraInfo('Camera featureAbility.getWant success');
                    break;
                default:
                    this.cameraStatus = 'DistributedPreview';
                    break;
            }
            mLogUtil.cameraInfo('onNewRequest getWant success');
            this.responderPreviewStartedSuccess();
        }).catch((error) => {
            mLogUtil.cameraError(`Camera featureAbility.getWant fail ${error}`);
        });
        mLogUtil.cameraInfo('PreviewView onNewRequest end.');
    },
    responderPreviewStartedSuccess() {
        mLogUtil.cameraInfo('PreviewView responderPreviewStartedSuccess begin.');
        if (this.cameraStatus === 'ResponderPreview') {
            mPreviewPresenter.previewStartedSuccess(this.$element('CameraId'));
            mPreviewPresenter.registerDeviceStateChangeCallback((action, deviceId) => {
                mLogUtil.cameraInfo('PreviewView registerDeviceStateChangeCallback begin.' + 'deviceId: ' + deviceId);
                switch (action) {
                    case 'OFFLINE':
                        this.promptShowDialog(this.$t('strings.network_interruption'));
                        setTimeout(() => {
                            featureAbility.terminateAbility();
                        }, 3000);
                        break;
                    default:
                        break;
                }
            });
        }
        mLogUtil.cameraInfo('PreviewView responderPreviewStartedSuccess end.');
    },
    switchCamera() {
        mLogUtil.cameraInfo('PreviewView switchCamera begin.');
        this.isDeviceListDialogOpen = true;
        mLogUtil.cameraInfo('PreviewView switchCamera end.');
    },
    jumpToAlbum() {
        mLogUtil.cameraInfo('jumpToAlbum begin.');
        mPreviewPresenter.jumpToAlbum();
        mLogUtil.cameraInfo('jumpToAlbum end.');
    },
    onTouchStartPhoto() {
        mLogUtil.cameraInfo('onTouchStartPhoto begin.');
        this.isShowFlashingState = true;
        setTimeout(() => {
            this.isShowFlashingState = false;
        }, 100);
        mPreviewPresenter.takePhoto(this.$element('CameraId')).then((object) => {
            if (object.result === 'success') {
                this.photoUri = object.photoUri;
                this.isAnimationState = true;
                this.isAnimationState = false;
            }
        });
        this.isTouchPhoto = true;
        mLogUtil.cameraInfo('onTouchStartPhoto end.');
    },
    onTouchEndPhoto() {
        mLogUtil.cameraInfo('onTouchEndPhoto begin.');
        this.isTouchPhoto = false;
        mLogUtil.cameraInfo('onTouchEndPhoto end.');
    },
    deviceListDialogCancel() {
        mLogUtil.cameraInfo('PreviewView deviceListDialogCancel begin.');
        this.isDeviceListDialogOpen = false;
        mLogUtil.cameraInfo('PreviewView deviceListDialogCancel end.');
    },
    swiButtonClick(e) {
        mLogUtil.cameraInfo('swiButtonClick begin.');
        var inputValue = e.detail.inputValue;
        var event = e.detail.event;
        var deviceList = e.detail.deviceList;
        mLogUtil.cameraInfo('Camera[IndexPage] JSON.stringify inputValue ' + JSON.stringify(inputValue));
        mLogUtil.cameraInfo('Camera[IndexPage] JSON.stringify event ' + JSON.stringify(event));
        mLogUtil.cameraInfo('Camera[IndexPage] event.value ' + event.value);
        mLogUtil.cameraInfo('Camera[IndexPage] deviceList ' + deviceList);
        let self = this;
        mPreviewPresenter.startRemoteCamera(inputValue, event, deviceList, (data) => {
            switch (data) {
                case 'backToLocalhost':
                    break;
                case 'remoteCameraStartedFail':
                    mLogUtil.cameraInfo('remoteCameraStartedFail start.');
                    self.isDeviceListDialogOpen = false;
                    setTimeout(() => {
                        self.promptShowDialog(self.$t('strings.remote_camera_started_fail'));
                    }, 300);
                    mLogUtil.cameraInfo('remoteCameraStartedFail end.');
                    break;
                case 'remoteCameraStartedSuccess':
                    mLogUtil.cameraInfo('remoteCameraStartedSuccess start.');
                    self.startDistributedView();
                    mLogUtil.cameraInfo('remoteCameraStartedSuccess end.');
                    break;
                default:
                    break;
            }
        });
        mLogUtil.cameraInfo('swiButtonClick end.');
    },
    listTouchEnd() {
        mLogUtil.cameraInfo('listTouchEnd begin.');
        this.scrollValue = 0;
        mLogUtil.cameraInfo('listTouchEnd end.');
    },
    promptShowDialog(message) {
        mLogUtil.cameraInfo('promptShowDialog begin.');
        this.isPromptDialogShow = true;
        let self = this;
        Prompt.showDialog({
            message: message,
            buttons:
            [{
                 text: self.$t('strings.restore_defaults_dialog_confirm'),
                 color: '#666666',
             }],
            success: function (data) {
                self.isPromptDialogShow = false;
                mLogUtil.cameraInfo('dialog success callback' + data);
            },
            cancel: function () {
                self.isPromptDialogShow = false;
                mLogUtil.cameraInfo('dialog cancel callback');
            },
        });
        mLogUtil.cameraInfo('promptShowDialog end.');
    },
    startDistributedView() {
        RouterUtil.replace(DISTRIBUTED_VIEW);
    }
};