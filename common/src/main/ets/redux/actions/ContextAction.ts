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
import type window from '@ohos.window';
import type { ActionData } from './Action';
import lazy { ContextActionType } from './ContextActionType';

const PREFIX: string = 'CONTEXT_ACTION_';

export class ContextAction {

  public static abilityOnForeground(): ActionData {
    return {
      isEvent: true,
      type: ContextActionType.ABILITY_ON_FOREGROUND,
      data: {}
    };
  }

  public static abilityOnBackground(isPickerBack: boolean, isScreenLockBack?: boolean): ActionData {
    return {
      isEvent: true,
      type: ContextActionType.ABILITY_ON_BACKGROUND,
      data: { isPickerBack: isPickerBack, isScreenLockBack: isScreenLockBack }
    };
  }

  public static abilityOnCreate(): ActionData {
    return {
      isEvent: true,
      type: ContextActionType.ABILITY_ON_CREATE,
      data: {}
    };
  }

  public static abilityOnDestroy(): ActionData {
    return {
      isEvent: true,
      type: ContextActionType.ABILITY_ON_DESTROY,
      data: {}
    };
  }

  public static abilityOnNewWant(): ActionData {
    return {
      isEvent: true,
      type: ContextActionType.ABILITY_ON_NEW_WANT,
      data: {}
    };
  }

  public static stageOnAcceptWant(): ActionData {
    return {
      isEvent: true,
      type: ContextActionType.STAGE_ON_ACCEPT_WANT,
      data: {}
    };
  }

  public static stageOnConfUpdate(): ActionData {
    return {
      isEvent: true,
      type: ContextActionType.STAGE_ON_CONF_UPDATE,
      data: {}
    };
  }

  public static stageOnMemLevel(): ActionData {
    return {
      isEvent: true,
      type: ContextActionType.STAGE_ON_MEM_LEVEL,
      data: {}
    };
  }

  public static changeWindowEventType(windowStageEventType: window.WindowStageEventType): ActionData {
    return {
      isEvent: true,
      type: ContextActionType.CHANGE_WINDOW_EVENT_TYPE,
      data: { windowStageEventType: windowStageEventType }
    };
  }

  public static changeExtensionWindowEventType(windowEventType: window.WindowEventType): ActionData {
    return {
      isEvent: true,
      type: ContextActionType.CHANGE_EXTENSION_WINDOW_EVENT_TYPE,
      data: { windowEventType: windowEventType }
    };
  }

  public static devOnShutDown(): ActionData {
    return {
      isEvent: true,
      type: ContextActionType.DEV_ON_SHUTDOWN,
      data: {}
    };
  }

  public static screenLockedState(isLocked: boolean): ActionData {
    return {
      isEvent: true,
      type: ContextActionType.SCREEN_LOCKED_STATE,
      data: { isLocked: isLocked }
    };
  }

  public static updateScreenOnState(isScreenOn: boolean): ActionData {
    return {
      isEvent: true,
      type: ContextActionType.UPDATE_SCREEN_ON_STATE,
      data: { isScreenOn: isScreenOn }
    };
  }

  public static updateSaveModeState(isShow: boolean): ActionData {
    return {
      isEvent: true,
      type: ContextActionType.UPDATE_SAVE_POWER_MODE_STATE,
      data: { isDuringSavePowerMode: isShow }
    };
  }

  public static resetSaveModeTimer(): ActionData {
    return {
      isEvent: true,
      type: ContextActionType.RESET_SAVE_MODE_TIMER,
      data: {}
    };
  }

  public static volumeKeyUp(): ActionData {
    return {
      isEvent: true,
      type: ContextActionType.VOLUME_KEY_UP,
      data: {}
    };
  }

  public static abilityActive(): ActionData {
    return {
      isEvent: true,
      type: ContextActionType.ABILITY_ACTIVE,
      data: {}
    };
  }

  public static updateHighContrastState(isHighContrast: boolean): ActionData {
    return {
      isEvent: true,
      type: ContextActionType.HIGH_CONTRAST_TEXT_STATE,
      data: { isHighContrastText: isHighContrast }
    };
  }

  public static setIsIntroLoaded(isIntro: boolean): ActionData {
    return {
      isEvent: true,
      type: ContextActionType.ABILITY_ON_INTRO,
      data: { isIntro: isIntro }
    };
  }
}
