#
# Cookbook Name:: netatalk-timemachine

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

directory "/var/tmp/netatalk" do
  owner "root"
  group "root"
end

arch = node['kernel']['machine'] =~ /x86_64/ ? "amd64" : "i386"

remote_file "/var/tmp/netatalk/netatalk_2.2.1-1_" + arch + ".deb" do
  source "http://www.mikepalmer.net/files/netatalk_2.2.1-1_" + arch + ".deb"
  mode "0644"
  action :create_if_missing
end

package "avahi-daemon"

service "avahi-daemon" do
  action :nothing
end

service "netatalk" do
  action :nothing
end

execute "untar-netatalk" do
  cwd "/var/tmp/netatalk"
  command "dpkg -i netatalk_2.2.1-1_" + arch + ".deb && touch /var/tmp/netatalk/installed"
  creates "/var/tmp/netatalk/installed"
  notifies :restart, resources(:service => "netatalk")
end

cookbook_file "/etc/avahi/services/afpd.service" do
  source "afpd.service"
  notifies :restart, resources(:service => "avahi-daemon")
  notifies :restart, resources(:service => "netatalk")
end

directory node['netatalk-timemachine']['path'] do
  owner node['netatalk-timemachine']['user']
  group node['netatalk-timemachine']['group']
  mode "0755"
  action :create
end

file node['netatalk-timemachine']['path'] + "/.com.apple.timemachine.supported" do
  owner node['netatalk-timemachine']['user']
  group node['netatalk-timemachine']['group']
  mode "0555"
  action :create
end

template "/etc/netatalk/AppleVolumes.default" do
  source "AppleVolumes.default.erb"
  mode 0755
  owner "root"
  group "root"
  notifies :restart, resources(:service => "netatalk")
end