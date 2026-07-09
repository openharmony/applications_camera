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

import lazy { HiLog } from '../HiLog';
import camera from '@ohos.multimedia.camera';
import lazy { DeviceInfo } from '../../component/deviceinfo/DeviceInfo';
import configPolicy from '@ohos.configPolicy';
import fs from '@ohos.file.fs';
import lazy { ModeType } from '../../mode/ModeType';
import lazy { OutputOperation } from '../../function/outputswitcher/OutputOperation';
import lazy { OutputType } from '../../function/outputswitcher/OutputType';
import lazy { CapabilityInterface } from './CapabilityInterface';
import lazy { WindowService } from '../../service/window/WindowService';
import lazy { display, window } from '@kit.ArkUI';
import lazy { ContextManager } from '../../service/context/ContextManager';
import lazy { OutputSwitcher } from '../../function/outputswitcher/OutputSwitcher';
import lazy { PickerUtils } from '../PickerUtils';
import lazy { TREASURE_BOX_ORDER } from '../../component/treasurebox/common/TreasureBoxOrder';
import lazy { PersistType, PreferencesService } from '../../service/preferences/PreferencesService';
import lazy {
  V2Capability,
  AppCapabilityDataByType,
  TypeDataByCollapsState,
  CollapsStateDataByMode,
  ModeProfilesData,
  BaseProfileData,
  ZoomParameterData,
  ZoomTypeDataByMode,
  SupportedModeData,
  AppMetadata,
  reportResolutionCapabilityCombine,
  execPhotoCapabilityDataCombine,
  getPreviewAndVideoFormat,
  getModeNameForZoom,
  getModeNameForProfile,
  getDefaultFileNameByDeviceType,
  ZoomCycleClickData,
  ZoomCycleClickDataByMode,
  getPhotoFormat
} from './ProfileStructure';
import lazy { StringUtil } from '../StringUtil';
import { PhotoFormatMode } from '../../function/enumbase/PhotoFormatMode';
import { util } from '@kit.ArkTS';

const SUBSCRIPT_ZERO: number = 0;
const SUBSCRIPT_ONE: number = 1;
const SUBSCRIPT_TWO: number = 2;
const SUBSCRIPT_THREE: number = 3;

const TAG: string = 'CameraProfilesJsonUtilV2';

export default class CameraProfilesJsonUtilV2 extends CapabilityInterface {
  private mV2Capability: V2Capability = undefined;

  public constructor() {
    super();
    HiLog.i(TAG, 'constructor E.');
  }

  /* instrument ignore next */
  public init(): boolean {
    HiLog.i(TAG, 'getCameraCapabilityJson E.');
    try {
      let json: string = '';
      let mV2DiffCapability: V2Capability = undefined; // 差异配置临时数据容器

      HiLog.begin(TAG, 'getOneCfgFile');
      if (DeviceInfo.isUis7885()) {
        json = this.getCameraProfilesToString('DefaultPhoneCameraProfiles_v2_uis7885.json')
      } else if (DeviceInfo.isRk3568()) {
        json = this.getCameraProfilesToString('DefaultPhoneCameraProfiles_v2_rk3568.json')
      } else if (DeviceInfo.isDayu300()) {
        json = this.getCameraProfilesToString('DefaultPhoneCameraProfiles_v2_dayu300.json')
      } else {
        // 默认配置，从设备本地获取
        const relPath: string = 'etc/camera/CameraProfiles.json';
        HiLog.begin(TAG, 'getOneCfgFile');
        const filePath: string = configPolicy.getOneCfgFileSync(relPath);
        if (filePath !== '') {
          json = fs.readTextSync(filePath);
        }
      }
      HiLog.end(TAG, 'getOneCfgFile');
      if (json !== '') {
        HiLog.begin(TAG, 'getDeviceConfigurationJson');
        mV2DiffCapability = JSON.parse(json) as V2Capability;
        HiLog.i(TAG, `mV2DiffCapability ${mV2DiffCapability?.version}.`);
        if (mV2DiffCapability?.version !== 'v2') {
          return false;
        }
        HiLog.end(TAG, 'getDeviceConfigurationJson');
      }

      const data: Uint8Array = ContextManager.getInstance().getResourceManager().getRawFileContentSync(
        getDefaultFileNameByDeviceType());
      json = String.fromCharCode.apply(null, data);
      this.mV2Capability = JSON.parse(json) as V2Capability; // 先用Default配置充满数据容器
      this.mV2Capability.treasureBoxOrder = TREASURE_BOX_ORDER;
      if (!this.mV2Capability) {
        return false;
      }

      // 再用差异配置增量修正数据容器
      if (mV2DiffCapability !== undefined) {
        this.execCapabilityIncrementDataCombine(mV2DiffCapability);
        this.execZoomIncrementDataCombine(mV2DiffCapability);
        this.execModeListIncrementDataCombine(mV2DiffCapability);
        this.execMetadataIncrementDataCombine(mV2DiffCapability);
        this.execTreasureBoxOrderIncrementDataCombine(mV2DiffCapability);
        this.execCustomColorStyleSupportedModeIncrementDataCombine(mV2DiffCapability);
        this.execStartupGuidancePagesIncrementDataCombine(mV2DiffCapability);
        this.execCycleClickZoomData(mV2DiffCapability);
      }
    } catch (error) {
      HiLog.e(TAG, 'getCameraCapabilityJson failed.');
      return false;
    }

    reportResolutionCapabilityCombine(this.mV2Capability); // 底层上报分辨率能力按需融合
    HiLog.i(TAG, 'getCameraCapabilityJson X.');
    return true;
  }

