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
import lazy { PersistType, PreferencesService } from '../../service/preferences/PreferencesService';
import lazy { HiLog } from '../HiLog';
import lazy { StringUtil } from '../StringUtil';
import lazy { camera } from '@kit.CameraKit';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { OutputType } from '../../function/outputswitcher/OutputType';
import lazy { ModeTransform } from '../../mode/ModeTransform';
import lazy { ContextManager } from '../../service/context/ContextManager';
import lazy { OutputOperation } from '../../function/outputswitcher/OutputOperation';
import lazy { FeatureManager } from '../../function/core/FeatureManager';
import lazy { FunctionId } from '../../function/core/functionproperty/FunctionId';
import lazy { DeviceInfo } from '../../component/deviceinfo/DeviceInfo';
import lazy { hasCameraProfiles } from '../FileReadUtil';
import lazy { DisplayService } from '../../service/UIAdaptive/DisplayService';
import { PhotoFormatMode } from '../../function/enumbase/PhotoFormatMode';

const TAG: string = 'CameraProfilesJsonUtilV2';

export class V2Capability { // 一级数据结构:对齐配置文件
  public version?: string;
  public cameraCapability?: AppCapabilityDataByType[];
  public zoomParameter?: ZoomParameterData[];
  public supportedMode?: SupportedModeData;
  public metadata?: AppMetadata;
  public treasureBoxOrder?: number[];
  public customColorStyleSupportedMode?: ModeType[];
  public startupGuidancePages?: string[];
  public zoomCycleClickData?: ZoomCycleClickData[];
}

export type AppCapabilityDataByType = { // 二级数据结构,按镜头维度:比例格式分辨率帧率
  cameraType?: number,
  cameraTypeData?: TypeDataByCollapsState[],
};

export type TypeDataByCollapsState = { // 三级数据结构,按维度:特有配置+默认配置
  collapsState?: number,
  collapsStateData?: CollapsStateDataByMode[],
  defaultData?: ModeProfilesData,
};

export type CollapsStateDataByMode = { // 四级数据结构,按模式维度
  modeName?: string,
  modeData?: ModeProfilesData,
};

export type ModeProfilesData = {
  lensMode?: number,
  photoProfiles?: BaseProfileData[],
  photoPreviewProfiles?: BaseProfileData[],
  videoProfiles?: BaseProfileData[],
  videoPreviewProfiles?: BaseProfileData[],
};

export type BaseProfileData = {
  ratio?: string,
  profileWidth?: number,
  profileHeight?: number,
  format?: string[],
  frameRateArray?: number[],
};

export type ZoomParameterData = { // 二级数据结构:焦段
  cameraType?: number,
  cameraTypeData?: ZoomTypeDataByMode[],
  defaultData?: ZoomTypeDataByMode[],
};

export type ZoomTypeDataByMode = {
  modeName?: string,
  quickZoomArray?: number[],
  opticalZoomArray?: number[],
};

export type ZoomCycleClickDataByMode = {
  clickQuickZoom?: number,
  cycleZoomArray?: number[],
};

export type ZoomCycleClickData = {
  modeName?: string,
  ZoomCycleClickData?: ZoomCycleClickDataByMode[],
};

export type SupportedModeData = { // 二级数据结构:模式
  modeBarList?: string[],
  moreModeList?: string[],
  filteredModeList?: string[],
};

