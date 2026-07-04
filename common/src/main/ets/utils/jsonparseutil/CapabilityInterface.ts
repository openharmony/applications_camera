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

import type camera from '@ohos.multimedia.camera';
import { PhotoFormatMode } from '../../function/enumbase/PhotoFormatMode';
import lazy { OutputType } from '../../function/outputswitcher/OutputType';
import lazy { ModeType } from '../../mode/ModeType';

export abstract class CapabilityInterface {
  public constructor() {
  }

  // 数据容器初始化
  public abstract init(): boolean;

  // 系统参数校验失败时机使用系统配置文件与底层上报分辨率执行匹配,持久化需矫正的配置项
  public paramAbnormal2MatchCapability(): void {
  }

  // 读取底层能力上报时,提供先查询填充数据容器接口
  public queryCapability(position: camera.CameraPosition, mode: ModeType): void {
  }

  // 获取拍照流配置
  public abstract getPhotoProfiles(position: camera.CameraPosition, mode: ModeType, photoFormat: PhotoFormatMode,
    isPhysicalLens?: boolean): camera.Profile[];

  // 获取拍照预览流配置
  public abstract getPhotoPreviewProfiles(position: camera.CameraPosition, mode: ModeType): camera.Profile[];

  // 获取录像流配置
  public abstract getVideoProfiles(position: camera.CameraPosition, mode: ModeType, isHdrVivid?: boolean):
    camera.VideoProfile[];

  // 获取录像预览流配置
  public abstract getVideoPreviewProfiles(position: camera.CameraPosition, mode: ModeType, isHdrVivid?: boolean):
    camera.Profile[];

  // 获取录像帧率范围配置
  public abstract getVideoFrameRateArray(position: camera.CameraPosition, mode: ModeType, ratioIndex: number): number[];


  // 百宝箱图标排序
  public getTreasureBoxOrder(): number[] {
    return undefined;
  }

  // 开屏页排序
  public getStartupGuidancePages(): string[] {
    return undefined;
  }

  // 获取快捷变焦点
  public getQuickZoomArray(position: camera.CameraPosition, mode: ModeType, output: OutputType): number[] {
    return undefined;
  }

  // 获取变焦环大刻度点
  public getOpticalZoomArray(position: camera.CameraPosition, mode: ModeType, output: OutputType): number[] {
    return undefined;
  }

  // 获取当前模式和当前快捷变焦点的循环点切数组
  public getZoomCycleList(mode: ModeType, index: number): number[] {
    return undefined;
  }

  // 获取首页默认模式栏
  public getModeBarList(): ModeType[] {
    return undefined;
  }

  // 获取更多页装载模式栏
  public getMoreModeList(): ModeType[] {
    return undefined;
  }

  // 获取后当前情况时不支持的模式
  public getFilteredModeList(): ModeType[] {
    return undefined;
  }


  // 获取是否使能大图组件状态
  public getPhotoBrowserDisabled(): boolean {
    return undefined;
  }

  // 获取是否支持前置滑动变焦能力
  public getIsSupportedFrontZoomSlide(): boolean {
    return undefined;
  }

  // 获取是否支持后置60FPS广角
  public getNotSupportedVideo60fpsWide(): boolean {
    return undefined;
  }

  // 获取是否支持高画质照片特性能力
  public getIsSupportedHighQualityPhotoFunction(): boolean {
    return undefined;
  }

  // 获取应用高画质照片特性默认值
  public getHighQualityPhotoFuncDefaultValue(): boolean {
    return undefined;
  }

  public getIsSupportedFestivalWatermark(): boolean {
    return undefined;
  }

  public getLimitTimeWatermarkDuration(): string {
    return '';
  }

  // 获取是否需要移除闪光灯
  public getIsNeedRemoveFlashFunc(): boolean {
    return undefined;
  }

  public getIsSupportedOverHotHidePip(): boolean {
    return undefined;
  }

  // 获取是否支持后置自拍功能拉齐
  public getIsSupportedEnhancedBackSelfie(): boolean {
    return undefined;
  }

  // 获取是否支持低角度拍摄
  public getIsSupportedLowAngleShot(): boolean {
    return undefined;
  }

  // 获取前置swing zoom ratio
  public getIsSupportedSmartBackSelfieFunction(): boolean {
    return undefined;
  }

  // 获取是否低配置设备
  public getIsDeviceLowConfig(): boolean {
    return undefined;
  }

  // 获取前置swing zoom ratio
  public getFrontSwingZoomRatio(): number {
    return undefined;
  }

