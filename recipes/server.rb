::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)
::Chef::Recipe.send(:include, Spadeworks::Openstack)

package "keystone"

mysql_node = node_by_role "mysql"
connection = "mysql://keystone:#{mysql_node[:openstack][:mysql][:keystone_password]}@#{mysql_node[:fqdn]}/keystone"
node.set_unless[:keystone][:admin_token] = secure_password

template '/etc/keystone/keystone.conf' do
    source 'keystone.conf.erb'
    mode 0644
    variables({
        :connection => connection,
    })
    notifies :restart, "service[keystone]", :immediately
end

service 'keystone' do
    provider Chef::Provider::Service::Upstart
    supports :status => :true, :restart => :true, :reload => :true
    action [:enable, :start]
end

package "python-mysqldb"
execute "keystone dbsync" do
    command "keystone-manage db_sync"
end


