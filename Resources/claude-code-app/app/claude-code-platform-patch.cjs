'use strict';

const ORIGINAL_PLATFORM_METHOD =
  'getHostPlatform(){let e=process.arch;if(process.platform==="darwin")return e==="arm64"?"darwin-arm64":"darwin-x64";if(process.platform==="win32")return e==="arm64"?"win32-arm64":"win32-x64";if(process.platform==="linux")return e==="arm64"?"linux-arm64":"linux-x64";throw Error(`Unsupported platform: ${process.platform}-${e}`)}';
const PATCHED_PLATFORM_METHOD =
  'getHostPlatform(){let e=process.arch;if(process.platform==="darwin")return e==="arm64"?"darwin-arm64":"darwin-x64";if(process.platform==="win32")return e==="arm64"?"win32-arm64":"win32-x64";if(process.platform==="linux"||process.platform==="openharmony")return e==="arm64"?"linux-arm64":"linux-x64";throw Error(`Unsupported platform: ${process.platform}-${e}`)}';
const ORIGINAL_MAIN_WINDOW_OPTIONS =
  'titleBarStyle:"hidden",titleBarOverlay:!0,trafficLightPosition:yRa(),show:i&&!0';
const PATCHED_MAIN_WINDOW_OPTIONS =
  'titleBarStyle:"default",titleBarOverlay:!1,frame:!0,trafficLightPosition:yRa(),show:i&&!0';
const ORIGINAL_LOCAL_INIT = 'this.localBinaryPath=null,this.localBinaryInitPromise=null,';
const PATCHED_LOCAL_INIT = 'this.localBinaryPath=null,this.localBinaryInitPromise=process.env.CLAUDE_CODE_LOCAL_BINARY?this.initLocalBinary(process.env.CLAUDE_CODE_LOCAL_BINARY):null,';

function replaceExactlyOnce(source, before, after, label) {
  const at = source.indexOf(before);
  if (at < 0 || source.indexOf(before, at + before.length) !== -1) {
    throw new Error(`Claude Code OHOS patch anchor mismatch: ${label}`);
  }
  return source.slice(0, at) + after + source.slice(at + before.length);
}

function patchCodeManagerSource(source) {
  const platformPatched = source.includes(PATCHED_PLATFORM_METHOD);
  const localPatched = source.includes(PATCHED_LOCAL_INIT);
  const windowPatched = source.includes(PATCHED_MAIN_WINDOW_OPTIONS);
  if (platformPatched && localPatched && windowPatched) return source;
  if (platformPatched || localPatched || windowPatched) throw new Error('Claude Code OHOS patch is only partially applied');
  source = replaceExactlyOnce(source, ORIGINAL_PLATFORM_METHOD, PATCHED_PLATFORM_METHOD, 'host platform');
  source = replaceExactlyOnce(source, ORIGINAL_LOCAL_INIT, PATCHED_LOCAL_INIT, 'local binary initialization');
  return replaceExactlyOnce(source, ORIGINAL_MAIN_WINDOW_OPTIONS, PATCHED_MAIN_WINDOW_OPTIONS, 'main native title bar');
}

if (require.main === module) {
  const chunks = [];
  process.stdin.on('data', (chunk) => chunks.push(chunk));
  process.stdin.on('end', () => {
    try {
      process.stdout.write(patchCodeManagerSource(Buffer.concat(chunks).toString('utf8')));
    } catch (error) {
      process.stderr.write(`${error.message}\n`);
      process.exitCode = 1;
    }
  });
}

module.exports = { patchCodeManagerSource };
