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

import lazy { HiLog } from '../utils/HiLog';
import camera from '@ohos.multimedia.camera';
import lazy { ModeType } from '../mode/ModeType';
import lazy { FunctionId } from '../function/core/functionproperty/FunctionId';
import lazy { /* CameraProfilesJsonUtilV1,*/
  CameraProfilesJsonUtilV2
} from '../utils/LazyImportUtil';
import lazy { CapabilityInterface } from '../utils/jsonparseutil/CapabilityInterface';
import lazy { OutputType } from '../function/outputswitcher/OutputType';
import lazy { ContextManager } from '../service/context/ContextManager';
import lazy { FeatureManager } from '../function/core/FeatureManager';
import lazy { GlobalContext } from '../utils/GlobalContext';
import lazy { TREASURE_BOX_ORDER } from '../component/treasurebox/common/TreasureBoxOrder';
import { PhotoFormatMode } from '../function/enumbase/PhotoFormatMode';

const TAG: string = 'CameraAppCapability';

/**
 * 相机应用能力集查询器,对上屏蔽实现细节：不区分不同版本应用配置获取、相机底层能力上报
 */
export class CameraAppCapability extends CapabilityInterface {
  private static sInstanceCapability: CameraAppCapability;
  private mCapabilityVersion: string = 'v0'; // v0代表走底层能力上报路径CameraPlatformCapability
  private mCameraProfilesJsonUtil: CapabilityInterface;
  private mCameraDevicesPC: camera.CameraDevice[] = [];

  private constructor() {
    super();
    this.init();
    HiLog.i(TAG, 'CameraAppCapability constructor E.');
  }

  public static getInstance(): CameraAppCapability {
    if (!CameraAppCapability.sInstanceCapability) {
      CameraAppCapability.sInstanceCapability = new CameraAppCapability();
    }
    return CameraAppCapability.sInstanceCapability;
  }

  public init(): boolean { // 通过CameraProfiles获取版本号
    HiLog.i(TAG, 'init E.');
    this.mCameraProfilesJsonUtil = new CameraProfilesJsonUtilV2();
    let isSupportedV2 = this.mCameraProfilesJsonUtil.init();
    if (isSupportedV2) {
      this.mCapabilityVersion = 'v2';
      GlobalContext.get().setPhotoBrowserDisabled(this.getPhotoBrowserDisabled());
      return;
    }
    HiLog.i(TAG, 'init X.');
  }

  public paramAbnormal2MatchCapability(): void {
    this.mCameraProfilesJsonUtil.paramAbnormal2MatchCapability();
  }

  // 获取PC支持的CameraPosition逻辑镜头
  public getPcSupportCameraPosition(): camera.CameraPosition { // 直接从camera查询,避免CameraPlatformCapability必初始化
    const cameraManager = camera.getCameraManager(ContextManager.getInstance().getAbilityStageContext());
    this.mCameraDevicesPC = cameraManager.getSupportedCameras();
    if (this.mCameraDevicesPC.length >= 1) {
      return this.mCameraDevicesPC[0].cameraPosition;
    }
    return camera.CameraPosition.CAMERA_POSITION_UNSPECIFIED;
  }

  // 获取PC缓存的镜头角度，勿重复执行耗时操作
  public getPcCameraOrientation(): number {
    if (this.mCameraDevicesPC.length >= 1) {
      return this.mCameraDevicesPC[0].cameraOrientation;
    }
    return 0;
  }

  // 读取底层能力上报时,提供先查询填充数据容器接口
  public queryCapability(position: camera.CameraPosition, mode: ModeType): void {
    HiLog.i(TAG, `queryCapability position: ${position}, mode: ${mode} E.`);
    this.mCameraProfilesJsonUtil.queryCapability(position, mode);
    HiLog.i(TAG, 'queryCapability X.');
  }

  // 获取拍照流配置
  public getPhotoProfiles(position: camera.CameraPosition, mode: ModeType, photoFormat: PhotoFormatMode,
    isPhysicalLens?: boolean): camera.Profile[] {
    return this.mCameraProfilesJsonUtil.getPhotoProfiles(position, mode, photoFormat, isPhysicalLens);
  }

  // 获取拍照预览流配置
  public getPhotoPreviewProfiles(position: camera.CameraPosition, mode: ModeType): camera.Profile[] {
    return this.mCameraProfilesJsonUtil.getPhotoPreviewProfiles(position, mode);
  }

