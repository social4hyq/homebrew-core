class Antigravity < Formula
  desc "Google Antigravity CLI"
  homepage "https://antigravity.google/product/antigravity-cli"
  url "https://storage.googleapis.com/antigravity-public/antigravity-cli/" \
      "1.5.15-5514532022517760/linux-arm/cli_linux_arm64.tar.gz"
  version "1.5.15"
  sha256 "e5b5d7ca1dda2cfdc0b09c72931320c3ef5c481a14dbda137304107ce6e776b1"
  license :cannot_represent # Google Terms of Service; the CLI is a closed-source native binary
  revision 1

  livecheck do
    url "https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/linux_arm64.json"
    regex(/"version"\s*:\s*"(\d+(?:\.\d+)+)"/i)
  end

  depends_on "glibc"
  depends_on "ohos-selfsign"
  depends_on "patchelf"

  def install
    # The bottle ships no vendor binary: the official CLI is downloaded and
    # prepared on the user's device by the install step below.
    rm_r buildpath.children

    (bin/"agy").write <<~SH
      #!/bin/sh
      set -eu
      # The CLI self-updates in the background and would replace the signed
      # binary with an unsigned one, which OHOS refuses to execute.
      export AGY_CLI_DISABLE_AUTO_UPDATE="${AGY_CLI_DISABLE_AUTO_UPDATE:-true}"
      export TMPDIR="${TMPDIR:-/data/storage/el2/base/cache}"
      exec "$HOMEBREW_PREFIX/var/#{name}/#{pkg_version}/agy" "$@"
    SH
    chmod 0755, bin/"agy"

    (libexec/"install-agy.sh").write <<~SH
      set -eu
      prefix="$1"
      target="${3:-$prefix/var/#{name}/#{pkg_version}}"
      work=$(mktemp -d "$2/agy-install.XXXXXX")
      pending=""
      trap 'rm -rf "$work"; [ -z "$pending" ] || rm -f "$pending"' EXIT
      trap 'exit 1' HUP INT TERM
      cd "$work"
      found=""
      for url in "#{stable.url}" "https://github.com/google-antigravity/antigravity-cli/releases/download/#{version}/agy_cli_linux_arm64.tar.gz"; do
        rm -f payload.tar.gz
        if curl -fsSL --retry 5 --retry-all-errors --connect-timeout 30 -o payload.tar.gz "$url" &&
           echo "#{stable.checksum}  payload.tar.gz" | sha256sum -c - >/dev/null 2>&1; then
          found="$url"
          break
        fi
      done
      [ -n "$found" ] || { echo "failed to download the official Antigravity CLI" >&2; exit 1; }
      tar -xzf payload.tar.gz
      mkdir -p "$target"
      pending=$(mktemp "$target/.agy.XXXXXX")
      cp antigravity "$pending"
      "$prefix/opt/patchelf/bin/patchelf" --set-interpreter "$prefix/opt/glibc/lib/ld-linux-aarch64.so.1" "$pending"
      "$prefix/opt/ohos-selfsign/bin/selfsign" "$pending"
      chmod +x "$pending"
      mv -f "$pending" "$target/agy"
      if [ -z "${3:-}" ]; then
        find "$prefix/var/#{name}" -mindepth 1 -maxdepth 1 -type d \
          ! -name "#{pkg_version}" -exec rm -rf {} +
      fi
    SH
  end

  post_install_steps do
    run "/usr/bin/sh",
        args: ["{{libexec}}/install-agy.sh", "{{HOMEBREW_PREFIX}}", "{{temp}}"],
        writable_paths: ["{{var}}/{{formula_name}}", "{{temp}}"], network_access: true
  end

  test do
    system "/usr/bin/sh", libexec/"install-agy.sh", HOMEBREW_PREFIX, testpath, testpath/"runtime"
    assert_match version.to_s, shell_output("#{testpath}/runtime/agy --version")
  end
end
