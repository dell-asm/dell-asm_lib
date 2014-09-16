#This is a custom puppet function that takes an encrypted password string and decrypts it
require '/etc/puppetlabs/puppet/modules/asm_lib/lib/security/encode'
require 'uri'

module Puppet::Parser::Functions
  newfunction(:asm_decrypt, :type => :rvalue) do |args|
    pass = args[0]
    URI.decode(asm_decrypt(pass))
  end
end
