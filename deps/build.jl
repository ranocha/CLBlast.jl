using BinDeps
using Compat

@BinDeps.setup
libnames = ["libCLBlast", "libclblast", "clblast"]
libCLBlast = library_dependency("libCLBlast", aliases = libnames)
version = "1.4.0"

if is_windows()
    if Sys.ARCH == :x86_64
        uri = URI("https://github.com/CNugteren/CLBlast/releases/download/1.4.0/CLBlast-" * 
                  version * "-Windows-x64.zip")
        basedir = @__DIR__
        provides(
            Binaries, uri,
            libCLBlast, unpacked_dir = ".",
            installed_libpath = joinpath(basedir, "libCLBlast", "lib"), os = :Windows
        )
    else
        error("Only 64 bit windows supported with automatic build.")
    end
end

if is_linux()
    #=if Sys.ARCH == :x86_64
        name, ext = splitext(splitext(basename(baseurl * "Linux-x64.tar.gz"))[1])
        uri = URI(baseurl * "Linux-x64.tar.gz")
        basedir = joinpath(@__DIR__, name)
        provides(
            Binaries, uri,
            libCLBlast, unpacked_dir = basedir,
            installed_libpath = joinpath(basedir, "lib"), os = :Linux
        )
    else
        error("Only 64 bit linux supported with automatic build.")
    end=#
    provides(Sources, URI("https://github.com/CNugteren/CLBlast/archive/1.4.0.tar.gz"), libCLBlast,
             unpacked_dir="CLBlast-1.4.0")

    builddir = joinpath(@__DIR__, "src", "CLBlast-1.4.0", "build")
    libpath = joinpath(builddir, "libclblast.so")
    provides(BuildProcess,
        (@build_steps begin
            GetSources(libCLBlast)
            CreateDirectory(builddir)
            FileRule(libpath, @build_steps begin   
                ChangeDirectory(builddir)
                `cmake -DSAMPLES=OFF -DTESTS=OFF -DTUNERS=OFF -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ ..`
                `make -j 4`
            end)
        end), 
        libCLBlast, installed_libpath=libpath, os=:Linux)
end

if is_apple()
    using Homebrew
    provides(Homebrew.HB, "homebrew/core/clblast", libCLBlast, os = :Darwin)
end

if is_linux()
    # BinDeps.jl seems to be broken, cf. https://github.com/JuliaLang/BinDeps.jl/issues/172
    wd = pwd()
    gitdir = joinpath(@__DIR__, "CLBlast")
    builddir = joinpath(gitdir, "build")
    libpath = joinpath(builddir, "libclblast.so")
    if !isdir(gitdir)
        run(`git clone https://github.com/CNugteren/CLBlast.git`)
    end
    cd(gitdir)
    run(`git fetch origin`)
    run(`git checkout 1.4.0`)
    isdir(builddir) || mkdir(builddir)
    cd(builddir)
    run(`cmake -DSAMPLES=OFF -DTESTS=OFF -DTUNERS=OFF -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ ..`)
    run(`make -j 4`)
    cd(wd)
    open(joinpath(@__DIR__, "deps.jl"), "w") do file
        write(file,
"""
if VERSION >= v"0.7.0-DEV.3382"
    using Libdl
end
# Macro to load a library
macro checked_lib(libname, path)
    if Libdl.dlopen_e(path) == C_NULL
        error("Unable to load \n\n\$libname (\$path)\n\nPlease ",
              "re-run Pkg.build(package), and restart Julia.")
    end
    quote
        const \$(esc(libname)) = \$path
    end
end

# Load dependencies
@checked_lib libCLBlast "$libpath"
""")
    end
else
    @BinDeps.install Dict(:libCLBlast => :libCLBlast)
end
