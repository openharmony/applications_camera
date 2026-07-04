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

import { afterAll, beforeAll, describe, expect, it, TestType } from '@ohos/hypium';
import { HiLog } from '@ohos/common/src/main/ets/utils/HiLog';
import { TestConstants } from '../../TestConstants';
import { CommonHandler } from '../../aw/CommonHandler';
import { Driver } from '@kit.TestKit';
import {
  addState,
  ChangeState,
  execDispatch,
  getDispatch,
  getStates,
  reduxInit,
  reduxSubscribe
} from '@ohos/common/src/main/ets/redux/Store';
import { initTestStateMap } from './TestReducer';
import { ModeType } from '@ohos/common/src/main/ets/mode/ModeType';
import { OhCombinedState } from '@ohos/common/src/main/ets/redux';
import { ComponentIdKeys } from '@ohos/common/src/main/ets/utils/ComponentIdKeys';
import { HideBugUtil } from '@ohos/common/src/main/ets/utils/HideBugUtil';

const TAG: string = TestConstants.TAG + '_' + 'CameraReduxTest';

export default function cameraReduxTest() {
  const driver: Driver = Driver.create();

  beforeAll(async () => {
    await CommonHandler.abilityStart(driver).then(() => {
      HiLog.i(TAG, 'CameraReduxTest test is start.');
      reduxInit();
    })
  });

  afterAll(async () => {
    HideBugUtil.checkDtPss(57);
    await CommonHandler.abilityEnd(driver).then(() => {
      HiLog.i(TAG, 'CameraReduxTest test is finished.');
    });
  });

  describe('CameraReduxTest', () => {
    it('CameraReduxTest_010', TestType.FUNCTION, async () => {
      HiLog.begin(TAG, 'CameraReduxTest_010');
      expect(getStates()).not().assertUndefined();
      HiLog.end(TAG, 'CameraReduxTest_010');
    });

    it('CameraReduxTest_020', TestType.FUNCTION, async () => {
      HiLog.begin(TAG, 'CameraReduxTest_020');
      expect(getDispatch()).not().assertUndefined();
      HiLog.end(TAG, 'CameraReduxTest_020');
    });

    it('CameraReduxTest_030', TestType.FUNCTION, async () => {
      HiLog.begin(TAG, 'CameraReduxTest_030');
      if (!getStates().getStateMap<Map<string, object>>('testReducer')) {
        expect(getStates().get('testReducer', 'testVal')).assertUndefined();
      } else {
        expect(getStates().get('testReducer', 'testStr')).not().assertUndefined();
      }
      HiLog.end(TAG, 'CameraReduxTest_030');
    });

    it('CameraReduxTest_040', TestType.FUNCTION, async () => {
      HiLog.begin(TAG, 'CameraReduxTest_040');
      addState('testReducer', initTestStateMap());
      expect(getStates().getStateMap('testReducer')).not().assertUndefined();
      HiLog.end(TAG, 'CameraReduxTest_040');
    });

    it('CameraReduxTest_050', TestType.FUNCTION, async () => {
      HiLog.begin(TAG, 'CameraReduxTest_050');
      let val = new Object(1);
      getStates().getStateMap<Map<string, object>>('testReducer').set('testVal', val);
      expect(getStates().get<number>('testReducer', 'testVal')).assertEqual(val);
      HiLog.end(TAG, 'CameraReduxTest_050');
    });

    it('CameraReduxTest_060', TestType.FUNCTION, async () => {
      HiLog.begin(TAG, 'CameraReduxTest_060');
      let str = new Object('testOK');
      getStates().getStateMap<Map<string, object>>('testReducer').set('testStr', str);
      expect(getStates().get<number>('testReducer', 'testStr')).assertEqual(str);
      HiLog.end(TAG, 'CameraReduxTest_060');
    });

    it('CameraReduxTest_070', TestType.FUNCTION, async () => {
      HiLog.begin(TAG, 'CameraReduxTest_070');

      class StateStruct {
        testVal: number = -1;
        mode: ModeType = ModeType.NONE;
      };
      let states = new StateStruct();
      let str = 'tst';
      let mSubscriber = reduxSubscribe((state: OhCombinedState, changeState: ChangeState<StateStruct>) => {
        changeState(states, {
          testVal: state.get<number>('testReducer', 'testVal'),
          mode: state.get<ModeType>('modeReducer', 'mode'),
        });
        str = state.get<string>('testReducer', 'testStr');
      }, undefined);
      expect(mSubscriber).not().assertUndefined();
      expect(states.testVal).assertEqual(getStates().get<number>('testReducer', 'testVal'));
      expect(states.mode).assertEqual(getStates().get<ModeType>('modeReducer', 'mode'));
      expect(str).assertEqual(getStates().get<string>('testReducer', 'testStr'));
      HiLog.end(TAG, 'CameraReduxTest_070');
    });

    it('CameraReduxTest_080', TestType.FUNCTION, async () => {
      HiLog.begin(TAG, 'CameraReduxTest_080');
      execDispatch({
        isEvent: true,
        type: 'ACTION_SHOW_PICKER',
        data: { showPicker: false, needRestart: false }
      });
      let id = ComponentIdKeys.SHUTTER_PHOTO_1;
      expect(id).not().assertNull();
      HiLog.end(TAG, 'CameraReduxTest_080');
    });
  });
}