class ClaudeCode < Formula
  desc "Anthropic Claude Code CLI"
  homepage "https://code.claude.com/docs/en/overview"
  url "https://registry.npmmirror.com/@anthropic-ai/claude-code-linux-arm64-musl/-/claude-code-linux-arm64-musl-2.1.237.tgz"
  sha256 "13d0c2c0bf1adf0f33eb2841aea642338113bcb8320fe5fd0a24bf2c75d920da"
  license :cannot_represent # Anthropic Commercial Terms of Service
  # npmmirror mirror: brew's curl SIGILLs on the Cloudflare-fronted registry.npmjs.org
  # (aarch64 SIMD AES path trapped by kernel); npmmirror (Aliyun CDN) doesn't.
  # Files are byte-identical (sha256 matches); wrapper tries npmmirror first,
  # falls back to registry.npmjs.org for non-buggy curl or mirror lag.
  #
  # Runtime-fetch stub: Anthropic License prohibits redistributing the official
  # artifacts, so install() ships only a wrapper plus an extractor — the official
  # tarball is fetched, sha256-checked and unpacked at first run. The official
  # compiled binary is NEVER executed (see below), so nothing fetched is ever
  # signed or run as code.
  #
  # Why not run the official binary: both bun builds Anthropic ships abort
  # during early stdio init, before any JS runs (verified via OHOS faultlog
  # backtrace + qemu strace + local disassembly; see memory note
  # project_claude_embedded_bun_crash_diagnosis). 2.1.228's bun calls
  # syscall(close_range, 4, ~0, flags=4), which the OHOS kernel seccomp-traps
  # with SIGSYS; 2.1.229+ die earlier: the binary's own dynsym exports
  # stdout/stderr (R_AARCH64_COPY relocs), OHOS musl's ld.so resolves the copy
  # against the executable itself, leaving the slot NULL, and OHOS musl's
  # hardened setvbuf("parameter is null") aborts. Neither path is shimmable,
  # so the wrapper extracts the standalone-module-graph CLI bundle from the
  # fetched binary (pure data parsing, no execution) and runs it on our own
  # bun: same JS, working runtime. (Earlier note blaming a regex-automata
  # panic was an artifact of symbolizing this custom build's addresses
  # against official bun debug info — layout mismatch, disregard it.)
  #
  # Relocatability: wrapper uses runtime $HOMEBREW_PREFIX only — no build-time path interpolation.

  livecheck do
    # www.npmjs.com 403s from this env; registry API JSON is reachable.
    # Same npmmirror livecheck pattern used elsewhere in this tap.
    url "https://registry.npmjs.org/@anthropic-ai/claude-code-linux-arm64-musl/latest"
    regex(/"version":\s*"(\d+(?:\.\d+)+)"/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/claude-code-v2.1.237-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "803b7399f6bd79349ca28b9999fbe08ff9a125376270166ed81ced50241405d3"
  end

  depends_on "bun"

  def install
    # Extractor: parses the ELF ".bun" section of a `bun build --compile`
    # executable, reads the StandaloneModuleGraph offsets from the section
    # tail, scans the module record blob for the largest "// @bun" source
    # payload and writes it as a standalone cli.js. Pure data processing.
    (libexec/"extract-cli.mjs").write <<~JS
      const [binPath, outPath] = Bun.argv.slice(2);
      if (!binPath || !outPath) {
        console.error("usage: bun extract-cli.mjs <compiled-binary> <out.js>");
        process.exit(2);
      }
      const buf = new Uint8Array(await Bun.file(binPath).arrayBuffer());
      const dv = (off) => new DataView(buf.buffer, off);
      const u16 = (off) => dv(off).getUint16(0, true);
      const u32 = (off) => dv(off).getUint32(0, true);
      const u64 = (off) => Number(dv(off).getBigUint64(0, true));

      const shoff = u64(0x28);
      const shentsize = u16(0x3a);
      const shnum = u16(0x3c);
      const shstrndx = u16(0x3e);
      const strOff = u64(shoff + shstrndx * shentsize + 0x18);
      let bunOff = -1, bunSize = 0;
      for (let i = 0; i < shnum; i++) {
        const sh = shoff + i * shentsize;
        const nameOff = strOff + u32(sh);
        let end = nameOff;
        while (buf[end] !== 0) end++;
        if (new TextDecoder().decode(buf.subarray(nameOff, end)) === ".bun") {
          bunOff = u64(sh + 0x18);
          bunSize = u64(sh + 0x20);
          break;
        }
      }
      if (bunOff < 0) die("no .bun section (not a bun --compile binary?)");

      if (new TextDecoder().decode(buf.subarray(bunOff + bunSize - 16, bunOff + bunSize)) !== "\\n---- Bun! ----\\n")
        die("bad .bun trailer");
      const o = bunOff + bunSize - 48;
      const byteCount = u64(o);
      const modPtrOff = u32(o + 8), modPtrLen = u32(o + 12);

      let best = null;
      const blobEnd = bunOff + modPtrOff + modPtrLen;
      for (let p = bunOff + modPtrOff; p + 8 <= blobEnd; p++) {
        const off = u32(p), len = u32(p + 4);
        if (off === 0 || len < 1_000_000) continue; // main bundle is tens of MB
        if (off + len > bunOff + byteCount) continue;
        const win = new TextDecoder().decode(buf.subarray(bunOff + off, bunOff + off + 64));
        const at = win.indexOf("// @bun");
        if (at < 0) continue;
        const realLen = len - at;
        if (!best || realLen > best.len) best = { off: off + at, len: realLen };
      }
      if (!best) die("main bundle not found in module graph");

      // The contents length may stop a few bytes short of the real bundle end
      // (name-tail preamble artifact); JS source contains no NUL, so extend
      // to the section's next NUL boundary.
      let end = bunOff + best.off + best.len;
      while (end < bunOff + bunSize && buf[end] !== 0) end++;
      const src = buf.subarray(bunOff + best.off, end);
      await Bun.write(outPath, src);
      console.error(`claude-code: extracted ${src.length} bytes of CLI bundle`);

      function die(msg) {
        console.error(`extract-cli: ${msg}`);
        process.exit(1);
      }
    JS

    (bin/"claude").write <<~SH
      #!/bin/sh
      set -e
      : "${HOMEBREW_PREFIX:?claude-code: HOMEBREW_PREFIX not set; run 'brew shellenv' first}"
      HB="$HOMEBREW_PREFIX"
      VER="#{version}"
      NPM_URL="#{stable.url}"
      NPM_SHA="#{stable.checksum}"
      CACHE="${CLAUDE_CODE_CACHE:-${HOMEBREW_CACHE:-$HOME/.cache/homebrew}/claude-code/$VER}"
      CLI="$CACHE/cli.js"

      # /tmp is read-only here, so hand the CLI a writable scratch dir of its
      # own. A caller-set value wins; an unusable fallback is left unset rather
      # than failing the wrapper.
      if [ -z "${CLAUDE_CODE_TMPDIR:-}" ] && [ -w /data/storage/el2/base/tmp ]; then
        export CLAUDE_CODE_TMPDIR=/data/storage/el2/base/tmp
      fi

      if [ ! -f "$CLI" ]; then
        mkdir -p "$CACHE"
        TMP="$(mktemp -d)"
        trap 'rm -rf "$TMP"' EXIT
        echo "claude-code: fetching official binary $VER..." >&2
        # npmmirror primary (curl SIGILL on Cloudflare); sha256 verifies regardless of source.
        FALLBACK="https://registry.npmjs.org/@anthropic-ai/claude-code-linux-arm64-musl/-/claude-code-linux-arm64-musl-$VER.tgz"
        fetched=0
        for u in "$NPM_URL" "$FALLBACK"; do
          # --retry: npmmirror long connections occasionally die mid-transfer
          # (SSL unexpected eof); one retry has been enough in practice.
          curl -fsSL --retry 3 --retry-all-errors --retry-delay 2 "$u" -o "$TMP/pkg.tgz" && { fetched=1; break; }
        done
        [ "$fetched" = 1 ] || { echo "claude-code: download failed from all mirrors" >&2; exit 1; }
        # Fail closed: an unverified runtime download must never be trusted.
        command -v sha256sum >/dev/null 2>&1 || {
          echo "claude-code: sha256sum not found; refusing an unverified download" >&2
          exit 1
        }
        printf '%s  %s\\n' "$NPM_SHA" "$TMP/pkg.tgz" | sha256sum -c -
        tar -xzf "$TMP/pkg.tgz" -C "$TMP"
        [ -f "$TMP/package/claude" ] || { echo "claude-code: 'claude' binary not found in tarball" >&2; exit 1; }
        # Extract the CLI bundle; the official binary itself is never executed
        # (its embedded bun aborts on OHOS — see formula comments).
        "$HB/opt/bun/bin/bun" "$HB/opt/#{name}/libexec/extract-cli.mjs" "$TMP/package/claude" "$CLI" || {
          echo "claude-code: bundle extraction failed" >&2; exit 1; }
      fi

      exec "$HB/opt/bun/bin/bun" "$CLI" "$@"
    SH
    chmod 0755, bin/"claude"
  end

  def caveats
    <<~EOS
      claude-code is installed as a runtime-fetch stub: nothing of the official
      release is in the bottle (Anthropic License). The first `claude` invocation
      downloads the official tarball (via the npmmirror mirror), verifies its
      sha256, extracts the CLI bundle from the compiled binary, and runs it on
      this tap's bun. The official binary itself is never executed (its embedded
      bun crashes on OHOS). Cached under $HOMEBREW_CACHE/claude-code/#{version}/
      (override with CLAUDE_CODE_CACHE).

      Claude Code requires API credentials. Configure via environment variables:

        export ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic
        export ANTHROPIC_AUTH_TOKEN=sk-xxx
        export ANTHROPIC_MODEL=deepseek-v4-flash
        export ANTHROPIC_DEFAULT_OPUS_MODEL=deepseek-v4-flash
        export ANTHROPIC_DEFAULT_SONNET_MODEL=deepseek-v4-flash
        export ANTHROPIC_DEFAULT_HAIKU_MODEL=deepseek-v4-flash
        export CLAUDE_CODE_SUBAGENT_MODEL=deepseek-v4-flash
        export CLAUDE_CODE_EFFORT_LEVEL=max

      See https://api-docs.deepseek.com/zh-cn/quick_start/agent_integrations/claude_code
      for DeepSeek integration details.

      For OpenAI-format APIs, install claude-code-router:
        brew install claude-code-router
    EOS
  end

  test do
    # End-to-end: wrapper runtime-fetches, sha256-verifies, extracts the CLI
    # bundle and runs it on our bun. The embedded-bun startup abort that
    # shipped in 2.1.229-2.1.233 (official binary aborts on OHOS before any
    # JS runs) is exactly what this catches — the version must come out of
    # the extracted bundle running on OUR runtime. First run downloads the
    # ~95MB tgz from npmmirror.
    assert_match "#{version} (Claude Code)", shell_output("#{bin}/claude --version")
  end
end