export type AppMetadata = { // 二级数据结构:元数据
  photoBrowserDisabled?: boolean,
  isSupportedSuperMacroTelephoto?: boolean,
  isSupportHDRVividFunction?: boolean,
  isSupportedXmageFunction?: boolean,
  isSupportedClassicXmageFunction?: boolean,
  isSupportedFrontZoomSlide?: boolean,
  notSupportedVideo60fpsWide?: boolean,
  isSupportedHighQualityPhotoFunction?: boolean,
  highQualityPhotoFuncDefaultValue?: boolean,
  isSupportedLivePhotoFunction?: boolean,
  isNotSupportedFrontPortraitLivePhotoFunction?: boolean,
  livePhotoFuncDefaultValue?: boolean,
  isSupportedWatermarkFunction?: boolean,
  isSupportedRealTimeFilterFunction?: boolean,
  isSupportedVideoWaterMark?: boolean,
  isSupportedTimingWaterMark?: boolean,
  limitTimeWatermarkDuration?: string,
  isDisAbleSlowMotionSwitch?: boolean,
  isSupportedLrSwipeFunction?: boolean,
  isSupportedRightSwipeRecordSwapSurface?: boolean,
  burstMaxNum?: number,
  superSlowMoFrameRate?: number,
  isSupportedAugmentedStabilizationFunction?: boolean,
  isDisAbleApertureVideo?: boolean,
  isSupportedNightVideoBeautyFunction?: boolean,
  isNotSupportedNightShutterEffectFunction?: boolean,
  isSupportedOverHotHidePip?: boolean,
  isSupportedHeifPhotoFormat?: boolean,
  isHeifFormatFuncDefaultValue?: boolean,
  isSupportedStabilizationWithHDRVivid?: boolean,
  isSupportedEnhancedBackSelfie?: boolean,
  isSupportedLowAngleShot?: boolean,
  isSupportedSmartBackSelfieFunction?: boolean,
  isSupportedAigcFunction?: boolean,
  isNotCustomFilterLandSupport?: boolean,
  isNotHalfCollapsCustomFilterSupport?: boolean,
  isNotCustomFilterVdeSemiSupport?: boolean,
  isSupportedNightSubMode?: boolean,
  isNightModeOnlySupportSuperNightAndChaseMoon?: boolean,
  isDeviceLowConfig?: boolean,
  frontSwingZoomRatio?: number,
  backSwingZoomRatio?: number,
  backVideoEisStabilizeRatio?: number,
  frontVideoEisStabilizeRatio?: number,
  isSupportedCollaborationFunction?: boolean,
  isSupportedDepthFusion?: boolean,
  supportedXmageStylesNum?: number,
  is60fpsDefaultCloseEfficientVideo?: boolean,
  isShortExposureDuration?: boolean,
  isSupportedFrontHighPixelFunction?:boolean,
  isCloseThermalDialog?: boolean,
  isSupportedCustomColorStyle?: boolean,
  isSupportedConstellationDraw?: boolean;
  isSupportedBeautyThemeFunction?: boolean,
  isSupportedNightFrontZoom?: boolean,
  isSupportedApertureVideoResolutionChanged?: boolean,
  is60fpsSupportHdrVivid?: boolean,
  isSupportedPreRecord?: boolean,
  needHidePreviewWhenBackground?: boolean,
  isNotSupportedEfficientVideoFunction?: boolean,
  isNotSupportedWideZoom60fpsVideoBack?: boolean,
  isChange3To4Zoom60fpsVideoBack?: boolean,
  superMacroLivePhotoFuncDefaultValue?: boolean,
  isSupportedDynamicFramerate?: boolean,
  isSupportGlobalExposure?: boolean,
  isSupportRecordingFlowing?: boolean,
  isNovaProduct?: boolean,
  ringLightConfigBrightness?: number,
  isNeedRemoveFlashFunc?: boolean,
  isNeedRemoveAiMaster?: boolean,
  isSupportedFestivalWatermark?: boolean,
  isSupportedFrontSnapShotFunction?: boolean,
  isSupportedEquivalentFocalBigText?: boolean,
  isShowBeautySkinMode?: boolean,
  videoBitrateH264?: number,
  videoBitrateH265?: number,
  isSupportedEffectWhenNotEnableCapture?: boolean,
  isOnlySupportAccelerometer?: boolean,
  isSupportOnlyShowEye?: boolean,
  isHide60fps ?: boolean,
  notSupportNearFocus?: boolean,
  isDisAbleTabletNightSwitch?: boolean,
  isSupportedHighColorSpace?: boolean,
  isSupportedScanCode?: boolean,
  isSupportedAIComposition?: boolean,
  isSupportImmediatelyStopPreview?: boolean,
  isNeedFixedBlurRadius?: boolean,
  isSupportedLogStyle?: boolean,
  isNotSupportedWatchMoonPictureInPicture: boolean,
  isSupportPortraitBeautyPro?: boolean,
  isNotSupportVideoBeautyPro?: boolean,
  isSupportEnableStableQuality?: boolean,
  beautyProDefaultValue?: number[],
  isNotSupportAudioControl?: boolean,
  panGestureZoomVelocity?: number,
  isUseNormalPhotoRapidCapture ?: boolean,
  isStitchingOnlySupportHeif?: boolean,
  isSupportsAntiShakeSnapshot?: boolean,
  isSupportSetFilterType?: boolean,
  smartPosition?: number,
  isSupportDefault1080PAnd60Fps?: boolean, // 录像分辨率帧率是否默认为1080P 60fps,当前仅青云版本支持
  isSupportStopStreamFormMultiTask?: boolean,
  isSupportMovieFile?: boolean,
  isSuspendPhotoBrowser?: boolean,
  isSupportedUltraPhotoFunction?: boolean,
  highUltraPhotoFuncDefaultValue?: boolean,
  isSupportedHDRBrightness?: boolean,
  isDisAbleBigCollapsScreenStitching?: boolean,
  isDisAbleRealTimeLapsePro?: boolean,
  isObtainStabilizationSupportFromCameraProfiles?: boolean,
  isSupportedStabilization?: boolean,
  isSupportMergedCustomColorStyle?: boolean,
  isPanoramaSupportHeif?: boolean,
  isPickerSupportedPortrait?: boolean,
  isSupportedIntervalPhotoCapture?: boolean,
  isSupportStageVideo?: boolean,
  isNotSupportPreCreate?: boolean,
  isSupportedFrontSnapShotSkinBeauty?: boolean,
  isDisableFrontVideoMirror?: boolean,
  isSupportedCycleClickZoom?: boolean,
};


