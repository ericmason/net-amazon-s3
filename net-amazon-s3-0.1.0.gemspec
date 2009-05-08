# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{net-amazon-s3}
  s.version = "0.1.0"

  s.required_rubygems_version = nil if s.respond_to? :required_rubygems_version=
  s.authors = ["Ryan Grove"]
  s.cert_chain = nil
  s.date = %q{2006-11-25}
  s.email = %q{ryan@wonko.com}
  s.files = ["lib/net", "lib/net/amazon", "lib/net/amazon/s3", "lib/net/amazon/s3.rb", "lib/net/amazon/s3/bucket.rb", "lib/net/amazon/s3/errors.rb", "lib/net/amazon/s3/object.rb", "LICENSE"]
  s.has_rdoc = true
  s.homepage = %q{http://wonko.com/software/net-amazon-s3}
  s.rdoc_options = ["--title", "Net::Amazon::S3 Documentation", "--main", "Net::Amazon::S3", "--line-numbers"]
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.4")
  s.rubyforge_project = %q{net-amazon-s3}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Amazon S3 library.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 1

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
