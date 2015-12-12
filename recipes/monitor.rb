include_recipe 'apt'
include_recipe 'java'

elasticsearch_user 'elasticsearch'
elasticsearch_install 'elasticsearch' do
  version '1.7.3'
end

elasticsearch_plugin 'marvel' do
  url 'elasticsearch/marvel/1.3.1'
end

elasticsearch_configure 'elasticsearch' do
  path_data(package: '/data/db/elasticsearch')
  path_logs(package: '/data/log/elasticsearch')

  configuration(
    'cluster.name' => 'issue-elasticsearch-monitoring',

    'http.cors.enabled' => true,
    'http.cors.allow-origin' => '/.*/',
    'http.cors.allow-headers' => 'X-Requested-With, Content-Type, Content-Length, Authorization',
    'http.cors.allow-credentials' => true,

    'marvel.agent.enabled' => false
  )
end

elasticsearch_service 'elasticsearch' do
  service_actions([:enable, :restart])
end
