export const logger = store => next => action => {
  console.info(`logger: dispatch ${JSON.stringify(action)}, store: ${JSON.stringify(store.getState())}`)
  let result = next(action)
  console.info(`logger: new state ${JSON.stringify(store.getState())}`)
  return result
}