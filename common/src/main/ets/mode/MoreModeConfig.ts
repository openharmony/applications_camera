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
import lazy { CameraAppCapability } from '../camera/CameraAppCapability';
import lazy { CameraAction } from "../camera/uithread/CameraAction";
import lazy { Action } from "../redux/actions/Action";
import lazy { DeviceInfo } from "../component/deviceinfo/DeviceInfo";
import lazy {
  EXPIRE_MINUTE_TIME_15,
  FLUSH_TIMESTAMP,
  PersistType,
  PreferencesService
} from "../service/preferences/PreferencesService";
import lazy { PropTag } from "../service/preferences/PropTag";
import lazy { AccessibilityUtils } from "../utils/AccessibilityUtils";
import lazy { GlobalContext } from "../utils/GlobalContext";
import lazy { HiLog } from "../utils/HiLog";
import lazy { StoreManager } from "../worker/StoreManager";
import lazy { ModeListManager } from "./ModeListManager";
import lazy { ModeType, VdeCollapsedFilterModeType } from "./ModeType";
import lazy {
  BackAsFrontFilterModeData,
  MoreModeType,
  MorePageData,
  MorePageDefaultData,
  MorePageType,
  NewAddMode,
  EditedMoreModeData,
  isDisDragEditedMode
} from './MoreModeConfigData';
import lazy { camera } from '@kit.CameraKit';
import lazy { FeatureManager } from "../function/core/FeatureManager";
import lazy { FunctionId } from "../function/core/functionproperty/FunctionId";
import lazy { MULTIPLE_OUTPUTS_MODES } from "../function/outputswitcher/OutputSwitcher";
import lazy { getStates } from "../redux";
import lazy { ModeControl } from "./ModeControl";
import ResGetter from '../utils/ResGetter';

const TAG: string = 'MoreModeConfig';

export class MoreModeConfig {
  private static instance: MoreModeConfig;
  public mDefaultModeList: ModeType[] = this.isSupportMorePage() ?
  this.initDefaultGlobalModeList() : [ModeType.PHOTO, ModeType.VIDEO];

  private morePageGridMode: ModeType[] = [];
  private morePageBarMode: ModeType[] = [];
  private bAsFModeList: ModeType[] = [];
  private bAsFGridMode: ModeType[] = [];
  private bAsFBarMode: ModeType[] = [];

  private constructor() {
  }

  public getMoreModeIcon(): Resource {
    return $r('app.media.ic_system_collapse_up');
  }


  private initDefaultGlobalModeList(): ModeType[] {
    return MorePageDefaultData.barModeType.concat(ModeType.MORE);
  }

  public static getInstance(): MoreModeConfig {
    if (!MoreModeConfig.instance) {
      MoreModeConfig.instance = new MoreModeConfig();
    }
    return MoreModeConfig.instance;
  }

  public isSupportMorePage(): boolean {
    return !GlobalContext.get().getIsPicker() && !DeviceInfo.isPc();
  }

  public getGridMode(): ModeType[] {
    return this.morePageGridMode;
  }

  public getBarMode(): ModeType[] {
    return this.morePageBarMode;
  }

  public isShowMorePageContent(): boolean {
    return CameraAppCapability.getInstance().getMoreModeList()?.length > 0;
  }

  public getAllRealEditedMode(): ModeType[] {
    return MorePageDefaultData.barModeType.concat(MorePageDefaultData.gridModeType);
  }

  public getGlobalModeList(): ModeType[] {
    try {
      const catchModeList: string = PreferencesService.getInstance().getPropValue(PersistType.FOREVER,
        PropTag.CAMERA_MODE_LIST_DATA, JSON.stringify([...this.mDefaultModeList])) as string;
      const catchModeListArr: ModeType[] = (JSON.parse(catchModeList) as ModeType[]);
      return catchModeListArr;
    } catch (err) {
      HiLog.e(TAG, `getGlobalModeList fail, errCode: ${err?.code}`);
      return [];
    }
  }

