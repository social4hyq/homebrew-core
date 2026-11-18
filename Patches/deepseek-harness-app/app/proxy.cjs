'use strict';

function normalizeProxySettings(value) {
  if (!value || !['direct', 'system', 'manual'].includes(value.mode)) {
    throw new Error('无效的代理模式');
  }
  if (value.mode !== 'manual') return { mode: value.mode, url: '' };
  let parsed;
  try { parsed = new URL(String(value.url || '')); } catch { throw new Error('代理地址格式无效'); }
  if (!['http:', 'https:', 'socks4:', 'socks5:'].includes(parsed.protocol) || !parsed.hostname || !parsed.port) {
    throw new Error('代理地址须为带端口的 HTTP(S)/SOCKS 地址');
  }
  return { mode: 'manual', url: parsed.href.replace(/\/$/, '') };
}

function toElectronProxyConfig(value) {
  const settings = normalizeProxySettings(value);
  if (settings.mode === 'direct') return { mode: 'direct' };
  if (settings.mode === 'system') return { mode: 'system' };
  return { proxyRules: settings.url };
}

module.exports = { normalizeProxySettings, toElectronProxyConfig };
