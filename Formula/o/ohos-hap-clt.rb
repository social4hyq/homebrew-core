class OhosHapClt < Formula
  desc "Stage pinned HarmonyOS command-line tools for HAP builds"
  homepage "https://developer.huawei.com/consumer/cn/download/command-line-tools-for-hmos"
  url "https://s3.oheco.org/command-line-tools/26.0.0.201/commandline-tools-harmonyos-26.0.0.201.tar.gz"
  sha256 "60929c00ae486cc038ea48145497ad34dbd4ac6a25c3f2fa895ce74afb4607f5"
  license :cannot_represent
  revision 1

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/ohos-hap-clt-v26.0.0.201-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1f205bdfcd17b224d1acd5e58226aefbeda0aeb7d646faacf3a1a955a2763515"
  end

  depends_on "curl"
  depends_on "gnu-tar"
  depends_on "node"

  def install
    entries = %w[hvigor/bin/hvigorw.js ohpm/bin/pm-cli.js]
    entries.each do |entry|
      odie "CLT archive missing #{entry}" unless (buildpath/entry).file?
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
      const { execFileSync } = require('node:child_process');
      const usage = 'Usage: ohos-hap-clt stage DEST [ARCHIVE]';

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

      const [command, destination, archive, ...extra] = process.argv.slice(2);
      if (command === '--help' && destination === undefined) {
        console.log(usage);
      } else if (command !== 'stage' || !destination || extra.length) {
        console.error(usage);
        process.exitCode = 1;
      } else {
        stage(destination, archive).catch(error => {
          console.error(`ohos-hap-clt: ${error.message}`);
          process.exitCode = 1;
        });
      }
    SCRIPT
    (bin/"ohos-hap-clt").write_env_script formula_opt_bin("node")/"node", "\"#{tool}\"", {}
  end

  test do
    command = bin/"ohos-hap-clt"
    assert_match "Usage: ohos-hap-clt stage DEST [ARCHIVE]", shell_output("#{command} --help")
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
  end
end
