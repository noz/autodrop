#!/usr/bin/env ruby

require 'optparse'
require 'syslog'

DEFAULT_CONFFILE = '/etc/autodrop.conf'

$debug = false

def log msg
  if $debug
    puts "#{Time.now}: syslog: #{msg}"
  else
    if Syslog.opened?
      Syslog.info msg
    end
  end
end

def debug msg
  return unless $debug
  puts "#{Time.now}: debug: #{msg}"
end

def terminate whymsg, status = 0
  log "terminate (#{whymsg})"
  exit! status
end

module Autodrop
  # { ip => Dog obj }
  @dogs = {}

  def Autodrop.house ip
    @dogs.delete ip
  end

  def Autodrop.watch
    log "start watching '#{WATCH_FIFO_}'"
    loop {
      begin
        File.open(WATCH_FIFO_, File::RDONLY | File::NONBLOCK) { |f|
          ready = File.select([f])
          if ready
            line = ready[0][0].gets
            ip = nil
            MESSAGES_TO_WATCH.each { |msg|
              ip = $1 if line =~ msg
            }
            if ip
              if @dogs.has_key? ip
                @dogs[ip].bark
              else
                @dogs[ip] = Dog.new(ip)
              end
            end
          end
        }
      rescue Errno::ENOENT => ex
        log "lost FIFO '#{WATCH_FIFO_}'. exit"
        break
      end
    }
  end
end  # Autodrop

class Dog
  def initialize ip
    @ip = ip
    @count = 1
    @time = Time.now + INTERVAL
    @thread = Thread.new {
      debug "[#{@ip}] bark! (#{@count})"
      loop {
        if Time.now >= @time
          debug "[#{@ip}] leave"
          break
        end
        if @count >= COUNT_MAX
          bite
          break
        end
        debug "[#{@ip}] grrr..."
        sleep 1
      }
      Autodrop.house @ip
      debug "[#{@ip}] end"
    }
  end

  def bark
    @count += 1
    @time = Time.now + INTERVAL
    debug "[#{@ip}] bark! (#{@count})"
  end

  def bite
    if $debug
      log "DROP (#{@ip})"
      return
    end
    if system(IPTABLES_PROGRAM, '-I', 'INPUT', '-s', @ip, '-j', 'DROP')
      log "DROP (#{@ip})"
    else
      log "error (iptables fail)"
    end
  end
end  # Dog

### main

@conffile = nil
opts = OptionParser.new
opts.on("-c CONFFILE", "--config CONFFILE", String, /.*/,
        "Configuration file",
        "(default: '#{DEFAULT_CONFFILE}')") { |conffile|
  @conffile = conffile
}
opts.on("-d", "--debug", nil, nil,
        "Debug mode",
        "+ no daemon",
        "+ write logs to stdout",
        "+ watch fifo named './fifo'") { |flag|
  $debug = true
}
opts.parse! ARGV
opts = nil

@conffile ||= DEFAULT_CONFFILE
unless File.file? @conffile
  puts "#{@conffile} does not exist."
  exit 1
end

eval File.readlines(@conffile).join("\n")

unless File.executable? IPTABLES_PROGRAM
  puts "#{IPTABLES_PROGRAM} is not executable."
  exit 1
end

if $debug
  WATCH_FIFO_ = 'fifo'
else
  WATCH_FIFO_ = WATCH_FIFO
  if Process.euid != 0
    puts 'Run as root'
    exit 1
  end
end

begin
  Syslog.open('autodrop', Syslog::LOG_PID|Syslog::LOG_CONS, Syslog::LOG_AUTH)
  if $debug
    Autodrop.watch
  else
    # daemonify self
    Process.fork {
      Process.setsid
      Dir.chdir "/"
      trap("SIGINT") { terminate 'SIGINT' }
      trap("SIGTERM") { terminate 'SIGTERM' }
      trap("SIGHUP") { terminate 'SIGHUP' }
      STDIN.reopen "/dev/null"
      STDOUT.reopen "/dev/null"
      STDERR.reopen "/dev/null"
      File.open(PIDFILE, 'w') {|f|
        f.puts Process.pid
      }
      Autodrop.watch
    }
  end
rescue => ex
  log "error (#{ex}). exit"
  exit! 1
end

# Copyright (c) 2009, NOZAWA Hiromasa. All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 
#  1. Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#  2. Redistributions in binary form must reproduce the above
#     copyright notice, this list of conditions and the following
#     disclaimer in the documentation and/or other materials provided
#     with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
