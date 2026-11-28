class OhosHapClt < Formula
  desc "Stage pinned HarmonyOS command-line tools for HAP builds"
  homepage "https://developer.huawei.com/consumer/cn/download/command-line-tools-for-hmos"
  url "https://s3.oheco.org/command-line-tools/26.0.0.201/commandline-tools-harmonyos-26.0.0.201.tar.gz"
  sha256 "60929c00ae486cc038ea48145497ad34dbd4ac6a25c3f2fa895ce74afb4607f5"
  license :cannot_represent
  revision 2

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/ohos-hap-clt-v26.0.0.201-r2"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d65cb0095be5712211ba3ef3bc87326dee1f929ac8ec5b44fb3bdbe94646b03a"
  end

  depends_on "ohos-sdk" => :build if OS.ohos?
  depends_on "curl"
  depends_on "gnu-tar"
  depends_on "node"

  def install
    entries = %w[hvigor/bin/hvigorw.js ohpm/bin/pm-cli.js]
    entries.each do |entry|
      odie "CLT archive missing #{entry}" unless (buildpath/entry).file?
    end

    if OS.ohos?
      # es2abc uses the device logging API in the build container.
      source = buildpath/"hilog-stderr.c"
      source.write <<~C
        #include <stdarg.h>
        #include <stdio.h>
        #include <stdlib.h>
        #include <string.h>

        int HiLogPrint(int type, int level, unsigned int domain, const char *tag, const char *format, ...) {
          (void)type;
          (void)level;
          (void)domain;
          if (!format) return -1;
          char *clean = malloc(strlen(format) + 1);
          if (!clean) return -1;
          char *out = clean;
          for (const char *p = format; *p; ++p) {
            *out++ = *p;
            if (*p == '%' && p[1] == '%') {
              *out++ = *++p;
            } else if (*p == '%' && p[1] == '{') {
              const char *end = strchr(p + 2, '}');
              if (end && end[1]) p = end;
            }
          }
          *out = '\\0';
          fprintf(stderr, "[%s] ", tag ? tag : "");
          va_list args;
          va_start(args, format);
          int count = vfprintf(stderr, clean, args);
          va_end(args);
          fputc('\\n', stderr);
          free(clean);
          return count;
        }
      C
      (libexec/"host-libs").mkpath
      system formula_opt_bin("ohos-sdk")/"clang", "-shared", "-fPIC", "-Wl,-soname,libhilog.so",
             source, "-o", libexec/"host-libs/libhilog.so"

      (libexec/"hvigor-host.cjs").write <<~JS
        const path = require('node:path');
        const hvigor = process.env.OHOS_HAP_CLT_HVIGOR_ROOT;
        // The container kernel reports Linux even when Node targets OHOS.
        for (const name of ['hvigor', 'hvigor-ohos-plugin']) {
          const common = require(path.join(hvigor, name, 'node_modules/@ohos/hvigor-common/src/util/system-util.js'));
          common.isHarmony = () => true;
        }
      JS
    end

    tool = libexec/"stage.cjs"
    tool.write <<~JS + <<~SCRIPT
      const url = #{JSON.generate(stable.url)};
      const checksum = #{JSON.generate(stable.checksum.hexdigest)};
      const entries = #{JSON.generate(entries)};
      const curl = #{JSON.generate((formula_opt_bin("curl")/"curl").to_s)};
      const tar = #{JSON.generate((formula_opt_bin("gnu-tar")/(OS.mac? ? "gtar" : "tar")).to_s)};
    JS
      const crypto = require('node:crypto');
      const fs = require('node:fs');
      const path = require('node:path');
      const { execFileSync, spawnSync } = require('node:child_process');
      const { constants } = require('node:os');
      const usage = 'Usage: ohos-hap-clt stage DEST [ARCHIVE]' + '\\n' +
        '       ohos-hap-clt hvigor DEST [ARG ...]';

      async function stage(destination, archive) {
        const target = path.resolve(destination);
        fs.mkdirSync(target);
        let scratch;
        let installed = false;
        try {
          scratch = fs.mkdtempSync(path.join(path.dirname(target), '.ohos-hap-clt-'));
          const input = archive ? path.resolve(archive) : path.join(scratch, 'clt.tar.gz');
          if (!archive) {
            execFileSync(curl, ['--disable', '--fail', '--silent', '--show-error', '--location',
              '--retry', '2', '--output', input, url], { stdio: 'inherit' });
          }
          const hash = crypto.createHash('sha256');
          for await (const chunk of fs.createReadStream(input)) hash.update(chunk);
          if (hash.digest('hex') !== checksum) throw new Error('CLT archive SHA-256 mismatch');

          const unpacked = path.join(scratch, 'unpacked');
          fs.mkdirSync(unpacked);
          execFileSync(tar, ['-xzf', input, '-C', unpacked, '--strip-components=1'], { stdio: 'inherit' });
          for (const entry of entries) {
            if (!fs.statSync(path.join(unpacked, entry), { throwIfNoEntry: false })?.isFile()) {
              throw new Error(`CLT archive missing ${entry}`);
            }
          }
          fs.renameSync(unpacked, target);
          installed = true;
          console.log(target);
        } finally {
          if (!installed) fs.rmdirSync(target);
          if (scratch) fs.rmSync(scratch, { recursive: true, force: true });
        }
      }

      function runHvigor(destination, args) {
        const root = path.resolve(destination);
        const entry = path.join(root, entries[0]);
        const sdk = path.join(root, 'sdk');
        if (!fs.existsSync(entry)) throw new Error(`CLT archive missing ${entries[0]}`);

        const env = { ...process.env, DEVECO_SDK_HOME: sdk, HOS_SDK_HOME: sdk };
        const nodeArgs = [];
        if (process.platform === 'openharmony') {
          const sdkRoot = path.join(sdk, 'default');
          const runtime = fs.globSync('clang/*/lib/aarch64-linux-ohos', {
            cwd: path.join(sdkRoot, 'openharmony/native/llvm/lib'),
          });
          if (runtime.length !== 1) throw new Error('Expected one CLT clang runtime');
          const libraries = [
            path.join(__dirname, 'host-libs'),
            path.join(root, 'lib'),
            path.join(sdkRoot, 'hms/toolchains/lib'),
            path.join(sdkRoot, 'openharmony/toolchains/lib'),
            path.join(sdkRoot, 'openharmony/native/llvm/lib', runtime[0]),
            env.LD_LIBRARY_PATH,
          ];
          env.LD_LIBRARY_PATH = libraries.filter(Boolean).join(path.delimiter);
          env.OHOS_HAP_CLT_HVIGOR_ROOT = path.join(root, 'hvigor');
          nodeArgs.push('--require', path.join(__dirname, 'hvigor-host.cjs'));
        }

        const result = spawnSync(process.execPath, [...nodeArgs, entry, ...args], { env, stdio: 'inherit' });
        if (result.error) throw result.error;
        process.exitCode = result.status ?? 128 + constants.signals[result.signal];
      }

      const [command, destination, ...args] = process.argv.slice(2);
      const reportError = error => {
        console.error(`ohos-hap-clt: ${error.message}`);
        process.exitCode = 1;
      };
      if (command === '--help' && destination === undefined) {
        console.log(usage);
      } else if (command === 'stage' && destination && args.length <= 1) {
        stage(destination, args[0]).catch(reportError);
      } else if (command === 'hvigor' && destination) {
        try {
          runHvigor(destination, args);
        } catch (error) {
          reportError(error);
        }
      } else {
        console.error(usage);
        process.exitCode = 1;
      }
    SCRIPT
    (bin/"ohos-hap-clt").write_env_script formula_opt_bin("node")/"node", "\"#{tool}\"", {}
  end

  test do
    command = bin/"ohos-hap-clt"
    help = shell_output("#{command} --help")
    assert_match "Usage: ohos-hap-clt stage DEST [ARCHIVE]", help
    assert_match "ohos-hap-clt hvigor DEST [ARG ...]", help
    (testpath/"bad.tar.gz").write "invalid archive"
    assert_match "CLT archive SHA-256 mismatch", shell_output("#{command} stage staged bad.tar.gz 2>&1", 1)
    refute_path_exists testpath/"staged"
    (testpath/"staged").mkpath
    assert_match "EEXIST", shell_output("#{command} stage staged bad.tar.gz 2>&1", 1)
    assert_path_exists testpath/"staged"

    (testpath/"command-line-tools/hvigor/bin/hvigorw.js").write "// Hvigor fixture"
    (testpath/"command-line-tools/ohpm/bin/pm-cli.js").write "// OHPM fixture"
    system "tar", "-czf", "fixture.tar.gz", "command-line-tools"
    fixture_checksum = (testpath/"fixture.tar.gz").sha256
    (testpath/"stage.cjs").write (libexec/"stage.cjs").read.sub(stable.checksum.hexdigest, fixture_checksum)
    system formula_opt_bin("node")/"node", "stage.cjs", "stage", "staged tools", "fixture.tar.gz"
    assert_equal "// Hvigor fixture", (testpath/"staged tools/hvigor/bin/hvigorw.js").read
    assert_equal "// OHPM fixture", (testpath/"staged tools/ohpm/bin/pm-cli.js").read

    clt = testpath/"staged tools"
    %w[hvigor hvigor-ohos-plugin].each do |package|
      common = clt/"hvigor/#{package}/node_modules/@ohos/hvigor-common/src/util/system-util.js"
      common.dirname.mkpath
      common.write "exports.isHarmony = () => false;"
    end
    runtime = clt/"sdk/default/openharmony/native/llvm/lib/clang/15.0.4/lib/aarch64-linux-ohos"
    runtime.mkpath
    entry = clt/"hvigor/bin/hvigorw.js"
    File.write(entry, <<~JS)
      const assert = require('node:assert/strict');
      const path = require('node:path');
      assert.deepEqual(process.argv.slice(2), ['--probe', 'two words']);
      assert.equal(process.env.HOS_SDK_HOME, path.resolve('staged tools/sdk'));
      assert.equal(process.env.DEVECO_SDK_HOME, process.env.HOS_SDK_HOME);
      if (process.platform === 'openharmony') {
        for (const name of ['hvigor', 'hvigor-ohos-plugin']) {
          const common = require(`../${name}/node_modules/@ohos/hvigor-common/src/util/system-util.js`);
          assert.equal(common.isHarmony(), true);
        }
        assert.ok(process.env.LD_LIBRARY_PATH.split(':').includes(#{JSON.generate(runtime.to_s)}));
        assert.equal(process.env.LD_LIBRARY_PATH.split(':').at(-1), '/caller/lib');
      }
      process.exitCode = 17;
    JS
    ENV["LD_LIBRARY_PATH"] = "/caller/lib"
    assert_empty shell_output("#{command} hvigor 'staged tools' --probe 'two words'", 17)
    assert_equal "exports.isHarmony = () => false;",
                 (clt/"hvigor/hvigor/node_modules/@ohos/hvigor-common/src/util/system-util.js").read
  end
end
