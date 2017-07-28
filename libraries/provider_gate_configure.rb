class GateConfigureProvider < Chef::Provider::LWRPBase
  provides :gate_configure

  def whyrun_supported?
    false
  end

  action :create do
    create_conf :main
    create_conf :proxy
    create_pass_file
    create_ssl_file
  end

  protected

  alias_method :nginx, :new_resource

  def create_conf name
    case name
    when :main
      conf = template nginx.paths[:main] do
        source nginx.templates[:main]
        owner "root"
        mode 0644
        action :nothing
        variables(
          run_as: nginx.run_as,
          proxy_path: nginx.paths[:proxy],
          worker_count: (node.cpu.total.to_i rescue 1),
        )
      end

    when :proxy
      create_conf :preflight
      create_conf :cors
      create_conf :auth

      conf = template nginx.paths[:proxy] do
        source nginx.templates[:proxy]
        owner nginx.run_as
        group nginx.run_as
        mode 0755
        notifies :reload, 'service[nginx]'
        action :nothing
        variables(
          preflight_path: nginx.paths[:preflight],
          cors_path: nginx.paths[:cors],
          auth_path: nginx.paths[:auth],
          key_path: nginx.paths[:key],
          cert_path: nginx.paths[:cert],
          monitor_url: node.idata.monitor_url,
        )
      end

    when :preflight, :cors
      conf = template nginx.paths[name] do
        source nginx.templates[name]
        owner nginx.run_as
        group nginx.run_as
        mode 0755
        action :nothing
      end

    when :auth
      conf = template nginx.paths[:auth] do
        source nginx.templates[:auth]
        owner nginx.run_as
        group nginx.run_as
        mode 0755
        action :nothing
        variables(pass_path: nginx.paths[:pass])
      end
    end

    conf.run_action(:create)
    nginx.updated_by_last_action(true) if conf.updated_by_last_action?
  end

  # create passwords file
  def create_pass_file
    ruby_block "add users to passwords file" do
      block do
        require 'webrick/httpauth/htpasswd'
        htpasswd = WEBrick::HTTPAuth::Htpasswd.new(nginx.paths[:pass])
        htpasswd.set_passwd('Elasticsearch', nginx.auth[:user], nginx.auth[:pass])
        htpasswd.flush
      end
    end

    file nginx.paths[:pass] do
      owner nginx.run_as
      group nginx.run_as
      mode 0755
      action :touch
    end
  end

  def create_ssl_file
    dir = directory ::File.dirname(nginx.paths[:key]) do
      owner nginx.run_as
      group nginx.run_as
      mode '0540'
      action :nothing
    end
    dir.run_action(:create)
    nginx.updated_by_last_action(true) if dir.updated_by_last_action?

    [:key, :cert].each do |ssl|
      f = file nginx.paths[ssl] do
        owner nginx.run_as
        group nginx.run_as
        mode '0440'
        content nginx.ssl[ssl]
        action :nothing
      end
      f.run_action(:create)
      nginx.updated_by_last_action(true) if f.updated_by_last_action?
    end
  end
end
