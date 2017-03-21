#!/usr/bin/env ruby
require "syslog"
require "trad-getopt"
require "yaml"

class Autodrop

  VERSION = "1.0.0"

  class SyslogLogger
    def initialize
      Syslog.open "autodrop", Syslog::LOG_PID|Syslog::LOG_CONS, Syslog::LOG_AUTH
    end
    def log msg
      Syslog.info msg
    end
  end

  class StdoutLogger
    def log msg
      puts "#{Time.now}: #{msg}"
    end
  end

  class FileLogger
    def initialize file
      @file = open file, "a+"
    end
    def log msg
      @file.puts "#{Time.now}: #{msg}"
      @file.flush
    end
  end

  CONF_KEYS = [
    KW_COUNT = "count",
    KW_DAEMON = "daemon",
    KW_DROP_COMMAND = "drop-command",
    KW_DURATION = "duration",
    KW_INPUT = "input",
    KW_LOG = "log",
    KW_PATTERNS = "patterns",
    KW_PIDFILE = "pidfile",
    KW_VERBOSE = "verbose",
  ]

  CONF_DEFAULTS = {
    KW_COUNT => 3,
    KW_DAEMON => true,
    KW_DROP_COMMAND => [
      "/sbin/iptables", "-I", "INPUT", "-s", "%remote_address%", "-j", "DROP" ],
    KW_DURATION => 10,
    KW_INPUT => "/var/log/authfifo",
    KW_LOG => "syslog",
    KW_PATTERNS => [],
    KW_PIDFILE => "/var/run/autodrop.pid",
    KW_VERBOSE => false,
  }

  def self.loadconf file
    conf = YAML.load File.read file
    raise "wrong format" unless conf.is_a? Hash
    conf = CONF_DEFAULTS.merge conf

    badkw = conf.keys - CONF_KEYS
    raise "unknown keywords - #{badkw.join ","}" unless badkw.empty?

    [ KW_COUNT, KW_DURATION ].each { |k|
      unless conf[k].is_a? Integer
        raise "integer required - #{k}: #{conf[k].inspect}"
      end
    }
    [ KW_DROP_COMMAND, KW_INPUT, KW_LOG, KW_PIDFILE ].each { |k|
      unless conf[k].is_a? String
        raise "string required - #{k}: #{conf[k].inspect}"
      end
    }
    conf[KW_DROP_COMMAND] = conf[KW_DROP_COMMAND].split

    conf[KW_PATTERNS].map! { |item|
      unless [ String, Regexp ].include? item.class
        raise "string or regexp required - #{item.inspect}"
      end
      Regexp.new item
    }

    conf
  end

  def terminate whymsg, status = 0
    @logger.log "terminate (#{whymsg})"
    exit status
  end
  private :terminate

  class Dog
    def initialize addr, config
      @addr = addr
      @duration = config[KW_DURATION]
      @expire = Time.now + config[KW_DURATION]
      @count_max = config[KW_COUNT]
      @count = 1
      @drop_command = config[KW_DROP_COMMAND].map { |e|
        e == "%remote_address%" ? addr : e
      }
    end
    attr_reader :addr, :count_max, :drop_command, :duration
    attr_accessor :count, :expire
  end

  def run config
    @logger = nil
    case config[KW_LOG]
    when "syslog"
      @logger = SyslogLogger.new
    when "stdout"
      @logger = StdoutLogger.new
    else
      begin
        @logger = FileLogger.new config[KW_LOG]
      rescue
        warn "autodrop: can not open - #{config[KW_LOG]}"
        exit 1
      end
    end

    if config[KW_DAEMON]
      if Process.respond_to? :daemon
        Process.daemon
      else
        exit if fork
        Process.setsid
        exit if fork
        Dir.chdir "/"
        STDIN.reopen "/dev/null"
        STDOUT.reopen "/dev/null"
        STDERR.reopen "/dev/null"
      end
      File.write config[KW_PIDFILE], Process.pid
    end

    trap("SIGINT") { terminate "SIGINT" }
    trap("SIGTERM") { terminate "SIGTERM" }
    trap("SIGHUP") { terminate "SIGHUP" }

    @logger.log "start watching - #{config[KW_INPUT]}"
    unless File.ftype(config[KW_INPUT]) == "fifo"
      raise "not a named pipe - #{config[KW_INPUT]}"
    end
    fifofp = File.open config[KW_INPUT], File::RDWR

    @dogs = {}
    loop {
      ready = select [fifofp]
      next unless ready

      addr = nil
      line = ready[0][0].gets
      config[KW_PATTERNS].each { |pat|
        if line =~ pat
          addr = $1
          break
        end
      }
      next unless addr

      dog = @dogs[addr]
      if dog
        dog.count += 1
        dog.expire = Time.now + dog.duration
        @logger.log "#{dog.addr} bark! (#{dog.count})" if config[KW_VERBOSE]
        next
      end

      dog = Dog.new addr, config
      Thread.new(dog) { |dog|
        begin
          @dogs[dog.addr] = dog

          @logger.log "#{dog.addr} bark! (#{dog.count})" if config[KW_VERBOSE]

          loop {
            break if Time.now >= dog.expire

            if dog.count >= dog.count_max
              @logger.log "#{dog.addr} DROP"
              out = IO.popen(dog.drop_command, "r+", :err => [ :child, :out ]) { |io|
                buf = []
                while l = io.gets
                  buf.push l.chomp
                end
                buf
              }
              st = $?.exitstatus
              if st != 0
                @logger.log "DROP fail. command exit status #{st}"
                out.each { |l| @logger.log "|#{l}" }
              end
              break
            end

            # @logger.log "#{dog.addr} grrr" if config[KW_VERBOSE]
            sleep 1
          }
        rescue => ex
          @logger.log "error in worker"
          @logger.log "|#{ex}"
          ex.backtrace.each { |l| @logger.log "|#{l}" }
        ensure
          @dogs.delete dog.addr
          @logger.log "#{dog.addr} leave" if config[KW_VERBOSE]
        end
      }
    }
  rescue => ex
    @logger.log ex.message
    ex.backtrace.each { |l| @logger.log "|#{l}" }
    terminate "error", 1
  ensure
    File.unlink config[KW_PIDFILE] rescue nil
  end
