autodrop README

2009, NOZAWA Hiromasa, Tokyo Japan


= About

Autodrop is a daemon, observes syslog logs and forbid accesses from
remote hosts who continue wrong attempt to our host like knocking port
22 for 100,000,000 times a day.  Autodrop uses iptables(8) and named
pipe from syslogd.

Autodrop adds DROP rule into iptables' INPUT table for the remote host
which generates log messages matched with same reguler expression more
than specified times in specified interval.

Multiple regular expression can be specified by config file.  Also
matching count threshold and interval time to continue counting can be
customizable.

Autodrop watches a named pipe and not neither does polling nor stat(2)
on many log files.  You need syslogd which can output logs to named
pipe.

Autodrop is written in Ruby scripting language then surely it will not
suit for very high traffic sites.  However it works well to shut up
port 22 knockers for my small site.

Using autodrop can also shut out yourself from your host.  Be careful.


= Requirement

* linux box (for iptables)
* syslogd (can output logs to named pipes)
* ruby 1.8.6 or later (I have not run autodrop on other versions)


= Licence

BSD


= Install

After doing 'gem install', you need to write config file.
Fix #! line in the script if necessary.

*1. gem install autodrop

*2. cd <GEMDIR>/gems/autodrop-x.x.x/conf

*3. sudo cp autodrop.conf.default /etc

*4. Edit /etc/autodrop.conf


= Usage

== Start

	------------------------------
	$ sudo ruby autodrop.rb
	------------------------------

Default config file is /etc/autodrop.conf .
Another config file can be specified from command line.

	------------------------------
	$ ruby autodrop.rb -c /foo/bar/autodrop.conf
	------------------------------

== Stop

	------------------------------
	$ sudo kill `cat /var/run/autodrop.pid`
	------------------------------

== When Running

Autodrop itself also outputs syslog logs with prefix 'autodrop' when
started, stopped and each occurrences of DROP.

After running autodrop, iptables's INPUT table will filled with DROP
rules in few weeks or months but autodrop does not have ability to
clear them.  Please do it by your hand when it required.


= autodrop.conf

All variables are not omit-able.
These are Ruby's constant variables.

* MESSAGES_TO_WATCH

	Array of regular expressions.
	Each expression must have $1 and it must match an IP address.

	------------------------------
	MESSAGES_TO_WATCH =
	  [
	   /Invalid user [^\s]+ from (.+)/,
	   /Address (.+) maps to.*POSSIBLE BREAK-IN ATTEMPT!/,
	  ]
	------------------------------

* COUNT_MAX

	Matching count to do DROP.

	------------------------------
	COUNT_MAX = 3
	------------------------------

* INTERVAL

	Interval time to continue counting for a remote host matched
	to a pattern.  Specify in seconds.
	Each interval timers are reset on each matches.

	------------------------------
	INTERVAL = 10
	------------------------------

* IPTABLES_PROGRAM

	iptables(8) command path.

	------------------------------
	IPTABLES_PROGRAM = '/sbin/iptables'
	------------------------------

* PIDFILE

	PID file path.

	------------------------------
	PIDFILE = '/var/run/autodrop.pid'
	------------------------------

* WATCH_FIFO

	Named pipe path to watch.

	------------------------------
	WATCH_FIFO = '/var/log/authfifo'
	------------------------------


= Example: syslogd configuration

Create fifo,
	------------------------------
	mkfifo /var/log/authfifo
	------------------------------
and add it to your syslog.conf .
	------------------------------
	auth,authpriv.*		/var/log/auth.log

	# this
	auth.*			|/var/log/authfifo
	------------------------------

`|' means `out put logs to this pipe'.
See your syslog.conf(5) for more details.

#eof
