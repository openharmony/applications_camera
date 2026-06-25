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

import lazy { HiLog } from '../../utils/HiLog';
import camera from '@ohos.multimedia.camera';
import media from '@ohos.multimedia.media';
import lazy { DeviceInfo } from '../../component/deviceinfo/DeviceInfo';
import lazy { FeatureManager } from '../core/FeatureManager';
import lazy { FunctionId } from '../core/functionproperty/FunctionId';
import lazy { WindowDirection } from '../../utils/WindowDirection';
import display from '@ohos.display';
import lazy { DisplayService } from '../../service/UIAdaptive/DisplayService';
import lazy { WindowService } from '../../service/window/WindowService';
import window from '@ohos.window';
import lazy { CameraAppCapability } from '../../camera/CameraAppCapability';
import lazy { getStates } from '../../redux';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { BlurAnimateUtil } from '../../utils/BlurAnimateUtil';
import lazy { PcInfo } from '../../component/deviceinfo/PcInfo';

const TAG: string = 'RecorderConfigOperation';

export class RecorderConfigOperation {
  /* instrument ignore file */
  private static readonly AUDIO_BITRATE = 192000;
  private static readonly AUDIO_CHANNELS = DeviceInfo.isTv() ? 1 : 2;
  private static readonly AUDIO_SAMPLE_RATE = DeviceInfo.isTv() ? 16000 : 48000;
  private static readonly HARD_VIDEO_BITRATE = 30000000;
  public static VIDEO_META_TYPES: number[] = [0];
  private static readonly TAG_TYPE_SSLOW_MOTION: string = 'TypeSSlowMotion';
  private static readonly TAG_TYPE_SLOW_MOTION: string = 'TypeSlowMotion';
  private static readonly TAG_NOMAL_VIDEO: string = 'TypeNormalVideo';

  public static getDefaultConfig(profile: camera.VideoProfile, frameRate: number): media.AVRecorderConfig {
    const defaultConfig = {
      //@ts-ignore
      audioSourceType: DeviceInfo.isTv() ? media.AudioSourceType.AUDIO_SOURCE_TYPE_VOICE_COMMUNICATION :
      media.AudioSourceType.AUDIO_SOURCE_TYPE_CAMCORDER,
      videoSourceType: 0,
      profile: this.getRecorderProfile(profile, frameRate, media.CodecMimeType.VIDEO_AVC, false),
      location: undefined,
      url: '',
      rotation: 0,
      metaSourceTypes: RecorderConfigOperation.VIDEO_META_TYPES,
      metadata: {
        genre: this.getVideoResourceType(),
      }
    };
    return defaultConfig;
  }

  public static createVideoConfig(profile: camera.VideoProfile, frameRate: number,
    isHdr: boolean): media.AVRecorderConfig {
    const isDefault: boolean = DeviceInfo.isUis7885() || DeviceInfo.isDefault() || DeviceInfo.isDayu300();
    // 默认使用 video/avc，rk 设备不兼容 video/mp4v-es
    // const videoCodec: media.CodecMimeType = isDefault ? media.CodecMimeType.VIDEO_MPEG4 :
    const videoCodec: media.CodecMimeType = isDefault ? media.CodecMimeType.VIDEO_AVC :
      (isHdr || this.getIsEfficientVideoFormat()) ? media.CodecMimeType.VIDEO_HEVC : media.CodecMimeType.VIDEO_AVC;

    const videoConfig: media.AVRecorderConfig = {
      //@ts-ignore
      audioSourceType: DeviceInfo.isTv() ? media.AudioSourceType.AUDIO_SOURCE_TYPE_VOICE_COMMUNICATION :
      media.AudioSourceType.AUDIO_SOURCE_TYPE_CAMCORDER,
      videoSourceType: isDefault ? 1 : 0,
      profile: this.getRecorderProfile(profile, frameRate, videoCodec, isHdr),
      url: '',
      rotation: this.getJpegRotation(),
      // @ts-ignore
      metaSourceTypes: RecorderConfigOperation.VIDEO_META_TYPES,
      metadata: {
        genre: this.getVideoResourceType(),
      }
    };
    return videoConfig;
  }


  private static getVideoResourceType(): string {
    const mode: ModeType = getStates().get<ModeType>('modeReducer', 'mode');
    switch (mode) {
      default:
        return this.TAG_NOMAL_VIDEO;
    }
  }

