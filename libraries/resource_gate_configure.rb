class GateConfigureResource < Chef::Resource::LWRPBase
  resource_name :gate_configure
  provides :gate_configure

  actions(:create)
  default_action :create

  # {user: xxx, pass: xxx}
  attribute(:auth, Hash, default: nil)

  # {key: xxx, cert: xxx}
  attribute(:ssl, Hash, default: nil)

  attribute(:paths, Hash, default: {
    main:      '/etc/nginx/nginx.conf',
    preflight: '/etc/nginx/conf.d/preflight.conf',
    proxy:     '/etc/nginx/conf.d/proxy.conf',
    cors:      '/etc/nginx/conf.d/cors.conf',
    auth:      '/etc/nginx/conf.d/auth.conf',

    pass:    '/etc/nginx/htpasswd',

    key:     '/etc/nginx/ssl/es.issue.by.pem',
    cert:    '/etc/nginx/ssl/es.issue.by.cert',
  })

  attribute(:templates, Hash, default: {
    main:  'nginx.conf.erb',
    proxy: 'proxy.conf.erb',
    cors:  'cors.conf.erb',
    auth:  'auth.conf.erb',
  })

  attribute(:run_as, String, default: 'www-data')
  #attribute(:worker_count, Integer, default: (node.cpu.total.to_i rescue 1))
  #attribute(:monitor_url, String, default: node.idata.monitor_url)
end
