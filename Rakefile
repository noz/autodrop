# -*-ruby-*-

FILES = [
         'ChangeLog',
         'Makefile',
         'Rakefile',
         'bin/autodrop',
         'bin/autodrop.rb',
         'conf/autodrop.conf.default',
         'doc/README.jp.txt',
         'doc/README.txt',
         'misc/autodrop.sh',
        ]

desc "Same as 'rake bin/autodrop'"
task :default => [ "bin/autodrop" ]

desc "Make bin/autodrop"
file "bin/autodrop" do
  sh "cp -f bin/autodrop.rb bin/autodrop"
  sh "chmod 755 bin/autodrop"
end

desc "Do distclean"
task :distclean => [ :clobber_package ] do
  sh "rm -f bin/autodrop"
end

task :gem => [ "bin/autodrop" ]
require 'rubygems'
require 'rake/gempackagetask'
spec = Gem::Specification.new do |s|
  s.name = "autodrop"
  s.version = "0.1.0"
  s.author = "NOZAWA Hiromasa"
  s.summary = "Automatic iptables DROP daemon"
  s.homepage = 'http://rubyforge.org/projects/autodrop'
  s.rubyforge_project = 'autodrop'
  s.files = FILES
  s.bindir = 'bin'
  s.executables = 'autodrop'
  s.require_path = []
end
Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end