  /* instrument ignore next */
  public mixPersistAndDefaultModeList(): void {
    const preferData: string = PreferencesService.getInstance().getPropValue(PersistType.FOREVER,
      PropTag.MORE_PAGE_MODE, JSON.stringify({ gridModeType: [], barModeType: [] })) as string;
    const parsePreferData: MorePageType = JSON.parse(preferData) as MorePageType;
    const preferModeLength: number = parsePreferData.gridModeType.length + parsePreferData.barModeType.length;
    const isEditMorePage: boolean = preferModeLength !== 0; // 只有更多页：编辑或恢复默认值，模式数据才会缓存进本地，否则缓存为空
    const defaultModeLength: number = MorePageDefaultData.gridModeType.length + MorePageDefaultData.barModeType.length;
    HiLog.i(TAG, `mixPersistAndDefaultModeList, ${preferModeLength}, ${defaultModeLength},${isEditMorePage},
      ${JSON.stringify(MorePageDefaultData)}`);
    if ((preferModeLength <= defaultModeLength) && isEditMorePage) {
      this.handleEditedCcmAndHotData();
    } else {
      PreferencesService.getInstance().putPropValue(PersistType.FOREVER, PropTag.CAMERA_MODE_LIST_DATA,
        JSON.stringify([...MorePageDefaultData.barModeType].concat([ModeType.MORE])));
      PreferencesService.getInstance().putPropValue(PersistType.FOREVER, PropTag.MORE_PAGE_MODE,
        JSON.stringify(MorePageDefaultData));
    }
  }

  /* instrument ignore next */
  private replacePreferenceData(newCcmModeData: ModeType[], preferBarMode: ModeType[], preferGridMode: ModeType[]) {
    let deletedBarModeData: ModeType[] = [];
    preferBarMode.forEach(item => {
      if (newCcmModeData.indexOf(item) === -1) {
        deletedBarModeData.push(item);
      }
    });
    if (deletedBarModeData.length) {
      deletedBarModeData.forEach(item => {
        let index = preferBarMode.indexOf(item);
        preferBarMode.splice(index, 1);
      });
    }
    let deletedGridModeData: ModeType[] = [];
    preferGridMode.forEach(item => {
      if (newCcmModeData.indexOf(item) === -1) {
        deletedGridModeData.push(item);
      }
    });
    if (deletedGridModeData.length) {
      deletedGridModeData.forEach(item => {
        let index = preferGridMode.indexOf(item);
        preferGridMode.splice(index, 1);
      });
    }
  }

  /* instrument ignore next */
  private handleNewAddCCMData(newCcmModeData: ModeType[], preferBarMode: ModeType[], preferGridMode: ModeType[],
    newAddModeData: NewAddMode[]) {
    newCcmModeData.forEach((item, index) => {
      if (preferGridMode.indexOf(item) === -1 && preferBarMode.indexOf(item) === -1) {
        let newModeType: ModeType = item;
        let isNewBarMode: boolean = MorePageDefaultData.barModeType.includes(item);
        let prevMode: ModeType | undefined = undefined;
        if (isNewBarMode) {
          let prevIndex: number = index >= 1 ? index - 1 : 0;
          prevMode = newCcmModeData[prevIndex];
        }
        newAddModeData.push({ mode: newModeType, prevMode: prevMode, isBarMode: isNewBarMode });
      }
    });
    HiLog.i(TAG, `ccmAndHot Added, newAddMode:${JSON.stringify(newAddModeData)},existAdd${!!newAddModeData.length}`);
    if (!newAddModeData.length) {
      return;
    }
    newAddModeData.forEach(item => {
      if (item.isBarMode) {
        let isAddDisDragMode: boolean = isDisDragEditedMode(item.mode);
        if (isAddDisDragMode && !!item.prevMode) {
          let prevModeIndexInPrefer: number = preferBarMode.indexOf(item.prevMode);
          preferBarMode.splice(prevModeIndexInPrefer + 1, 0, item.mode); // 将增量不可拖动模式按照CCM顺序对比插入缓存相应模式位置
        } else {
          preferBarMode.push(item.mode); // 将增量可拖动模式添加到对应模式区域的末尾
        }
      } else {
        preferGridMode.push(item.mode);
      }
    });
  }

