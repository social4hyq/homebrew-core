class PhpAT84 < Formula
  desc "General-purpose scripting language"
  homepage "https://www.php.net/"
  # Should only be updated if the new version is announced on the homepage, https://www.php.net/
  url "https://www.php.net/distributions/php-8.4.25.tar.xz"
  mirror "https://fossies.org/linux/www/php-8.4.25.tar.xz"
  sha256 "dc1ad8b4109898d9db49744450403874858c23efc685b1032a50bd1e83906848"
  license all_of: [
    "PHP-3.01",

    # Extra licenses not documented in README.REDIST.BINS
    "Zend-2.0", # Zend/LICENSE
    "BSL-1.0",  # Zend/asm/LICENSE
    "MIT",      # ext/date/lib/LICENSE.rst

    # Extra licenses documented in README.REDIST.BINS ignoring unbundled pcre2lib (3) and gd (13)
    # ref: https://github.com/php/php-src/blob/PHP-8.4/README.REDIST.BINS
    "Apache-1.0",            # 10
    "Apache-2.0",            # 20
    "bcrypt-Solar-Designer", # 5
    "BSD-2-Clause-Darwin",   # 1
    "BSD-2-Clause",          # 14, 18, 19, 21; also TSRM/LICENSE
    "BSD-3-Clause",          # 4, 6, 11, 12, 15
    "BSD-4-Clause-UC",       # 9
    "ISC",                   # 10
    "LGPL-2.1-only",         # 2
    "LGPL-2.1-or-later",     # 16
    "OLDAP-2.8",             # 17
    "TCL",                   # 7
    "Zlib",                  # 8
  ]
  compatibility_version 1

  livecheck do
    url "https://www.php.net/downloads?source=Y"
    regex(/href=.*?php[._-]v?(#{Regexp.escape(version.major_minor)}(?:\.\d+)*)\.t/i)
  end

  bottle do
    sha256 arm64_tahoe:   "30b20b3a48e3df37abf6bde328c4d0d5288475d63fd49105064d506b23582f3c"
    sha256 arm64_sequoia: "0defe3137bca2b145971e7b7076449f63e96d914ff1e21e61003131e7ce99443"
    sha256 arm64_sonoma:  "d0a9105f6e70779e9bafd05b42a7123798660811936883592093ee4c2cfe8e7c"
    sha256 arm64_linux:   "ba1bb6cb3c8539a085aba5aa7c45f74ca4fe5d6ee06933e39956b813e2e8204b"
    sha256 x86_64_linux:  "3f690e642215990e64ef6013ded9029d8941db9a9a0effae1be77ed660bd79b6"
  end

  keg_only :versioned_formula

  # Security Support Until 31 Dec 2028
  # https://www.php.net/supported-versions.php
  deprecate! date: "2028-12-31", because: :unsupported
  disable! date: "2029-12-31", because: :unsupported

  depends_on "httpd" => [:build, :test]
  depends_on "pkgconf" => :build
  depends_on "apr"
  depends_on "apr-util"
  depends_on "argon2"
  depends_on "autoconf"
  depends_on "curl"
  depends_on "freetds"
  depends_on "gd"
  depends_on "gmp"
  depends_on "icu4c@78"
  depends_on "libpq"
  depends_on "libsodium"
  depends_on "libzip"
  depends_on "net-snmp"
  depends_on "oniguruma"
  depends_on "openldap"
  depends_on "openssl@3"
  depends_on "pcre2"
  depends_on "sqlite"
  depends_on "tidy-html5"
  depends_on "unixodbc"

  uses_from_macos "xz" => :build
  uses_from_macos "bzip2"
  uses_from_macos "libedit"
  uses_from_macos "libffi"
  uses_from_macos "libxml2"
  uses_from_macos "libxslt"

  on_macos do
    depends_on "gettext"
  end

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    inreplace "configure" do |s|
      s.gsub! "$APXS_HTTPD -V 2>/dev/null | grep 'threaded:.*yes' >/dev/null 2>&1",
              "false"
      s.gsub! "APXS_LIBEXECDIR='$(INSTALL_ROOT)'$($APXS -q LIBEXECDIR)",
              "APXS_LIBEXECDIR='$(INSTALL_ROOT)#{lib}/httpd/modules'"
      s.gsub! "-z $($APXS -q SYSCONFDIR)",
              "-z ''"

      # apxs will interpolate the @ in the versioned prefix: https://bz.apache.org/bugzilla/show_bug.cgi?id=61944
      s.gsub! "LIBEXECDIR='$APXS_LIBEXECDIR'",
              "LIBEXECDIR='" + "#{lib}/httpd/modules".gsub("\\", "\\\\").gsub("@", "\\@") + "'"
    end

    # Update error message in apache sapi to better explain the requirements
    # of using Apache http in combination with php if the non-compatible MPM
    # has been selected. Homebrew has chosen not to support being able to
    # compile a thread safe version of PHP and therefore it is not
    # possible to recompile as suggested in the original message
    inreplace "sapi/apache2handler/sapi_apache2.c",
              "You need to recompile PHP.",
              "Homebrew PHP does not support a thread-safe php binary. " \
              "To use the PHP apache sapi please change " \
              "your httpd config to use the prefork MPM"

    inreplace "sapi/fpm/php-fpm.conf.in", ";daemonize = yes", "daemonize = no"

    config_path = etc/"php/#{version.major_minor}"
    # Prevent system pear config from inhibiting pear install
    (config_path/"pear.conf").delete if (config_path/"pear.conf").exist?

    # Prevent homebrew from hardcoding path to sed shim in phpize script
    ENV["lt_cv_path_SED"] = "sed"

    # Identify build provider in php -v output and phpinfo()
    ENV["PHP_BUILD_PROVIDER"] = tap.user

    if OS.mac?
      sdk_path = MacOS.sdk_for_formula(self).path
      ENV["SASL_CFLAGS"] = "-I#{sdk_path}/usr/include/sasl"
      ENV["SASL_LIBS"] = "-lsasl2"

      # Each extension needs a direct reference to the sdk path or it won't find the headers
      headers_path = "=#{sdk_path}/usr"

      # PHP build system incorrectly links system libraries: https://github.com/php/php-src/issues/10680
      # Homebrew's superenv can only discard these if using realpath of SDK
      ENV["HOMEBREW_SDKROOT"] = sdk_path.realpath
    else
      ENV["SQLITE_CFLAGS"] = "-I#{formula_opt_include("sqlite")}"
      ENV["SQLITE_LIBS"] = "-lsqlite3"
      ENV["BZIP_DIR"] = formula_opt_prefix("bzip2")
    end

    # `_www` only exists on macOS.
    fpm_user = OS.mac? ? "_www" : "www-data"
    fpm_group = OS.mac? ? "_www" : "www-data"

    args = %W[
      --prefix=#{prefix}
      --localstatedir=#{var}
      --sysconfdir=#{config_path}
      --with-config-file-path=#{config_path}
      --with-config-file-scan-dir=#{config_path}/conf.d
      --with-pear=#{pkgshare}/pear
      --enable-bcmath
      --enable-calendar
      --enable-dba
      --enable-exif
      --enable-ftp
      --enable-fpm
      --enable-gd
      --enable-intl
      --enable-mbregex
      --enable-mbstring
      --enable-mysqlnd
      --enable-pcntl
      --enable-phpdbg
      --enable-phpdbg-readline
      --enable-shmop
      --enable-soap
      --enable-sockets
      --enable-sysvmsg
      --enable-sysvsem
      --enable-sysvshm
      --with-apxs2=#{formula_opt_bin("httpd")}/apxs
      --with-bz2#{headers_path}
      --with-curl
      --with-external-gd
      --with-external-pcre
      --with-ffi
      --with-fpm-user=#{fpm_user}
      --with-fpm-group=#{fpm_group}
      --with-gettext=#{formula_opt_prefix("gettext")}
      --with-gmp=#{formula_opt_prefix("gmp")}
      --with-iconv#{headers_path}
      --with-layout=GNU
      --with-ldap=#{formula_opt_prefix("openldap")}
      --with-libxml
      --with-libedit
      --with-mhash#{headers_path}
      --with-mysql-sock=/tmp/mysql.sock
      --with-mysqli=mysqlnd
      --with-ndbm#{headers_path}
      --with-openssl
      --with-password-argon2=#{formula_opt_prefix("argon2")}
      --with-pdo-dblib=#{formula_opt_prefix("freetds")}
      --with-pdo-mysql=mysqlnd
      --with-pdo-odbc=unixODBC,#{formula_opt_prefix("unixodbc")}
      --with-pdo-pgsql=#{formula_opt_prefix("libpq")}
      --with-pdo-sqlite
      --with-pgsql=#{formula_opt_prefix("libpq")}
      --with-pic
      --with-snmp=#{formula_opt_prefix("net-snmp")}
      --with-sodium
      --with-sqlite3
      --with-tidy=#{formula_opt_prefix("tidy-html5")}
      --with-unixODBC
      --with-xsl
      --with-zip
      --with-zlib
    ]

    if OS.mac?
      args << "--enable-dtrace"
      args << "--with-ldap-sasl"
    else
      args << "--disable-dtrace"
      args << "--without-ldap-sasl"
      args << "--without-ndbm"
      args << "--without-gdbm"
    end

    # phpdbg's userfaultfd write-protection watchpoints call
    # pthread_cancel/pthread_setcanceltype, which the OHOS musl libc does not
    # provide, so `phpdbg` would fail to link. Disable the feature by
    # pre-setting the configure cache variable.
    ENV["ac_cv_have_decl_UFFDIO_WRITEPROTECT_MODE_WP"] = "no"

    system "./configure", *args

    # Shared PHP extensions (and the Apache SAPI module `libphp.so`) are
    # linked without the external libraries and resolve their symbols against
    # the main `php` binary / `httpd` process at runtime. This works on glibc
    # (dlopen global scope) but fails on the musl-based OHOS loader ("Error
    # relocating opcache.so: pcre2_code_free_8: symbol not found"). Unlike the
    # httpd modules, the referenced libraries here (pcre2, libxml2, ...) are
    # separate formulae that cannot be marked DF_1_GLOBAL, and an executable's
    # DF_1_GLOBAL does not re-expose its dependencies' symbols, so record
    # NEEDED dependencies on the external libraries for every shared object by
    # adding them to `EXTRA_LDFLAGS` (used by the shared link rule in
    # build/php.m4) with `--as-needed`, so each object only keeps the
    # libraries it actually references. APR/APR-util are needed by `libphp.so`
    # (like the Darwin bundle case in sapi/apache2handler/config.m4).
    php_shared_ldflags = [
      "-Wl,--as-needed",
      "-L#{formula_opt_lib("apr")} -lapr-1 -L#{formula_opt_lib("apr-util")} -laprutil-1",
      "-lpcre2-8 -lxml2 -lxslt -lexslt -lsqlite3 -lssl -lcrypto -lonig",
      "-lcurl -lgd -lgmp -licui18n -licuuc -licuio -lsodium -lzip -lpq",
      "-lsybdb -lodbc -lldap -llber -largon2 -ltidy -lnetsnmp",
      "-lbz2 -ledit -lffi -lz -lintl -lc++_shared",
    ].join(" ")
    inreplace "Makefile" do |s|
      s.gsub!(/^(EXTRA_LDFLAGS ?= ?)(.*)$/, "\\1#{php_shared_ldflags} \\2")
    end

    system "make"
    system "make", "install"

    # Allow pecl to install outside of Cellar
    extension_dir = Utils.safe_popen_read(bin/"php-config", "--extension-dir").chomp
    orig_ext_dir = File.basename(extension_dir)
    inreplace bin/"php-config", lib/"php", prefix/"pecl"

    openssl = Formula["openssl@3"]
    %w[development production].each do |mode|
      inreplace "php.ini-#{mode}" do |s|
        # Allow pecl to install outside of Cellar
        s.gsub! %r{; ?extension_dir = "\./"}, "extension_dir = \"#{HOMEBREW_PREFIX}/lib/php/pecl/#{orig_ext_dir}\""

        # Use OpenSSL cert bundle
        s.gsub!(/; ?openssl\.cafile=/, "openssl.cafile = \"#{openssl.pkgetc}/cert.pem\"")
        s.gsub!(/; ?openssl\.capath=/, "openssl.capath = \"#{openssl.pkgetc}/certs\"")
      end
    end

    config_files = {
      "php.ini-development"   => "php.ini",
      "php.ini-production"    => "php.ini-production",
      "sapi/fpm/php-fpm.conf" => "php-fpm.conf",
      "sapi/fpm/www.conf"     => "php-fpm.d/www.conf",
    }
    config_files.each_value do |dst|
      dst_default = config_path/"#{dst}.default"
      rm dst_default if dst_default.exist?
    end
    config_path.install config_files

    unless (var/"log/php-fpm.log").exist?
      (var/"log").mkpath
      touch var/"log/php-fpm.log"
    end
  end

  def post_install
    configure_php
  end

  def caveats
    <<~EOS
      To enable PHP in Apache add the following to httpd.conf and restart Apache:
          LoadModule php_module #{opt_lib}/httpd/modules/libphp.so

          <FilesMatch \\.php$>
              SetHandler application/x-httpd-php
          </FilesMatch>

      Finally, check DirectoryIndex includes index.php
          DirectoryIndex index.php index.html

      The php.ini and php-fpm.ini file can be found in:
          #{etc}/php/#{version.major_minor}/
    EOS
  end

  service do
    run [opt_sbin/"php-fpm", "--nodaemonize"]
    run_type :immediate
    keep_alive true
    error_log_path var/"log/php-fpm.log"
    working_dir var
  end

  test do
    assert_match(/^Zend OPcache$/, shell_output("#{bin}/php -i"), "Zend OPCache extension not loaded")

    # Test related to libxml2 and https://github.com/Homebrew/homebrew-core/issues/28398
    require "utils/linkage"
    libpq = formula_opt_lib("libpq")/shared_library("libpq")
    assert Utils.binary_linked_to_library?(bin/"php", libpq), "No linkage with Homebrew #{libpq.basename}!"

    port = free_port
    port_fpm = free_port
    expected_output = /^Hello world!$/

    (testpath/"fpm.conf").write <<~INI
      [global]
      daemonize=no
      [www]
      listen = 127.0.0.1:#{port_fpm}
      pm = dynamic
      pm.max_children = 5
      pm.start_servers = 2
      pm.min_spare_servers = 1
      pm.max_spare_servers = 3
    INI

    # Validate the php-fpm configuration using the test's own pool config
    # (which has no `user`), so the check doesn't depend on a pool user that
    # may not exist on the host; the installed config's user is site-specific.
    system sbin/"php-fpm", "-t", "-y", "fpm.conf", "--allow-to-run-as-root"
    system bin/"phpdbg", "-V"
    system bin/"php-cgi", "-m"

    (testpath/"test.php").write <<~PHP
      <?php
      $formatter = new NumberFormatter('en_US', NumberFormatter::DECIMAL);
      echo $formatter->format(1234567), PHP_EOL;

      $formatter = new MessageFormatter('de_DE', '{0,number,#,###.##} MB');
      echo $formatter->format([12345.6789]);
      ?>
    PHP
    assert_equal "1,234,567\n12.345,68 MB", shell_output("#{bin}/php test.php")

    (testpath/"index.php").write <<~PHP
      <?php
      echo 'Hello world!' . PHP_EOL;
      var_dump(ldap_connect());
      $session = new SNMP(SNMP::VERSION_1, '127.0.0.1', 'public');
      var_dump(@$session->get('sysDescr.0'));
    PHP

    main_config = <<~EOS
      Listen #{port}
      ServerName localhost:#{port}
      DocumentRoot "#{testpath}"
      ErrorLog "#{testpath}/httpd-error.log"
      ServerRoot "#{formula_opt_prefix("httpd")}"
      PidFile "#{testpath}/httpd.pid"
      Mutex file:#{testpath} default
      LoadModule authz_core_module lib/httpd/modules/mod_authz_core.so
      LoadModule unixd_module lib/httpd/modules/mod_unixd.so
      LoadModule dir_module lib/httpd/modules/mod_dir.so
      DirectoryIndex index.php
    EOS

    (testpath/"httpd.conf").write <<~EOS
      #{main_config}
      LoadModule mpm_prefork_module lib/httpd/modules/mod_mpm_prefork.so
      LoadModule php_module #{lib}/httpd/modules/libphp.so
      <FilesMatch \\.(php|phar)$>
        SetHandler application/x-httpd-php
      </FilesMatch>
    EOS

    (testpath/"httpd-fpm.conf").write <<~EOS
      #{main_config}
      LoadModule mpm_event_module lib/httpd/modules/mod_mpm_event.so
      LoadModule proxy_module lib/httpd/modules/mod_proxy.so
      LoadModule proxy_fcgi_module lib/httpd/modules/mod_proxy_fcgi.so
      <FilesMatch \\.(php|phar)$>
        SetHandler "proxy:fcgi://127.0.0.1:#{port_fpm}"
      </FilesMatch>
    EOS

    begin
      pid = spawn formula_opt_bin("httpd")/"httpd", "-X", "-f", testpath/"httpd.conf"
      sleep 10
      assert_match expected_output, shell_output("curl -s 127.0.0.1:#{port}")

      Process.kill("TERM", pid)
      Process.wait(pid)

      # php-fpm refuses to run as root without an explicit pool `user`, so
      # allow it when tests run as root (e.g. CI); harmless for non-root users.
      fpm_pid = spawn sbin/"php-fpm", "-y", "fpm.conf", "--allow-to-run-as-root"
      pid = spawn formula_opt_bin("httpd")/"httpd", "-X", "-f", testpath/"httpd-fpm.conf"
      sleep 10
      assert_match expected_output, shell_output("curl -s 127.0.0.1:#{port}")
    ensure
      if pid
        Process.kill("TERM", pid)
        Process.wait(pid)
      end
      if fpm_pid
        Process.kill("TERM", fpm_pid)
        Process.wait(fpm_pid)
      end
    end
  end

  # The harmonybrew fork's `InstallSteps::DSL` doesn't support the upstream
  # `configure_php` step, so replicate it as a classic `post_install` method.
  # Mirrors `Homebrew::InstallSteps::Runner#run_configure_php` from brew HEAD.
  private

  def configure_php
    pear_prefix = pkgshare/"pear"
    channels = [pear_prefix/".channels", pear_prefix/".channels/.alias"]
    channels.select(&:directory?).each { |directory| chmod 0755, directory }
    pear_files = %w[.depdblock .filemap .depdb .lock].map { |file| pear_prefix/file }.select(&:file?)
    pear_files.concat(channels.flat_map do |directory|
      directory.directory? ? directory.children.select(&:file?) : []
    end)
    chmod 0644, pear_files

    # Allow pecl to install outside of Cellar.
    pecl_path = HOMEBREW_PREFIX/"lib/php/pecl"
    pecl_path.mkpath
    prefix_pecl = prefix/"pecl"
    prefix_pecl.unlink if prefix_pecl.symlink?
    File.symlink pecl_path, prefix_pecl unless prefix_pecl.exist?
    php_basename = File.basename(Utils.safe_popen_read(bin/"php-config", "--extension-dir").chomp)
    (pecl_path/php_basename).mkpath

    version_major_minor = version.major_minor
    raise ArgumentError, "PHP configuration requires a version" if version_major_minor.nil?

    # Share PEAR data across PHP versions.
    pear_dir = (name == "php") ? "pear" : "pear@#{version_major_minor}"
    pear_path = HOMEBREW_PREFIX/"share"/pear_dir
    cp_r "#{pear_prefix}/.", pear_path
    php_ext_dir = opt_prefix/"lib/php"/php_basename
    {
      "php_ini"  => etc/"php/#{version_major_minor}/php.ini",
      "php_dir"  => pear_path,
      "doc_dir"  => pear_path/"doc",
      "ext_dir"  => pecl_path/php_basename,
      "bin_dir"  => opt_prefix/"bin",
      "data_dir" => pear_path/"data",
      "cfg_dir"  => pear_path/"cfg",
      "www_dir"  => pear_path/"htdocs",
      "man_dir"  => HOMEBREW_PREFIX/"share/man",
      "test_dir" => pear_path/"test",
      "php_bin"  => opt_prefix/"bin/php",
    }.each do |key, value|
      value.mkpath if /(?<!bin|man)_dir$/.match?(key)
      system bin/"pear", "config-set", key, value, "system"
    end
    system bin/"pear", "update-channels"
    return if name == "php"

    ext_config_path = etc/"php/#{version_major_minor}/conf.d/ext-opcache.ini"
    ext_config_path.dirname.mkpath
    zend_extension_line = %Q(zend_extension="#{php_ext_dir}/opcache.so")
    if ext_config_path.exist?
      inreplace ext_config_path, /^\s*zend_extension\s*=.*$/, zend_extension_line
    else
      ext_config_path.atomic_write <<~INI
        [opcache]
        #{zend_extension_line}
      INI
    end
  end
end
