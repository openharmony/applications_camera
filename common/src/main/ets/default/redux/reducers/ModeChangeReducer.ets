import {ACTION_CHANGE_PREVIEW_SIZE, ACTION_CHANGE_SHUTTER_BUTTON} from '../actions/ModeChange'
import {UIDATA_TAB_ITEM} from '../actions/UiData'

let initState = {
  number: 154,
  res: "app.media.icon",
  tabItem: ['', 'flash', 'zoom', 'focus', 'setup']
}

export default function ModeChangeReducer(state = initState, action: {
  type: string,
  data: any
}) {
  switch (action.type) {
    case ACTION_CHANGE_PREVIEW_SIZE:
      return { ...state, number: action.data.size}
    case ACTION_CHANGE_SHUTTER_BUTTON:
      return { ...state, res: action.data.res}
    case UIDATA_TAB_ITEM:
      return { ...state, tabItem: action.data}
    default:
      return state;
  }
  return state;
}