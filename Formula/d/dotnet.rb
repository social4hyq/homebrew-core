class Dotnet < Formula
  OHOS_SOURCE_REVISION = "c1cb05c3b2e5b716c3de646ad4faca670ac11610".freeze

  desc ".NET Core"
  homepage "https://dotnet.microsoft.com/"
  license "MIT"
  version_scheme 1
  compatibility_version 9

  stable do
    if OS.ohos?
      # OpenHarmony runtime and SDK support are both present in dotnet/dotnet#11131.
      url "https://github.com/dotnet/dotnet/archive/c1cb05c3b2e5b716c3de646ad4faca670ac11610.tar.gz"
      sha256 "dae70ac6f5214695dd8a15949d6070b99ca67c56a36cda6601ae91fc26f5a542"
      version "12.0.100-alpha"
      patch do
        file "Patches/dotnet/0001-bootstrap-cached-artifacts.patch"
      end
      patch do
        file "Patches/dotnet/0002-ohos-build-tools-and-libraries.patch"
      end
      patch do
        file "Patches/dotnet/0003-ohos-shim-system-serialization-forwards.patch"
      end
      patch do
        file "Patches/dotnet/0004-ohos-unix-managed-library-fallback.patch"
      end
      patch do
        file "Patches/dotnet/0005-ohos-sign-generated-apphosts.patch"
      end
      patch do
        file "Patches/dotnet/0006-ohos-run-native-build-tools.patch"
      end
      patch do
        file "Patches/dotnet/0007-ohos-drop-statically-linked-host-libraries.patch"
      end
      patch do
        file "Patches/dotnet/0008-ohos-aspnetcore-runtime-build.patch"
      end
      patch do
        file "Patches/dotnet/0009-ohos-ilasm-duplicate-package-assets.patch"
      end
      patch do
        file "Patches/dotnet/0010-ohos-nuget-trust-store.patch"
      end
      next
    end

    # Source-build tag announced at https://github.com/dotnet/source-build/discussions
    url "https://github.com/dotnet/dotnet/releases/download/v11.0.100/release.json"
    sha256 "007b0ad9b0cf567e35fab4db99fd01310e906e8566f57b437141ca314edc30cd"

    resource "src" do
      url "https://github.com/dotnet/dotnet/archive/refs/tags/v11.0.100.tar.gz"
      sha256 "d133a74d6bb0b7eccdbfc96bf81950767691c08f88f9e25a374de92ab4d31b34"

      livecheck do
        formula :parent
      end

      on_macos do
        # FIXME: Workaround for brew sandbox. See if upstream can add support to override /tmp
        patch do
          file "Patches/dotnet/brew-sandbox-workaround.diff"
          type :unofficial
        end
      end
    end

    resource "1xx" do
      url "https://github.com/dotnet/dotnet/archive/refs/tags/v11.0.100.tar.gz"
      sha256 "d133a74d6bb0b7eccdbfc96bf81950767691c08f88f9e25a374de92ab4d31b34"

      livecheck do
        url "https://github.com/dotnet/dotnet/releases/download/v#{LATEST_VERSION}/release.json"
        regex(/^v?(\d+\.\d+\.1\d\d)$/i)
        strategy :json do |json, regex|
          channel_url = "https://builds.dotnet.microsoft.com/dotnet/release-metadata/#{json["channel"]}/releases.json"
          channel_json = JSON.parse(Homebrew::Livecheck::Strategy.page_content(channel_url)[:content])
          latest_release = channel_json["releases"]&.find { |release| release["release-version"] == json["release"] }
          next if latest_release.blank?

          latest_release["sdks"]&.filter_map do |sdk|
            sdk["version"]&.[](regex, 1)
          end
        end
      end

      on_macos do
        # FIXME: Workaround for brew sandbox. See if upstream can add support to override /tmp
        patch do
          file "Patches/dotnet/brew-sandbox-workaround.diff"
          type :unofficial
        end

        # FIXME: Skip installer build on macOS - prevents CreatePkg target errors
        patch do
          file "Patches/dotnet/skipinstallerbuild.diff"
          type :unofficial
          resolves "https://github.com/dotnet/runtime/issues/122832"
        end
      end

      # Avoid OpenSSL APIs missing from the shim with OpenSSL 4.1
      patch do
        url "https://github.com/dotnet/runtime/commit/d89205572858c883d9ab16a3089a13782e7f4d7e.patch?full_index=1"
        sha256 "9228a8475b8e6e2b21b007ef86fc059d0885f52cef456781a2b223e6767e6b36"
        directory "src/runtime"
        type :backport
        resolves "https://github.com/dotnet/runtime/pull/136435"
      end
    end

    resource "1xx-manifest" do
      url "https://github.com/dotnet/dotnet/releases/download/v11.0.100/release.json"
      sha256 "007b0ad9b0cf567e35fab4db99fd01310e906e8566f57b437141ca314edc30cd"

      livecheck do
        url "https://github.com/dotnet/dotnet/releases/download/v#{LATEST_VERSION}/release.json"
        regex(/^v?(\d+\.\d+\.1\d\d)$/i)
        strategy :json do |json, regex|
          channel_url = "https://builds.dotnet.microsoft.com/dotnet/release-metadata/#{json["channel"]}/releases.json"
          channel_json = JSON.parse(Homebrew::Livecheck::Strategy.page_content(channel_url)[:content])
          latest_release = channel_json["releases"]&.find { |release| release["release-version"] == json["release"] }
          next if latest_release.blank?

          latest_release["sdks"]&.filter_map do |sdk|
            sdk["version"]&.[](regex, 1)
          end
        end
      end
    end
  end

  if OS.ohos?
    livecheck do
      skip "OpenHarmony uses a pinned .NET 12 prerelease commit"
    end
  else
    # Check blob storage JSON so that resources' livechecks work during version bump
    livecheck do
      url "https://builds.dotnet.microsoft.com/dotnet/release-metadata/releases-index.json"
      regex(/^v?(\d+\.\d+\.\d{3})$/i)
      strategy :json do |json, regex|
        json["releases-index"]&.filter_map do |channel|
          next if channel["support-phase"] != "active"

          channel["latest-sdk"]&.[](regex, 1)
        end
      end
    end
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/dotnet-v12.0.100-alpha-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "aabb50961f7b0fe99d7a0cedb77bfd089ab204b463537b413ebe4c75616a4256"
  end

  head do
    url "https://github.com/dotnet/dotnet.git", branch: "main"

    on_macos do
      depends_on xcode: :build # for xcodebuild
    end
  end

  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => :build
  depends_on "rapidjson" => :build
  depends_on "brotli"
  depends_on "icu4c@79"
  depends_on "openssl@4"
  depends_on "zstd"

  uses_from_macos "cpio" => :build
  uses_from_macos "python" => :build
  uses_from_macos "krb5"

  on_macos do
    depends_on "bash" => :build
    depends_on "grep" => :build # grep: invalid option -- P
  end

  if OS.ohos?
    depends_on "binutils" => :build
    depends_on "patchelf" => :build
    depends_on "xz" => :build
    depends_on "ohos-selfsign"

    # The Linux musl SDK bootstrap needs robust mutex APIs absent from OpenHarmony's libc.
    resource "bootstrap-sdk" do
      url "https://ci.dot.net/public/Sdk/12.0.100-alpha.1.26557.102/" \
          "dotnet-sdk-12.0.100-alpha.1.26557.102-linux-arm64.tar.gz"
      sha256 "e6b8a22505b6f4ba27bd80238c74fcb56764994d8145fe7db0b54e48d767e6a8"
    end

    resource "bootstrap-artifacts" do
      url "https://ci.dot.net/public/source-build/" \
          "Private.SourceBuilt.Artifacts.12.0.100-alpha.1.26557.102.centos.10-x64.tar.gz", using: :nounzip
      sha256 "0db28070aea111ba1c0c950dc37f056e3ea4fd3690534c81065a93b96a473302"
    end

    resource "bootstrap-glibc" do
      url "https://harmonybrew.atomgit.com/bottles/glibc-2.39_4.arm64_ohos.bottle.tar.gz"
      sha256 "52690e1a0e44df4f58b08c28203f3b7e8076c0b6cb08cf7450fa5103bac08976"
    end

    # The OpenHarmony Bash crashes on nested command substitutions in script files.
    resource "bootstrap-bash" do
      url "https://deb.debian.org/debian/pool/main/b/bash/bash-static_5.2.37-2+b10_arm64.deb", using: :nounzip
      sha256 "7353d15a7160940496204ca38b6c00495995c389b4c3946d9b1f83b1b0b7a06e"
    end

    # Use the matching glibc ABI for dependencies of the build-only Linux SDK.
    resource "bootstrap-libgcc" do
      url "https://deb.debian.org/debian/pool/main/g/gcc-12/libgcc-s1_12.2.0-14+deb12u1_arm64.deb", using: :nounzip
      sha256 "576926b283613db80168ddf76380a3bd877602778cf0d226caa7bfbfa71eacf3"
    end

    resource "bootstrap-libstdcxx" do
      url "https://deb.debian.org/debian/pool/main/g/gcc-12/libstdc++6_12.2.0-14+deb12u1_arm64.deb", using: :nounzip
      sha256 "26e138c677a985775331373828a6c286c551ff397cb735d00e2383cb273d1cb2"
    end

    resource "bootstrap-openssl" do
      url "https://deb.debian.org/debian/pool/main/o/openssl/libssl3_3.0.20-1~deb12u2_arm64.deb", using: :nounzip
      sha256 "a256e03cc3abd7243ac5c6ee91a9deb56478221ef0d3c2b0748551e13140c0bf"
    end

    resource "bootstrap-icu" do
      url "https://deb.debian.org/debian/pool/main/i/icu/libicu72_72.1-3+deb12u1_arm64.deb", using: :nounzip
      sha256 "4f5d892fd81110435e45ed0a5f1b12899d7ff989d51db283cbc043f5631646d8"
    end

    resource "bootstrap-zlib" do
      url "https://deb.debian.org/debian/pool/main/z/zlib/zlib1g_1.2.13.dfsg-1_arm64.deb", using: :nounzip
      sha256 "52b8b8a145bbe1956bba82034f77022cbef0c3d0885c9e32d9817a7932fe1913"
    end
  end

  on_linux do
    depends_on "libunwind"
    depends_on "lttng-ust" unless OS.ohos? # CoreCLR disables the LTTng event source on OpenHarmony.
    depends_on "zlib-ng-compat"

    on_intel do
      depends_on "llvm" => :build

      fails_with :gcc do
        cause "Illegal instruction when running crossgen2"
      end
    end
  end

  resource "docfx", :test do
    url "https://github.com/dotnet/docfx/archive/refs/tags/v2.81.0.tar.gz"
    sha256 "55b492cab70a7f883ea5e9a7a134a23d25d70e97153b61d1083ad6b5fa6e2d68"

    livecheck do
      url "https://formulae.brew.sh/api/formula/docfx.json"
      strategy :json do |json|
        json.dig("versions", "stable")
      end
    end
  end

  # Perform "1xx" or "2xx/3xx/4xx" Band Bootstrap. Skipping stage 2 as didn't work via documented steps
  # https://github.com/dotnet/source-build/blob/main/Documentation/feature-band-source-building.md
  def bootstrap_build(with_shared_components: nil)
    prep_args = %w[--no-shared-components] if with_shared_components
    args = %w[
      --clean-while-building
      --source-only
    ]
    # CoreCLR's source-build config cannot find liblttng-ust on OpenHarmony and the
    # LTTng event source is unavailable there. Use system libs but disable LTTng.
    # Keep the option and value as separate argv elements.
    args += OS.ohos? ? %w[--with-system-libs all-lttng] : %w[--with-system-libs all]
    args += ["--release-manifest", "release.json"] if build.stable? && !OS.ohos?
    args += ["--with-shared-components", with_shared_components] if with_shared_components
    on_linux do
      args << "-p:PortableBuild=true"
    end

    if OS.ohos?
      prepare_ohos_bootstrap
      archive = Pathname.pwd/"prereqs/packages/archive"
      resource("bootstrap-artifacts").stage { archive.install Pathname.pwd.children }
      prep_args = %w[--no-sdk --bootstrap-rid linux-arm64]
      args += %w[--os openharmony --arch arm64 --rid openharmony-arm64]
      args += ["--source-repository", "https://github.com/dotnet/dotnet", "--source-version", OHOS_SOURCE_REVISION]
    end

    # FIXME: Workaround for brew sandbox. See if upstream can add support to override /tmp
    on_macos do
      # `prep-source-build.sh` runs binary detection with the prebuilt SDK, so patch its MSBuild first
      system "./prep-source-build.sh", "--no-binary-removal", *prep_args
      # Avoid worker nodes and the task hosts of `Directory.Build.rsp`'s `/mt`,
      # which the unpatched bootstrap MSBuild cannot reach
      system ".dotnet/dotnet", "build", "src/msbuild/src/MSBuild/MSBuild.csproj", "--configuration", "Release",
             "-maxcpucount:1", "-noAutoResponse"
      # Replace the bootstrap SDK's MSBuild with the patched one
      cp Dir["src/msbuild/artifacts/bin/MSBuild/Release/net*/{MSBuild,Microsoft.Build*}.dll"],
         Dir[".dotnet/sdk/*"].first
      # `build.sh` builds MSBuild again into the same directory
      rm_r "src/msbuild/artifacts"
    end
    system "./prep-source-build.sh", *prep_args
    prepare_ohos_il_tools if OS.ohos?
    system "./build.sh", *args
    buildpath.install "artifacts/assets/Release"
  end

  def prepare_ohos_bootstrap
    sdk = Pathname.pwd/".dotnet"
    bootstrap_bin = buildpath/"bootstrap-bin"
    bootstrap_lib = buildpath/"bootstrap-lib"
    resource("bootstrap-sdk").stage { sdk.install Pathname.pwd.children }
    resource("bootstrap-glibc").stage do
      glibc_lib = Pathname.glob("**/lib/ld-linux-aarch64.so.1").fetch(0).dirname
      bootstrap_lib.install glibc_lib.glob("*.so.*")
    end
    %w[bash libgcc libstdcxx openssl icu zlib].each do |name|
      resource("bootstrap-#{name}").stage do
        system formula_opt_bin("binutils")/"ar", "x", Pathname.glob("*.deb").fetch(0)
        system "tar", "-I", formula_opt_bin("xz")/"xz", "-xf", "data.tar.xz"
        if name == "bash"
          bootstrap_bin.install "usr/bin/bash-static" => "bash"
        else
          bootstrap_lib.install Pathname.glob("{lib,usr/lib}/aarch64-linux-gnu/*.so*")
        end
      end
    end
    ENV.prepend_path "PATH", bootstrap_bin

    # Keep the Linux SDK's loader and libraries out of the environment of the OHOS compiler.
    sdk.glob("**/*").each do |path|
      next if !path.file? || !path.executable?

      elf = BinaryPathname.wrap(path)
      next unless elf.elf?
      next if elf.interpreter != "/lib/ld-linux-aarch64.so.1"

      use_bootstrap_loader path
    end
  end

  def prepare_ohos_il_tools
    bootstrap_bin = buildpath/"bootstrap-bin"
    # Source-build-assets executes ILAsm and ILDasm from the host packages restored by prep-source-build.sh.
    { "ilasm" => "ILAsm", "ildasm" => "ILDAsm" }.each do |tool, package|
      package_path = Pathname.glob("prereqs/packages/previously-source-built/runtime.linux-arm64.Microsoft.NETCore." \
                                   "#{package}.*.nupkg").fetch(0)
      system "unzip", "-jo", package_path, "runtimes/linux-arm64/native/#{tool}", "-d", bootstrap_bin
      executable = bootstrap_bin/tool
      executable.chmod(0755)
      use_bootstrap_loader executable
      ENV["#{package}ToolPath"] = bootstrap_bin.to_s
    end
  end

  def use_bootstrap_loader(path)
    bootstrap_lib = buildpath/"bootstrap-lib"
    system formula_opt_bin("patchelf")/"patchelf", "--force-rpath", "--set-rpath", bootstrap_lib,
           "--set-interpreter", bootstrap_lib/"ld-linux-aarch64.so.1", path
  end

  def install
    odie "Use the pinned source version on OpenHarmony" if OS.ohos? && build.head?

    # Make sure CoreCLR builds with our compiler shims
    ENV["CLR_CC"] = which(ENV.cc)
    ENV["CLR_CXX"] = which(ENV.cxx)
    ENV["DOTNET_CLI_TELEMETRY_OPTOUT"] = "1"

    if OS.mac?
      # Need GNU grep (Perl regexp support) to use release manifest rather than git repo
      ENV.prepend_path "PATH", formula_opt_libexec("grep")/"gnubin"

      # Avoid mixing CLT and Xcode.app when building CoreCLR component which can
      # cause undefined symbols, e.g. __swift_FORCE_LOAD_$_swift_Builtin_float
      ENV["SDKROOT"] = MacOS.sdk_for_formula(self).path
    elsif OS.ohos?
      ENV["OHOS_NDK_HOME"] = "/opt/ohos-sdk/ohos"
      ENV["DotNetOhosSystemRoot"] = HOMEBREW_PREFIX.to_s
      %w[brotli icu4c@79 krb5 libunwind openssl@4 rapidjson zlib-ng-compat zstd].each do |name|
        ENV.prepend_path "CMAKE_PREFIX_PATH", formula_opt_prefix(name)
      end
    else
      ENV.append_path "LD_LIBRARY_PATH", dep("icu4c").opt_lib
    end

    if build.head? || OS.ohos?
      (buildpath/"dotnet").install buildpath.children
    else
      odie "Update src resource to #{version}!" if version != resource("src").version
      odie "Update 1xx resource to #{version}!" if version != resource("1xx").version && version.patch.to_i < 200
      odie "Update 1xx and/or 1xx-manifest resource!" if resource("1xx").version != resource("1xx-manifest").version
      (buildpath/"dotnet").install resource("1xx"), resource("1xx-manifest")

      release = JSON.parse(File.read("release.json"))["release"]
      release_1xx = JSON.parse(File.read("dotnet/release.json"))["release"]
      odie "1xx resource uses .NET Runtime #{release_1xx} but was expecting #{release}!" if release != release_1xx
    end

    cd "dotnet" do
      bootstrap_build
    end

    if build.stable? && !OS.ohos? && version.patch.to_i >= 200
      mkdir "1xx-artifacts"
      system "tar", "-ozxvf", Dir["Release/Private.SourceBuilt.Artifacts.*.tar.gz"].first, "-C", "1xx-artifacts"
      rm_r(["Release", "dotnet"])
      (buildpath/"dotnet").install resource("src"), "release.json"

      cd "dotnet" do
        bootstrap_build with_shared_components: buildpath/"1xx-artifacts"
      end
    end

    libexec.mkpath
    sdk_archive = OS.ohos? ? "Release/dotnet-sdk-*-openharmony-arm64.tar.gz" : "Release/dotnet-sdk-*.tar.gz"
    tarball = buildpath.glob(sdk_archive).first
    odie "No SDK archive found matching #{sdk_archive}" if tarball.nil?
    system "tar", "--extract", "--file", tarball, "--directory", libexec

    if OS.linux?
      # Source-only builds default `KeepNativeSymbols` to true, so the native
      # binaries keep their DWARF. That leaves build paths in the binaries and
      # adds hundreds of MB to the x86_64 bottle. Upstream asks packagers to
      # strip downstream rather than flip that switch, see
      # https://github.com/dotnet/source-build/blob/main/Documentation/debugging-support.md
      # `--strip-debug` keeps `.symtab`, so native frames still symbolise, and
      # unlike an `--only-keep-debug` split it leaves no `.dbg` files behind.
      native_binaries = libexec.glob("**/*").select { |path| path.file? && BinaryPathname.wrap(path).elf? }
      system "strip", "--strip-debug", "--preserve-dates", *native_binaries
    end

    doc.install libexec.glob("*.txt")
    dotnet_env = { DOTNET_ROOT: libexec }
    dotnet_env[:PATH] = "#{formula_opt_bin("ohos-selfsign")}:$PATH" if OS.ohos?
    (bin/"dotnet").write_env_script libexec/"dotnet", dotnet_env

    bash_completion.install "dotnet/src/sdk/scripts/register-completions.bash" => "dotnet"
    zsh_completion.install "dotnet/src/sdk/scripts/register-completions.zsh" => "_dotnet"
    man1.install Utils::Gzip.compress(*buildpath.glob("dotnet/src/sdk/documentation/manpages/sdk/*.1"))
    man7.install Utils::Gzip.compress(*buildpath.glob("dotnet/src/sdk/documentation/manpages/sdk/*.7"))
  end

  def caveats
    <<~CAVEATS
      For other software to find dotnet you may need to set:
        export DOTNET_ROOT="#{opt_libexec}"
    CAVEATS
  end

  test do
    ENV["XDG_RUNTIME_DIR"] = testpath

    if OS.ohos?
      assert_match(/^\s*RID:\s+openharmony(?:\.\d+)?-arm64\s*$/, shell_output("#{bin}/dotnet --info"))
      runtimes = shell_output("#{bin}/dotnet --list-runtimes")
      assert_match "Microsoft.NETCore.App #{version.major_minor}.", runtimes
      assert_match "Microsoft.AspNetCore.App #{version.major_minor}.", runtimes
    else
      assert_match version.to_s, shell_output("#{bin}/dotnet --version")
    end

    target_framework = "net#{version.major_minor}"

    (testpath/"test.cs").write <<~CS
      using System;

      namespace Homebrew
      {
        public class Dotnet
        {
          public static void Main(string[] args)
          {
            var joined = String.Join(",", args);
            Console.WriteLine(joined);
          }
        }
      }
    CS

    (testpath/"test.csproj").write <<~XML
      <Project Sdk="Microsoft.NET.Sdk">
        <PropertyGroup>
          <OutputType>Exe</OutputType>
          <TargetFrameworks>#{target_framework}</TargetFrameworks>
          <PlatformTarget>AnyCPU</PlatformTarget>
          <RootNamespace>Homebrew</RootNamespace>
          <PackageId>Homebrew.Dotnet</PackageId>
          <Title>Homebrew.Dotnet</Title>
          <Product>$(AssemblyName)</Product>
          <EnableDefaultCompileItems>false</EnableDefaultCompileItems>
        </PropertyGroup>
        <ItemGroup>
          <Compile Include="test.cs" />
        </ItemGroup>
      </Project>
    XML

    system bin/"dotnet", "build", "--framework", target_framework, "--output", testpath, testpath/"test.csproj"
    output = shell_output("#{bin}/dotnet run --framework #{target_framework} #{testpath}/test.dll a b c")
    assert_equal "#{testpath}/test.dll,a,b,c\n", output

    if OS.ohos?
      ENV["DOTNET_ROOT"] = libexec.to_s
      assert_equal "a,b,c\n", shell_output("#{testpath}/test a b c")
    end

    # Test to avoid uploading broken bottle, see https://github.com/Homebrew/homebrew-core/issues/197546
    resource("docfx").stage do
      restore_args = %w[--disable-build-servers --no-cache]
      restore_args << "-p:UseAppHost=false" if OS.ohos?
      system bin/"dotnet", "restore", "src/docfx", *restore_args
    end
  end
end
