-- stub code for hake MIPS info
-- derived with reference to calls in RuleDefs.hs

module MIPS where

import HakeTypes
import qualified Config
import qualified ArchDefaults

arch = "mips"
archFamily = "mips"

-- if Config is set up correctly, this should work fine
compiler    = Config.mips_cc
objcopy     = Config.mips_objcopy
objdump     = Config.mips_objdump
ar          = Config.mips_ar
ranlib      = Config.mips_ranlib
cxxcompiler = Config.mips_cxx

-- options

ourCommonFlags = [ Str "-fno-PIC",
                   Str "-mno-abicalls"
 ]

-- XXX check if any of these flags non-interop w/ gcc 4.8.3
cFlags = ArchDefaults.commonCFlags
         ++ ArchDefaults.commonFlags
         ++ ourCommonFlags

-- shouldn't be used
cxxFlags = ArchDefaults.commonCxxFlags
           ++ ArchDefaults.commonFlags
           ++ ourCommonFlags

cDefines = ArchDefaults.cDefines options

-- XXXXXX
ourLdFlags = [ Str "-Wl,-section-start,.text=0x400000",
               Str "-Wl,--build-id=none",
               Str "-static" ]

ldFlags = ArchDefaults.ldFlags arch ++ ourLdFlags
ldCxxFlags = ArchDefaults.ldCxxFlags arch ++ ourLdFlags

stdLibs = ArchDefaults.stdLibs arch

-- XXXXXX
options = (ArchDefaults.options arch archFamily) { 
            optFlags = cFlags,
            optCxxFlags = cxxFlags,
            optDefines = cDefines,
            optLdFlags = ldFlags,
            optLdCxxFlags = ldCxxFlags,
            optLibs = stdLibs,
            optInterconnectDrivers = ["lmp", "ump"],
            optFlounderBackends = ["lmp", "ump"]
          }

-- kernelCFlags XXXXXX
kernelCFlags = ourCommonFlags

-- kernelLdFlags XXXXXX
kernelLdFlags = [ Str "-Wl,-N",
                  Str "-fno-builtin",
                  Str "-nostdlib",
                  Str "-pie",
                  Str "-Wl,--fatal-warnings",
                  Str "-Wl,--dynamic-list-data",
                  Str "-Wl,--export-dynamic"
                ]

-- toolchain defs --- if ArchDefaults defs are good, this should work
-- cCompiler opts phase src obj
-- makeDepend opts phase src obj depfile
-- cToAssembler opts phase src afile objdepfile
-- assembler opts src obj
-- archive opts objs libs name libname
-- linker opts objs libs bin
-- strip opts src debuglink target
-- debug opts src target
cCompiler = ArchDefaults.cCompiler arch compiler Config.cOptFlags
cxxCompiler = ArchDefaults.cxxCompiler arch cxxcompiler Config.cOptFlags
makeDepend = ArchDefaults.makeDepend arch compiler
makeCxxDepend  = ArchDefaults.makeCxxDepend arch cxxcompiler
cToAssembler = ArchDefaults.cToAssembler arch compiler Config.cOptFlags
assembler = ArchDefaults.assembler arch compiler Config.cOptFlags
archive = ArchDefaults.archive arch
linker = ArchDefaults.linker arch compiler
strip = ArchDefaults.strip arch objcopy
debug = ArchDefaults.debug arch objcopy
cxxlinker = ArchDefaults.cxxlinker arch cxxcompiler

-- linkKernel
-- look for the boot.lds.in script somewhere in kernel/arch/mips
-- XXXXXX cribbed from ARMv7.hs, needs modifications
linkKernel :: Options -> [String] -> [String] -> String -> String -> HRule
linkKernel opts objs libs name driverType =
    let linkscript = "/kernel/" ++ name ++ ".lds"
        kernelmap  = "/kernel/" ++ name ++ ".map"
        kasmdump   = "/kernel/" ++ name ++ ".asm"
        kbinary    = "/sbin/" ++ name
        kbootable  = kbinary ++ ".bin"
    in
        Rules [ Rule ([ Str compiler ] ++
                    map Str Config.cOptFlags ++
                    [ NStr "-T", In BuildTree arch linkscript,
                      Str "-o", Out arch kbinary,
                      NStr "-Wl,-Map,", Out arch kernelmap
                    ]
                    ++ (optLdFlags opts)
                    ++
                    [ In BuildTree arch o | o <- objs ]
                    ++
                    [ In BuildTree arch l | l <- libs ]
                    ++
                    (ArchDefaults.kernelLibs arch)
                   ),
              -- Generate kernel assembly dump
              Rule [ Str objdump, 
                     Str "-d", 
                     In BuildTree arch kbinary, 
                     Str ">", Out arch kasmdump ],
              -- XXX not sure how the following modifies lds.in
              Rule [ Str "cpp",
                     NStr "-I", NoDep SrcTree "src" "/kernel/include/arch/mips",
                     Str "-D__ASSEMBLER__",
                     Str "-P",
                        In SrcTree "src"
                           ("/kernel/arch/mips/"++driverType++".lds.in"),
                     Out arch linkscript
                   ],
              -- Produce a stripped binary
              Rule [ Str objcopy,
                     Str "-g",
                     In BuildTree arch kbinary,
                     Out arch (kbinary ++ ".stripped")
                   ]
            ]
