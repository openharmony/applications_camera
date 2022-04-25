import {AsyncManager} from '../../Utils/AsyncManager'
import {CLog} from '../../Utils/CLog'
import EventBusManager from '../../Utils/EventBusManager'

const TAG: string = '[ReduxWorkerMiddle]:'

export const ReduxWorkerMiddle = store => next => action => {
  let asyncManager = AsyncManager.getInstance()
  let uiAction = {type: undefined, data: undefined}
  if (Object.keys(action).length == 2) {
    asyncManager.postMessage(action)
  }
  uiAction.type = action.type
  uiAction.data = action.data
  //  EventBusManager.getInstance().getEventBus().emit(action.type, [action.data])
  let result = next(uiAction)
  CLog.info(`${TAG} logger: new state ${JSON.stringify(store.getState())}`)
  return result
}