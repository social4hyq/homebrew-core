'use strict';
const { app, systemPreferences } = require('electron');

// Delay taking a batch until the vendor has registered its argv handler.
// On Linux Claude parses deep links from second-instance argv (including argv[0]).
function startClaudeLaunchBridge() {
  let draining = false;
  const drain = async () => {
    if (draining || app.listenerCount('second-instance') === 0) return;
    draining = true;
    let batch;
    try {
      const result = await systemPreferences.callArkTSFunction('EtsBridge.DrainClaudeLaunchUris', 'string[]', []);
      batch = result?.value;
    } catch {
      return;
    } finally {
      draining = false;
    }
    if (!Array.isArray(batch)) return;
    for (const uri of batch) {
      if (typeof uri === 'string' && /^claude:\/\//i.test(uri)) {
        app.emit('second-instance', { preventDefault() {} }, [process.execPath, uri], process.cwd());
      }
    }
  };
  void app.whenReady().then(() => {
    drain();
    setInterval(drain, 250).unref();
  });
}
module.exports = { startClaudeLaunchBridge };