  /* instrument ignore next */
  public handleEditedCcmAndHotData(): void {
    const preferData: string = PreferencesService.getInstance().getPropValue(PersistType.FOREVER,
      PropTag.MORE_PAGE_MODE, JSON.stringify({ gridModeType: [], barModeType: [] })) as string;
    const parsePreferData: MorePageType = JSON.parse(preferData) as MorePageType;
    const preferBarMode: ModeType[] = parsePreferData.barModeType;
    const preferGridMode: ModeType[] = parsePreferData.gridModeType;
    HiLog.i(TAG,
      `ccmAndHot Preference,bar:${JSON.stringify(preferBarMode)},grid:${JSON.stringify(preferGridMode)}`);
    let newAddModeData: NewAddMode[] = [];
    // CCM上全量的模式数据，要和本地缓存的进行比对，找到新增的模式以及所要添加模式的位置
    const newCcmModeData: ModeType[] = [...MorePageDefaultData.gridModeType, ...MorePageDefaultData.barModeType];
    this.replacePreferenceData(newCcmModeData, preferBarMode, preferGridMode);
    this.handleNewAddCCMData(newCcmModeData, preferBarMode, preferGridMode, newAddModeData);
    HiLog.i(TAG, `ccmAndHot final,bar:${JSON.stringify(preferBarMode)},grid:${JSON.stringify(preferGridMode)}}`);
    const addedMorePageData: MorePageType = { gridModeType: preferGridMode, barModeType: preferBarMode };
    PreferencesService.getInstance().putPropValue(PersistType.FOREVER, PropTag.CAMERA_MODE_LIST_DATA,
      JSON.stringify([...preferBarMode].concat([ModeType.MORE])));
    PreferencesService.getInstance().putPropValue(PersistType.FOREVER, PropTag.MORE_PAGE_MODE,
      JSON.stringify(addedMorePageData));
  }

  public modifyMoreModeListAndName(mode: ModeType): void {
    const curModeList: ModeType[] = ModeListManager.getInstance().getModeList();
    HiLog.i(TAG, 'modifyMoreModeListAndName ' + curModeList?.toString());
    const curModeListLen: number = curModeList.length - 1;
    if (curModeList[curModeListLen] !== mode) {
      ModeListManager.getInstance().modifyModeList(mode); // 变更最后一项
      StoreManager.getInstance().postMessage(Action.updateModeBar()); // 通知ModeBar拿最新的数据
      const modeListPreferenceStr: string = PreferencesService.getInstance().getPropValue(PersistType.FOREVER,
        PropTag.CAMERA_MODE_LIST_DATA, JSON.stringify([...this.mDefaultModeList])) as string;
      HiLog.i(TAG, `modifyMoreModeListAndName:${mode}`);
      const modeListArr: ModeType[] = JSON.parse(modeListPreferenceStr) as ModeType[];
      modeListArr[modeListArr.length - 1] = mode; // 基于缓存模式变更，保证缓存模式正确
      PreferencesService.getInstance().putPropValue(PersistType.FOREVER,
        PropTag.CAMERA_MODE_LIST_DATA, JSON.stringify([...modeListArr]));
      HiLog.i(TAG, 'modifyMoreModeListAndName putPropValue ' + modeListArr?.toString());
    }
  }

  public processGlobalModeListAndName(mode: ModeType): ModeType[] {
    let initModeListData: ModeType[] = this.getGlobalModeList();
    if (this.isSupportMorePage()) {
      const initModeListLen: number = initModeListData.length;
      const modeIndex: number = initModeListData.indexOf(mode);
      if (PreferencesService.getInstance().isExpire(EXPIRE_MINUTE_TIME_15, FLUSH_TIMESTAMP) ||
        (modeIndex !== initModeListLen - 1 && modeIndex !== -1)) {
        // mode配置15min不恢复默认，但是最后一项要变为more或者闪退重启相机场景
        initModeListData.splice(initModeListLen - 1, 1, ModeType.MORE);
      } else {
        if (modeIndex === -1) {
          initModeListData.splice(initModeListLen - 1, 1, mode);
        }
      }
    }
    HiLog.i(TAG, `processGlobalModeListAndName initModeListData:${JSON.stringify(initModeListData)}, mode:${mode}`);
    return initModeListData;
  }