// 获取机型对应的默认配置名
export function getDefaultFileNameByDeviceType(): string {
  let mDeviceType: string = '';
  if (DeviceInfo.isDefault() || DeviceInfo.isPhone() || DeviceInfo.isTablet()) {
    mDeviceType = 'Phone';
  }
  if (DeviceInfo.isPc() && hasCameraProfiles()) {
    mDeviceType = 'Pc';
  }
  // tv的相机复用手机的配置
  if (DeviceInfo.isTv()) {
    mDeviceType = 'Phone';
  }
  return 'Default' + 'Phone' + 'CameraProfiles_v2.json';
}
// 校验并返回预览流、录像流的Format
export function getPreviewAndVideoFormat(formatArr: string[], hdrVivid?: boolean): camera.CameraFormat {

  let resFormat = camera.CameraFormat.CAMERA_FORMAT_YUV_420_SP;
  for (let i = 0; i < formatArr.length; i++) {
    if (formatArr[i] === 'YUV_420_SP') {
      resFormat = camera.CameraFormat.CAMERA_FORMAT_YUV_420_SP;
    }
    if (formatArr[i] === 'RGBA_8888') {
      resFormat = camera.CameraFormat.CAMERA_FORMAT_RGBA_8888;
    }
    if (formatArr[i] === 'YCBCR_P010') { // hdrVivid将CAMERA_FORMAT_YCBCR_P010作为备选
      resFormat = camera.CameraFormat.CAMERA_FORMAT_YCBCR_P010;
    }
    if (formatArr[i] === 'YCRCB_P010') {
      resFormat = camera.CameraFormat.CAMERA_FORMAT_YCRCB_P010;
      return resFormat;
    }
  }
  return resFormat;
}

export function getModeNameForProfile(mode: ModeType): ModeType {
  let modeName = mode;
  return modeName;
}

export function getModeNameForZoom(mode: ModeType): ModeType {
  let modeName = mode;
  return modeName;
}


/*
 * 使用this.mV2Capability与底层上报分辨率执行匹配,生成需矫正的配置项
 */
