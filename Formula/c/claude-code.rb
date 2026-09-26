class ClaudeCode < Formula
  desc "Anthropic Claude Code CLI"
  homepage "https://code.claude.com/docs/en/overview"
  url "https://registry.npmmirror.com/@anthropic-ai/claude-code-linux-arm64-musl/-/claude-code-linux-arm64-musl-2.1.274.tgz"
  sha256 "dd66731ab73827cf56c8b7ddca6d2693667759d6a0cff0ba222d07e7b9a9b321"
  license :cannot_represent # Anthropic Legal Agreements (Commercial ToS)
  revision 1
  # Stable release channel. Anthropic License forbids redistributing the
  # official artifacts, so this is a runtime-fetch stub: install() ships only a
  # wrapper plus an extractor that runs the CLI bundle on this tap's bun. The
  # latest channel is the separate claude-code.latest formula.
  #
  # CLAUDE_CODE_RUNTIME=musl switches the wrapper from this tap's bun to the
  # official prebuilt binary run as-is (signed, through ohos-compat-shim) — the
  # escape hatch for a release that only runs on Anthropic's private bun
  # internals.
  #
  # npmmirror: brew's curl SIGILLs on the Cloudflare-fronted registry.npmjs.org.

  livecheck do
    url "https://downloads.claude.ai/claude-code-releases/stable"
    regex(/(\d+(?:\.\d+)+)/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/claude-code-v2.1.274-r2"
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "80f205fc5d0c0c62f05bd3ab24677c9196c6e8635802639d5af9998d31a01b9f"
  end

  depends_on "bun"
  depends_on "ohos-compat-shim"
  depends_on "ohos-selfsign"

  conflicts_with "claude-code.latest", because: "both install the `claude` binary"

  def install
    # Homebrew's build step auto-installs README/LICENSE metafiles from the
    # staged tarball into the keg; drop them so the bottle carries no bytes of
    # the official artifact (Anthropic License: all rights reserved).
    require "metafiles"
    buildpath.children.each { |p| p.unlink if p.file? && Metafiles.copy?(p.basename.to_s) }

    # Extractor: parses the ELF ".bun" section of a `bun build --compile`
    # executable, reads the StandaloneModuleGraph offsets from the section
    # tail, walks the CompiledModuleGraphFile record table and writes every
    # module to disk (entry point "cli" plus all chunks/assets). Since
    # 2.1.246 the CLI is code-split into ~1400 chunks; the entry references
    # them via "/$bunfs/root/<chunk>.js" specifiers valid only inside bun's
    # embedded virtual filesystem, so those are rewritten to relative paths.
    # Pure data processing — nothing fetched is ever executed.
    (libexec/"extract-cli.mjs").write <<~JS
      import { resolve } from "path";

      const [binPath, outDir] = Bun.argv.slice(2);
      if (!binPath || !outDir) {
        console.error("usage: bun extract-cli.mjs <compiled-binary> <out-dir>");
        process.exit(2);
      }
      const buf = new Uint8Array(await Bun.file(binPath).arrayBuffer());
      const dv = (off) => new DataView(buf.buffer, off);
      const u16 = (off) => dv(off).getUint16(0, true);
      const u32 = (off) => dv(off).getUint32(0, true);
      const u64 = (off) => Number(dv(off).getBigUint64(0, true));
      const td = new TextDecoder();

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
        if (td.decode(buf.subarray(nameOff, end)) === ".bun") {
          bunOff = u64(sh + 0x18);
          bunSize = u64(sh + 0x20);
          break;
        }
      }
      if (bunOff < 0) die("no .bun section (not a bun --compile binary?)");

      if (td.decode(buf.subarray(bunOff + bunSize - 16, bunOff + bunSize)) !== "\\n---- Bun! ----\\n")
        die("bad .bun trailer");

      // Tail Offsets struct (StandaloneModuleGraph.rs in bun's source):
      //   u64 byte_count; StringPointer modules {u32 off, u32 len}; u32 entry_id; ...
      const o = bunOff + bunSize - 48;
      const modPtrOff = u32(o + 8), modPtrLen = u32(o + 12);

      // All StringPointer offsets are relative to bunOff + 8: the appended-data
      // segment carries a leading u64 length prefix that the section view keeps.
      const BASE = bunOff + 8;

      // modules region = [8-byte header] + N x CompiledModuleGraphFile records
      // (52 bytes each): 6 x StringPointer (name@0, contents@8, sourcemap@16,
      // bytecode@24, module_info@32, bytecode_origin_path@40) + 4 enum bytes@48.
      // Names are stored as "/$bunfs/root/<file>\\0" — NUL-terminated.
      const RECSIZE = 52;
      function cstr(off, maxLen) {
        const start = BASE + off;
        let end = start;
        const lim = Math.min(start + maxLen, bunOff + bunSize);
        while (end < lim && buf[end] !== 0) end++;
        return td.decode(buf.subarray(start, end));
      }

      const files = [];
      for (let p = modPtrOff + 8; p + RECSIZE <= modPtrOff + modPtrLen; p += RECSIZE) {
        const r = bunOff + p;
        const sp = (k) => ({ off: u32(r + k), len: u32(r + k + 4) });
        const name = sp(0), contents = sp(8);
        if (name.len === 0 || name.off >= bunSize) break;
        const nm = cstr(name.off, name.len);
        if (!nm.startsWith("/$bunfs/root/")) break;
        const rel = nm.slice("/$bunfs/root/".length);
        if (rel === "" || rel.startsWith("/") || rel.split("/").includes("..")) die(`unsafe module path: ${nm}`);
        files.push({ name: rel, contents });
      }
      console.error(`claude-code: module graph has ${files.length} files`);

      // Entry point file ("cli" in claude-code builds)
      const entry = files.find((f) => f.name === "cli");
      if (!entry || entry.contents.len === 0) die("entry point 'cli' not found in module graph");

      // Text contents are Latin1-encoded; decode and write back out as UTF-8.
      const latin1 = new TextDecoder("latin1");
      function isTextAsset(base) {
        return base.endsWith(".js") || base.endsWith(".md") || base.endsWith(".txt");
      }
      // Some assets are binary under filenames the extractor has no fixed
      // suffix list for: 2.1.251 added ".zst"-suffixed zstd-compressed .md
      // files ("plugin-eval-quickref-<hash>.md.zst"); 2.1.252 added a
      // zstd-compressed "payload.template.html.asset" (the /design canvas
      // template) plus three native ".node" addons (image-processor,
      // clipboard-napi, audio-capture) with no distinctive suffix at all.
      // Matching by filename suffix is a losing game — Anthropic can (and
      // did) rename the convention release to release. Sniff the leading
      // magic bytes instead and write matches as raw bytes, never through
      // the Latin1-decode/UTF-8-re-encode path used for text assets — that
      // round-trip corrupts any byte >= 0x80, which both zstd frames and
      // ELF binaries are full of. (The extracted CLI's own asset reader
      // already does zstd-magic detection + Bun.zstdDecompressSync on read,
      // regardless of what the extractor named the file on disk.)
      const ZSTD_MAGIC = [0x28, 0xb5, 0x2f, 0xfd];
      const ELF_MAGIC = [0x7f, 0x45, 0x4c, 0x46];
      function hasMagic(f, magic) {
        if (f.contents.len < magic.length) return false;
        const start = BASE + f.contents.off;
        for (let i = 0; i < magic.length; i++) if (buf[start + i] !== magic[i]) return false;
        return true;
      }
      function isBinaryAsset(f) {
        return hasMagic(f, ZSTD_MAGIC) || hasMagic(f, ELF_MAGIC);
      }

      // Built-in plugins pick their hooks module by Bun.isStandaloneExecutable:
      // the build-carried bundle when compiled, else a source-tree folder an
      // extracted graph does not have (so AGENTS.md support silently never
      // loads). Pin only that selector to the compiled branch; every other
      // consumer (self-respawn argv, embedded ripgrep, updater) must still see
      // plain bun.
      const BUILTIN_HOOKS_SELECTOR =
        /=\\(([\\w$]+),([\\w$]+),([\\w$]+)\\)=>[\\w$]+\\(\\)\\?([\\w$]+)\\(\\2,\\3\\(\\),\\1\\):\\{module:\\2,folder:\\1\\}/g;

      // Files keep their full graph path (the hooks worker lives under src/),
      // and "/$bunfs/root/" becomes the absolute extraction root: identical to
      // "./" for flat chunk imports, but also right for new URL()/fs uses,
      // which "./" would resolve against the user's working directory.
      // Bytecode-only records carry no JS payload.
      const root = `${resolve(outDir)}/`;
      let rewritten = 0, selectorPatched = 0;
      for (const f of files) {
        if (f.contents.len === 0) continue;
        const outPath = `${outDir}/${f.name}`;
        const bytes = buf.subarray(BASE + f.contents.off, BASE + f.contents.off + f.contents.len);
        if (f === entry || isTextAsset(f.name)) {
          let src = latin1.decode(bytes);
          if (src.includes("/$bunfs/root/")) {
            src = src.replaceAll("/$bunfs/root/", root);
            rewritten++;
          }
          src = src.replace(BUILTIN_HOOKS_SELECTOR, (_, a, b, c, kt) => {
            selectorPatched++;
            return `=(${a},${b},${c})=>${kt}(${b},${c}(),${a})`;
          });
          await Bun.write(outPath, src);
        } else if (isBinaryAsset(f)) {
          await Bun.write(outPath, bytes);
        }
      }
      console.error(`claude-code: extracted ${files.length} files (rewrote ${rewritten} bunfs specifiers)`);
      if (selectorPatched !== 1)
        console.error(`claude-code: built-in hooks selector matched ${selectorPatched} times (expected 1)`);

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

      # CLAUDE_CODE_RUNTIME picks how the official bundle is run:
      #   bun (default) - extract the JS module graph and run it on this tap's bun
      #   musl          - run the official prebuilt binary as-is, signed for this
      #                   device and launched through ohos-compat-shim; the
      #                   escape hatch for a release that only runs on
      #                   Anthropic's private bun internals
      RUNTIME="${CLAUDE_CODE_RUNTIME:-bun}"
      case "$RUNTIME" in
        bun|musl) ;;
        *)
          echo "claude-code: invalid CLAUDE_CODE_RUNTIME '$RUNTIME' (expected bun or musl)" >&2
          exit 2
          ;;
      esac

      CACHE="${CLAUDE_CODE_CACHE:-${HOMEBREW_CACHE:-$HOME/.cache/homebrew}/#{name}/$VER}/$RUNTIME"

      # /tmp is read-only here, so hand the CLI a writable scratch dir of its
      # own. A caller-set value wins; an unusable fallback is left unset rather
      # than failing the wrapper.
      if [ -z "${CLAUDE_CODE_TMPDIR:-}" ] && [ -w /data/storage/el2/base/tmp ]; then
        export CLAUDE_CODE_TMPDIR=/data/storage/el2/base/tmp
      fi

      # herdr picks the agent detection manifest from HERDR_AGENT in the
      # foreground process's environ; the bun-exec'd CLI (basename "cli")
      # is otherwise invisible to it.
      export HERDR_AGENT="${HERDR_AGENT:-claude}"

      # Download the official tarball into $TMP and fail closed: an unverified
      # runtime download must never be trusted.
      fetch_official() {
        TMP="$(mktemp -d)"
        trap 'rm -rf "$TMP"' EXIT
        echo "claude-code: fetching official binary $VER..." >&2
        FALLBACK="https://registry.npmjs.org/@anthropic-ai/claude-code-linux-arm64-musl/-/claude-code-linux-arm64-musl-$VER.tgz"
        fetched=0
        for u in "$NPM_URL" "$FALLBACK"; do
          curl -fsSL --retry 3 --retry-all-errors --retry-delay 2 "$u" -o "$TMP/pkg.tgz" && { fetched=1; break; }
        done
        [ "$fetched" = 1 ] || { echo "claude-code: download failed from all mirrors" >&2; exit 1; }
        command -v sha256sum >/dev/null 2>&1 || {
          echo "claude-code: sha256sum not found; refusing an unverified download" >&2
          exit 1
        }
        printf '%s  %s\\n' "$NPM_SHA" "$TMP/pkg.tgz" | sha256sum -c -
        tar -xzf "$TMP/pkg.tgz" -C "$TMP"
        [ -f "$TMP/package/claude" ] || { echo "claude-code: 'claude' binary not found in tarball" >&2; exit 1; }
      }

      if [ "$RUNTIME" = "musl" ]; then
        # Official prebuilt binary as-is: this device only execs signed ELFs, and
        # ohos-compat-shim supplies the libc entry points OHOS lacks.
        BIN="$CACHE/claude"
        if [ ! -x "$BIN" ]; then
          rm -rf "$CACHE"
          mkdir -p "$CACHE"
          fetch_official
          "$HB/opt/ohos-selfsign/bin/selfsign" "$TMP/package/claude"
          mv "$TMP/package/claude" "$BIN"
          chmod 0755 "$BIN"
        fi
        exec "$HB/opt/ohos-compat-shim/bin/ohos-shim" "$BIN" "$@"
      fi

      # Default: extract the CLI module graph (entry + chunks) and run it on this
      # tap's bun; the official binary itself is never executed. The suffix is
      # the extractor's output-layout generation: bump it when that changes, so
      # a stale extraction is never reused nor rewritten under a live session.
      CACHE="$CACHE.2"
      CLI="$CACHE/cli"
      if [ ! -f "$CLI" ]; then
        rm -rf "$CACHE"
        mkdir -p "$CACHE"
        fetch_official
        "$HB/opt/bun/bin/bun" "$HB/opt/#{name}/libexec/extract-cli.mjs" "$TMP/package/claude" "$CACHE" || {
          echo "claude-code: bundle extraction failed" >&2; exit 1; }
      fi

      exec "$HB/opt/bun/bin/bun" "$CLI" "$@"
    SH
    chmod 0755, bin/"claude"
  end

  test do
    assert_match "#{version} (Claude Code)", shell_output("#{bin}/claude --version")

    # The runtime switch must reject an unknown value rather than silently
    # falling back to one of the two runtimes.
    assert_match "invalid CLAUDE_CODE_RUNTIME",
                 shell_output("CLAUDE_CODE_RUNTIME=bogus #{bin}/claude --version 2>&1", 2)

    # --version never touches the renderer, so a bundle that only runs on
    # Anthropic's private bun internals crash-loops at startup and slips
    # through. Start the real TUI under a pty and fail on the crash signature.
    tui = shell_output("timeout 10 script -q -c '#{bin}/claude' /dev/null 2>&1; true")
    refute_includes tui, "Uncaught exception",
                    "claude's TUI crash-looped at startup (this release may need claude-code.latest)"
    refute_includes tui, "hooks module did not load",
                    "a built-in plugin's hooks module did not load from the extracted bundle"
  end
end
