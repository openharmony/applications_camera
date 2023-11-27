/**
 * Creates a store enhancer that applies middleware to the dispatch method
 * of the Redux store. This is handy for a variety of tasks, such as expressing
 * asynchronous actions in a concise manner, or logging every action payload.
 *
 * See `redux-thunk` package as an example of the Redux middleware.
 *
 * Because middleware is potentially asynchronous, this should be the first
 * store enhancer in the composition chain.
 *
 * Note that each middleware will be given the `dispatch` and `getState` functions
 * as named arguments.
 *
 * @param middlewares The middleware chain to be applied.
 * @returns A store enhancer applying the middleware.
 *
 * @template Ext Dispatch signature added by a middleware.
 * @template S The type of the state supported by a middleware.
 */
import type { ActionData } from '../actions/Action';
import type { Dispatch } from '../store';

export interface Middleware {
  (): (next: Dispatch) => (action: ActionData) => ActionData
}

export interface Enhancer {
  (dispatch: Dispatch): Dispatch
}

export function applyMiddleware(...middlewares: Middleware[]): Enhancer {
  return (dispatch: Dispatch) => {
    const chain: Function[] = middlewares.map(middleware => middleware());
    return compose(chain)(dispatch);
  };
}

function compose(functions: Function[]): Function {
  if (functions.length === 0) {
    return <T = {}>(arg: T): T => arg;
  }
  if (functions.length === 1) {
    return functions[0];
  }

  return functions.reduce(
    (a, b): Function =>
    (...args): void =>
    a(b(...args))
  );
}