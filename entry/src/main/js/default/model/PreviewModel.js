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

import LogUtil from '../common/utils/LogUtil.js';
import MediaLibrary from '@ohos.multimedia.medialibrary';

let mLogUtil = new LogUtil();
let mMediaImage = MediaLibrary.getMediaLibraryHelper();
let photoQuality = '';
const ALBUMNAME = 'camera';

export default class PreviewModel {
    getPhotoUri() {
        return new Promise((resolve, reject) => {
            mLogUtil.cameraInfo('getPhotoUri begin.');
            const IMAGEARGS = {
                selections: ALBUMNAME,
                selectionArgs: ['imagealbum'],
            };
            let photoUri;
            mMediaImage.getImageAssets(IMAGEARGS, (error, value) => {
                if (error) {
                    mLogUtil.cameraError(`MediaLibrary: getImageAssets returned an error ${error.message}`);
                }
                if (value === undefined) {
                    mLogUtil.cameraError(`MediaLibrary: There are no images in ${IMAGEARGS.selections} folder`);
                } else {
                    mLogUtil.cameraInfo(`MediaLibrary: There are images in ${IMAGEARGS.selections} folder`);
                    photoUri = `file://${value[0].URI}`;
                    mLogUtil.cameraInfo(`MediaLibrary: initialize photoUri ${photoUri}`);
                }
                resolve(photoUri);
            });
        });
    }

    getPhotoQuality() {
        return photoQuality;
    }
}