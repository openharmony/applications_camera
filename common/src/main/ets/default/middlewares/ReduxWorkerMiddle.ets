import {AsyncManager} from '../../Utils/AsyncManager.ets'

export const ReduxWorkerMiddle = store => next => action => {
  let asyncManager = AsyncManager.getInstance()
  asyncManager.postMessage(action)
  let result = next(action)
  console.info(`logger: new state ${JSON.stringify(store.getState())}`)
  return result
}