# Set a frozen certificate store to avoid contention when initializing.
# https://github.com/jruby/jruby/issues/4150

SSL_CERTIFICATE_STORE = OpenSSL::X509::Store.new.freeze
SSL_CERTIFICATE_STORE.set_default_paths