  public processBackAsFrontModeData(isNeedFilterGlobalMode: boolean = false,
    isNeedFilterMorePageData: boolean = true): void {
    /* instrument ignore  if*/
    if (isNeedFilterGlobalMode) {
      this.modifyMoreModeListAndName(ModeType.MORE); // 先变更模式ModeListManger
      let initModeListData: ModeType[] = this.getGlobalModeList();
      if (isNeedFilterMorePageData) {
        this.bAsFModeList = initModeListData.filter(item => (BackAsFrontFilterModeData.includes(item)));
        initModeListData = initModeListData.filter(item => (!BackAsFrontFilterModeData.includes(item)));
      }
      HiLog.i(TAG, `processBackAsFrontModeData initModeNameData：${initModeListData.toString()}`);
      ModeListManager.getInstance().init(initModeListData);
      StoreManager.getInstance().postMessage(Action.updateModeBar());
    }

    let preferData: string = PreferencesService.getInstance().getPropValue(PersistType.FOREVER,
      PropTag.MORE_PAGE_MODE, JSON.stringify(MorePageDefaultData)) as string;
    const parseData: MorePageType = JSON.parse(preferData) as MorePageType; // 非后当前全量数据
    let gridModeType: ModeType[] = parseData.gridModeType;
    let barModeType: ModeType[] = parseData.barModeType;
    /* instrument ignore  if*/
    if (isNeedFilterMorePageData) {
      this.bAsFGridMode = gridModeType.filter(item => (BackAsFrontFilterModeData.includes(item)));
      this.bAsFBarMode = barModeType.filter(item => (BackAsFrontFilterModeData.includes(item)));
      gridModeType = gridModeType.filter(item => (!BackAsFrontFilterModeData.includes(item)));
      barModeType = barModeType.filter(item => (!BackAsFrontFilterModeData.includes(item)));
    }
    HiLog.i(TAG, `processBackAsFront gridModeType:${gridModeType.toString()},barModeType:${barModeType.toString()}`);
    this.morePageGridMode = gridModeType;
    this.morePageBarMode = barModeType;
  }

  /* instrument ignore next */
  public processVdeCollapsedModeData(isVdeCollapsed: boolean): void {
    HiLog.i(TAG, 'processVdeCollapsedModeData isVdeCollapsed = ' + isVdeCollapsed);
    const initModeListData: ModeType[] = this.getGlobalModeList();
    const currentModeList: ModeType[] = isVdeCollapsed ?
    initModeListData.filter(item => (VdeCollapsedFilterModeType.includes(item))) : initModeListData;
    HiLog.i(TAG, `processVdeCollapsedModeData initModeNameData：${currentModeList.toString()}`);
    ModeListManager.getInstance().init(currentModeList);
    StoreManager.getInstance().postMessage(Action.updateModeBar());
    if (!isVdeCollapsed) {
      let preferData: string = PreferencesService.getInstance().getPropValue(PersistType.FOREVER,
        PropTag.MORE_PAGE_MODE, JSON.stringify(MorePageDefaultData)) as string;
      const parseData: MorePageType = JSON.parse(preferData) as MorePageType; // 非后当前全量数据
      let gridModeType: ModeType[] = parseData.gridModeType;
      let barModeType: ModeType[] = parseData.barModeType;
      this.morePageGridMode = gridModeType;
      this.morePageBarMode = barModeType;
    }
  }

  public filterDataByModeConfig(data: ModeType[]): MoreModeType[] {
    let tempData: MoreModeType[] = [];
    if (!data.length) {
      return [];
    }
    data.forEach(item => {
      if (EditedMoreModeData.has(item) && !!EditedMoreModeData.get(item)?.modeType) {
        tempData.push(EditedMoreModeData.get(item));
      } else {
        HiLog.e(TAG, `item mode:${item} can not find.`);
      }
    });
    return tempData;
  };

  public getMorePageData(): MorePageData {
    const gridModeArr: ModeType[] = this.morePageGridMode;
    const barModeArr: ModeType[] = this.morePageBarMode;
    HiLog.i(TAG, `getMorePageData: [${gridModeArr.toString()}], [${barModeArr.toString()}]`);
    const gridModeData: MoreModeType[] = this.filterDataByModeConfig(gridModeArr);
    const barModeData: MoreModeType[] = this.filterDataByModeConfig(barModeArr);
    if (AppStorage.get('isRunningDT')) {
      AppStorage.setOrCreate('gridModeArr', gridModeData);
    }
    return {
      gridModeData: gridModeData,
      barModeData: barModeData
    };
  }

