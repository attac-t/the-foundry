# A checkout's origin, rewritten as a container can clone it. `bin/host.sh` reads it.
#
# An SSH address, `name@host:path`, becomes the same path over HTTPS. The container holds no key.
s#^[^/@:]*@\([^/:]*\):#https://\1/#

# So does an `ssh://` URL.
s#^ssh://#https://#

# A name, or a name and a token, before the host goes. Kept, it would reach the volume's config.
s#^\([a-z+]*://\)[^/@]*@#\1#