/* instrument ignore next */
export function execPhotoCapabilityDataCombine(mV2Capability: V2Capability): Map<string, string> {
  let mV2CapabilityDiffMap: Map<string, string> = new Map();
  let cameraManager = camera.getCameraManager(ContextManager.getInstance().getAbilityStageContext());
  const devices = cameraManager?.getSupportedCameras();

  mV2Capability?.cameraCapability?.forEach((cameraCapability: AppCapabilityDataByType) => {
    cameraCapability?.cameraTypeData?.forEach((typeData: TypeDataByCollapsState) => {
      let cameraDeviceBase = devices?.find(device => {
        // 逻辑镜头CAMERA_TYPE_DEFAULT
        return device.connectionType !== camera.ConnectionType.CAMERA_CONNECTION_REMOTE &&
          device.cameraType === camera.CameraType.CAMERA_TYPE_DEFAULT &&
          device.cameraPosition === cameraCapability.cameraType;
        // 内屏前置无法获取(typeData.collapsState === 1 ? camera.CameraPosition.CAMERA_POSITION_FRONT))
      });
      HiLog.d(TAG, `cameraDeviceBase:${JSON.stringify(cameraDeviceBase)}`);
      if (cameraDeviceBase === null || cameraDeviceBase === undefined) {
        return;
      }
      try {
        handleModeProfileData(typeData, cameraDeviceBase, devices, cameraCapability, cameraManager,
          mV2CapabilityDiffMap);
        handleDefaultProfileData(typeData, cameraDeviceBase, cameraCapability, cameraManager, mV2CapabilityDiffMap);
      } catch (err) {
        const msg: string = err?.message;
        HiLog.e(TAG, `execPhotoCapabilityDataCombine fail, ${err?.code},${msg}`);
      }
    });
  });
  HiLog.i(TAG, `mV2CapabilityDiffMap size:${mV2CapabilityDiffMap.size}`);
  mV2CapabilityDiffMap.forEach((value, key) => {
    HiLog.d(TAG, `mV2CapabilityDiffMap key => ${key}, value => ${value}`);
  });
  if (mV2CapabilityDiffMap.size <= 0) {
    return undefined;
  }
  return mV2CapabilityDiffMap;
}

/* instrument ignore next */
function getSceneModeByModeName(modeName: string, outputType: OutputType): camera.SceneMode {
  let mode = modeName;
  switch (modeName) {
    case ModeType.VIDEO_SNAPSHOT:
      mode = ModeType.VIDEO;
      break;
  }
  return ModeTransform.modeType2SceneMode(mode as ModeType, { outputType: outputType });
}

/* instrument ignore next */
function handleModeProfileData(typeData: TypeDataByCollapsState, cameraDeviceBase: camera.CameraDevice | undefined,
  devices: camera.CameraDevice[], cameraCapability: AppCapabilityDataByType, cameraManager: camera.CameraManager,
  mV2CapabilityDiffMap: Map<string, string>): void {
  typeData?.collapsStateData?.forEach((modeDataObj: CollapsStateDataByMode) => {
    const keyPrefix = `${cameraCapability.cameraType}_${typeData.collapsState}_${modeDataObj.modeName}`;
    const modeData = modeDataObj?.modeData;
    // 泛拍照分辨率参数
    let cameraMode = getSceneModeByModeName(modeDataObj?.modeName, OutputType.PHOTO_OUTPUT);
    if (cameraMode === null || cameraMode === undefined) {
      return;
    }
    let supportCapabilityBase = cameraManager?.getSupportedOutputCapability(cameraDeviceBase, cameraMode);
    HiLog.i(TAG, `photo supportCapability:${JSON.stringify(supportCapabilityBase)}`);
    modeData?.photoProfiles?.forEach((profile: BaseProfileData) => {
      let cameraDevice = cameraDeviceBase;
      let supportCapability = supportCapabilityBase;
      if (modeData?.lensMode === 1) {
        cameraDevice = getCameraDevice(cameraDevice, devices, profile, cameraCapability);
        HiLog.i(TAG, `cameraDevice:${JSON.stringify(cameraDevice)}`);
        supportCapability = cameraManager?.getSupportedOutputCapability(cameraDevice, cameraMode);
      }
    });
    handlePhotoPreviewProfiles(modeData, supportCapabilityBase, keyPrefix, mV2CapabilityDiffMap);

    // 泛录像分辨率参数
    cameraMode = getSceneModeByModeName(modeDataObj?.modeName, OutputType.VIDEO_OUTPUT);
    if (cameraMode === null || cameraMode === undefined) {
      return;
    }
    supportCapabilityBase = cameraManager?.getSupportedOutputCapability(cameraDeviceBase, cameraMode);
    HiLog.i(TAG, `video supportCapability:${JSON.stringify(supportCapabilityBase)}`);
    handleVideoProfiles(modeData, supportCapabilityBase, keyPrefix, mV2CapabilityDiffMap);
  });
}

