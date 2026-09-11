class PostgresqlAT18 < Formula
  desc "Object-relational database system"
  homepage "https://www.postgresql.org/"
  url "https://ftp.postgresql.org/pub/source/v18.6/postgresql-18.6.tar.bz2"
  sha256 "555610c24d53e4316da5b7d3fc25c279d96856d5e0e23ee308c328c5fa881d9f"
  license "PostgreSQL"
  revision 1

  livecheck do
    url "https://ftp.postgresql.org/pub/source/"
    regex(%r{href=["']?v?(18(?:\.\d+)+)/?["' >]}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e6e317342769abd2275be1a48bcff0d12ccdc30516fbae047b13f48900b185b8"
  end

  keg_only :versioned_formula

  # https://www.postgresql.org/support/versioning/
  deprecate! date: "2030-11-14", because: :unsupported

  depends_on "docbook" => :build
  depends_on "docbook-xsl" => :build
  depends_on "gettext" => :build
  depends_on "pkgconf" => :build
  depends_on "icu4c@78"
  # GSSAPI provided by Kerberos.framework crashes when forked.
  # See https://github.com/Homebrew/homebrew-core/issues/47494.
  depends_on "krb5"
  depends_on "lz4"
  depends_on "openssl@3"
  depends_on "readline"
  depends_on "zstd"

  uses_from_macos "bison" => :build
  uses_from_macos "flex" => :build
  uses_from_macos "libxml2"
  uses_from_macos "libxslt"
  uses_from_macos "openldap"
  uses_from_macos "perl"

  on_macos do
    depends_on "gettext"
  end

  on_linux do
    depends_on "linux-pam"
    depends_on "util-linux"
    depends_on "zlib-ng-compat"
  end

  # HarmonyOS adaptations:
  # — fallback to PGUSER/USER/LOGNAME env vars when getpwuid fails (UID not in /etc/passwd)
  #      covers: src/interfaces/libpq/fe-auth.c (libpq) + src/common/username.c (initdb/psql/pg_ctl)
  # — default directory/file modes permit group access (filesystem UID remapping)
  # — default unix_socket_directories to /data/storage/el2/base/haps/entry/files (/tmp is read-only)
  # — skip data dir permission/ownership checks (UID/permissions not portable)
  # — hardcode initdb defaults (UTF-8) + force mmap DSM (initdb matches backend)
  # — skip SysV shmget for main shared memory (HarmonyOS seccomp blocks shmget)
  # — force DSM implementation to mmap (avoid shm_open)
  patch do
    file "Patches/postgresql@18/fe-auth-username-fallback.patch"
  end
  patch do
    file "Patches/postgresql@18/file-perm-group-default.patch"
  end
  patch do
    file "Patches/postgresql@18/pg-config-no-unix-socket.patch"
  end
  patch do
    file "Patches/postgresql@18/miscinit-relaxed-perm-check.patch"
  end
  patch do
    file "Patches/postgresql@18/initdb-hardcode-defaults.patch"
  end
  patch do
    file "Patches/postgresql@18/skip-sysv-shmem.patch"
  end
  patch do
    file "Patches/postgresql@18/dsm-mmap-default.patch"
  end

  def install
    # Modify Makefile to link macOS binaries using Cellar path. Otherwise, binaries are linked
    # using #{HOMEBREW_PREFIX}/lib path set during ./configure, which will cause audit failures
    # for broken linkage as the paths are not created until post-install step.
    inreplace "src/Makefile.shlib", "-install_name '$(libdir)/", "-install_name '#{lib}/postgresql/"

    ENV["XML_CATALOG_FILES"] = etc/"xml/catalog"
    ENV.runtime_cpu_detection
    ENV.delete "PKG_CONFIG_LIBDIR"
    ENV.prepend "LDFLAGS", "-L#{Formula["openssl@3"].opt_lib} -L#{Formula["readline"].opt_lib}"
    ENV.prepend "CPPFLAGS", "-I#{Formula["openssl@3"].opt_include} -I#{Formula["readline"].opt_include}"

    # Fix 'libintl.h' file not found for extensions
    # Update config to fix `error: could not find function 'gss_store_cred_into' required for GSSAPI`
    if OS.mac?
      ENV.prepend "LDFLAGS", "-L#{Formula["gettext"].opt_lib} -L#{Formula["krb5"].opt_lib}"
      ENV.prepend "CPPFLAGS", "-I#{Formula["gettext"].opt_include} -I#{Formula["krb5"].opt_include}"
    end

    args = %W[
      --datadir=#{HOMEBREW_PREFIX}/share/#{name}
      --includedir=#{HOMEBREW_PREFIX}/include/#{name}
      --sysconfdir=#{etc}
      --docdir=#{doc}
      --enable-nls
      --enable-thread-safety
      --with-gssapi
      --with-icu
      --with-ldap
      --with-libxml
      --with-libxslt
      --with-lz4
      --with-zstd
      --with-openssl
      --with-pam
      --with-perl
      --with-uuid=e2fs
    ]
    args << "--with-extra-version= (#{tap.user})" if tap
    args += %w[--with-bonjour --with-tcl] if OS.mac?

    # PostgreSQL by default uses xcodebuild internally to determine this,
    # which does not work on CLT-only installs.
    args << "PG_SYSROOT=#{MacOS.sdk_path}" if OS.mac?

    system "./configure", *args, *std_configure_args(libdir: HOMEBREW_PREFIX/"lib/#{name}")
    system "make"
    # We use an unversioned `postgresql` subdirectory rather than `#{name}` so that the
    # post-installed symlinks can use non-conflicting `#{name}` and be retained on `brew unlink`.
    # Removing symlinks may break PostgreSQL as its binaries expect paths from ./configure step.
    system "make", "install-world", "datadir=#{share}/postgresql",
                                    "libdir=#{lib}/postgresql",
                                    "includedir=#{include}/postgresql"

    # Modify the Makefile back so dependents pick up common path
    makefile = lib/"postgresql/pgxs/src/Makefile.shlib"
    inreplace makefile, "-install_name '#{lib}/postgresql/", "-install_name '$(libdir)/"
  end

  def post_install
    (var/"log").mkpath
    postgresql_datadir.mkpath

    # Manually link files from keg to non-conflicting versioned directories in HOMEBREW_PREFIX.
    %w[include lib share].each do |dir|
      dst_dir = HOMEBREW_PREFIX/dir/name
      src_dir = prefix/dir/"postgresql"
      src_dir.find do |src|
        dst = dst_dir/src.relative_path_from(src_dir)

        # Retain existing real directories for extensions if directory structure matches
        next if dst.directory? && !dst.symlink? && src.directory? && !src.symlink?

        rm_r(dst) if dst.exist? || dst.symlink?
        if src.symlink? || src.file?
          Find.prune if src.basename.to_s == ".DS_Store"
          dst.parent.install_symlink src
        elsif src.directory?
          dst.mkpath
        end
      end
    end

    # Also link versioned executables
    bin.each_child { |f| (HOMEBREW_PREFIX/"bin").install_symlink f => "#{f.basename}-#{version.major}" }
  end

  def postgresql_datadir
    var/name
  end

  def postgresql_log_path
    var/"log/#{name}.log"
  end

  def pg_version_exists?
    (postgresql_datadir/"PG_VERSION").exist?
  end

  def caveats
    <<~EOS
      To initialize a database cluster:
        export PGUSER=currentUser
        initdb --locale=en_US.UTF-8 -E UTF-8 #{postgresql_datadir}

      To start the server (run in background):
        export PGUSER=currentUser
        pg_ctl -D #{postgresql_datadir} -l #{postgresql_log_path} start

      To stop the server:
        pg_ctl -D #{postgresql_datadir} stop

      Client utilities (psql, createdb, etc.) require PGUSER env var.
      Add to your shell profile for convenience:
        export PGUSER=currentUser

      When uninstalling, some dead symlinks are left behind so you may want to run:
        brew cleanup --prune-prefix
    EOS
  end

  test do
    [bin/"pg_config", HOMEBREW_PREFIX/"bin/pg_config-#{version.major}"].each do |pg_config|
      assert_equal "#{HOMEBREW_PREFIX}/share/#{name}", shell_output("#{pg_config} --sharedir").chomp
      assert_equal "#{HOMEBREW_PREFIX}/lib/#{name}", shell_output("#{pg_config} --libdir").chomp
      assert_equal "#{HOMEBREW_PREFIX}/lib/#{name}", shell_output("#{pg_config} --pkglibdir").chomp
      assert_equal "#{HOMEBREW_PREFIX}/include/#{name}", shell_output("#{pg_config} --pkgincludedir").chomp
      assert_equal "#{HOMEBREW_PREFIX}/include/#{name}/server", shell_output("#{pg_config} --includedir-server").chomp
      assert_match "-I#{Formula["gettext"].opt_include}", shell_output("#{pg_config} --cppflags") if OS.mac?
    end
  end
end
