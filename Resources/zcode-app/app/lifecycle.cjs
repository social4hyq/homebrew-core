'use strict';
// Quit handling for the ZCode shell, kept free of Electron so it is unit tested.
//
// The shell starts the host service by running `zcode-app serve` detached, but
// that does not keep it alive: every process the app starts belongs to the
// app's own cgroup and ends with it (`aa force-stop`, tray quit). Only a
// service started from a terminal outlives the app. zcode offers no stable
// query for running tasks, so the shell asks whenever quitting would end a
// service it started itself.

// Ask only when this shell started the service and it is still up. A service
// that was already running when the shell connected is not touched by quitting.
function shouldConfirmQuit({ startedService, serviceUp }) {
  return Boolean(startedService && serviceUp);
}

function quitDialog() {
  return {
    type: 'warning',
    title: '退出 ZCode',
    message: '退出应用会同时结束由本应用启动的后台服务',
    detail: '正在进行的任务会被中断。要让服务在退出后继续运行，请先在终端运行 zcode-app serve。',
    buttons: ['取消', '仍然退出'],
    defaultId: 0,
    cancelId: 0,
  };
}

// Index of the "quit anyway" button.
function confirmedQuit(response) {
  return response === 1;
}

// Diagnostic line for the serve log; it never carries credentials.
function attachLine({ startedService }) {
  return startedService ? 'kind=own reason=started-by-shell' : 'kind=existing reason=already-serving';
}

module.exports = { attachLine, confirmedQuit, quitDialog, shouldConfirmQuit };