  // 获取录像流配置
  public getVideoProfiles(position: camera.CameraPosition, mode: ModeType, isHdrVivid?: boolean):
    camera.VideoProfile[] {
    return this.mCameraProfilesJsonUtil.getVideoProfiles(position, mode, isHdrVivid);
  }

  // 获取录像预览流配置
  public getVideoPreviewProfiles(position: camera.CameraPosition, mode: ModeType, isHdrVivid?: boolean):
    camera.Profile[] {
    return this.mCameraProfilesJsonUtil.getVideoPreviewProfiles(position, mode, isHdrVivid);
  }

  // 获取录像帧率范围配置
  public getVideoFrameRateArray(position: camera.CameraPosition, mode: ModeType): number[] {
    const videoRatio: number = FeatureManager.getInstance().getFunction(FunctionId.VIDEO_RESOLUTION).getValue();
    let frameArr = this.mCameraProfilesJsonUtil.getVideoFrameRateArray(position, mode, videoRatio - 1); // func转为index
    if (!frameArr || frameArr.length <= 0) { // 泛拍照场景设置页显示普通录像模式帧率支持范围
      frameArr = this.mCameraProfilesJsonUtil.getVideoFrameRateArray(position, ModeType.VIDEO, videoRatio - 1);
    }

    return frameArr;
  }

  // 提供60fps能力查询接口
  public is60fpsSupport(position: camera.CameraPosition, mode: ModeType): boolean {
    let index = this.getVideoFrameRateArray(position, mode).findIndex((value: number) => {
      return value === 60;
    });
    if (index >= 0) {
      return true;
    }
    return false;
  }

  // 获取快捷变焦点
  public getQuickZoomArray(position: camera.CameraPosition, mode: ModeType, output: OutputType): number[] {
    return this.mCameraProfilesJsonUtil.getQuickZoomArray(position, mode, output);
  }

  // 获取变焦环大刻度点
  public getOpticalZoomArray(position: camera.CameraPosition, mode: ModeType, output: OutputType): number[] {
    return this.mCameraProfilesJsonUtil.getOpticalZoomArray(position, mode, output);
  }

  // 获取当前模式中当前快捷变焦点的循环点切数组
  public getZoomCycleList(mode: ModeType, index: number): number[] {
    return this.mCameraProfilesJsonUtil.getZoomCycleList(mode, index);
  }

  // 获取首页默认模式栏
  public getModeBarList(): ModeType[] {
    return this.mCameraProfilesJsonUtil.getModeBarList();
  }

  // 获取更多页装载模式栏
  public getMoreModeList(): ModeType[] {
    return this.mCameraProfilesJsonUtil.getMoreModeList();
  }

  // 获取后当前需要过滤展示的模式数据
  public getFilteredModeList(): ModeType[] {
    return this.mCameraProfilesJsonUtil.getFilteredModeList();
  }

  // 获取是否使能大图组件状态
  public getPhotoBrowserDisabled(): boolean {
    return this.mCameraProfilesJsonUtil.getPhotoBrowserDisabled();
  }

  // 获取是否支持前置滑动变焦能力
  public getIsSupportedFrontZoomSlide(): boolean {
    return this.mCameraProfilesJsonUtil.getIsSupportedFrontZoomSlide();
  }

  // 获取是否支持后置60fps广角
  public getNotSupportedVideo60fpsWide(): boolean {
    return this.mCameraProfilesJsonUtil.getNotSupportedVideo60fpsWide();
  }

  // 获取是否支持高画质照片特性能力
  public getIsSupportedHighQualityPhotoFunction(): boolean {
    return this.mCameraProfilesJsonUtil.getIsSupportedHighQualityPhotoFunction();
  }

  // 获取应用高画质照片特性默认值
  public getHighQualityPhotoFuncDefaultValue(): boolean {
    return this.mCameraProfilesJsonUtil.getHighQualityPhotoFuncDefaultValue();
  }

  // 获取是否支持节假日水印特性能力
  public getIsSupportedFestivalWatermark(): boolean {
    return this.mCameraProfilesJsonUtil.getIsSupportedFestivalWatermark();
  }

  // 获取是否支持节假日水印特性能力
  public getLimitTimeWatermarkDuration(): string {
    return this.mCameraProfilesJsonUtil.getLimitTimeWatermarkDuration();
  }

  // 是否需要移除闪光灯（需要移除配置true，默认为false不移除）
  public getIsNeedRemoveFlashFunc(): boolean {
    return this.mCameraProfilesJsonUtil.getIsNeedRemoveFlashFunc();
  }