  private static getRecorderProfile(profile: camera.VideoProfile, frameRate: number, videoCodec: media.CodecMimeType,
    isHdr: boolean): media.AVRecorderProfile {
    return {
      audioBitrate: RecorderConfigOperation.AUDIO_BITRATE,
      audioChannels: RecorderConfigOperation.AUDIO_CHANNELS,
      audioCodec: media.CodecMimeType.AUDIO_AAC,
      audioSampleRate: RecorderConfigOperation.AUDIO_SAMPLE_RATE,
      fileFormat: media.ContainerFormatType.CFT_MPEG_4,
      videoBitrate: videoCodec === media.CodecMimeType.VIDEO_HEVC ?
      CameraAppCapability.getInstance().getVideoBitrateH265() : CameraAppCapability.getInstance().getVideoBitrateH264(),
      videoCodec: videoCodec,
      videoFrameWidth: profile.size.width,
      videoFrameHeight: profile.size.height,
      videoFrameRate: frameRate,
      isHdr: isHdr,
      enableStableQualityMode: getStates().get<ModeType>('modeReducer', 'mode') === ModeType.VIDEO &&
      CameraAppCapability.getInstance().getIsSupportEnableStableQuality(),
    };
  }

  public static createPreviewRecordConfig(profile: camera.Profile, frameRate: number): media.AVRecorderConfig {
    const isDefault: boolean = DeviceInfo.isDefault();
    const videoCodec: media.CodecMimeType = isDefault ? media.CodecMimeType.VIDEO_MPEG4 :
      (this.getIsEfficientVideoFormat()) ? media.CodecMimeType.VIDEO_HEVC : media.CodecMimeType.VIDEO_AVC;

    const videoConfig: media.AVRecorderConfig = {
      //@ts-ignore
      audioSourceType: DeviceInfo.isTv() ? media.AudioSourceType.AUDIO_SOURCE_TYPE_VOICE_COMMUNICATION :
      media.AudioSourceType.AUDIO_SOURCE_TYPE_CAMCORDER,
      videoSourceType: isDefault ? 1 : 0,
      profile: this.getPreviewRecorderProfile(profile, frameRate, videoCodec),
      url: '',
      rotation: this.getJpegRotation()
    };
    return videoConfig;
  }

  private static getPreviewRecorderProfile(profile: camera.Profile, frameRate: number,
    videoCodec: media.CodecMimeType): media.AVRecorderProfile {
    return {
      audioBitrate: RecorderConfigOperation.AUDIO_BITRATE,
      audioChannels: RecorderConfigOperation.AUDIO_CHANNELS,
      audioCodec: media.CodecMimeType.AUDIO_AAC,
      audioSampleRate: RecorderConfigOperation.AUDIO_SAMPLE_RATE,
      fileFormat: media.ContainerFormatType.CFT_MPEG_4,
      videoBitrate: videoCodec === media.CodecMimeType.VIDEO_HEVC ?
      CameraAppCapability.getInstance().getVideoBitrateH265() : CameraAppCapability.getInstance().getVideoBitrateH264(),
      videoCodec: videoCodec,
      videoFrameWidth: profile.size.width,
      videoFrameHeight: profile.size.height,
      videoFrameRate: frameRate,
      isHdr: false
    };
  }

  public static createTimelapseRecordConfig(profile: camera.Profile, frameRate: number,
    isHdr: boolean): media.AVRecorderConfig {
    if (!profile) {
      return null;
    }

    const isDefault: boolean = DeviceInfo.isDefault();
    const videoCodec: media.CodecMimeType = isDefault ? media.CodecMimeType.VIDEO_MPEG4 :
      (isHdr || this.getIsEfficientVideoFormat()) ? media.CodecMimeType.VIDEO_HEVC : media.CodecMimeType.VIDEO_AVC;

    const videoConfig: media.AVRecorderConfig = {
      //@ts-ignore
      audioSourceType: DeviceInfo.isTv() ? media.AudioSourceType.AUDIO_SOURCE_TYPE_VOICE_COMMUNICATION :
      media.AudioSourceType.AUDIO_SOURCE_TYPE_CAMCORDER,
      videoSourceType: isDefault ? 1 : 0,
      profile: this.getTimelapseRecorderProfile(profile, frameRate, videoCodec, isHdr),
      url: '',
      rotation: this.getJpegRotation()
    };
    Reflect.deleteProperty(videoConfig, 'audioSourceType');
    return videoConfig;
  }

