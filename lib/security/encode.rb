require 'openssl'
require 'base64'

def asm_decrypt(message)
  if isEncryption != true
    return message
  end
  if check_base64(message) != true
    return message
  end
  password = message[0,32]
  message = message[32,message.length]
  decryptWithSecret(message,password)
end

def check_base64(string_input)
  if string_input =~ /^([A-Za-z0-9+\/]{4})*([A-Za-z0-9+\/]{4}|[A-Za-z0-9+\/]{3}=|[A-Za-z0-9+\/]{2}==)$/
    true
  else
    false
  end
end

def decryptWithSecret(message, password)
  base64_decoded = Base64.decode64(message.to_s.strip)
  decrypt_data(base64_decoded, key_digest(password), nil, "AES-256-CBC")
end

def key_digest(password)
  OpenSSL::Digest::SHA256.new(password).digest
end

def decrypt_data(encrypted_data, key, iv, cipher_type)
  aes = OpenSSL::Cipher::Cipher.new(cipher_type)
  aes.decrypt
  aes.key = key
  aes.iv = iv if iv != nil
  aes.update(encrypted_data) + aes.final
end

def isEncryption
  encryption = true
  module_lib= File.expand_path(File.dirname(__FILE__))
  prop_file_path = File.join module_lib.to_s, '../../asm.properties'
  if File.exists?(prop_file_path)
    properties = load_properties(prop_file_path)
    if properties["Encryption"] != "true"
      encryption = false
end
  end
  return encryption
end

def load_properties(properties_filename)
  properties = {}
  File.open(properties_filename, 'r') do |properties_file|
    properties_file.read.each_line do |line|
      line.strip!
      if (line[0] != "#")
        i = line.index('=')
        if (i)
          properties[line[0..i - 1].strip] = line[i + 1..-1].strip
        else
          properties[line] = ''
        end
      end
    end
  end
  properties
end

