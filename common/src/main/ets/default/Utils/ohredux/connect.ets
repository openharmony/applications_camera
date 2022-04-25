function merge(obj, props) {
  const keysProp = Object.keys(props)
  console.info(`mapProps: ${JSON.stringify(keysProp)}`)
  for(let i = 0; i < keysProp.length; i++) {
    obj[keysProp[i]] = props[keysProp[i]]
  }
}

function connect(store, mapToProps, mapToDispatch) {
  return (obj) => {
    console.info(JSON.stringify(store.getState()))
    merge(obj, mapToProps(store.getState()))
    merge(obj, mapToDispatch(store.dispatch))
    let unsubscribe = store.subscribe(() => merge(obj, mapToProps(store.getState())))
    return {
      destroy() {
        unsubscribe()
      }
    }
  }
}

export {connect}