/* instrument ignore next */
function handlePhotoPreviewProfiles(modeData: ModeProfilesData | undefined,
  supportCapabilityBase: camera.CameraOutputCapability, keyPrefix: string,
  mV2CapabilityDiffMap: Map<string, string>): void {
  modeData?.photoPreviewProfiles?.forEach((profile: BaseProfileData) => {
    profile = findClosestProfile(profile, supportCapabilityBase?.previewProfiles,
      getPreviewAndVideoFormat(profile?.format, undefined), `${keyPrefix}_photoPreviewProfiles`,
      mV2CapabilityDiffMap);
  });
}

/* instrument ignore next */
function handleVideoProfiles(modeData: ModeProfilesData | undefined,
  supportCapabilityBase: camera.CameraOutputCapability, keyPrefix: string,
  mV2CapabilityDiffMap: Map<string, string>): void {
  modeData?.videoProfiles?.forEach((profile: BaseProfileData) => {
    profile = findClosestProfile(profile, supportCapabilityBase?.videoProfiles,
      getPreviewAndVideoFormat(profile?.format, undefined), `${keyPrefix}_videoProfiles`, mV2CapabilityDiffMap);
  });
  modeData?.videoPreviewProfiles?.forEach((profile: BaseProfileData) => {
    profile = findClosestProfile(profile, supportCapabilityBase?.previewProfiles,
      getPreviewAndVideoFormat(profile?.format, undefined), `${keyPrefix}_videoPreviewProfiles`,
      mV2CapabilityDiffMap);
  });
}

/* instrument ignore next */
function getCameraDevice(cameraDevice: camera.CameraDevice | undefined, devices: camera.CameraDevice[],
  profile: BaseProfileData, cameraCapability: AppCapabilityDataByType): camera.CameraDevice | undefined {
  cameraDevice = devices?.find(device => {
    // 物理镜头camera.CameraType
    return device.connectionType !== camera.ConnectionType.CAMERA_CONNECTION_REMOTE &&
      device.cameraType === (profile?.ratio === '4:3 MAIN' ? camera.CameraType.CAMERA_TYPE_WIDE_ANGLE :
        profile?.ratio === '4:3 WIDE' ? camera.CameraType.CAMERA_TYPE_ULTRA_WIDE :
        camera.CameraType.CAMERA_TYPE_TELEPHOTO) && device.cameraPosition === cameraCapability.cameraType;
  });
  return cameraDevice;
}

/* instrument ignore next */
function handleDefaultProfileData(typeData: TypeDataByCollapsState, cameraDeviceBase: camera.CameraDevice,
  cameraCapability: AppCapabilityDataByType, cameraManager: camera.CameraManager,
  mV2CapabilityDiffMap: Map<string, string>): void {
  const keyPrefix = `${cameraCapability.cameraType}_${typeData.collapsState}_defaultData`;
  const defaultData = typeData?.defaultData;
  // 泛拍照默认分辨率
  let supportProfilesBase =
    cameraManager?.getSupportedOutputCapability(cameraDeviceBase, camera.SceneMode.NORMAL_PHOTO);
  defaultData?.photoProfiles?.forEach((profile: BaseProfileData) => {
  });
  defaultData?.photoPreviewProfiles?.forEach((profile: BaseProfileData) => {
    profile = findClosestProfile(profile, supportProfilesBase?.previewProfiles,
      getPreviewAndVideoFormat(profile?.format, undefined), `${keyPrefix}_photoPreviewProfiles`,
      mV2CapabilityDiffMap);
  });

  // 泛录像默认分辨率
  supportProfilesBase =
    cameraManager?.getSupportedOutputCapability(cameraDeviceBase, camera.SceneMode.NORMAL_VIDEO);
  defaultData?.videoProfiles?.forEach((profile: BaseProfileData) => {
    profile = findClosestProfile(profile, supportProfilesBase?.videoProfiles,
      getPreviewAndVideoFormat(profile?.format, undefined), `${keyPrefix}_videoProfiles`, mV2CapabilityDiffMap);
  });
  defaultData?.videoPreviewProfiles?.forEach((profile: BaseProfileData) => {
    profile = findClosestProfile(profile, supportProfilesBase?.previewProfiles,
      getPreviewAndVideoFormat(profile?.format, undefined), `${keyPrefix}_videoPreviewProfiles`,
      mV2CapabilityDiffMap);
  });
}

