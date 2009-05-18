# -*-ruby-*-

FILES = [
         'ChangeLog',
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

PACKAGE_NAME = 'autodrop'
PACKAGE_VERSION = '0.1.0'

begin
  task :gem => [ "bin/autodrop" ]
  require 'rubygems'
  require 'rake/gempackagetask'
  spec = Gem::Specification.new do |s|
    s.name = PACKAGE_NAME
    s.version = PACKAGE_VERSION
    s.author = "NOZAWA Hiromasa"
    s.summary = "Automatic iptables DROP daemon"
    s.homepage = 'http://rubyforge.org/projects/autodrop'
    s.rubyforge_project = 'autodrop'
    s.files = FILES
    s.bindir = 'bin'
    s.executables = 'autodrop'
    s.require_path = []
  end
  Rake::GemPackageTask.new spec do |pkg|
    pkg.need_tar_gz = true
    # pkg.need_tar_bz2 = true
    # pkg.need_zip = true
  end
rescue LoadError
  puts "# No rubygems. 'gem' task is disabled."

  require 'rake/packagetask'
  Rake::PackageTask.new PACKAGE_NAME, PACKAGE_VERSION do |p|
    p.package_dir = "pkg"
    p.package_files.include FILES
    p.need_tar_gz = true
    # p.need_tar_bz2 = true
    # p.need_zip = true
  end
end

desc "Do distclean"
task :distclean => [ :clobber_package ] do
  sh "rm -f bin/autodrop"
end

#
# for manual installation (without rubygem)
#

DEFAULT_BIN_INSTALL_DIR = '/usr/local/sbin'
DEFAULT_CONF_INSTALL_DIR = '/etc'

desc "Install (without rubygem)"
task :install => "bin/autodrop" do
  bin_install_dir = ENV['BIN_INSTALL_DIR']
  bin_install_dir ||= DEFAULT_BIN_INSTALL_DIR
  conf_install_dir = ENV['CONF_INSTALL_DIR']
  conf_install_dir ||= DEFAULT_CONF_INSTALL_DIR
  directory bin_install_dir
  directory conf_install_dir
  sh "cp -f bin/autodrop #{bin_install_dir}/autodrop"
  sh "cp -f conf/autodrop.conf.default #{conf_install_dir}/autodrop.conf.default"
end

desc "Uninstall (without rubygem)"
task :uninstall do
  bin_install_dir = ENV['BIN_INSTALL_DIR']
  bin_install_dir ||= DEFAULT_BIN_INSTALL_DIR
  conf_install_dir = ENV['CONF_INSTALL_DIR']
  conf_install_dir ||= DEFAULT_CONF_INSTALL_DIR
  sh "rm -f #{bin_install_dir}/autodrop"
  sh "rm -f #{conf_install_dir}/autodrop.conf.default"
end
