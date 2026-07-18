class InjectRunpath < Formula
  desc "Inject DT_RUNPATH into an ELF in-place, without shifting file offsets"
  homepage "https://atomgit.com/social4hyq/homebrew-core"
  # No dedicated upstream repo — the Python source is generated inline in
  # install() below (originally written in-place inside opencode.rb before
  # being extracted here, same lineage as dlopen-sign-shim). Homebrew
  # requires a url/resource on every formula, so this pins to the tap's own
  # repo; install() never reads anything from the checkout, it only exists
  # to satisfy that requirement.
  url "https://atomgit.com/social4hyq/homebrew-core.git",
      revision: "d1fc7a588c1e040b8b34203784669a66731e43e7",
      using:    :git
  version "0.1.0"
  license "MIT"

  livecheck do
    skip "development tool, manually versioned"
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/inject-runpath-v0.1.0"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "61307e99f9a924fa4009ca5cf9556299db5ceff6fa71355a328532fbcd4b8866"
  end

  # Why this exists instead of patchelf: single-file executables built by
  # Bun --compile (and PyInstaller-style bundlers) append their embedded
  # module graph after the ELF sections and locate it by absolute file
  # offset. patchelf rewrites segment layout and shifts offsets, which
  # corrupts that appended data. This tool instead rebuilds the dynamic
  # section and string table inside the existing RW-segment padding — zero
  # bytes move, only the PT_DYNAMIC program header is repointed — so the
  # appended payload survives untouched.
  #
  # It matters on OHOS specifically because the loader ignores
  # LD_LIBRARY_PATH and LD_PRELOAD cannot satisfy DT_NEEDED entries:
  # DT_RUNPATH is the only way to point a prebuilt binary at bundled
  # replacement libraries (see opencode.rb for the original use case).
  depends_on "python@3.14"

  def install
    python = formula_opt_bin("python@3.14")/"python3"
    # Shebang is concatenated separately: the Python body must go through a
    # non-interpolating heredoc so its \x00 escapes reach the file verbatim.
    script = "#!#{python}\n"
    script << <<~'PY'
      # inject-runpath <elf> <runpath-dir>
      #
      # Appends a DT_RUNPATH entry pointing at <runpath-dir> by writing a new
      # dynamic string table and dynamic section into the tail padding of the
      # ELF's RW LOAD segment, then repointing PT_DYNAMIC at them. No existing
      # byte changes file offset, so payloads appended after the sections
      # (Bun --compile module graph, ...) stay valid. Fails with an assertion
      # if the RW segment has too little padding to host the two new blobs.
      import struct
      import sys

      def u(d, off, fmt): return struct.unpack_from(fmt, d, off)

      def patch(path, libdir):
          with open(path, "rb") as f: d = bytearray(f.read())
          e_phoff=u(d,0x20,"<Q")[0]; e_phnum=u(d,0x38,"<H")[0]; e_phentsize=u(d,0x36,"<H")[0]
          loads=[]; ptdyn=None
          for i in range(e_phnum):
              b=e_phoff+i*e_phentsize
              t,fl,off,va,pa,fsz,msz,al=u(d,b,"<IIQQQQQQ")
              if t==1: loads.append((off,va,fsz,msz))
              if t==2: ptdyn=(i,b)
          def seg_for_v(v):
              for off,va,fsz,msz in loads:
                  if va<=v<va+msz: return (off,va)
          def v2f(v):
              o,va=seg_for_v(v); return o+(v-va)
          rw=max(loads,key=lambda l:l[1]); rw_off,rw_v=rw[0],rw[1]
          def f2v_rw(off): return rw_v+(off-rw_off)
          _,db=ptdyn
          _,_,d_off,d_va,d_pa,d_fsz,_,_=u(d,db,"<IIQQQQQQ")
          entries=[]; strtab_v=None; strsz=None; i=0
          while True:
              tag,val=u(d,d_off+i*16,"<qQ")
              if tag==0: break
              entries.append((tag,val))
              if tag==5: strtab_v=val
              if tag==10: strsz=val
              i+=1
          strtab_f=v2f(strtab_v)
          orig=bytes(d[strtab_f:strtab_f+strsz])
          e_shoff=u(d,0x28,"<Q")[0]; e_shnum=u(d,0x3c,"<H")[0]; e_shentsize=u(d,0x3a,"<H")[0]
          maxend=0
          for i in range(e_shnum):
              b=e_shoff+i*e_shentsize; off,size=u(d,b+24,"<QQ")
              if rw_off<=off<rw_off+rw[2]: maxend=max(maxend,off+size)
          free=maxend+((16-(maxend%16))%16)
          rp=libdir.encode()+b"\x00"
          pad=(8-(len(orig)%8))%8
          new_str=orig+b"\x00"*pad+rp
          rp_off=len(orig)+pad; new_sz=len(new_str)
          str_f=free; str_v=f2v_rw(str_f)
          dyn_f=str_f+new_sz+((16-((str_f+new_sz)%16))%16); dyn_v=f2v_rw(dyn_f)
          nd=[]
          for tag,val in entries:
              if tag==5: val=str_v
              elif tag==10: val=new_sz
              nd.append((tag,val))
          nd.append((29,rp_off)); nd.append((0,0))
          db_b=b"".join(struct.pack("<qQ",t,v) for t,v in nd)
          assert dyn_f+len(db_b)<=rw_off+rw[2], "not enough RW padding"
          d[str_f:str_f+new_sz]=new_str
          d[dyn_f:dyn_f+len(db_b)]=db_b
          struct.pack_into("<IIQQQQQQ",d,db,2,u(d,db,"<IIQQQQQQ")[1],dyn_f,dyn_v,dyn_v,len(db_b),len(db_b),8)
          with open(path,"wb") as f: f.write(d)
          print("RUNPATH=%s injected"%libdir)

      if __name__ == "__main__":
          if len(sys.argv) != 3:
              sys.stderr.write("usage: inject-runpath <elf> <runpath-dir>\n")
              sys.exit(2)
          patch(sys.argv[1], sys.argv[2])
    PY
    (bin/"inject-runpath").write script
    chmod 0755, bin/"inject-runpath"
  end

  test do
    output = shell_output("#{bin}/inject-runpath 2>&1", 2)
    assert_match "usage", output
  end
end
