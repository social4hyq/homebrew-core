// hc bridge client for the cmux-like OHOS app (ArkTS port of HcBridge.mjs).
// The HAP sandbox cannot spawn the host's `hc`, so all core access goes through
// the host-side herdr-bridge (loopback TCP + HERDR-AUTH token), exactly like
// herdr-app's src/hc.rs::connect_bridge (see tap Patches/herdr-app/ohos/src_hc.rs.patch).
//
// Wire protocol (verified against hc 0.1.22, probe/hc-framed-probe.py):
//   hello reply: line JSON. After hello{framed:true}, all frames are:
//   [u32 LE channel][u8 kind][u32 LE len][payload]  (HEADER = 9)
//   kind: DATA=0 CREDIT=1 CLOSE=2 RESIZE=3 FOCUS=4 FACTS=5 AUTOMATIC_INPUT=6
//   channel 0 = JSON-RPC; other channels = terminal PTY byte streams.

import { socket } from '@kit.NetworkKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { util } from '@kit.ArkTS';

const TAG = 'cmuxHcBridge';
const HEADER: number = 9;

export class Frame {
  channel: number = 0;
  kind: number = 0;
  payload: Uint8Array = new Uint8Array(0);
  constructor(channel: number, kind: number, payload: Uint8Array) {
    this.channel = channel; this.kind = kind; this.payload = payload;
  }
}

function encodeFrame(channel: number, kind: number, payload: Uint8Array): ArrayBuffer {
  const out = new ArrayBuffer(HEADER + payload.length);
  const dv = new DataView(out);
  dv.setUint32(0, channel >>> 0, true);
  dv.setUint8(4, kind);
  dv.setUint32(5, payload.length >>> 0, true);
  new Uint8Array(out, HEADER).set(payload);
  return out;
}

const textEncoder = new util.TextEncoder();
const textDecoder = new util.TextDecoder();

function utf8Encode(s: string): Uint8Array {
  return textEncoder.encodeInto(s);
}
function utf8Decode(b: Uint8Array): string {
  return textDecoder.decodeToString(b);
}

// Streaming frame decoder: TCP `message` boundaries can split/coalesce frames.
export class FrameDecoder {
  private buf: Uint8Array = new Uint8Array(0);

  push(chunk: Uint8Array): Frame[] {
    const merged = new Uint8Array(this.buf.length + chunk.length);
    merged.set(this.buf, 0); merged.set(chunk, this.buf.length);
    this.buf = merged;
    const out: Frame[] = [];
    while (this.buf.length >= HEADER) {
      const dv = new DataView(this.buf.buffer, this.buf.byteOffset, this.buf.byteLength);
      const len = dv.getUint32(5, true);
      if (this.buf.length < HEADER + len) break;
      const channel = dv.getUint32(0, true);
      const kind = dv.getUint8(4);
      const payload = this.buf.slice(HEADER, HEADER + len);
      this.buf = this.buf.slice(HEADER + len);
      out.push(new Frame(channel, kind, payload));
    }
    return out;
  }
}

interface Pending {
  resolve: (value: Object) => void;
  reject: (err: Error) => void;
  timer: number;
}

type DataCallback = (data: Uint8Array) => void;

export class HcBridge {
  private tcp: socket.TCPSocket | null = null;
  private token: string = '';
  private framed: boolean = false;
  private decoder: FrameDecoder = new FrameDecoder();
  private nextId: number = 1;
  private pending: Map<number, Pending> = new Map();
  private streams: Map<number, DataCallback> = new Map();
  private lineBuf: string = '';
  private lineWaiters: Array<() => void> = [];
  private connected: boolean = false;

  constructor(token: string) { this.token = token; }

  // Connect, auth, hello(framed). Resolves with the hello result object.
  async connect(host: string, port: number): Promise<Object> {
    const tcp = socket.constructTCPSocketInstance();
    this.tcp = tcp;
    const addr: socket.NetAddress = { address: host, port: port };
    const opts: socket.TCPConnectOptions = { address: addr, timeout: 6000 };
    tcp.on('message', (value: socket.SocketMessageInfo) => this.onMessage(new Uint8Array(value.message)));
    tcp.on('error', (err: Error) => {
      hilog.error(0x0000, TAG, 'socket error: %{public}s', JSON.stringify(err));
    });
    await tcp.connect(opts);
    tcp.setExtraOptions({ TCPNoDelay: true });

    // 1) HERDR-AUTH <token>\n -> OK\n
    if (this.token.length > 0) {
      this.sendText(`HERDR-AUTH ${this.token}\n`);
      const reply = await this.readLine();
      if (reply.trim() !== 'OK') throw new Error(`auth refused: ${reply.trim()}`);
    }
    // 2) hello (line JSON), framed:true
    this.sendText('{"jsonrpc":"2.0","id":0,"method":"hello","params":{"framed":true}}\n');
    const helloLine = await this.readLine();
    const parsed: Object = JSON.parse(helloLine) as Object;
    const err = (parsed as Record<string, Object>)['error'];
    if (err !== undefined) throw new Error(`hello refused: ${JSON.stringify(err)}`);
    this.framed = true;
    this.connected = true;
    hilog.info(0x0000, TAG, 'connected, framed=%{public}s', this.framed ? 'true' : 'false');
    return parsed;
  }

