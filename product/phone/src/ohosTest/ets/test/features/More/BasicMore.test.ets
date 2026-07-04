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

import { afterAll, beforeAll, describe, it, Level } from '@ohos/hypium';
import { Driver, ON } from '@ohos.UiTest';
import { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import { TestConstants } from '../../../TestConstants';
import { CommonHandler } from '../../../aw/CommonHandler';
import { HideBugUtil } from '@ohos/common/src/main/ets/utils/HideBugUtil';

const TAG: string = TestConstants.TAG + '_' + 'BasicMoreTest';

class MoreModeType {
  public name?: Resource | string;
  public img?: Resource;
  public isDelete?: boolean;
  public isDrag?: boolean;
  public modeType?: ModeType;
}

export default function basicMoreTest() {
  describe('BasicMoreTest', () => {
    const driver = Driver.create();
    let projectModeData: Map<ModeType, MoreModeType>;

    beforeAll(async () => {
      await CommonHandler.abilityStart(driver).then(async () => {
        HiLog.i(TAG, 'MoreModeIndex test is start.');
        // projectModeData = (await import('../../../../../main/ets/common/MoreModeConfigData')).EditedMoreModeData;
      })
    });

    afterAll(async () => {
      HideBugUtil.checkDtPss(36);
      await CommonHandler.abilityEnd(driver).then(() => {
        HiLog.i(TAG, 'MoreModeIndex test is finished.');
      });
    });

    /**
     * 1.点击更多按钮
     * 2.进入更多页面
     * 3.点击编辑按钮
     * 4.进入更多编辑页面
     * 5.点击取消
     * 6.点击保存
     * 7.点击恢复默认布局
     */
    it('MoreModeIndex', Level.LEVEL2, async () => {
      HiLog.i(TAG, 'MoreModeIndex begin.');
      try {
        await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
        HiLog.i(TAG, 'photoMode.');
        await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance()
          .getKey('ControlModeText', ModeType.PHOTO)));
        let photoMode = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
          .getKey('ControlModeText', ModeType.PHOTO)));
        await photoMode.click();
        await driver.delayMs(TestConstants.DELAY_ONE_SECOND);

        HiLog.i(TAG, 'MORE mode.');
        await driver.assertComponentExist(ON.id(ComponentIdKeys.getInstance()
          .getKey('ControlModeText', ModeType.MORE)));
        let moreMode = await driver.findComponent(ON.id(ComponentIdKeys.getInstance()
          .getKey('ControlModeText', ModeType.MORE)));
        await moreMode.click();
        await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
        const gridModeArr = AppStorage.get('gridModeArr') as MoreModeType[];
        let modeTypeDataList = Array.from(gridModeArr?.values()).map(item => item.modeType);
        let modeTypeDataLen = modeTypeDataList.length;
        HiLog.i(TAG, `MoreModeIndex_close open click== ${modeTypeDataLen}`);
        if (modeTypeDataLen === 0) {
          HiLog.i(TAG, 'MoreModeIndex_close open click.');
          await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
          await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
        } else {
          HiLog.i(TAG, 'MoreModeIndex_edit open click.');
          await driver.assertComponentExist(ON.id(ComponentIdKeys.COMPONENT_ID_MOREMODE_EDIT));
          let moreModePage = await driver.findComponent(ON.id(ComponentIdKeys.COMPONENT_ID_MOREMODE_EDIT));
          await moreModePage.click();
          await driver.delayMs(TestConstants.DELAY_ONE_SECOND);

          HiLog.i(TAG, 'MoreModeIndex_default open click.');
          await driver.assertComponentExist(ON.id(ComponentIdKeys.COMPONENT_ID_MOREMODE_DEFAULT));
          let moreModeDefault = await driver.findComponent(ON.id(ComponentIdKeys.COMPONENT_ID_MOREMODE_DEFAULT));
          await moreModeDefault.click();
          await driver.delayMs(TestConstants.DELAY_ONE_SECOND);

          HiLog.i(TAG, 'MoreModeIndex_default_confirm open click.');
          await driver.assertComponentExist(ON.id(ComponentIdKeys.SETTING_RESTORE_DEFAULT_CONFIRM));
          let moreModeDefaultConfirm =
            await driver.findComponent(ON.id(ComponentIdKeys.SETTING_RESTORE_DEFAULT_CONFIRM));
          await moreModeDefaultConfirm.click();
          await driver.delayMs(TestConstants.DELAY_ONE_SECOND);

          HiLog.i(TAG, 'MoreModeIndex_drag open drag.');
          if (modeTypeDataLen > 1) {
            let minDrag = Math.floor(Math.random() * (modeTypeDataLen - 2) + 1);
            let modeBar3 = await driver.findComponent(ON.id(modeTypeDataList[0]));
            let modeBar4 = await driver.findComponent(ON.id(modeTypeDataList[minDrag]));
            await modeBar3.dragTo(modeBar4);
            await driver.delayMs(TestConstants.DELAY_ONE_SECOND);

            let maxDrag = Math.floor(Math.random() * (modeTypeDataLen - 1) + 1);
            HiLog.i(TAG, 'MoreModeIndex_drag open drag updown.');
            const modeBar1 = await driver.findComponent(ON.id(modeTypeDataList[maxDrag]));
            let modeBar2 = await driver.findComponent(ON.id(modeTypeDataList[modeTypeDataLen-1]));
            await modeBar1.dragTo(modeBar2);
            await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
          } else {
            HiLog.i(TAG, 'MoreModeIndex_drag close drag');
          }
          HiLog.i(TAG, 'MoreModeIndex_sumbit open click');
          await driver.assertComponentExist(ON.id(ComponentIdKeys.COMPONENT_ID_MOREMODE_SUMBIT));
          let moreModeSumbit = await driver.findComponent(ON.id(ComponentIdKeys.COMPONENT_ID_MOREMODE_SUMBIT));
          await moreModeSumbit.click();
          await driver.delayMs(TestConstants.DELAY_ONE_SECOND);

          HiLog.i(TAG, 'MoreModeIndex_edit open click.');
          await moreModePage.click();
          await driver.delayMs(TestConstants.DELAY_ONE_SECOND);

          HiLog.i(TAG, 'moreMoreIndex open click.');
          await driver.assertComponentExist(ON.id(ComponentIdKeys.COMPONENT_ID_MOREMODE_CANCEL));
          let moreModeCancel = await driver.findComponent(ON.id(ComponentIdKeys.COMPONENT_ID_MOREMODE_CANCEL));
          await moreModeCancel.click();
          await driver.delayMs(TestConstants.DELAY_ONE_SECOND);

          await driver.assertComponentExist(ON.id(ComponentIdKeys.SHUTTER_PHOTO_1));
          await driver.delayMs(TestConstants.DELAY_ONE_SECOND);
        }
      } catch (err) {
        HiLog.e(TAG, `MoreModeIndex err: ${JSON.stringify(err)}.`);
      }
      HiLog.i(TAG, 'MoreModeIndex end.');
    });
  });

}