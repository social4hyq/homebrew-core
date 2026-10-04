class MuslCompat < Formula
  desc "Compatibility shim for musl symbols missing on OpenHarmony"
  homepage "https://atomgit.com/Harmonybrew/musl-compat"
  url "https://raw.atomgit.com/Harmonybrew/musl-compat/archive/refs/heads/v1.0.1.tar.gz"
  sha256 "b3e4d8da001019b09a2d7d15198000b0d6c00307f3857eb956f057cc6ec144bb"
  license "MIT"
  revision 2

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/musl-compat-v1.0.1-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c613eb479cb4a773569c880204e60c32c628d79de747ae144cb253937baf548a"
  end

  patch do
    file "Patches/musl-compat/0001-handle-unavailable-message-queues.patch"
  end

  def install
    system "make", "static", "shared",
           "CC=#{ENV.cc}",
           "CFLAGS=-O2 -fPIC",
           "PREFIX=#{prefix}"
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    (testpath/"test.c").write <<~C
      #include "musl_compat.h"
      #include <stdio.h>
      #include <string.h>
      static int cmp_int(const void *a, const void *b, void *arg) {
          (void)arg;
          return *(const int*)a - *(const int*)b;
      }
      int main() {
        int arr[] = {3, 1, 4, 1, 5, 9, 2, 6};
        int expected[] = {1, 1, 2, 3, 4, 5, 6, 9};
        qsort_r(arr, 8, sizeof(int), cmp_int, NULL);
        if (memcmp(arr, expected, sizeof(arr)) == 0) {
          printf("musl-compat OK\\n");
          return 0;
        }
        printf("FAIL: sort mismatch\\n");
        return 1;
      }
    C
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lmusl_compat",
           "-o", "test"
    system "./test"

    (testpath/"mqueue.c").write <<~C
      #define _GNU_SOURCE
      #include <errno.h>
      #include <fcntl.h>
      #include <mqueue.h>
      #include "musl_compat.h"
      #include <stdio.h>
      #include <string.h>
      #include <sys/utsname.h>
      #include <unistd.h>
      #define ENSURE(c) do { if (!(c)) { fprintf(stderr, "FAIL line %d: %s, errno=%d\\n", __LINE__, #c, errno); return 1; } } while (0)
      #define UNSUPPORTED(c) do { errno=0; ENSURE((c)==-1 && errno==ENOSYS); } while (0)
      int main(void) {
       struct utsname u; ENSURE(uname(&u)==0);
       if (!strcmp(u.sysname,"HarmonyOS")) {
        char data[32]; unsigned prio; struct mq_attr attr;
        UNSUPPORTED(mq_open("/harmony-compat-test",O_RDONLY));
        UNSUPPORTED(mq_unlink("/harmony-compat-test"));
        UNSUPPORTED(mq_getattr(-1,&attr));
        UNSUPPORTED(mq_setattr(-1,&attr,&attr));
        UNSUPPORTED(mq_notify(-1,NULL));
        UNSUPPORTED(mq_send(-1,"x",1,0));
        UNSUPPORTED(mq_receive(-1,data,sizeof(data),&prio));
        UNSUPPORTED(mq_timedsend(-1,"x",1,0,NULL));
        UNSUPPORTED(mq_timedreceive(-1,data,sizeof(data),&prio,NULL));
        errno=0; ENSURE(mq_close(-1)==-1 && errno==EBADF);
        puts("PASS: HarmonyOS mq_* return ENOSYS; mq_close preserves EBADF");
        return 0;
       }
       struct mq_attr attr={.mq_maxmsg=2,.mq_msgsize=32},got;
       char name[64],data[32]; unsigned prio=0;
       snprintf(name,sizeof(name),"/compat-test-%ld",(long)getpid());
       mqd_t fd=mq_open(name,O_CREAT|O_EXCL|O_RDWR|O_NONBLOCK,0600,&attr);
       ENSURE(fd!=-1);
       int result=0;
       if (mq_getattr(fd,&got)!=0 || got.mq_msgsize!=32) result=1;
       attr.mq_flags=O_NONBLOCK;
       if (mq_setattr(fd,&attr,&got)!=0) result=2;
       if (mq_notify(fd,NULL)!=0) result=3;
       if (mq_send(fd,"hello",5,3)!=0) result=4;
       if (mq_receive(fd,data,sizeof(data),&prio)!=5 || memcmp(data,"hello",5) || prio!=3) result=5;
       if (mq_timedsend(fd,"timed",5,2,NULL)!=0) result=6;
       if (mq_timedreceive(fd,data,sizeof(data),&prio,NULL)!=5 || memcmp(data,"timed",5) || prio!=2) result=7;
       errno=0; if (mq_receive(fd,data,sizeof(data),&prio)!=-1 || errno!=EAGAIN) result=8;
       if (mq_close(fd)!=0) result=9;
       errno=0; if (mq_getattr(-1,&got)!=-1 || errno!=EBADF) result=10;
       if (mq_unlink(name)!=0) result=11;
       errno=0; if (mq_open(name,O_RDONLY)!=-1 || errno!=ENOENT) result=12;
       errno=0; if (mq_unlink(name)!=-1 || errno!=ENOENT) result=13;
       errno=0; if (mq_close(-1)!=-1 || errno!=EBADF) result=14;
       ENSURE(result==0);
       puts("PASS: Linux queue lifecycle and error propagation");
       return 0;
      }
    C
    system ENV.cc, "mqueue.c", "-I#{include}", "-L#{lib}", "-lmusl_compat", "-o", "mqueue"
    system "./mqueue"
  end
end