  // 获取后置swing zoom ratio
  public getBackSwingZoomRatio(): number {
    return undefined;
  }

  // 获取是否支持前置高像素拍照
  public getIsSupportedFrontHighPixelFunction(): boolean {
    return undefined;
  }

  // 获取是否需要在退出时隐藏预览界面
  public needHidePreviewWhenBackground(): boolean {
    return undefined;
  }

  // 获取是否支持高效视频格式
  public getIsNotSupportedEfficientVideoFunction(): boolean {
    return undefined;
  }

  // 获取是否支持全局曝光
  public getIsSupportGlobalExposure(): boolean {
    return undefined;
  }

  // 获取是否支持录像前后切换不断流
  public getIsSupportRecordingFlowing(): boolean {
    return undefined;
  }

  // 获取是否NOVA产品，用来区分模式文字下的小圆点颜色等nova产品特殊判断
  public getIsNovaProduct(): boolean {
    return undefined;
  }

  // 获取是否支持前置闪拍
  public getIsSupportedFrontSnapShotFunction(): boolean {
    return undefined;
  }

  // 获取是否支持等效焦距大字体
  public getIsSupportedEquivalentFocalBigText(): boolean {
    return undefined;
  }

  // 获取是否为美肤而非人像模式
  public getIsShowBeautySkinMode(): boolean {
    return undefined;
  }

  // 获取视频Bitrate值
  public getVideoBitrateH264(): number {
    return 30000000;
  }

  // 获取视频Bitrate值
  public getVideoBitrateH265(): number {
    return 30000000;
  }

  // 在不能拍照的时候执行闪黑动效，提升用户观感
  public getIsSupportedEffectWhenNotEnableCapture(): boolean {
    return undefined;
  }

  // 获取是否仅支持ACC重力传感器
  public getIsOnlySupportAccelerometer(): boolean {
    return undefined;
  }

  // 获取是否支持特殊情况下单人脸人眼下仅显示人眼不显示人脸
  public getIsSupportOnlyShowEye(): boolean {
    return undefined;
  }

  // 获取是否是否支持近物对焦选项
  public getIsNotSupportNearFocus(): boolean {
    return undefined;
  }

  // 获取是否退后台时立马stopPreviewOutput
  public getIsSupportImmediatelyStopPreview(): boolean {
    return undefined;
  }

  // 获取是否需要固定模糊半径
  public getIsNeedFixedBlurRadius(): boolean {
    return undefined;
  }

  // 是否支持质量优先
  public getIsSupportEnableStableQuality(): boolean {
    return undefined;
  }

  // 是否支持声控拍照
  public getIsNotSupportAudioControl(): boolean {
    return undefined;
  }

  // 滑动变焦响应速率调节
  public getPanGestureZoomVelocity(): number {
    return undefined;
  }

  // 获取是否支持录像默认为1080P 60fps
  public getIsSupportDefault1080PAnd60Fps(): boolean {
    return undefined;
  }

  // 是否支持相机退至多任务之后停流
  public getIsSupportStopStreamToMultiTask(): boolean {
    return undefined;
  }

  // 获取是否支持前置闪拍美肤
  public getIsSupportedFrontSnapShotSkinBeauty(): boolean {
    return undefined;
  }

  // 是否支持MovieFileOutput
  public getIsSupportMovieFile(): boolean {
    return false;
  }

  // 是否隔离大图组件
  public getIsSuspendPhotoBrowser(): boolean {
    return false;
  }

  //延时摄影是否支持自动和曝光功能
  public getIsDisAbleRealTimeLapsePro(): boolean {
    return undefined;
  }

  // 获取是否支持Picker人像
  public getIsPickerSupportedPortrait(): boolean {
    return undefined;
  }

  // 是否支持间隔拍照功能
  public getIsSupportedIntervalPhotoCapture(): boolean {
    return false;
  }

  // 是否支持快捷变焦点循环点切
  public getIsSupportedCycleClickZoom(): boolean {
    return undefined;
  }

  // 获取设备是否禁用前置录像镜像
  public getIsDisableFrontVideoMirror(): boolean {
    return undefined;
  }

  public getIs60fpsDefaultCloseEfficientVideo(): boolean {
    return undefined;
  }

  public getIs60fpsSupportHdrVivid(): boolean {
    return undefined;
  }

  public getIsNotSupportedWideZoom60fpsVideoBack(): boolean {
    return undefined;
  }

  public getIsChange3To4Zoom60fpsVideoBack(): boolean {
    return undefined;
  }

  public getIsSupportedHighColorSpace(): boolean {
    return undefined;
  }
}