  /**
   * 资源文件替换成String
   */
  getCameraProfilesToString(CameraProfilesName: string): string {
    let textDecoderOptions: util.TextDecoderOptions = {
      fatal: false,
      ignoreBOM: true
    }
    let decodeToStringOptions: util.DecodeToStringOptions = {
      stream: false
    }
    let unt = ContextManager.getInstance().getResourceManager().getRawFileContentSync(CameraProfilesName)
    let textDecoder = util.TextDecoder.create('utf-8', textDecoderOptions);
    return textDecoder.decodeToString(unt, decodeToStringOptions);
  }

  // 系统参数校验失败时机使用系统配置文件与底层上报分辨率执行匹配,持久化需矫正的配置项
  /* instrument ignore next */
  public paramAbnormal2MatchCapability(): void {
    HiLog.i(TAG, 'paramAbnormal2MatchCapability E.');
    // 对比底层与ccm配置
    let mV2CapabilityDiffMap = execPhotoCapabilityDataCombine(this.mV2Capability);

    // 下述为底层矫正配置持久化流程
    if (mV2CapabilityDiffMap) {
      PreferencesService.getInstance()
        .putCapabilityValue(PersistType.FOREVER, 'RectifyCapability', StringUtil.map2String(mV2CapabilityDiffMap));
    }
  }

  // json解析时执行cameraCapability差异配置融合至默认配置
  private execCapabilityIncrementDataCombine(mV2DiffCapability: V2Capability): void {
    mV2DiffCapability?.cameraCapability?.forEach((appCapDataByType: AppCapabilityDataByType, appCapIndex: number) => {
      appCapDataByType?.cameraTypeData?.forEach((typeDataByCollaps: TypeDataByCollapsState, typeDataIndex: number) => {
        // defaultData数据按分辨率维度执行补充融合
        this.combineDefaultData(typeDataByCollaps, appCapIndex, typeDataIndex);

        // collapsStateData数据修正/增量融合
        this.combineCollapsStateData(typeDataByCollaps, appCapIndex, typeDataIndex);
      });
    });

    // 对默认配置的剩余collapsState执行融合
    this.combineRemainCollapsStateData(mV2DiffCapability);
  }

  private combineDefaultData(typeDataByCollaps: TypeDataByCollapsState, appCapIndex: number, typeDataIndex: number): void {
    for (let key in typeDataByCollaps.defaultData) {
      let defaultProfileData: BaseProfileData[] =
        this.mV2Capability.cameraCapability[appCapIndex].cameraTypeData[typeDataIndex].defaultData[key];
      typeDataByCollaps.defaultData[key]?.forEach((baseProfileData: BaseProfileData) => {
        let index = defaultProfileData?.findIndex((value: BaseProfileData) => {
          return value?.ratio === baseProfileData.ratio;
        });
        if (index >= 0) { // CCM差异化的default配置按分辨率维度补充融合至默认的default配置,如full分辨率
          defaultProfileData[index] = baseProfileData;
        }
      });
    }
    // combineDefaultData数据融合结束后,CCM差异化的default配置后续禁止使用,仅允许使用this.mV2Capability.defaultData
  }

  private combineCollapsStateData(typeDataByCollaps: TypeDataByCollapsState, appCapIndex: number, typeDataIndex: number): void {
    typeDataByCollaps?.collapsStateData?.forEach((collapsDataByMode: CollapsStateDataByMode, collapsDataIndex: number) => {
      let index = this.mV2Capability.cameraCapability[appCapIndex].cameraTypeData[typeDataIndex].collapsStateData
        .findIndex((value: CollapsStateDataByMode) => {
          return value.modeName === collapsDataByMode?.modeName; // this.mV2Capability.collapsStateData也存在CCM配置的modeData
        });
      let resCollapsData: ModeProfilesData = JSON.parse(JSON.stringify(collapsDataByMode.modeData)); // 先使用CCM配置填充临时容器
      if (collapsDataByMode.modeData?.lensMode !== 1 && collapsDataByMode.modeName !== 'VIDEO SNAPSHOT') {
        this.traverseDiffConfig2ResCollapsData(collapsDataByMode, appCapIndex, typeDataIndex, resCollapsData);
      }

      if (index >= 0) {
        this.execProRawContinueLensAdapter(collapsDataByMode.modeData?.lensMode, collapsDataByMode.modeName, resCollapsData);

        this.mV2Capability.cameraCapability[appCapIndex].cameraTypeData[typeDataIndex].collapsStateData[index].modeData =
          resCollapsData; // CCM差异化的collapsState配置直接覆盖修正默认的collapsState配置
      } else {
        this.mV2Capability.cameraCapability[appCapIndex].cameraTypeData[typeDataIndex].collapsStateData
          .push({
            modeName: collapsDataByMode.modeName, modeData: resCollapsData
          });
      }
    });
    // combineCollapsStateData数据融合结束后,CCM差异化的collapsState配置后续禁止使用,仅允许使用this.mV2Capability.collapsStateData
  }

  private traverseDiffConfig2ResCollapsData(collapsDataByMode: CollapsStateDataByMode, appCapIndex: number, typeDataIndex:
    number, resCollapsData: ModeProfilesData): void {
    for (let key in collapsDataByMode.modeData) { // 遍历CCM差异化配置的modeData
      if (collapsDataByMode.modeData[key].length ===
      this.mV2Capability.cameraCapability[appCapIndex].cameraTypeData[typeDataIndex].defaultData[key].length) {
        continue;
      }
      // 按key维度,使用defaultData替换数据
      resCollapsData[key] = JSON.parse(JSON.stringify(
        this.mV2Capability.cameraCapability[appCapIndex].cameraTypeData[typeDataIndex].defaultData[key]));

      // 再将CCM差异化collapsStateData配置按分辨率维度增量融合至resCollapsData
      collapsDataByMode.modeData[key].forEach((value: BaseProfileData) => {
        resCollapsData[key][this.getProfilesIndexByRatio(value.ratio,
          this.mV2Capability.cameraCapability[appCapIndex].cameraTypeData[typeDataIndex].defaultData[key].length)] =
          value;
      });
    }
  }

