name             "mysql-configuration"
maintainer_email "thomas.liebscher@iconicfuture.com"
maintainer       "Thomas Liebscher"
license          "Apache Software License 2.0"
description      "Deploys database schemas"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1"

depends 'mysql', '~> 6.0'

%w{ ubuntu debian }.each do |os|
  supports os
end
