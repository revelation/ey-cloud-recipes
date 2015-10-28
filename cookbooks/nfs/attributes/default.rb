#
# Cookbook Name:: nfs
# Attributes:: node.default
#
# Copyright 2011, Eric G. Wolfe
#
# Licensed under the Apache License, Version 2.0(the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#options = { 'nfs' => {'service' => {}, 'config' => {}, 'packages' => {} , 'port' => {} }}
nfs(
  'instance_name' => 'utility',
  'packages' => [ 'nfs-utils', 'portmap', 'File-NFSLock' ],
  'service' =>  {
                  'portmap' => 'portmap',
                  'lock'    => 'nfslock',
                  'server'  => 'nfs'
  },
  'config' => {
                  'client_templates' => [ '/etc/conf.d/nfs' ],
                  'server_template'  => '/etc/conf.d/nfs'
  },
  'port' => {
                  'statd'       => 32765,
                  'statd_out'   => 32766,
                  'mountd'      => 32767,
                  'lockd'       => 32768
  },
  'exports' => ["/data 172.31.0.0/16(rw,sync,no_root_squash)"],

  # Application specific settings
  'links' => ["reports"]
)
