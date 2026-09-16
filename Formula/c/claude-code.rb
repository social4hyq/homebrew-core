class ClaudeCode < Formula
  desc "Anthropic Claude Code CLI"
  homepage "https://code.claude.com/docs/en/overview"
  url "https://registry.npmmirror.com/@anthropic-ai/claude-code-linux-arm64-musl/-/claude-code-linux-arm64-musl-2.1.267.tgz"
  sha256 "7eb3b730b2f9198f059b849acaa55f0f55f18608e5b3f876172b2baaa943bbed"
  license :cannot_represent # Anthropic Commercial Terms of Service
  # Stable release channel. Anthropic License forbids redistributing the
  # official artifacts, so this is a runtime-fetch stub: install() ships only a
  # wrapper plus an extractor that runs the CLI bundle on this tap's bun. The
  # latest channel is the separate claude-code.latest formula.
  #
  # npmmirror: brew's curl SIGILLs on the Cloudflare-fronted registry.npmjs.org.

  livecheck do
    url "https://downloads.claude.ai/claude-code-releases/stable"
    regex(/(\d+(?:\.\d+)+)/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/claude-code-v2.1.267-r3"
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c3bfb099eedc598c64447878ba244c0aff1e4ec277aa5dcd615dc749e4027199"
  end

  depends_on "bun"

  def install
    # Extractor: parses the ELF ".bun" section of a `bun build --compile`
    # executable, reads the StandaloneModuleGraph offsets from the section
    # tail, walks the CompiledModuleGraphFile record table and writes every
    # module to disk (entry point "cli" plus all chunks/assets). Since
    # 2.1.246 the CLI is code-split into ~1400 chunks; the entry references
    # them via "/$bunfs/root/<chunk>.js" specifiers valid only inside bun's
    # embedded virtual filesystem, so those are rewritten to relative paths.
    # Pure data processing — nothing fetched is ever executed.
    (libexec/"extract-cli.mjs").write <<~JS
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
        files.push({ name: nm.slice("/$bunfs/root/".length), contents });
      }
      console.error(`claude-code: module graph has ${files.length} files`);

      // Entry point file ("cli" in claude-code builds)
      const entry = files.find((f) => f.name === "cli");
      if (!entry || entry.contents.len === 0) die("entry point 'cli' not found in module graph");

      const latin1 = new TextDecoder("latin1");
      function emit(f, outPath) {
        // contents are Latin1-encoded; decode and write back out as UTF-8
        const src = latin1.decode(buf.subarray(BASE + f.contents.off, BASE + f.contents.off + f.contents.len));
        Bun.write(outPath, src);
        return src;
      }
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

      // Extract every module-graph file next to the entry. Non-.js files keep
      // their basename; .js chunks land beside the entry so its relative
      // imports resolve. Bytecode-only records carry no JS payload.
      for (const f of files) {
        if (f.contents.len === 0) continue;
        const base = f.name.split("/").pop();
        if (f === entry || isTextAsset(base)) {
          emit(f, `${outDir}/${base}`);
        } else if (isBinaryAsset(f)) {
          await Bun.write(`${outDir}/${base}`, buf.subarray(BASE + f.contents.off, BASE + f.contents.off + f.contents.len));
        }
      }

      // The graph was built for bun's embedded virtual filesystem
      // ("/$bunfs/root/…"). Rewrite every such specifier to a relative one so
      // plain-bun execution resolves it against the extracted files on disk.
      // Binary assets (zstd-compressed, native .node addons) are skipped
      // here: they're already written correctly above, and being binary
      // can't contain a bunfs specifier to rewrite.
      let rewritten = 0;
      for (const f of files) {
        if (f.contents.len === 0) continue;
        const base = f.name.split("/").pop();
        const isEntry = f === entry;
        if (!isEntry && !isTextAsset(base)) continue;
        const outPath = `${outDir}/${base}`;
        const src = latin1.decode(buf.subarray(BASE + f.contents.off, BASE + f.contents.off + f.contents.len));
        if (src.includes("/$bunfs/root/")) {
          await Bun.write(outPath, src.replaceAll("/$bunfs/root/", "./"));
          rewritten++;
        } else if (!isEntry) {
          await Bun.write(outPath, src); // re-emit as UTF-8
        }
      }
      console.error(`claude-code: extracted ${files.length} files (rewrote ${rewritten} bunfs specifiers)`);

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
      CLI="$CACHE/cli"

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

      if [ ! -f "$CLI" ]; then
        rm -rf "$CACHE"
        mkdir -p "$CACHE"
        TMP="$(mktemp -d)"
        trap 'rm -rf "$TMP"' EXIT
        echo "claude-code: fetching official binary $VER..." >&2
        FALLBACK="https://registry.npmjs.org/@anthropic-ai/claude-code-linux-arm64-musl/-/claude-code-linux-arm64-musl-$VER.tgz"
        fetched=0
        for u in "$NPM_URL" "$FALLBACK"; do
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
        # Extract the CLI module graph (entry + chunks); the official binary
        # itself is never executed.
        "$HB/opt/bun/bin/bun" "$HB/opt/#{name}/libexec/extract-cli.mjs" "$TMP/package/claude" "$CACHE" || {
          echo "claude-code: bundle extraction failed" >&2; exit 1; }
      fi

      exec "$HB/opt/bun/bin/bun" "$CLI" "$@"
    SH
    chmod 0755, bin/"claude"
  end

  def caveats
    <<~EOS
      Claude Code needs a writable temp dir; this device's /tmp is read-only. Set:

        export CLAUDE_CODE_TMPDIR=/data/storage/el2/base/tmp
    EOS
  end

  test do
    assert_match "#{version} (Claude Code)", shell_output("#{bin}/claude --version")
  end
end