  private combineRemainCollapsStateData(mV2DiffCapability: V2Capability): void {
    this.mV2Capability?.cameraCapability?.forEach((appCapDataByType: AppCapabilityDataByType, appCapIndex: number) => {
      appCapDataByType?.cameraTypeData?.forEach((typeDataByCollaps: TypeDataByCollapsState, typeDataIndex: number) => {
        // 最后还需对默认配置的剩余collapsState执行融合
        let v2CollapsDataByModeArr: CollapsStateDataByMode[] = typeDataByCollaps.collapsStateData;

        this.traverseV2CollapsDataByModeArray(mV2DiffCapability, v2CollapsDataByModeArr, appCapIndex, typeDataIndex);
      });
    });
  }

  private traverseV2CollapsDataByModeArray(mV2DiffCapability: V2Capability, v2CollapsDataByModeArr:
    CollapsStateDataByMode[], appCapIndex: number, typeDataIndex: number): void {
    v2CollapsDataByModeArr?.forEach((v2CollapsStateData: CollapsStateDataByMode, collapsDataIndex: number) => {
      let index = -1;
      try {
        index = mV2DiffCapability?.cameraCapability[appCapIndex]?.cameraTypeData[typeDataIndex]?.collapsStateData
        ?.findIndex((value: CollapsStateDataByMode) => {
          return value.modeName === v2CollapsStateData?.modeName;
        }); // 说明index < 0 => this.mV2Capability中剩余的collapsStateData
      } catch (err) {
        HiLog.e(TAG, 'combineRemainCollapsStateData mV2DiffCapability cannot findIndex.');
      }
      if (index >= 0 || v2CollapsStateData.modeData?.lensMode === 1 || v2CollapsStateData.modeName === 'VIDEO SNAPSHOT') {
        this.execProRawContinueLensAdapter(v2CollapsStateData.modeData?.lensMode, v2CollapsStateData.modeName,
          v2CollapsStateData.modeData);
        return;
      }

      this.traverseV2CollapsStateData(v2CollapsDataByModeArr, v2CollapsStateData, appCapIndex, typeDataIndex, collapsDataIndex);
    });
  }

  /* instrument ignore next */
  private traverseV2CollapsStateData(v2CollapsDataByModeArr: CollapsStateDataByMode[], v2CollapsStateData:
    CollapsStateDataByMode, appCapIndex: number, typeDataIndex: number, collapsDataIndex: number): void {
    for (let key in v2CollapsStateData.modeData) { // 遍历剩余collapsState的modeData
      if (v2CollapsStateData.modeData[key].length ===
      this.mV2Capability.cameraCapability[appCapIndex].cameraTypeData[typeDataIndex].defaultData[key].length) {
        continue;
      }

      // 按key维度,使用defaultData替换数据
      let resModeData: BaseProfileData = JSON.parse(JSON.stringify(
        this.mV2Capability.cameraCapability[appCapIndex].cameraTypeData[typeDataIndex].defaultData[key]));
      // 再将剩余collapsStateData配置按分辨率维度增量融合至resModeData
      v2CollapsStateData.modeData[key].forEach((value: BaseProfileData) => {
        resModeData[this.getProfilesIndexByRatio(value.ratio,
          this.mV2Capability.cameraCapability[appCapIndex].cameraTypeData[typeDataIndex].defaultData[key].length)] =
          value;
      });
      v2CollapsDataByModeArr[collapsDataIndex].modeData[key] = resModeData;
    }
  }

  // BA产品二供模组(同制式不同模组)专业模式RAW图物理镜头分辨率能力上报存在差异
  /* instrument ignore next */
  private execProRawContinueLensAdapter(mLensMode: number, mModeName: string, resCollapsData: ModeProfilesData): void {
    return; // 主干兜底流程注释测试,继续评估
    if (mLensMode !== 1 || mModeName !== 'PRO') {
      return; // 接续镜头仅BA两款机型存在,其它机型归一化分辨率规格-故保持性能
    }
    const cameraManager: camera.CameraManager = camera.getCameraManager(
      ContextManager.getInstance().getAbilityStageContext());
    const devices: camera.CameraDevice[] = cameraManager.getSupportedCameras();

    for (let i = 0; i < resCollapsData.photoProfiles?.length; i++) {
      let cameraDevice: camera.CameraDevice | undefined = devices.find((item: camera.CameraDevice) => {
        return item.cameraPosition === camera.CameraPosition.CAMERA_POSITION_BACK &&
          item.connectionType !== camera.ConnectionType.CAMERA_CONNECTION_REMOTE &&
          item.cameraType ===
            (resCollapsData.photoProfiles[i].ratio === '4:3 MAIN' ? camera.CameraType.CAMERA_TYPE_WIDE_ANGLE :
              resCollapsData.photoProfiles[i].ratio === '4:3 WIDE' ? camera.CameraType.CAMERA_TYPE_ULTRA_WIDE :
                camera.CameraType.CAMERA_TYPE_TELEPHOTO);
      });
      if (!cameraDevice || !cameraDevice.cameraType) {
        continue;
      }
      const photoProfiles: camera.Profile[] = cameraManager.getSupportedOutputCapability(cameraDevice,
        camera.SceneMode.PROFESSIONAL_PHOTO).photoProfiles;

      let supportWidth: number = 4;
      let supportHeight: number = 3;
      for (let j = 0; j < photoProfiles.length; j++) {
        if (photoProfiles[j].format !== 4) {
          continue;
        }
        let curSize: camera.Size = photoProfiles[j].size;
        if (curSize.width === resCollapsData.photoProfiles[i].profileWidth &&
          curSize.height === resCollapsData.photoProfiles[i].profileHeight) {
          supportWidth = curSize.width;
          supportHeight = curSize.height;
          break;
        }
        if (Math.abs(curSize.height / curSize.width - 0.75) < 0.01 && curSize.width > supportWidth) {
          supportWidth = curSize.width;
          supportHeight = curSize.height;
        }
      }
      if (supportWidth !== resCollapsData.photoProfiles[i].profileWidth) {
        resCollapsData.photoProfiles[i].profileWidth = supportWidth;
        resCollapsData.photoProfiles[i].profileHeight = supportHeight;
      }
      HiLog.d(TAG, `PRO RAW Photo ${resCollapsData.photoProfiles[i].ratio} ${resCollapsData.photoProfiles[i].profileWidth}.`);
    }
  }

