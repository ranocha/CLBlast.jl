"""
    clear_cache()

CLBlast stores binaries of compiled kernels into a cache in case the same kernel
is used later on for thesame device. This cache can be cleared to free up system
memory or it can be useful in case of debugging.
"""
function clear_cache()
    err = ccall((:CLBlastClearCache, libCLBlast), cl.CL_int, ())
    if err != cl.CL_SUCCESS
        println(STDERR, "Calling function `clear_cache` failed!")
        throw(cl.CLError(err))
    end
    return err
end

#function fill_cache(device::cl.CL_device_id)
#    ccall((:CLBlastFillCache, libCLBlast), cl.CL_int, (cl.CL_device_id), device)
#end