end

### main

DEFAULT_CONFFILE = "/etc/autodrop.conf"

def usage
  puts <<EOD
usage: autodrop [options]
  -c, --config=FILE     specify config file
  -h, --help            print this
  -i, --input=FILE      specify input source
  -l, --log=FILE        specify log file or `syslog'
  -n, --no-daemon       run as no daemon
  -p, --pidfile=FILE    specify PID file
  -V, --version         print version
EOD
end

conffile = nil
opts = "c:i:hl:np:V"
longopts = {
  "config" => :required_argument,
  "help" => :no_argument,
  "input" => :required_argument,
  "log" => :required_argument,
  "no-daemon" => :no_argument,
  "pidfile" => :required_argument,
  "version" => :no_argument,
}

av = ARGV.dup
while (op, optarg = getopt(av, opts, longopts,
                           allow_empty_optarg:false, permute:true))
  case op
  when "c", "config"
    if optarg[0] == "/"
      conffile = optarg
    else
      conffile = File.join Dir.pwd, optarg
    end
  when "h", "help"
    usage
    exit
  when "V", "version"
    puts Autodrop::VERSION
    exit
  else
    exit 1 if op.is_a? Symbol
  end
end

conffile ||= DEFAULT_CONFFILE
begin
  conf = Autodrop.loadconf conffile
rescue => ex
  warn "autodrop: #{conffile} - #{ex}"
  exit 1
end

while (op, optarg = getopt ARGV, opts, longopts, allow_empty_optarg:false)
  case op
  when "c", "config", "h", "help", "V", "version"
    ;
  when "i", "input"
    if optarg[0] == "/"
      conf[Autodrop::KW_INPUT] = optarg
    else
      conf[Autodrop::KW_INPUT] = File.join Dir.pwd, optarg
    end
  when "l", "log"
    case optarg
    when "syslog"
      conf[Autodrop::KW_LOG] = "syslog"
    else
      if optarg[0] == "/"
        conf[Autodrop::KW_LOG] = optarg
      else
        conf[Autodrop::KW_LOG] = File.join Dir.pwd, optarg
      end
    end
  when "n", "no-daemon"
    conf[Autodrop::KW_DAEMON] = false
    conf[Autodrop::KW_LOG] = "stdout"
  when "p", "pidfile"
    if optarg[0] == "/"
      conf[Autodrop::KW_PIDFILE] = optarg
    else
      conf[Autodrop::KW_PIDFILE] = File.join Dir.pwd, optarg
    end
  else
    exit 1
  end
end
unless ARGV.empty?
  warn "autodrop: no arguments required - #{ARGV.join " "}"
  exit 1
end

Autodrop.new.run conf
