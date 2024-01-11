import {
  Store,
  createStore,
  ExtendState,
  PreloadedState,
  StoreEnhancer,
  Reducer,
  Action
} from '../redux/index'
import { connect } from './connect'

export default function _createStore<S,
A extends Action,
Ext = {},
StateExt = never>(
    reducer: Reducer<S, A>,
    enhancer?: StoreEnhancer<Ext, StateExt>
): Store<ExtendState<S, StateExt>, A, StateExt, Ext> & Ext

export default function _createStore<S,
A extends Action,
Ext = {},
StateExt = never>(
    reducer: Reducer<S, A>,
    preloadedState?: PreloadedState<S>,
    enhancer?: StoreEnhancer<Ext, StateExt>
): Store<ExtendState<S, StateExt>, A, StateExt, Ext> & Ext

export default function _createStore<S,
A extends Action,
Ext = {},
StateExt = never>(
  reducer: Reducer<S, A>,
  preloadedState?: PreloadedState<S>,
  enhancer?: StoreEnhancer<Ext, StateExt>
): Store<ExtendState<S, StateExt>, A, StateExt, Ext> & Ext {
  const store = createStore(reducer, preloadedState, enhancer)

  function _connect(mapToProps, mapToDispatch) {
    return connect(store, mapToProps, mapToDispatch)
  }

  return {
    ...store,
    connect: _connect
  }
}