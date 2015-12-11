include_recipe 'apt'

include_recipe 'java'

elasticsearch_user 'elasticsearch'
elasticsearch_install 'elasticsearch 1.7'

elasticsearch_plugin 'marvel' do
  url "elasticsearch/marvel/1.3.1"
end

elasticsearch_plugin 'elasticsearch-cloud-aws' do
  url 'elasticsearch/elasticsearch-cloud-aws/2.7.1'
end

elasticsearch_configure 'elasticsearch' do
  path_data(package: '/data/db/elasticsearch')
  path_logs(package: '/data/log/elasticsearch')

  configuration(
    'cluster.name' => 'issue-elasticsearch',

    'http.cors.enabled' => true,
    'http.cors.allow-origin' => '/.*/',
    'http.cors.allow-headers' => 'X-Requested-With, Content-Type, Content-Length, Authorization',
    'http.cors.allow-credentials' => true,

    'plugin.mandatory' => 'cloud-aws',

    'cloud.aws.access_key' => node.idata.aws_access_key,
    'cloud.aws.secret_key' => node.idata.aws_secret_key,

    'discovery.type' => 'ec2',
    'discovery.zen.ping.multicast.enabled' => false,
    'discovery.ec2.groups' => 'elasticsearch',
    #'discovery.ec2.tag.my_tag' => 'my_tag_value',

    'marvel.agent.exporter.es.hosts' => node.idata.monitor_url,
  )
end

elasticsearch_service 'elasticsearch' do
  service_actions([:enable, :restart])
end