  // json解析时执行zoomParameter差异配置融合至默认配置
  private execZoomIncrementDataCombine(mV2DiffCapability: V2Capability): void {
    mV2DiffCapability?.zoomParameter?.forEach((zoomParameterData: ZoomParameterData, zoomParamIndex: number) => {
      // defaultData数据直接覆盖
      zoomParameterData?.defaultData?.forEach((zoomModeData: ZoomTypeDataByMode) => {
        if (this.mV2Capability.zoomParameter[zoomParamIndex]) {
          this.mV2Capability.zoomParameter[zoomParamIndex].defaultData[zoomModeData.modeName === 'PHOTO' ? 0 : 1] =
            zoomModeData;
        }
      });
      // cameraTypeData数据修正/增量融合
      zoomParameterData?.cameraTypeData?.forEach((zoomModeData: ZoomTypeDataByMode) => {
        let index = this.mV2Capability.zoomParameter[zoomParamIndex].cameraTypeData
          .findIndex((value: ZoomTypeDataByMode) => {
            return value.modeName === zoomModeData?.modeName;
          });
        if (index >= 0) {
          this.mV2Capability.zoomParameter[zoomParamIndex].cameraTypeData[index] = zoomModeData;
        } else {
          this.mV2Capability.zoomParameter[zoomParamIndex].cameraTypeData.push(zoomModeData);
        }
      });
    });
  }

  // json解析时执行zoomCycleClick的差异配置融合至默认配置
  private execCycleClickZoomData(mV2DiffCapability: V2Capability): void {
    this.mV2Capability.zoomCycleClickData = mV2DiffCapability?.zoomCycleClickData;
  }

  // json解析时执行supportedMode差异配置融合至默认配置
  private execModeListIncrementDataCombine(mV2DiffCapability: V2Capability): void {
    if (mV2DiffCapability?.supportedMode?.modeBarList) {
      this.mV2Capability.supportedMode.modeBarList = mV2DiffCapability?.supportedMode?.modeBarList;
    }
    if (mV2DiffCapability?.supportedMode?.moreModeList) {
      this.mV2Capability.supportedMode.moreModeList = mV2DiffCapability?.supportedMode?.moreModeList;
    }
    if (mV2DiffCapability?.supportedMode?.filteredModeList) {
      this.mV2Capability.supportedMode.filteredModeList = mV2DiffCapability?.supportedMode?.filteredModeList;
    }
  }

  // json解析时执行metadata差异配置融合至默认配置
  private execMetadataIncrementDataCombine(mV2DiffCapability: V2Capability): void {
    for (let key in mV2DiffCapability.metadata) {
      this.mV2Capability.metadata[key] = mV2DiffCapability.metadata[key];
    }
  }

  // json解析时执行startupGuidancePages差异配置融合至默认配置
  private execStartupGuidancePagesIncrementDataCombine(mV2DiffCapability: V2Capability): void {
    if (mV2DiffCapability?.startupGuidancePages?.length > 0) {
      this.mV2Capability.startupGuidancePages = mV2DiffCapability?.startupGuidancePages;
    }
  }

  // json解析时TreasureBoxOrder差异配置融合至默认配置
  private execTreasureBoxOrderIncrementDataCombine(mV2DiffCapability: V2Capability): void {
    if (mV2DiffCapability?.treasureBoxOrder?.length > 0) {
      this.mV2Capability.treasureBoxOrder = mV2DiffCapability?.treasureBoxOrder;
    }
  }

  // json解析时CustomColorStyleSupportedMode差异配置融合至默认配置
  private execCustomColorStyleSupportedModeIncrementDataCombine(mV2DiffCapability: V2Capability): void {
    if (mV2DiffCapability?.customColorStyleSupportedMode?.length > 0) {
      this.mV2Capability.customColorStyleSupportedMode = mV2DiffCapability?.customColorStyleSupportedMode;
    }
    HiLog.i(TAG,
      `execCustomColorStyleSupportedModeIncrementDataCombine ${this.mV2Capability.customColorStyleSupportedMode}`);
  }

  // 通用方法获取TypeDataByCollapsState数据
  private getTypeDataByCollapsState(position: camera.CameraPosition): TypeDataByCollapsState {

    let appCapabilityDataByType = this.mV2Capability?.cameraCapability?.find((value: AppCapabilityDataByType) => {
      return value?.cameraType === position;
    });
    let typeDataByCollapsState = appCapabilityDataByType?.cameraTypeData?.find((value: TypeDataByCollapsState) => {
      const windowStatus = WindowService.getInstance().getWindowStatus();
      return value?.collapsState === 2;
    });
    HiLog.d(TAG, `typeDataByCollapsState = ${JSON.stringify(typeDataByCollapsState?.defaultData)}`);
    return typeDataByCollapsState;
  }

