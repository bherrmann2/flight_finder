require 'openssl'
require 'Base64'

#This is a good site for generation of keys:
#http://www.sshkeygen.com/

  class Crypt
    def initialize data_path
      @data_path = data_path
      generate_keys
    end

    def encrypt_string message
      pub = get_key 'id_rsa.pub'
      Base64::encode64(pub.public_encrypt(message)).rstrip
    end

    def decrypt_string message
      priv = get_key 'id_rsa'
      priv.private_decrypt Base64::decode64(message)
    end

    def generate_keys 
      rsa_path = File.join(@data_path, 'rsa')
      privkey  = File.join(rsa_path, 'id_rsa')
      pubkey   = File.join(rsa_path, 'id_rsa.pub')
      unless File.exists?(privkey) || File.exists?(pubkey)
        keypair  = OpenSSL::PKey::RSA.generate(1024)
        Dir.mkdir(rsa_path) unless File.exist?(rsa_path)
        File.open(privkey, 'w') { |f| f.write keypair.to_pem } unless File.exists? privkey
        File.open(pubkey, 'w') { |f| f.write keypair.public_key.to_pem } unless File.exists? pubkey
      end
    end

    private
    def get_key filename
      OpenSSL::PKey::RSA.new File.read(File.join(@data_path, 'rsa', filename))
    end
  end

x = Crypt.new(".");
x.generate_keys
en = x.encrypt_string("dj80hd");
puts "EN: " + en;
de = x.decrypt_string(en);
puts "DE: " + de



