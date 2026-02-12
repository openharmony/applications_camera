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

import initTest from './common/Init.test';
import onCreateTest from './common/OnCreat.test';
import abilityTest from './common/Ability.test';
import settingPopupTest from './SettingView/SettingPopup.test';
import timeLapseViewTest from './common/default/function/timelapse/TimeLapseView.test';
import zoomTest from './common/Zoom.test';
import basicMoreTest from './features/More/BasicMore.test';
import securityTest from './common/Security.test';
import savePowerModeTest from './common/SavePowerMode.test';
import soundMuteTest from './common/SoundMute.test';
import directionToAngleUtilTest from './common/default/utils/DirectionToAngleUtil.test';
import flashTest from './common/Flash.test';
import focusAndExposureTest from './common/FocusAndExposure.test';
import PickerTest from './common/PickerTest.test';
import leftRightSwipeTest from './common/LeftRightSwipe.test';
import OfflinePhotoTest from './common/OfflinePhoto.test';
import PhotoModeTest from './features/Photo/PhotoModeTest.test';
import VideoModeTest from './features/Video/VideoModeTest.test';
import basicPlaySoundTest from './features/PlaySound/BasicPlaySound.test';
import basicRecordingControlTest from './features/RecordingControl/BasicRecordingControl.test';
import cameraReduxTest from './redux/Redux.test';
import shortCutTest from './common/ShortCut.test';
import PreferencesServiceTest from './common/default/service/preferences/PreferencesService.test';
import ProfileStructureTest from './common/default/utils/jsonparseutil/ProfileStructure.test';
import FrameRateFunctionTest from './common/default/function/framerate/FrameRateFunction.test';
import ZoomActionTest from './common/default/function/zoombar/ZoomAction.test';
import ZoomOperationTest from './common/default/function/zoombar/ZoomOperation.test';
import StringUtilTest from './common/default/utils/StringUtil.test';
import ZoomFunctionTest from './common/default/function/zoombar/ZoomFunction.test';
import DisplayServiceTest from './common/default/service/UIAdaptive/DisplayService.test';
import AspectRatioFunctionTest from './common/default/function/aspectratio/AspectRatioFunction.test';
import CycleClickZoomTest from './features/cycleClickZoom/CycleClickZoom.test';

// 每个用例文件结束，最后一个用例/收尾保证在后置拍照模式结束
export default function testsuite() {
  initTest();
  onCreateTest();
  abilityTest();
  zoomTest();
  PhotoModeTest();
  VideoModeTest();
  leftRightSwipeTest();
  OfflinePhotoTest();

  settingPopupTest();
  timeLapseViewTest();

  flashTest();
  basicMoreTest();
  soundMuteTest();
  focusAndExposureTest();
  basicRecordingControlTest();
  basicPlaySoundTest();
  CycleClickZoomTest();

  // 单元测试
  directionToAngleUtilTest();
  cameraReduxTest();
  PreferencesServiceTest();
  ProfileStructureTest();
  FrameRateFunctionTest();
  ZoomActionTest();
  ZoomOperationTest();
  StringUtilTest();
  ZoomFunctionTest();
  DisplayServiceTest();
  AspectRatioFunctionTest();

  // 锁屏相机
  securityTest();
  savePowerModeTest();
  shortCutTest();
  PickerTest();
}