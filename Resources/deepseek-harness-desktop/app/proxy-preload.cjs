'use strict';

const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('proxySettings', {
  read: () => ipcRenderer.invoke('proxy:read'),
  save: (value) => ipcRenderer.invoke('proxy:save', value),
});