  private static getTimelapseRecorderProfile(profile: camera.Profile, frameRate: number,
    videoCodec: media.CodecMimeType,
    isHdr: boolean): media.AVRecorderProfile {
    return {
      audioBitrate: RecorderConfigOperation.AUDIO_BITRATE,
      audioChannels: RecorderConfigOperation.AUDIO_CHANNELS,
      audioCodec: media.CodecMimeType.AUDIO_AAC,
      audioSampleRate: RecorderConfigOperation.AUDIO_SAMPLE_RATE,
      fileFormat: media.ContainerFormatType.CFT_MPEG_4,
      videoBitrate: videoCodec === media.CodecMimeType.VIDEO_HEVC ?
      CameraAppCapability.getInstance().getVideoBitrateH265() : CameraAppCapability.getInstance().getVideoBitrateH264(),
      videoCodec: videoCodec,
      videoFrameWidth: profile.size.width,
      videoFrameHeight: profile.size.height,
      videoFrameRate: frameRate,
      isHdr: isHdr
    };
  }

  private static getIsEfficientVideoFormat(): boolean { // 用户操作需重启流,无须单独下发,AVRecorderConfig带下H.265
    const efficientVideoFunc = FeatureManager.getInstance().getFunction(FunctionId.EFFICIENT_VIDEO);
    if (!efficientVideoFunc) {
      return false;
    }
    const isEfficientVideoFormat = efficientVideoFunc.getValue();
    HiLog.i(TAG, `isEfficientVideoFormat: ${isEfficientVideoFormat}.`);
    return isEfficientVideoFormat; // 是否高效视频格式H.265; HDR依赖H.265,高效视频格式不依赖HDR; 仅高效视频格式时限制为8bit流
  }

  private static getTabletRotation(position: camera.CameraPosition, display: display.Display,
    isVideoMirror: boolean): camera.ImageRotation {
    const isLockOrientation: boolean = getStates().get<boolean>('windowReducer', 'isLockRotation');
    if (isLockOrientation) {
      const currentDirection: WindowDirection = getStates().get<WindowDirection>('contextReducer', 'direction');
      HiLog.i(TAG, `getJpegRotation currentDirection: ${currentDirection}, isVideoMirror:${isVideoMirror}.`);
      switch (currentDirection) {
        case WindowDirection.LEFT:
          return <number> camera.ImageRotation.ROTATION_180;
        case WindowDirection.RIGHT:
          return <number> camera.ImageRotation.ROTATION_0;
        case WindowDirection.BOTTOM:
          if (position === camera.CameraPosition.CAMERA_POSITION_FRONT) {
            return isVideoMirror ? <number> camera.ImageRotation.ROTATION_270 :
              <number> camera.ImageRotation.ROTATION_90;
          }
          return <number> camera.ImageRotation.ROTATION_270;
        default:
          if (position === camera.CameraPosition.CAMERA_POSITION_FRONT) {
            return isVideoMirror ? <number> camera.ImageRotation.ROTATION_90 :
              <number> camera.ImageRotation.ROTATION_270;
          }
          return <number> camera.ImageRotation.ROTATION_90;
      }
    }
    switch (display.orientation) {
      case 0:
        return position === camera.CameraPosition.CAMERA_POSITION_FRONT && !isVideoMirror ?
          <number> camera.ImageRotation.ROTATION_270
          : <number> camera.ImageRotation.ROTATION_90;
      case 1:
        return <number> camera.ImageRotation.ROTATION_180;
      case 2:
        return position === camera.CameraPosition.CAMERA_POSITION_FRONT && !isVideoMirror ?
          <number> camera.ImageRotation.ROTATION_90
          : <number> camera.ImageRotation.ROTATION_270;
      case 3:
        return <number> camera.ImageRotation.ROTATION_0;
      default:
        return <number> camera.ImageRotation.ROTATION_180;
    }
  }

  private static getVdeShowBackAsFrontRotation(display: display.Display): camera.ImageRotation {
    const isLockOrientation: boolean = getStates().get<boolean>('windowReducer', 'isLockRotation'); //锁定方向
    if (isLockOrientation) {
      const currentDirection: WindowDirection = getStates().get<WindowDirection>('contextReducer', 'direction');
      HiLog.i(TAG, 'Lock getVdeShowBackAsFrontRotation currentDirection: ' + currentDirection);
      switch (currentDirection) {
        case WindowDirection.TOP:
          return <number> camera.ImageRotation.ROTATION_90;
        case WindowDirection.RIGHT:
          return <number> camera.ImageRotation.ROTATION_0;
        case WindowDirection.LEFT:
          return <number> camera.ImageRotation.ROTATION_180;
        case WindowDirection.BOTTOM:
          return <number> camera.ImageRotation.ROTATION_270;
        default:
          return <number> camera.ImageRotation.ROTATION_0;
      }
    }
    HiLog.i(TAG,
      `Unlock getVdeShowBackAsFrontRotation dis.orientation: ${display.orientation}, dis.rotation: ${display.rotation}`);
    // 关闭锁定
    switch (display.orientation) {
      case 0: // 右
        return <number> camera.ImageRotation.ROTATION_270;
      case 1: // 下
        return <number> camera.ImageRotation.ROTATION_180;
      case 2: // 左
        return <number> camera.ImageRotation.ROTATION_90;
      case 3: // 上
        return <number> camera.ImageRotation.ROTATION_0;
      default:
        return <number> camera.ImageRotation.ROTATION_180;
    }
  }

