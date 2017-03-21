require "rake/clean"
require "rubygems/package_task"

task :default => :gem

file "autodrop" do
  sh "cp -f autodrop.rb autodrop"
  sh "chmod 755 autodrop"
end

task :gem => [ "autodrop" ]
spec = Gem::Specification.new { |s|
  s.name = "autodrop"
  s.version = "1.0.0"
  s.author = "NOZAWA Hiromasa"
  s.summary = "Automatic iptables DROP daemon"
  s.license = "BSD-2-Clause"
  s.homepage = "https://github.com/noz/autodrop"
  s.add_runtime_dependency "trad-getopt"
  s.files = FileList[
    "ChangeLog",
    "LICENSE",
    "Rakefile",
    "autodrop",
    "autodrop.conf.default",
    "autodrop.rb",
    "autodrop.sh",
    "autodrop.txt",
  ]
  s.bindir = "."
  s.executables = "autodrop"
  s.require_path = "."
}
Gem::PackageTask.new(spec) {|pkg|
  pkg.need_tar_gz = true
  pkg.need_tar_bz2 = true
  pkg.need_zip = true
}

CLOBBER << [ "autodrop" ]