  // 物理镜头场景创建camera.Profile对象
  private createLensModePhotoProfile(typeDataByCollapsState: TypeDataByCollapsState, index: number,
    photoFormat: PhotoFormatMode, lensModeRatio: string): camera.Profile {
    let baseProfileData = typeDataByCollapsState.collapsStateData[index]?.modeData?.photoProfiles
    ?.find((value: BaseProfileData) => { // 找到对应4:3的物理镜头,否则取默认4:3
      return typeDataByCollapsState.collapsStateData[index].modeData.lensMode && value.ratio === lensModeRatio;
    });
    if (!baseProfileData) {
      baseProfileData = typeDataByCollapsState.defaultData.photoProfiles[0];
    }
    return {
      format: getPhotoFormat(baseProfileData.format, photoFormat),
      size: {
        width: baseProfileData.profileWidth, height: baseProfileData.profileHeight
      }
    };
  }

  // public方法,getPhotoProfiles拍照流
  public getPhotoProfiles(position: camera.CameraPosition, mode: ModeType, photoFormat: PhotoFormatMode,
    isPhysicalLens?: boolean): camera.Profile[] {
    let typeDataByCollaps = this.getTypeDataByCollapsState(position);
    mode = getModeNameForProfile(mode);

    let index = typeDataByCollaps?.collapsStateData?.findIndex((value: CollapsStateDataByMode) => {
      return value.modeName === (mode as string);
    });
    let resultProfiles: camera.Profile[] = [];
    if (isPhysicalLens === true) { // 物理镜头全4:3,按MAIN、WIDE、TELEPHOTO
      resultProfiles.push(this.createLensModePhotoProfile(typeDataByCollaps, index, photoFormat, '4:3 MAIN'));
      resultProfiles.push(this.createLensModePhotoProfile(typeDataByCollaps, index, photoFormat, '4:3 WIDE'));
      resultProfiles.push(this.createLensModePhotoProfile(typeDataByCollaps, index, photoFormat, '4:3 TELEPHOTO'));
      resultProfiles.push(this.createLensModePhotoProfile(typeDataByCollaps, index, photoFormat, '1:1'));
      resultProfiles.push(this.createLensModePhotoProfile(typeDataByCollaps, index, photoFormat, 'full'));
      return resultProfiles;
    }
    // 逻辑镜头按4：3、1：1、full
    if (index >= 0 && typeDataByCollaps.collapsStateData[index]?.modeData?.photoProfiles &&
      typeDataByCollaps.collapsStateData[index]?.modeData?.lensMode !== 1) {
      typeDataByCollaps.collapsStateData[index]?.modeData?.photoProfiles?.forEach((value: BaseProfileData) => {
        resultProfiles.push({
          format: getPhotoFormat(value.format, photoFormat),
          size: {
            width: value.profileWidth, height: value.profileHeight
          }
        });
      });
    } else {
      typeDataByCollaps.defaultData.photoProfiles.forEach((value: BaseProfileData) => {
        resultProfiles.push({
          // 填充默认分辨率
          format: getPhotoFormat(value.format, photoFormat),
          size: {
            width: value.profileWidth, height: value.profileHeight
          }
        });
      });
    }
    return resultProfiles;
  }

  // getProfilesIndexByRatio获取profiles下标
  private getProfilesIndexByRatio(ratio: string, photoProfilesLength: number): number {
    return photoProfilesLength === SUBSCRIPT_THREE ? (ratio === '4:3' ? 0 : ratio === '1:1' ? 1 : SUBSCRIPT_TWO) :
      (ratio === '4K' ? 0 : ratio === 'full' ? 1 : ratio === '16:9 1080p' ? SUBSCRIPT_TWO : SUBSCRIPT_THREE);
  }

  // public方法,getPhotoPreviewProfiles泛拍照模式预览流
  public getPhotoPreviewProfiles(position: camera.CameraPosition, mode: ModeType): camera.Profile[] {
    let typeDataByCollapsState = this.getTypeDataByCollapsState(position);
    mode = getModeNameForProfile(mode);
    let index = typeDataByCollapsState?.collapsStateData?.findIndex((value: CollapsStateDataByMode) => {
      return value.modeName === mode;
    });
    let resultProfiles: camera.Profile[] = [];
    if (index >= 0 && typeDataByCollapsState.collapsStateData[index]?.modeData?.photoPreviewProfiles) {
      typeDataByCollapsState.collapsStateData[index]?.modeData?.photoPreviewProfiles?.forEach((value: BaseProfileData) => {
        resultProfiles.push({
          format: getPreviewAndVideoFormat(value.format, false),
          size: {
            width: value.profileWidth, height: value.profileHeight
          }
        });
      });
    } else {
      typeDataByCollapsState?.defaultData.photoPreviewProfiles.forEach((value: BaseProfileData) => {
        resultProfiles.push({
          format: getPreviewAndVideoFormat(value.format, false),
          size: {
            width: value.profileWidth, height: value.profileHeight
          }
        });
      });
    }
    return resultProfiles;
  }

