import * as module from 'module';

let registered = false;

export function registerLoader() {
  if (!registered) {
    if (typeof module.register === 'function') {
      module.register('import-in-the-middle/hook.mjs', import.meta.url);
    }
    registered = true;
  }
}

registerLoader();
