/**
 * Turns an object whose values are different reducer functions, into a single
 * reducer function. It will call every child reducer, and gather their results
 * into a single state object, whose keys correspond to the keys of the passed
 * reducer functions.
 *
 * @template S Combined state object type.
 *
 * @param reducers An object whose values correspond to different reducer
 *   functions that need to be combined into one. One handy way to obtain it
 *   is to use ES6 `import * as reducers` syntax. The reducers may never
 *   return undefined for any action. Instead, they should return their
 *   initial state if the state passed to them was undefined, and the current
 *   state for any unrecognized action.
 *
 * @returns A reducer function that invokes every reducer inside the passed
 *   object, and builds a state object with the same shape.
 */
import { Log } from '../../utils/Log';
import type { ActionData } from '../actions/Action';
import type { OhCombinedState } from '../store';

export type Reducer = (state: OhCombinedState | undefined,
                       action: ActionData) => OhCombinedState;

export function combineReducers(reducers: Array<Function>): Reducer {
  return function combination(
    state: OhCombinedState | undefined,
    action: ActionData
  ) {
    const nextState: unknown = {};
    const currentState = state || {};
    reducers.forEach((reducer: Function) => {
      const previousStateForKey = currentState[reducer.name];
      const nextStateForKey = reducer(previousStateForKey, action);
      if (!nextStateForKey) {
        Log.error('reducer error, result is undefined.');
      }
      nextState[reducer.name] = nextStateForKey;
    });
    return nextState as OhCombinedState;
  };
}