  public saveMorePageData({ gridModeData, barModeData }): void {
    HiLog.i(TAG, 'saveMorePageData X.');
    const gridModeTemp: ModeType[] = gridModeData.map(item => item.modeType);
    const barModeTemp: ModeType[] = barModeData.map(item => item.modeType);
    const morePageData: MorePageType = {
      gridModeType: gridModeTemp,
      barModeType: barModeTemp
    };
    this.preferenceMorePage(morePageData);
    this.updateGlobalModeConfig(barModeTemp);
    HiLog.i(TAG, 'saveMorePageData E.');
  };

  public restoreDefaultMorePage(): void {
    let finalDefaultMorePageData: MorePageType = MorePageDefaultData;
    let finalDefaultGlobalModeData: ModeType[] = MorePageDefaultData.barModeType;
    this.preferenceMorePage(finalDefaultMorePageData, true);
    this.updateGlobalModeConfig(finalDefaultGlobalModeData);
  }

  public preferenceMorePage(data: MorePageType, isRestoreDefaultMore: boolean = false): void {
    let reArrange: boolean = this.arraysEqual(this.morePageGridMode, data.gridModeType) ||
    this.arraysEqual(this.morePageBarMode, data.barModeType)
    this.morePageGridMode = data.gridModeType;
    this.morePageBarMode = data.barModeType;
    let morePagePrefData: MorePageType = data;
    PreferencesService.getInstance().putPropValue(PersistType.FOREVER,
      PropTag.MORE_PAGE_MODE, JSON.stringify(morePagePrefData));
  }

  private updateGlobalModeConfig(needUpdateModeConfig: ModeType[]): void {
    HiLog.i(TAG, 'updateGlobalModeConfig X.');
    const reduxModeList: ModeType[] = [...needUpdateModeConfig].concat(ModeType.MORE);
    ModeListManager.getInstance().init(reduxModeList);
    StoreManager.getInstance().postMessage(Action.updateModeBar());
    StoreManager.getInstance().postMessage(Action.updateModePosition(true));
    let globalModeListPrefData: ModeType[] = [...needUpdateModeConfig];
    globalModeListPrefData = globalModeListPrefData.concat(ModeType.MORE);
    PreferencesService.getInstance().putPropValue(PersistType.FOREVER, PropTag.CAMERA_MODE_LIST_DATA,
      JSON.stringify([...globalModeListPrefData]));
    HiLog.i(TAG, 'updateGlobalModeConfig E.');
  }

  private arraysEqual(arrOne: ModeType[], arrTwo: ModeType[]): boolean {
    if (arrOne.length !== arrTwo.length) { //检测长度是否相等
      return true
    }
    for (let i = 0; i < arrOne.length; i++) {
      if (arrOne[i] !== arrTwo[i]) {
        return true
      }
    }
    return false
  }

  /* instrument ignore next */
  public dragBarItemAccessibility(modeList: MoreModeType[], index: number, isEnd: boolean): void {
    let modeTypeName: Resource | string;
    if (index === 0) {
      modeTypeName = ResGetter.getStringSafe(modeList[index + 1]?.name);
      AccessibilityUtils.sendAnnounceAccessibilityEvent(isEnd ?
      ResGetter.getStringSafe($r('app.string.accessibility_placed_front_bar', modeTypeName)) :
      ResGetter.getStringSafe($r('app.string.accessibility_move_to_front_bar', modeTypeName)));
    } else {
      modeTypeName = ResGetter.getStringSafe(modeList[index - 1]?.name);
      AccessibilityUtils.sendAnnounceAccessibilityEvent(isEnd ?
      ResGetter.getStringSafe($r('app.string.accessibility_placed_back_bar', modeTypeName)) :
      ResGetter.getStringSafe($r('app.string.accessibility_move_to_back_bar', modeTypeName)));
    }
  }

