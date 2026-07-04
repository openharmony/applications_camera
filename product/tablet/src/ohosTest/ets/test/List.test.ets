/*
 * Copyright (c) Huawei Device Co., Ltd. 2024-2025. All rights reserved.
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

import abilityTest from './basic/Ability.test';
import basicMoreTest from './BasicMore.test';
import basicPhotoTest from './basic/BasicPhoto.test';
import basicVideoTest from './basic/BasicVideo.test';
import zoomTest from './basic/Zoom.test';

export default function testsuite() {
  abilityTest();
  basicPhotoTest();
  basicVideoTest();
  zoomTest();
  basicMoreTest();
}