  private onMessage(chunk: Uint8Array): void {
    if (!this.framed) {
      // line-oriented phase: auth/hello replies
      this.lineBuf += utf8Decode(chunk);
      const waiters = this.lineWaiters.splice(0);
      for (const w of waiters) w();
      return;
    }
    for (const f of this.decoder.push(chunk)) {
      if (f.channel === 0 && f.payload.length > 0) {
        const msg = JSON.parse(utf8Decode(f.payload)) as Record<string, Object>;
        const idVal = msg['id'];
        if (idVal !== undefined) {
          const id = Number(idVal);
          const p = this.pending.get(id);
          if (p !== undefined) {
            this.pending.delete(id);
            clearTimeout(p.timer);
            const error = msg['error'];
            if (error !== undefined) p.reject(new Error(JSON.stringify(error)));
            else p.resolve(msg['result'] !== undefined ? msg['result'] : {});
          }
        }
      } else if (f.kind === 0) { // DATA on a stream channel
        const cb = this.streams.get(f.channel);
        if (cb !== undefined) cb(f.payload);
      }
    }
  }

  private readLine(): Promise<string> {
    return new Promise<string>((resolve) => {
      const check = (): void => {
        const i = this.lineBuf.indexOf('\n');
        if (i >= 0) {
          const line = this.lineBuf.substring(0, i);
          this.lineBuf = this.lineBuf.substring(i + 1);
          resolve(line);
        } else this.lineWaiters.push(check);
      };
      this.lineWaiters.push(check);
    });
  }

  private sendText(s: string): void {
    if (this.tcp !== null) {
      const opts: socket.TCPSendOptions = { data: s };
      this.tcp.send(opts).catch((e: Error) => hilog.error(0x0000, TAG, 'sendText fail: %{public}s', JSON.stringify(e)));
    }
  }

  private sendFrame(channel: number, kind: number, payload: Uint8Array): void {
    if (this.tcp !== null) {
      const opts: socket.TCPSendOptions = { data: encodeFrame(channel, kind, payload) };
      this.tcp.send(opts).catch((e: Error) => hilog.error(0x0000, TAG, 'sendFrame fail: %{public}s', JSON.stringify(e)));
    }
  }

  // JSON-RPC call on channel 0 (framed).
  call(method: string, params: Object): Promise<Object> {
    return new Promise<Object>((resolve, reject) => {
      const id = this.nextId++;
      const timer = setTimeout(() => {
        if (this.pending.has(id)) { this.pending.delete(id); reject(new Error(`${method} timeout`)); }
      }, 15000);
      this.pending.set(id, { resolve: resolve, reject: reject, timer: timer });
      const req: Record<string, Object> = {
        'jsonrpc': '2.0', 'id': id, 'method': method, 'params': params
      };
      this.sendFrame(0, 0, utf8Encode(JSON.stringify(req)));
    });
  }

  // Attach to a terminal; onData receives raw PTY bytes. Returns the stream channel.
  async attach(terminal: string, rows: number, cols: number, onData: DataCallback): Promise<number> {
    const result = await this.call('terminal.attach', {
      'terminal': terminal, 'rows': rows, 'cols': cols
    } as Object);
    const ch = Number((result as Record<string, Object>)['channel']);
    this.streams.set(ch, onData);
    return ch;
  }

  // Send raw keystroke bytes on the stream channel (automatic_input path).
  sendInput(channel: number, data: Uint8Array): void {
    this.sendFrame(channel, 0, data);
  }

  // Send text + Enter via RPC (works without automatic_input).
  sendTextToTerminal(terminal: string, text: string): Promise<Object> {
    return this.call('terminal.send', { 'terminal': terminal, 'text': text } as Object);
  }

  // Resize a stream (cols, rows as u32 LE).
  resize(channel: number, rows: number, cols: number): void {
    const p = new ArrayBuffer(8);
    const dv = new DataView(p);
    dv.setUint32(0, cols, true); dv.setUint32(4, rows, true);
    this.sendFrame(channel, 3, new Uint8Array(p));
  }

  isConnected(): boolean { return this.connected; }

  close(): void {
    if (this.tcp !== null) {
      this.tcp.close().catch(() => {});
      this.tcp = null;
    }
    this.connected = false;
  }
}