  // public方法,getVideoProfiles录像流
  public getVideoProfiles(position: camera.CameraPosition, mode: ModeType, hdrVivid?: boolean):
    camera.VideoProfile[] {
    let typeDataByCollapsState = this.getTypeDataByCollapsState(position);
    mode = getModeNameForProfile(mode);
    let index = typeDataByCollapsState?.collapsStateData?.findIndex((value: CollapsStateDataByMode) => {
      return value.modeName === mode;
    });
    let resultProfiles: camera.VideoProfile[] = [];
    if (index >= 0 && typeDataByCollapsState.collapsStateData[index]?.modeData?.videoProfiles) {
      typeDataByCollapsState.collapsStateData[index]?.modeData?.videoProfiles?.forEach((value: BaseProfileData) => {
        resultProfiles.push({
          format: getPreviewAndVideoFormat(value.format, hdrVivid),
          size: {
            width: value.profileWidth, height: value.profileHeight
          },
          frameRateRange: {
            min: value.frameRateArray[0], max: value.frameRateArray[value.frameRateArray.length - 1]
          }
        });
      });
    } else {
      typeDataByCollapsState?.defaultData?.videoProfiles?.forEach((value: BaseProfileData) => {
        resultProfiles.push({
          format: getPreviewAndVideoFormat(value.format, hdrVivid),
          size: {
            width: value.profileWidth, height: value.profileHeight
          },
          frameRateRange: {
            min: value.frameRateArray[0], max: value.frameRateArray[value.frameRateArray.length - 1]
          }
        });
      });
    }
    HiLog.i(TAG, `getVideoProfiles length:${resultProfiles?.length}, resultProfiles：${JSON.stringify(resultProfiles)}`);
    return resultProfiles || [];
  }

  // public方法,getVideoPreviewProfiles获取录像预览流
  public getVideoPreviewProfiles(position: camera.CameraPosition, mode: ModeType, hdrVivid?: boolean):
    camera.Profile[] {
    let typeDataByCollapsState = this.getTypeDataByCollapsState(position);
    mode = getModeNameForProfile(mode);
    let index = typeDataByCollapsState?.collapsStateData?.findIndex((value: CollapsStateDataByMode) => {
      return value.modeName === mode;
    });
    let resultProfiles: camera.Profile[] = [];
    if (index >= 0 && typeDataByCollapsState.collapsStateData[index]?.modeData?.videoPreviewProfiles) {
      typeDataByCollapsState.collapsStateData[index]?.modeData?.videoPreviewProfiles?.forEach((value: BaseProfileData) => {
        resultProfiles.push({
          format: getPreviewAndVideoFormat(value.format, hdrVivid),
          size: {
            width: value.profileWidth, height: value.profileHeight
          }
        });
      });
    } else {
      typeDataByCollapsState?.defaultData?.videoPreviewProfiles?.forEach((value: BaseProfileData) => {
        resultProfiles.push({
          format: getPreviewAndVideoFormat(value.format, hdrVivid),
          size: {
            width: value.profileWidth, height: value.profileHeight
          }
        });
      });
    }
    HiLog.i(TAG,
      `getVideoPreviewProfiles length:${resultProfiles?.length}, resultProfiles：${JSON.stringify(resultProfiles)}`);
    return resultProfiles || [];
  }

  public getVideoFrameRateArray(position: camera.CameraPosition, mode: ModeType, ratioIndex: number): number[] {
    try {
      HiLog.i(TAG, `position: ${position}, mode: ${mode}, ratioIndex: ${ratioIndex}`);
      let typeDataByCollapsState = this.getTypeDataByCollapsState(position);
      const outputType: OutputType = OutputSwitcher.getInstance().getOutput();
      let modeName = mode;
      let index = typeDataByCollapsState?.collapsStateData?.findIndex((value: CollapsStateDataByMode) => {
        return value.modeName === modeName;
      });
      let videoProfiles = [];
      if (index >= 0 && (typeDataByCollapsState.collapsStateData[index]?.modeData?.videoProfiles?.length > ratioIndex)) {
        videoProfiles = typeDataByCollapsState.collapsStateData[index].modeData.videoProfiles;
      } else {
        videoProfiles = typeDataByCollapsState.defaultData.videoProfiles;
      }
      HiLog.i(TAG, `videoProfiles length: ${videoProfiles?.length}`);
      return videoProfiles[ratioIndex]?.frameRateArray || [];
    } catch (err) {
      HiLog.e(TAG, `videoProfiles length: ${err?.code}`);
      return [];
    }

  }

  // public方法,getQuickZoomArray获取快捷变焦点
  public getQuickZoomArray(position: camera.CameraPosition, mode: ModeType): number[] {
    let zoomParameterData = this.mV2Capability.zoomParameter.find((value: ZoomParameterData) => {
      return value.cameraType === position;
    });

    let modeName = getModeNameForZoom(mode);
    let zoomTypeDataByMode = zoomParameterData?.cameraTypeData.find((value: ZoomTypeDataByMode) => {
      return value.modeName === modeName;
    });
    try {
      if (zoomTypeDataByMode) {
        return JSON.parse(JSON.stringify(zoomTypeDataByMode.quickZoomArray || []));
      }

      if (OutputOperation.isPanPhotoOutput(mode) && zoomParameterData?.defaultData?.length > 0) {
        return JSON.parse(JSON.stringify(zoomParameterData?.defaultData[0]?.quickZoomArray || []));
      } else if (zoomParameterData?.defaultData?.length > 1) {
        return JSON.parse(JSON.stringify(zoomParameterData?.defaultData[1]?.quickZoomArray || []));
      }
    } catch (e) {
      HiLog.e(TAG, `JSON parse getQuickZoomArray error: ${e?.message}`);
    }
    return [];
  }

  // public方法,getOpticalZoomArray获取变焦环大刻度点
  public getOpticalZoomArray(position: camera.CameraPosition, mode: ModeType, output: OutputType): number[] {
    let zoomParameterData = this.mV2Capability.zoomParameter.find((value: ZoomParameterData) => {
      return value.cameraType === position;
    });

    let modeName = getModeNameForZoom(mode);
    let zoomTypeDataByMode = zoomParameterData?.cameraTypeData.find((value: ZoomTypeDataByMode) => {
      return value.modeName === modeName;
    });
    if (zoomTypeDataByMode) {
      return JSON.parse(JSON.stringify(zoomTypeDataByMode.opticalZoomArray || []));
    }

    if (OutputOperation.isPanPhotoOutput(mode) && zoomParameterData?.defaultData?.length > 0) {
      return JSON.parse(JSON.stringify(zoomParameterData?.defaultData[0].opticalZoomArray || []));
    } else if (zoomParameterData?.defaultData?.length > 1) {
      return JSON.parse(JSON.stringify(zoomParameterData?.defaultData[1].opticalZoomArray || []));
    }
    return [];
  }

