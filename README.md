This is a tool to build OpenMandriva Lx ISO.

https://openmandriva.org

Valid Options:

--arch= x86_64, aarch64. znver1

--tree= 6.0, rolling, cooker (Also controls download source. Cooker is master branch, rolling is rolling branch, and 6.0 is 6.0 branch)

--version= current version of rock (6.0), rolling (rolling), or cooker (25.90)

--release_id= alpha, beta, rc, snapshot

--type= Any .lst found in iso-pkg-$TREE ie: omdv-plasma6x11.lst = plasma6x11.lst

--displaymanager= sddm, gdm, lightdm, ly, none

Not using --displaymanager is equivalent to using --displaymanager=none

If using custom .lst make sure have the .lst in the repo source (can be changed in the .sh file through the wget command)