  public getIsSupportedOverHotHidePip(): boolean {
    return this.mCameraProfilesJsonUtil.getIsSupportedOverHotHidePip();
  }

  // 获取是否支持后置自拍功能拉齐能力
  public getIsSupportedEnhancedBackSelfie(): boolean {
    return this.mCameraProfilesJsonUtil.getIsSupportedEnhancedBackSelfie();
  }

  // 获取是否支持低角度拍摄
  public getIsSupportedLowAngleShot(): boolean {
    return this.mCameraProfilesJsonUtil.getIsSupportedLowAngleShot();
  }

  // 获取是否低配置设备
  public getIsDeviceLowConfig(): boolean {
    return this.mCameraProfilesJsonUtil.getIsDeviceLowConfig();
  }

  // 获取是否支持后置智感自拍功能(对应参数只在智感后置自拍使用；对应参数修改 需要找SE确认)
  public getIsSupportedSmartBackSelfieFunction(): boolean {
    return this.mCameraProfilesJsonUtil.getIsSupportedSmartBackSelfieFunction();
  }

  // 获取前置swing zoom ratio(前置swing 出图等效焦距/24mm)
  public getFrontSwingZoomRatio(): number {
    return this.mCameraProfilesJsonUtil.getFrontSwingZoomRatio();
  }

  // 获取后置swing zoom ratio(后置swing 出图等效焦距/24mm)
  public getBackSwingZoomRatio(): number {
    return this.mCameraProfilesJsonUtil.getBackSwingZoomRatio();
  }

  public getIsSupportedFrontHighPixelFunction(): boolean {
    return this.mCameraProfilesJsonUtil.getIsSupportedFrontHighPixelFunction();
  }

  // 获取是否需要在退出时隐藏预览界面
  public needHidePreviewWhenBackground(): boolean {
    return this.mCameraProfilesJsonUtil.needHidePreviewWhenBackground();
  }

  // 获取是否不支持高效视频格式
  public getIsNotSupportedEfficientVideoFunction(): boolean {
    return this.mCameraProfilesJsonUtil.getIsNotSupportedEfficientVideoFunction();
  }

  // 获取是否支持全局曝光
  public getIsSupportGlobalExposure(): boolean {
    return this.mCameraProfilesJsonUtil.getIsSupportGlobalExposure();
  }

  // 获取是否支持录像前后切换不断流
  public getIsSupportRecordingFlowing(): boolean {
    return this.mCameraProfilesJsonUtil.getIsSupportRecordingFlowing();
  }

  // 获取是否支持前置闪拍
  public getIsSupportedFrontSnapShotFunction(): boolean {
    return this.mCameraProfilesJsonUtil.getIsSupportedFrontSnapShotFunction();
  }

  // 获取是否支持等效焦距大字体
  public getIsSupportedEquivalentFocalBigText(): boolean {
    return this.mCameraProfilesJsonUtil.getIsSupportedEquivalentFocalBigText();
  }

  // 获取是否为美肤而非人像模式
  public getIsShowBeautySkinMode(): boolean {
    return this.mCameraProfilesJsonUtil?.getIsShowBeautySkinMode();
  }

  // 获取视频Bitrate值
  public getVideoBitrateH264(): number {
    return this.mCameraProfilesJsonUtil.getVideoBitrateH264();
  }

  // 获取视频Bitrate值
  public getVideoBitrateH265(): number {
    return this.mCameraProfilesJsonUtil.getVideoBitrateH265();
  }

  // 在不能拍照的时候执行闪黑动效，提升用户观感
  public getIsSupportedEffectWhenNotEnableCapture(): boolean {
    return this.mCameraProfilesJsonUtil.getIsSupportedEffectWhenNotEnableCapture();
  }

  // 获取是否支持仅ACC重力传感器
  public getIsOnlySupportAccelerometer(): boolean {
    return this.mCameraProfilesJsonUtil.getIsOnlySupportAccelerometer();
  }

  // 获取是否支持特殊情况下单人脸人眼下仅显示人眼不显示人脸。
  public getIsSupportOnlyShowEye(): boolean {
    return this.mCameraProfilesJsonUtil.getIsSupportOnlyShowEye();
  }

  // 获取是否是否支持近物对焦选项
  public getIsNotSupportNearFocus(): boolean {
    return this.mCameraProfilesJsonUtil.getIsNotSupportNearFocus();
  }