  private getZoomCycleListInMode(mode: ModeType, quickZoomVal: number): number[] {
    let zoomCycleList: number[] = [];
    let modeList: string[] = [];
    let zoomCycleClickDataByMode: ZoomCycleClickDataByMode[] = [];
    // 或许需要特殊处理的模式和对应的循环点切数组，其他都按照默认处理
    this.mV2Capability.zoomCycleClickData?.forEach((zoomCycleClickData: ZoomCycleClickData) => {
      if (zoomCycleClickData.modeName !== 'DEFAULT') {
        modeList.push(zoomCycleClickData.modeName);
      } else {
        zoomCycleClickDataByMode = zoomCycleClickData.ZoomCycleClickData;
      }
    })
    if (modeList.indexOf(mode) !== -1) {
      this.mV2Capability.zoomCycleClickData?.forEach((zoomCycleClickData: ZoomCycleClickData) => {
        if (zoomCycleClickData.modeName === mode) {
          zoomCycleClickDataByMode = zoomCycleClickData.ZoomCycleClickData;
        }
      })
    }
    zoomCycleClickDataByMode.forEach((zoomList: ZoomCycleClickDataByMode) => {
      if (zoomList.clickQuickZoom === quickZoomVal) {
        zoomCycleList = zoomList.cycleZoomArray;
      }
    })
    HiLog.i(TAG, `get cycleZoomData: ${zoomCycleList}`);
    return zoomCycleList;
  }

  public getZoomCycleList(mode: ModeType, quickZoomVal: number): number[] {
    if (this.mV2Capability.zoomCycleClickData === undefined) {
      return [];
    }
    try {
      return this.getZoomCycleListInMode(mode, quickZoomVal);
    } catch (e) {
      HiLog.e(TAG, `get cycleZoomData error: ${e?.message}`);
      return [];
    }
  }

  // public方法,getModeBarList获取首页默认模式栏
  public getModeBarList(): ModeType[] {
    return JSON.parse(JSON.stringify(this.mV2Capability.supportedMode.modeBarList)) as ModeType[];
  }

  // public方法,getMoreModeList获取更多页装载模式栏
  public getMoreModeList(): ModeType[] {
    return JSON.parse(JSON.stringify(this.mV2Capability.supportedMode.moreModeList)) as ModeType[];
  }

  // public方法,getFilteredModeList获取后当前时需要过滤掉的模式
  public getFilteredModeList(): ModeType[] {
    return JSON.parse(JSON.stringify(this.mV2Capability.supportedMode.filteredModeList)) as ModeType[];
  }

  public getPhotoBrowserDisabled(): boolean {
    return this.mV2Capability.metadata.photoBrowserDisabled;
  }


  public getIsSupportedFrontZoomSlide(): boolean {
    return this.mV2Capability.metadata.isSupportedFrontZoomSlide;
  }

  public getNotSupportedVideo60fpsWide(): boolean {
    return this.mV2Capability.metadata?.notSupportedVideo60fpsWide;
  }

  public getIsSupportedHighQualityPhotoFunction(): boolean {
    return this.mV2Capability.metadata.isSupportedHighQualityPhotoFunction;
  }

  public getHighQualityPhotoFuncDefaultValue(): boolean {
    return this.mV2Capability.metadata.highQualityPhotoFuncDefaultValue;
  }


  public getIsSupportedFestivalWatermark(): boolean {
    return this.mV2Capability.metadata?.isSupportedFestivalWatermark;
  }

  public getLimitTimeWatermarkDuration(): string {
    return this.mV2Capability.metadata?.limitTimeWatermarkDuration;
  }

  public getIsNeedRemoveFlashFunc(): boolean {
    return this.mV2Capability.metadata?.isNeedRemoveFlashFunc;
  }


  public getIsSupportedOverHotHidePip(): boolean {
    return this.mV2Capability.metadata?.isSupportedOverHotHidePip;
  }


  public getIsSupportedEnhancedBackSelfie(): boolean {
    return this.mV2Capability.metadata?.isSupportedEnhancedBackSelfie;
  }

  public getIsSupportedLowAngleShot(): boolean {
    return this.mV2Capability.metadata?.isSupportedLowAngleShot;
  }

  public getIsSupportedSmartBackSelfieFunction(): boolean {
    return this.mV2Capability.metadata?.isSupportedSmartBackSelfieFunction;
  }

  public getIsDeviceLowConfig(): boolean {
    return this.mV2Capability.metadata?.isDeviceLowConfig;
  }


  public getFrontSwingZoomRatio(): number {
    return this.mV2Capability.metadata?.frontSwingZoomRatio;
  }

  public getBackSwingZoomRatio(): number {
    return this.mV2Capability.metadata?.backSwingZoomRatio;
  }

  public getIsSupportedFrontHighPixelFunction(): boolean {
    return this.mV2Capability.metadata?.isSupportedFrontHighPixelFunction;
  }

  public needHidePreviewWhenBackground(): boolean {
    return this.mV2Capability.metadata?.needHidePreviewWhenBackground;
  }

  public getIsNotSupportedEfficientVideoFunction(): boolean {
    return this.mV2Capability.metadata?.isNotSupportedEfficientVideoFunction;
  }

  public getIs60fpsDefaultCloseEfficientVideo(): boolean {
    return this.mV2Capability.metadata?.is60fpsDefaultCloseEfficientVideo;
  }