  private static getVdeCollapsedRotation(display: display.Display): camera.ImageRotation {
    const isVideoMirror: boolean = FeatureManager.getInstance().getFunction(FunctionId.MIRROR).getValue();
    const isLockOrientation: boolean = getStates().get<boolean>('windowReducer', 'isLockRotation'); //锁定方向
    if (isLockOrientation) {
      const currentDirection: WindowDirection = getStates().get<WindowDirection>('contextReducer', 'direction');
      HiLog.i(TAG, 'Lock getCollapsedRotation currentDirection: ' + currentDirection);
      switch (currentDirection) {
        case WindowDirection.TOP:
          return isVideoMirror ? <number> camera.ImageRotation.ROTATION_90 : <number> camera.ImageRotation.ROTATION_270;
        case WindowDirection.RIGHT:
          return <number> camera.ImageRotation.ROTATION_180;
        case WindowDirection.LEFT:
          return <number> camera.ImageRotation.ROTATION_0;
        case WindowDirection.BOTTOM:
          return isVideoMirror ? <number> camera.ImageRotation.ROTATION_270 : <number> camera.ImageRotation.ROTATION_90;
        default:
          return <number> camera.ImageRotation.ROTATION_0;
      }
    }
    HiLog.i(TAG,
      `Unlock getCollapsedRotation dis.orientation: ${display.orientation}, dis.rotation: ${display.rotation}`);
    // 关闭锁定
    switch (display.rotation) {
      case 0: // 右
        return isVideoMirror ? <number> camera.ImageRotation.ROTATION_90 : <number> camera.ImageRotation.ROTATION_270;
      case 1: // 下
        return <number> camera.ImageRotation.ROTATION_180;
      case 2: // 左
        return isVideoMirror ? <number> camera.ImageRotation.ROTATION_270 : <number> camera.ImageRotation.ROTATION_90;
      case 3: // 上
        return <number> camera.ImageRotation.ROTATION_0;
      default:
        return <number> camera.ImageRotation.ROTATION_180;
    }
  }

  private static getGRLExpandRotation(position: camera.CameraPosition, display: display.Display): camera.ImageRotation {
    const isLockOrientation: boolean = getStates().get<boolean>('windowReducer', 'isLockRotation'); //锁定方向
    const isVideoMirror: boolean = FeatureManager.getInstance().getFunction(FunctionId.MIRROR).getValue();
    HiLog.i(TAG, `getGRLExpandRotation, isVideoMirror:${isVideoMirror}.`);
    if (isLockOrientation) {
      const currentDirection: WindowDirection = getStates().get<WindowDirection>('contextReducer', 'direction');
      HiLog.i(TAG, 'getGRLExpandRotation Lock getCollapsedRotation currentDirection: ' + currentDirection);
      switch (currentDirection) {
        case WindowDirection.TOP:
          if (position === camera.CameraPosition.CAMERA_POSITION_FRONT) {
            return isVideoMirror ? <number> camera.ImageRotation.ROTATION_90 :
              <number> camera.ImageRotation.ROTATION_270;
          }
          return <number> camera.ImageRotation.ROTATION_90;
        case WindowDirection.RIGHT:
          return <number> camera.ImageRotation.ROTATION_0;
        case WindowDirection.LEFT:
          return <number> camera.ImageRotation.ROTATION_180;
        case WindowDirection.BOTTOM:
          if (position === camera.CameraPosition.CAMERA_POSITION_FRONT) {
            return isVideoMirror ? <number> camera.ImageRotation.ROTATION_270 :
              <number> camera.ImageRotation.ROTATION_90;
          }
          return <number> camera.ImageRotation.ROTATION_270;
        default:
          return <number> camera.ImageRotation.ROTATION_90;
      }
    }
    HiLog.i(TAG,
      `getGRLExpandRotation Unlock getCollapsedRotation dis.orientation: ${display.orientation}, dis.rotation: ${display.rotation}`);
    // 关闭锁定
    switch (display.orientation) {
      case 0: // 右
        return <number> camera.ImageRotation.ROTATION_180;
      case 1: // 下
        if (position === camera.CameraPosition.CAMERA_POSITION_FRONT) {
          return isVideoMirror ? <number> camera.ImageRotation.ROTATION_270 : <number> camera.ImageRotation.ROTATION_90;
        }
        return <number> camera.ImageRotation.ROTATION_270;
      case 2: // 左
        return <number> camera.ImageRotation.ROTATION_0;
      case 3: // 上
        if (position === camera.CameraPosition.CAMERA_POSITION_FRONT) {
          return isVideoMirror ? <number> camera.ImageRotation.ROTATION_90 : <number> camera.ImageRotation.ROTATION_270;
        }
        return <number> camera.ImageRotation.ROTATION_90;
      default:
        return <number> camera.ImageRotation.ROTATION_0;
    }
  }