/* instrument ignore next */
// 查看最接近的配置项
function findClosestProfile(profile: BaseProfileData, supportProfiles: camera.Profile[],
  cameraFormat: camera.CameraFormat, keyPrefix: string, mV2CapabilityDiffMap: Map<string, string>): BaseProfileData {
  let minDiff = Number.MAX_VALUE;
  let closestProfile = null;
  supportProfiles?.forEach((supportProfile) => {
    const isMatchRatio = isMatchProfileRatio(profile, supportProfile);
    if (supportProfile.format === cameraFormat && isMatchRatio) {
      const diff = calculateDifference(profile, supportProfile);
      if (diff < minDiff) {
        minDiff = diff;
        closestProfile = supportProfile;
      }
    }
  });
  const isSameProfile: boolean = minDiff === 0;
  if (closestProfile && !isSameProfile) {
    HiLog.d(TAG, `closestProfile:${JSON.stringify(closestProfile)}`);
    profile.profileWidth = closestProfile.size?.width;
    profile.profileHeight = closestProfile.size?.height;
    mV2CapabilityDiffMap.set(`${keyPrefix}_${profile.ratio}`, JSON.stringify(profile));
  }
  return profile;
}

// 计算差异的函数
/* instrument ignore next */
function calculateDifference(profile: BaseProfileData, supportProfile: camera.Profile): number {
  const widthDiff = Math.abs(profile.profileWidth - supportProfile.size.width);
  const heightDiff = Math.abs(profile.profileHeight - supportProfile.size.height);
  return widthDiff + heightDiff;
}

// 匹配profile的宽高比
/* instrument ignore next */
function isMatchProfileRatio(profile: BaseProfileData, supportProfile: camera.Profile): boolean {
  // 保留小数点后2位
  const profileRatio = (profile?.profileWidth / profile?.profileHeight).toFixed(1);
  const supportRatio = (supportProfile?.size?.width / supportProfile?.size?.height).toFixed(1);
  return profileRatio === supportRatio;
}


/*
 * 底层上报分辨率能力按需融合
 */
