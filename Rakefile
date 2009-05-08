require 'rubygems'

Gem::manage_gems

require 'rake/gempackagetask'
require 'rake/rdoctask'

spec = Gem::Specification.new do |s|
  s.name     = 'net-amazon-s3'
  s.version  = '0.1.0'
  s.author   = 'Ryan Grove'
  s.email    = 'ryan@wonko.com'
  s.homepage = 'http://wonko.com/software/net-amazon-s3'
  s.platform = Gem::Platform::RUBY
  s.summary  = 'Amazon S3 library.'

  s.rubyforge_project = 'net-amazon-s3'
  
  s.files        = FileList['lib/**/*', 'LICENSE'].exclude('rdoc').to_a
  s.require_path = 'lib'

  s.has_rdoc = true
  s.rdoc_options << '--title' << 'Net::Amazon::S3 Documentation' <<
                    '--main' << 'Net::Amazon::S3' <<
                    '--line-numbers'
  
  s.required_ruby_version = '>= 1.8.4'
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_tar = true
end

Rake::RDocTask.new do |rd|
  rd.main     = 'Net::Amazon::S3'
  rd.title    = 'Net::Amazon::S3 Documentation'
  rd.rdoc_dir = 'doc/html'
  rd.rdoc_files.include('lib/**/*.rb')
end