  /* instrument ignore next */
  public dragGridItemAccessibility(modeList: MoreModeType[], index: number, isEnd: boolean,
    isSemiCollaps?: boolean): void {
    const count: number = (index + 1) % (isSemiCollaps ? 5 : 3);
    const row: number = Math.ceil((index + 1) / (isSemiCollaps ? 5 : 3)); // 所在行
    const columnArray: number[] = isSemiCollaps ? [5, 1, 2, 3, 4] : [3, 1, 2];
    const column: number = columnArray[count];
    // 根据 count 的值，从数组 columnArray 中获取对应的元素，并将其赋值给 column  写成一个数组
    let modeTypeName: Resource | string;
    if (count === 1) {
      modeTypeName = ResGetter.getStringSafe(modeList[index + 1]?.name);
      AccessibilityUtils.sendAnnounceAccessibilityEvent(isEnd ?
      ResGetter.getStringSafe($r('app.string.accessibility_placed_front_grid', modeTypeName, row, column)) :
      ResGetter.getStringSafe($r('app.string.accessibility_move_to_front', modeTypeName, row, column)));
    } else {
      modeTypeName = ResGetter.getStringSafe(modeList[index - 1]?.name);
      AccessibilityUtils.sendAnnounceAccessibilityEvent(isEnd ?
      ResGetter.getStringSafe($r('app.string.accessibility_placed_back_grid', modeTypeName, row, column)) :
      ResGetter.getStringSafe($r('app.string.accessibility_move_to_back', modeTypeName, row, column)));
    }
  }

  // TODO：所有界面可点击切换模式入口：只有changeMode和switchCameraChangeMode 不要在加if了，能合并就合并！
  public doConfigModeChange(oldMode: ModeType, newMode: ModeType): void {
    ModeControl.getInstance().setRemainZoomRatio(newMode, oldMode);
    const isFrontCameraPos: boolean = getStates()
      .get<camera.CameraPosition>('cameraReducer', 'cameraPosition') !== camera.CameraPosition.CAMERA_POSITION_BACK;
    HiLog.i(TAG, `change back camera, isFrontCamera: ${isFrontCameraPos}, newMode: ${newMode}, oldMode: ${oldMode}`);
    StoreManager.getInstance().postMessage(CameraAction.changeMode(newMode));
    AppStorage.setOrCreate('startOrUserChangeToModeLast', newMode);
    StoreManager.getInstance().postMessage(Action.updateXComponentShot(oldMode, newMode, oldMode === newMode ? false : true));
  }

  public handleWindowResumedModeChoose(): void {
    const isShowMorePage: boolean = getStates().get<boolean>('modeReducer', 'isShowMorePage');
    const isEditMorePage: boolean = getStates().get<boolean>('modeReducer', 'isEditMorePage');
    let isModeDetailShow = AppStorage.get<boolean>('isShowModeDetailPage');
    if (isShowMorePage && !isEditMorePage && !isModeDetailShow) {
      const curMode: ModeType = getStates().get<ModeType>('modeReducer', 'mode');
      const curModeList: ModeType[] = ModeListManager.getInstance().getModeList();
      const isLastMode: boolean = !curModeList.includes(curMode); // 模式列表找不到模式，选择了更多页内部的模式
      this.entryAOutMorePage(false);
      this.modifyMoreModeListAndName(isLastMode ? curMode : ModeType.MORE); // 先变更模式ModeListManger
      StoreManager.getInstance().postMessage(Action.updateModePosition(false)); // ModeBar根据新数据切换到对应模式
    }
  }

  public handleSlideDoubleStreamFromMore(nextMode: ModeType): void {
    if (MULTIPLE_OUTPUTS_MODES.includes(nextMode)) {
      StoreManager.getInstance().postMessage(Action.slideDoubleStreamFromMore());
    }
  }

  /* instrument ignore next */
  public entryAOutMorePage(isEntry: boolean): void {
    if (isEntry === getStates().get<boolean>('modeReducer', 'isShowMorePage')) {
      HiLog.i(TAG, 'MorePage status not changed.');
      return;
    }
    StoreManager.getInstance().postMessage(Action.showMoreModePage(isEntry));
  }

  public editMorePage(isEdit: boolean): void {
    if (isEdit === getStates().get<boolean>('modeReducer', 'isEditMorePage')) {
      HiLog.i(TAG, 'MorePage edited status not changed.');
      return;
    }
    StoreManager.getInstance().postMessage(Action.editMoreModePage(isEdit));
  }
}