/* instrument ignore next */
export function reportResolutionCapabilityCombine(mV2Capability: V2Capability): void {
  let rectifyCapability = PreferencesService.getInstance()
    .getCapabilityValue(PersistType.FOREVER, 'RectifyCapability', undefined) as string;
  let rectifyMap = StringUtil.string2Map(rectifyCapability);
  // 存储格式 key: '1_2_defaultData/PRO_photoProfiles_4:3', value: BaseProfileData as string;
  if (!rectifyCapability) {
    return;
  }
  const patternRegular = /(\w+)_(\w+)_(\w+-? ?\w*)_(\w+)_(\w+:?\w* ?\w*)/;
  // 以底层能力上报的异常diff数据为视角
  let rectifyAllData = Array.from(rectifyMap.keys());
  rectifyAllData.forEach((storageKey: string) => {
    const matchArr = patternRegular.exec(storageKey);
    let rectifyCameraType = matchArr[1];
    let rectifyCollapsState = matchArr[2];
    let rectifyMode = matchArr[3];
    let rectifyProfileType = matchArr[4];
    let rectifyRatio = matchArr[5];
    let rectifyKey: string =
      `${rectifyCameraType}_${rectifyCollapsState}_${rectifyMode}_${rectifyProfileType}_${rectifyRatio}`;
    let rectifyData = rectifyMap.get(storageKey);
    HiLog.i(TAG, `reportResolutionCapabilityCombine rectifyKey: ${rectifyKey}, rectifyData: ${rectifyData}.`);

    if (!rectifyData) {
      return;
    }
    let rectifyValObj = JSON.parse(rectifyData) as BaseProfileData;

    let appCapIndex = mV2Capability.cameraCapability?.findIndex((appCapDataByType: AppCapabilityDataByType) => {
      return appCapDataByType?.cameraType === Number(rectifyCameraType);
    });
    if (appCapIndex < 0) {
      return;
    }
    let typeDataIndex = mV2Capability.cameraCapability[appCapIndex].cameraTypeData
      .findIndex((typeDataByCollaps: TypeDataByCollapsState) => {
        return typeDataByCollaps.collapsState === Number(rectifyCollapsState);
      });
    if (typeDataIndex < 0) {
      return;
    }

    HiLog.i(TAG, `reportResolutionCapabilityCombine rectifyKey: ${rectifyKey}, rectifyData: ${rectifyData}.`);
    if (rectifyMode === 'defaultData') {
      execRectifyDataCombine(rectifyRatio, rectifyValObj,
        mV2Capability.cameraCapability[appCapIndex].cameraTypeData[typeDataIndex].defaultData[rectifyProfileType]);
      return;
    }

    let modeIndex = mV2Capability.cameraCapability[appCapIndex].cameraTypeData[typeDataIndex].collapsStateData
      .findIndex((value: CollapsStateDataByMode) => {
        return value.modeName === rectifyMode;
      });
    if (modeIndex < 0) {
      return;
    }
    execRectifyDataCombine(rectifyRatio, rectifyValObj,
      mV2Capability.cameraCapability[appCapIndex].cameraTypeData[typeDataIndex].collapsStateData[modeIndex].modeData[rectifyProfileType]);
  });
}

// 矫正配置融合进this.mV2Capability
/* instrument ignore next */
function execRectifyDataCombine(rectifyRatio: string, rectifyValObj: BaseProfileData,
  targetValObj: BaseProfileData[]): void {
  if (!rectifyValObj || !targetValObj || targetValObj.length <= 0) {
    return;
  }
  let ratioIndex = targetValObj.findIndex((value: BaseProfileData) => {
    return value.ratio === rectifyRatio;
  });
  if (ratioIndex < 0 || rectifyValObj.ratio !== targetValObj[ratioIndex].ratio) {
    return;
  }
  targetValObj[ratioIndex].profileWidth = rectifyValObj.profileWidth;
  targetValObj[ratioIndex].profileHeight = rectifyValObj.profileHeight;
  HiLog.i(TAG, `execRectifyDataCombine ratioIndex:${ratioIndex}, target:${JSON.stringify(targetValObj[ratioIndex])}.`);
}

// 校验并返回拍照流的直出Format
export function getPhotoFormat(formatArr: string[], selectFormat: PhotoFormatMode): camera.CameraFormat {
  let isSupportedYuv: boolean = false;
  let isSupportedHeif: boolean = false;
  let isSupportedXdraw: boolean = false;
  for (let i = 0; i < formatArr.length; i++) {
    if (formatArr[i] === 'YUV_420_SP') {
      isSupportedYuv = true;
    } else if (formatArr[i] === 'XDRAW') {
      isSupportedXdraw = true;
    }
    // DNG格式不再在Profile控制,RAW主图通过enable开关使能
  }
  if (isSupportedXdraw) {
    return camera.CameraFormat.CAMERA_FORMAT_DNG_XDRAW; // 专业拍照XDRAW
  }
  if (isSupportedYuv) {
    return camera.CameraFormat.CAMERA_FORMAT_YUV_420_SP; // 有YUV则直出YUV
  }
  if (isSupportedHeif) {
    return camera.CameraFormat.CAMERA_FORMAT_HEIC; // 无YUV则在线直出HEIF
  }
  return camera.CameraFormat.CAMERA_FORMAT_JPEG;
}