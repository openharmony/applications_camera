export const ACTION_CHANGE_PREVIEW_SIZE = 'changePreviewSize'
export const ACTION_CHANGE_SHUTTER_BUTTON = 'changeShutterButton'
export const ACTION_CHANGE_TAB_ITEM = 'changeTabItem'

export function changePreviewSize(size) {
  return {
    type: ACTION_CHANGE_PREVIEW_SIZE,
    data: { size: size }
  }
}

export function changeShutterButton(res) {
  return {
    type: ACTION_CHANGE_SHUTTER_BUTTON,
    data: { res: res }
  }
}

export function changeTabItem(mode: string) {
  return {
    type: ACTION_CHANGE_TAB_ITEM,
    data: mode
  }
}