  public getIs60fpsSupportHdrVivid(): boolean {
    return this.mV2Capability.metadata?.is60fpsSupportHdrVivid;
  }

  public getIsNotSupportedWideZoom60fpsVideoBack(): boolean {
    return this.mV2Capability.metadata?.isNotSupportedWideZoom60fpsVideoBack;
  }

  public getIsSupportGlobalExposure(): boolean {
    return this.mV2Capability.metadata?.isSupportGlobalExposure;
  }

  public getIsSupportRecordingFlowing(): boolean {
    return this.mV2Capability.metadata?.isSupportRecordingFlowing;
  }

  public getIsNovaProduct(): boolean {
    return this.mV2Capability.metadata?.isNovaProduct;
  }

  public getIsSupportedFrontSnapShotFunction(): boolean {
    return this.mV2Capability.metadata?.isSupportedFrontSnapShotFunction;
  }

  public getIsSupportedEquivalentFocalBigText(): boolean {
    return this.mV2Capability.metadata?.isSupportedEquivalentFocalBigText;
  }

  public getIsShowBeautySkinMode(): boolean {
    return this.mV2Capability.metadata?.isShowBeautySkinMode;
  }

  public getVideoBitrateH264(): number {
    if (this.mV2Capability.metadata?.videoBitrateH264) {
      return this.mV2Capability.metadata?.videoBitrateH264;
    }
    return 30000000;
  }

  public getVideoBitrateH265(): number {
    if (this.mV2Capability.metadata?.videoBitrateH265) {
      return this.mV2Capability.metadata?.videoBitrateH265;
    }
    return 30000000;
  }

  public getIsSupportedEffectWhenNotEnableCapture(): boolean {
    return this.mV2Capability.metadata?.isSupportedEffectWhenNotEnableCapture;
  }

  public getIsOnlySupportAccelerometer(): boolean {
    return this.mV2Capability.metadata?.isOnlySupportAccelerometer;
  }

  public getIsSupportOnlyShowEye(): boolean {
    return this.mV2Capability.metadata?.isSupportOnlyShowEye;
  }

  // 获取是否是否支持近物对焦选项
  public getIsNotSupportNearFocus(): boolean {
    return this.mV2Capability.metadata?.notSupportNearFocus;
  }

  // 获取是否退后台时立马stopPreviewOutput
  public getIsSupportImmediatelyStopPreview(): boolean {
    return this.mV2Capability.metadata?.isSupportImmediatelyStopPreview;
  }

  // 获取是否需要固定模糊半径
  public getIsNeedFixedBlurRadius(): boolean {
    return this.mV2Capability.metadata?.isNeedFixedBlurRadius;
  }

  // 是否支持质量优先配置
  public getIsSupportEnableStableQuality(): boolean {
    return this.mV2Capability.metadata?.isSupportEnableStableQuality;
  }

  // 百宝箱图标排序
  public getTreasureBoxOrder(): number[] {
    return this.mV2Capability?.treasureBoxOrder;
  }

  // 是否支持声控拍照
  public getIsNotSupportAudioControl(): boolean {
    return this.mV2Capability.metadata?.isNotSupportAudioControl;
  }

  // 开屏页排序
  public getStartupGuidancePages(): string[] {
    return this.mV2Capability?.startupGuidancePages;
  }

  // 滑动变焦响应速率调节
  public getPanGestureZoomVelocity(): number {
    return this.mV2Capability.metadata?.panGestureZoomVelocity;
  }

  // 获取是否支持录像默认为1080P 60fps
  public getIsSupportDefault1080PAnd60Fps(): boolean {
    return this.mV2Capability.metadata?.isSupportDefault1080PAnd60Fps;
  }

  // 是否支持相机退至多任务之后停流
  public getIsSupportStopStreamToMultiTask(): boolean {
    return this.mV2Capability.metadata?.isSupportStopStreamFormMultiTask;
  }

  //获取是否支持前置闪拍美肤
  public getIsSupportedFrontSnapShotSkinBeauty(): boolean {
    return this.mV2Capability.metadata?.isSupportedFrontSnapShotSkinBeauty;
  }

  // 是否支持MovieFileOutput
  public getIsSupportMovieFile(): boolean {
    return this.mV2Capability.metadata?.isSupportMovieFile;
  }

  // 是否隔离大图组件
  public getIsSuspendPhotoBrowser(): boolean {
    return this.mV2Capability.metadata?.isSuspendPhotoBrowser;
  }

  //延时摄影是否支持自动和曝光功能
  public getIsDisAbleRealTimeLapsePro(): boolean {
    return this.mV2Capability.metadata?.isDisAbleRealTimeLapsePro;
  }

  // 获取Picker是否支持人像
  public getIsPickerSupportedPortrait(): boolean {
    return this.mV2Capability.metadata?.isPickerSupportedPortrait;
  }

  // 是否支持间隔拍照功能
  public getIsSupportedIntervalPhotoCapture(): boolean {
    return this.mV2Capability.metadata?.isSupportedIntervalPhotoCapture ?? false;
  }

  // 获取是否支持快捷变焦点优化
  public getIsSupportedCycleClickZoom(): boolean {
    return this.mV2Capability.metadata?.isSupportedCycleClickZoom ?? false;
  }

  // 获取设备是否禁用前置录像镜像
  public getIsDisableFrontVideoMirror(): boolean {
    return this.mV2Capability.metadata?.isDisableFrontVideoMirror;
  }

  public getIsChange3To4Zoom60fpsVideoBack(): boolean {
    return this.mV2Capability.metadata?.isChange3To4Zoom60fpsVideoBack;
  }

  public getIsSupportedHighColorSpace(): boolean {
    return this.mV2Capability.metadata?.isSupportedHighColorSpace;
  }
}