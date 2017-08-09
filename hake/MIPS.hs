-- XXX XXX stub code for hake MIPS info
-- derived with reference to calls in RuleDefs.hs

-- options

-- kernelCFlags

-- kernelLdFlags

-- compiler
-- cCompiler opts phase src obj

-- makeDepend opts phase src obj depfile

-- cToAssembler opts phase src afile objdepfile

-- assembler opts src obj

-- archive opts objs libs name libname

-- linker opts objs libs bin

-- strip opts src debuglink target

-- debug opts src target

-- linkKernel
-- look for the boot.lds.in script somewhere in kernel/arch/mips
-- XXX cribbed from ARMv7.hs, needs modifications
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
                     Str "-M reg-names-raw",
                     In BuildTree arch kbinary, 
                     Str ">", Out arch kasmdump ],
              -- XXX not sure how the following modifies lds.in
              Rule [ Str "cpp",
                     NStr "-I", NoDep SrcTree "src" "/kernel/include/arch/armv7",
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