  private static getGRLCollapsedRotation(position: camera.CameraPosition): camera.ImageRotation {
    const currentDirection: WindowDirection = getStates().get<WindowDirection>('contextReducer', 'direction');
    const isVideoMirror: boolean = FeatureManager.getInstance().getFunction(FunctionId.MIRROR).getValue();
    HiLog.i(TAG, `getGRLCollapsedRotation currentDirection: ${currentDirection}, isVideoMirror:${isVideoMirror}.`);
    switch (currentDirection) {
      case WindowDirection.LEFT:
        return <number> camera.ImageRotation.ROTATION_180;
      case WindowDirection.RIGHT:
        return <number> camera.ImageRotation.ROTATION_0;
      case WindowDirection.BOTTOM:
        if (position === camera.CameraPosition.CAMERA_POSITION_FRONT) {
          return isVideoMirror ? <number> camera.ImageRotation.ROTATION_270 : <number> camera.ImageRotation.ROTATION_90;
        }
        return <number> camera.ImageRotation.ROTATION_270;
      default:
        if (position === camera.CameraPosition.CAMERA_POSITION_FRONT) {
          return isVideoMirror ? <number> camera.ImageRotation.ROTATION_90 : <number> camera.ImageRotation.ROTATION_270;
        }
        return <number> camera.ImageRotation.ROTATION_90;
    }
  }

  private static getGRLLandscapeRotation(position: camera.CameraPosition,
    display: display.Display): camera.ImageRotation {
    const isVideoMirror: boolean = FeatureManager.getInstance().getFunction(FunctionId.MIRROR).getValue();
    HiLog.i(TAG,
      `getGRLLandscapeRotation Unlock getCollapsedRotation dis.orientation: ${display.orientation}, dis.rotation: ${display.rotation}`);
    switch (display.orientation) {
      case 0: // 上
        if (position === camera.CameraPosition.CAMERA_POSITION_FRONT) {
          return isVideoMirror ? <number> camera.ImageRotation.ROTATION_90 : <number> camera.ImageRotation.ROTATION_270;
        }
        return <number> camera.ImageRotation.ROTATION_90;
      case 1: // 右
        return <number> camera.ImageRotation.ROTATION_180;
      case 2: // 下
        if (position === camera.CameraPosition.CAMERA_POSITION_FRONT) {
          return isVideoMirror ? <number> camera.ImageRotation.ROTATION_270 : <number> camera.ImageRotation.ROTATION_90;
        }
        return <number> camera.ImageRotation.ROTATION_270;
      case 3: // 左
        return <number> camera.ImageRotation.ROTATION_0;

      default:
        return <number> camera.ImageRotation.ROTATION_0;
    }
  }