  // 获取是否退后台时立马stopPreviewOutput
  public getIsSupportImmediatelyStopPreview(): boolean {
    return this.mCameraProfilesJsonUtil.getIsSupportImmediatelyStopPreview();
  }

  // 获取是否需要固定模糊半径
  public getIsNeedFixedBlurRadius(): boolean {
    return this.mCameraProfilesJsonUtil.getIsNeedFixedBlurRadius();
  }

  // 是否支持质量优先
  public getIsSupportEnableStableQuality(): boolean {
    return this.mCameraProfilesJsonUtil.getIsSupportEnableStableQuality();
  }

  // 百宝箱图标排序
  public getTreasureBoxOrder(): number[] {
    let treasureBoxOrder: number[] = this.mCameraProfilesJsonUtil.getTreasureBoxOrder() ?? TREASURE_BOX_ORDER
    return treasureBoxOrder;
  }

  // 是否支持声控拍照
  public getIsNotSupportAudioControl(): boolean {
    return this.mCameraProfilesJsonUtil.getIsNotSupportAudioControl();
  }

  // 开屏页排序
  public getStartupGuidancePages(): string[] {
    return this.mCameraProfilesJsonUtil.getStartupGuidancePages() ?? [];
  }

  // 滑动变焦响应速率调节
  public getPanGestureZoomVelocity(): number {
    return this.mCameraProfilesJsonUtil.getPanGestureZoomVelocity();
  }

  // 是否支持相机退至多任务之后停流
  public getIsSupportStopStreamToMultiTask(): boolean {
    return this.mCameraProfilesJsonUtil.getIsSupportStopStreamToMultiTask();
  }

  // 获取是否支持录像默认为1080P 60fps
  public getIsSupportDefault1080PAnd60Fps(): boolean {
    return this.mCameraProfilesJsonUtil.getIsSupportDefault1080PAnd60Fps();
  }

  // 获取60fps是否默认关闭搞笑视频编码
  public getIs60fpsDefaultCloseEfficientVideo(): boolean {
    return this.mCameraProfilesJsonUtil.getIs60fpsDefaultCloseEfficientVideo();
  }

  public getIs60fpsSupportHdrVivid(): boolean {
    return this.mCameraProfilesJsonUtil.getIs60fpsSupportHdrVivid();
  }


  // 获取是否支持前置闪拍美肤
  public getIsSupportedFrontSnapShotSkinBeauty(): boolean {
    return this.mCameraProfilesJsonUtil.getIsSupportedFrontSnapShotSkinBeauty();
  }

  // 是否支持MovieFileOutput
  public getIsSupportMovieFile(): boolean {
    return this.mCameraProfilesJsonUtil.getIsSupportMovieFile();
  }

  // 是否隔离大图组件
  public getIsSuspendPhotoBrowser(): boolean {
    return this.mCameraProfilesJsonUtil.getIsSuspendPhotoBrowser();
  }

  //延时摄影是否支持自动和曝光功能
  public getIsDisAbleRealTimeLapsePro(): boolean {
    return this.mCameraProfilesJsonUtil.getIsDisAbleRealTimeLapsePro();
  }

  // 获取Picker是否支持人像
  public getIsPickerSupportedPortrait(): boolean {
    return this.mCameraProfilesJsonUtil.getIsPickerSupportedPortrait();
  }

  // 是否支持间隔拍照功能
  public getIsSupportedIntervalPhotoCapture(): boolean {
    return this.mCameraProfilesJsonUtil.getIsSupportedIntervalPhotoCapture();
  }

  // 获取是否支持快捷变焦点优化
  public getIsSupportedCycleClickZoom(): boolean {
    return this.mCameraProfilesJsonUtil.getIsSupportedCycleClickZoom();
  }

  // 获取设备是否禁用前置录像镜像
  public getIsDisableFrontVideoMirror(): boolean {
    return this.mCameraProfilesJsonUtil.getIsDisableFrontVideoMirror();
  }

  public getIsNotSupportedWideZoom60fpsVideoBack() : boolean {
    return this.mCameraProfilesJsonUtil.getIsNotSupportedWideZoom60fpsVideoBack()
  }
  
  public getIsChange3To4Zoom60fpsVideoBack() : boolean {
    return this.mCameraProfilesJsonUtil.getIsChange3To4Zoom60fpsVideoBack()
  }

  public getIsSupportedHighColorSpace() :boolean {
    return this.mCameraProfilesJsonUtil.getIsSupportedHighColorSpace();
  }
}