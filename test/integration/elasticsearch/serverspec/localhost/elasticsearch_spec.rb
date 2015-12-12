require 'spec_helper'
require 'json'

describe 'Elasticsearch' do
  # TODO
  # tuning JVM

  describe port(9200) do
    it { should be_listening }
  end

  describe port(9300) do
    it { should be_listening }
  end

  describe service('elasticsearch') do
    it { should be_enabled }
    it { should be_running }
  end

  describe command('curl localhost:9200') do
    it 'is version 1.7.3' do
      hash = JSON.parse(subject.stdout)
      expect(hash['version']['number']).to eq '1.7.3'
    end
  end

  # Plugins
  describe command('curl localhost:9200/_nodes') do
    let(:plugins) do
      hash = JSON.parse(subject.stdout)
      hash['nodes'].values.first['plugins']
    end

    it 'has aws cloud 2.7.1 plugin' do
      expect(plugins).to satisfy {|plugins|
        plugins.any? do |plugin|
          plugin['name'] == 'cloud-aws' && plugin['version'] == '2.7.1'
        end
      }
    end

    it 'has marvel 1.3.1 plugin' do
      expect(plugins).to satisfy {|plugins|
        plugins.any? do |plugin|
          plugin['name'] == 'marvel' && plugin['version'] == '1.3.1'
        end
      }
    end
  end

  # cluster settings: discovery, CORS, data & log mount point
  describe command('curl localhost:9200/_nodes') do
    let(:hash) { JSON.parse(subject.stdout) }
    let(:settings) { hash['nodes'].values.first['settings'] }

    it 'has elasticsearch as cluster name' do
      expect(hash['cluster_name']).to eq 'issue-elasticsearch'
    end

    it 'requires cloud-aws plugin' do
      expect(settings).to include(
        'plugin' => {'mandatory' => 'cloud-aws'}
      )
    end

    it 'clusters within elasticsearch group' do
      expect(settings['discovery']).to include(
        'type' => 'ec2',
        'ec2' => {'groups' => 'elasticsearch'}
      )
      expect(settings['discovery']['zen']).to include(
        "ping" => {
          "multicast" => {"enabled"=>"false"}
        }
      )
    end

    it 'supports CORS requests' do
      expect(settings['http']).to include(
        'cors' => {
          'enabled' => 'true',
          'allow-origin' => '/.*/',
          'allow-headers' => 'X-Requested-With, Content-Type, Content-Length, Authorization',
          'allow-credentials' => 'true',
        }
      )
    end

    it 'stores data at /data/db/elasticsearch' do
      expect(settings['path']['data']).to eq '/data/db/elasticsearch'
    end

    it 'stores log at /data/log/elasticsearch' do
      expect(settings['path']['logs']).to eq '/data/log/elasticsearch'
    end
  end

  describe file('/etc/elasticsearch/elasticsearch.yml') do
    it { should be_file }

    # exports node stats to monitoring cluster
    its(:content) { should match %r{marvel.agent.exporter.es.hosts:\s+http://localhost:9200/monitor} }

    # skips monitoring cluster hostname verification
    #its(:content) { should match %r{marvel.agent.exporter.es.ssl.hostname_verification:\s+false} }

    # exports node stats to monitoring cluster via https
    #its(:content) { }
  end
end