  /**
   * get jpeg rotation to let photo fit default camera orientation
   *
   * @return the jpeg rotation
   * now get current screen orientation impossible,just can rotate to normal state on vertical.
   * horizon is still error orientation video orientation
   */
  private static getJpegRotation(): camera.ImageRotation {
    const state = getStates();
    const position: camera.CameraPosition = state.get<camera.CameraPosition>('cameraReducer', 'cameraPosition');
    const isLockOrientation: boolean = state.get<boolean>('windowReducer', 'isLockRotation'); //锁定方向
    const dis: display.Display = DisplayService.getInstance().getDisplay();
    const windowStatus = WindowService.getInstance().getWindowStatus();
    const isVideoMirror: boolean = FeatureManager.getInstance().getFunction(FunctionId.MIRROR).getValue();
    if (DeviceInfo.isTablet()) {
      return this.getTabletRotation(position, dis, isVideoMirror);
    }
    let angle = CameraAppCapability.getInstance().getPcCameraOrientation();
    if (DeviceInfo.isPc()) {
      return !PcInfo.isRotatablePc() ? angle : this.getXComponentRotation();
    }
    if ((state.get<boolean>('collapsReducer', 'isShowLandscape') &&
      !state.get<boolean>('collapsReducer', 'isShowSemiCollapsed') ||
      (windowStatus === window.WindowStatusType.FLOATING || windowStatus === window.WindowStatusType.SPLIT_SCREEN)) &&
      !isLockOrientation) {
      HiLog.i(TAG, `getJpegRotation orientation: ${dis.orientation}, isVideoMirror:${isVideoMirror}.`);
      switch (dis.orientation) {
        case 0:
          return position === camera.CameraPosition.CAMERA_POSITION_FRONT && !isVideoMirror ?
            <number> camera.ImageRotation.ROTATION_270
            : <number> camera.ImageRotation.ROTATION_90;
        case 1:
          return <number> camera.ImageRotation.ROTATION_180;
        case 2:
          return position === camera.CameraPosition.CAMERA_POSITION_FRONT && !isVideoMirror ?
            <number> camera.ImageRotation.ROTATION_90
            : <number> camera.ImageRotation.ROTATION_270;
        case 3:
          return <number> camera.ImageRotation.ROTATION_0;
        default:
          return <number> camera.ImageRotation.ROTATION_0;
      }
    }
    if (DeviceInfo.isTv()) {
      return camera.ImageRotation.ROTATION_0;
    }

    if (state.get<boolean>('collapsReducer', 'isVdeCollapsed')) {
      return this.getVdeCollapsedRotation(dis);
    }
    const currentDirection: WindowDirection = state.get<WindowDirection>('contextReducer', 'direction');
    HiLog.i(TAG, `getJpegRotation currentDirection: ${currentDirection}, isVideoMirror:${isVideoMirror}.`);
    let isCaptureFront = position === camera.CameraPosition.CAMERA_POSITION_FRONT;
    switch (currentDirection) {
      case WindowDirection.LEFT:
        return DeviceInfo.isUis7885() && isCaptureFront ? <number> camera.ImageRotation.ROTATION_0 :
          <number> camera.ImageRotation.ROTATION_180;
      case WindowDirection.RIGHT:
        return DeviceInfo.isUis7885() && isCaptureFront ? <number> camera.ImageRotation.ROTATION_180 :

          <number> camera.ImageRotation.ROTATION_0;
      case WindowDirection.BOTTOM:
        if (isCaptureFront) {
          return isVideoMirror ? <number> camera.ImageRotation.ROTATION_270 : <number> camera.ImageRotation.ROTATION_90;
        }
        return DeviceInfo.isUis7885()? <number> camera.ImageRotation.ROTATION_270 : <number> camera.ImageRotation.ROTATION_90;
      default:
        if (isCaptureFront) {
          return isVideoMirror ? <number> camera.ImageRotation.ROTATION_90 : <number> camera.ImageRotation.ROTATION_270;
        }
        return DeviceInfo.isUis7885()? <number> camera.ImageRotation.ROTATION_90 : <number> camera.ImageRotation.ROTATION_270;
    }
  }

  private static getXComponentRotation(): number {
    const rotation = DisplayService.getInstance().getDisplay().rotation;
    const isVideoMirror: boolean = FeatureManager.getInstance().getFunction(FunctionId.MIRROR).getValue();
    let xComponentRotate = 0;
    switch (rotation) {
      case 0:
        xComponentRotate = isVideoMirror ? BlurAnimateUtil.IMG_ROTATE_ANGLE_90 : BlurAnimateUtil.IMG_ROTATE_ANGLE_270;
        break;
      case 1:
        xComponentRotate = BlurAnimateUtil.IMG_ROTATE_ANGLE_180;
        break;
      case 2:
        xComponentRotate = BlurAnimateUtil.IMG_ROTATE_ANGLE_90;
        break;
      case 3:
        xComponentRotate = BlurAnimateUtil.IMG_ROTATE_ANGLE_0;
        break;
      default:
        xComponentRotate = BlurAnimateUtil.IMG_ROTATE_ANGLE_90;
    }
    return xComponentRotate;
  }
}