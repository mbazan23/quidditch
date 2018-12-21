
<!--
Load the Harness engine (Ruby)

>> require_relative './harness.rb'                                              # byexample: +pass +timeout=30
>> Harness::init_test(self)                                                     # byexample: +pass +timeout=30

>> require 'pflow'
>> require 'pp'
>> require 'resolv'

>> require_relative 'lib/csp/csp_barista/csp_barista.rb'
>> require_relative "lib/shared/dshell_helpers.rb"
>> require_relative "lib/shared/varys.rb"




-->



<!--
Local Constants  (originally <varys-host> was QA_HP_HELPER)
>> varys_host = "10.81.0.81"
>> varys_port = "8080"
>> arcsight_port = Varys.create_listener('udp',"ip" => varys_host, "port"=> varys_port).to_i
>> syslog_port   = Varys.create_listener('udp',"ip" => varys_host, "port"=> varys_port).to_i
>> perftech_port = Varys.create_listener('tcp',"ip" => varys_host, "port"=> varys_port).to_i

>> puts varys_host
<varys-host>
>> puts arcsight_port
<arcsight-port>
>> puts syslog_port
<syslog-port>
>> puts perftech_port
<perftech-port>
-->

<!--
Local methods
>> def fetch_until(number_of_results, time, type, port, opts = {})
..  number_of_results = number_of_results
..  time = time
..  type = type
..  port = port
..  options = opts
..  result = []
..  wait_until(time) do
..    sleep 1
..    result = Varys.fetch(type,port, options)
..    result.count >= number_of_results
..  end
.. result
.. end                                                                          #

-->
# How do integrations with third parties work?
The integrations are based on the conversion of the format of events generated by CSP to an event format of another product (SIEM, specific protocols, etc.), which is sent to a specific IP and port.

## About the event formats that CSP can send
* CSP can send events in CEF format (common event format) owner of Arcsight, which is also compatible with other SIEM.  

* You can also send events to Perftech through a mobile notification format (very short).  

* Finally, it has support for syslog, a protocol for sending registration messages in an IP computer network

## How to start Varys?
Before starting the test, it is important that Varys is active, otherwise no one will be listening to the events we send. To do this, simply go to the Varys directory and execute:

rackup config.ru --port=8080 --host 0.0.0.0



# How does the delivery of events to third parties work?

### STEP 1  
The specific third party is configured: destination IP, destination port, etc.
Note: The third-party product must be listening in that port. In our case, we use Varys as an event receiver.

```shell
dshell> expert on
Expert mode is now on.
dshell> /config/global/summary_interval = 300
300 (Fixnum)
```

#### Configuring ArcSight (CEF)

```shell
dshell> /config/global/integration/arcsight/destination_port = <arcsight-port>  # byexample: +paste
<arcsight-port> (Fixnum)
dshell> /config/global/integration/arcsight/filtering/filter_by_threat = false
false (FalseClass)
dshell> /config/global/integration/arcsight/filtering/include_msrt = false
false (FalseClass)
dshell> echo > /config/global/integration/arcsight/filtering/threats
dshell> /config/global/integration/arcsight/hostname = <varys-host>             # byexample: +paste
<varys-host> (String)
dshell> /config/global/integration/arcsight/publish = true
true (TrueClass)
dshell> /config/global/integration/arcsight/source_port = 65432
65432 (Fixnum)

```

#### Configuring Syslog

```shell
dshell> /config/global/integration/syslog/destination_port = <syslog-port>      # byexample: +paste
<syslog-port> (Fixnum)
dshell> /config/global/integration/syslog/hostname = <varys-host>               # byexample: +paste
<varys-host> (String)
dshell> /config/global/integration/syslog/publish = true
true (TrueClass)
dshell> /config/global/integration/syslog/send_header = true
true (TrueClass)
dshell> /config/global/integration/syslog/source_port = 65431
65431 (Fixnum)

```

#### Configuring Perftech

```shell
dshell> /config/global/integration/perftech/port = <perftech-port>              # byexample: +paste
<perftech-port> (Fixnum)
dshell> /config/global/integration/perftech/hostname = <varys-host>             # byexample: +paste
<varys-host> (String)
dshell> /config/global/integration/perftech/publish = true
true (TrueClass)
```


### STEP 2  
When CSP detects traffic, it is added to a summary file that contains evidence. The minimum time to create a summary is 300 seconds.


#### We create traffic with two different DNS
We create traffic with two different dns.
The first DNS is hardcoded and is for testing, the second DNS belongs to a list of threats of the KB.

```ruby
>>    traffic = PFlow.new(Time.now, 0)
>>    traffic.dns_lookup('test.damballa.com',
..                       '200.2.3.4',
..                       src_ip: '10.2.3.4',
..                       dst_ip: '200.3.4.5',
..                      )
>>    CSPBaristaClient.init_barista(mc['ip'],Harness.harness)                   # byexample: +timeout=30
>>    # if you need to look for more ids of threats you can use CSPBaristaClient.f_secure_threats(mc['ip'])
>>    # id 7292 belongs to the threat SevenLavaFighters
>>    threat  = CSPBaristaClient.kb_threat(mc['ip'], 7292)                      # byexample: +timeout=10
>>    traffic.dns_lookup(threat.domains[0],
..                         "200.2.3.5",
..                         src_ip: '10.2.3.4',
..                         dst_ip: '200.3.4.5',
..                         )

```
Note: Repeated traffics will only generate one event (the number of repetitions is indicated in the summary)  
Probably this is to not saturate the sending of events

```ruby
>>  replay traffic                                                              # byexample: +timeout=10
>>  replay traffic                                                              # byexample: +timeout=10

```

### STEP 3  
If the third party is activated, it converts the events contained in the Summary and sends them to the destination host (in this case all three are activated).


## We retrieve sent events and verify that they are correct

#### We Fetch ArcSight Events

```ruby
>> puts fetch_until(1,330,'udp', arcsight_port, "ip" =>"10.81.0.81" , "port" => "8080") # byexample: +timeout=330
<...>CEF:0|Damballa|SP Solution|<...>cs1=SevenLavaFighters cs1Label=ThreatName<...>destinationDnsDomain=ahobson.<...>.test.us dst=200.2.3.5<...>
<...>CEF:0|Damballa|SP Solution|<...>cs1=Testing cs1Label=ThreatName<...>destinationDnsDomain=test.damballa.com dst=200.2.3.4<...>

```

## We Fetch Syslog Events

```ruby
>> puts fetch_until(1,330,'udp', syslog_port, "ip" =>"10.81.0.81" , "port" => "8080") # byexample: +timeout=330
<...>SP_Solution 100 DNS CEF:0|Damballa|SP Solution|<...>cs1=SevenLavaFighters cs1Label=ThreatName<...>destinationDnsDomain=ahobson.<...>.test.us dst=200.2.3.5<...>
<...>SP_Solution 100 DNS CEF:0|Damballa|SP Solution|<...>cs1=Testing cs1Label=ThreatName<...>destinationDnsDomain=test.damballa.com dst=200.2.3.4<...>

```

#### We Fetch Perftech Events  

```ruby
>> puts fetch_until(1,330,'tcp', perftech_port, "ip" =>"10.81.0.81" , "port" => "8080") # byexample: +timeout=330
subscriber 10.2.3.4 if since 300 add policy damballaSecurityNotice set tag damballaThreat "SevenLavaFighters" set tag damballaIntent "Multi-Purpose" set tag damballaIndustryName <...> set tag damballaFSecureConfidence "<...>"

```

<!--
#### We check the cleanliness of the events received

```ruby
>> puts Varys.clear('udp',arcsight_port , "ip" =>"10.81.0.81" , "port" => "8080")
[]
>> puts Varys.clear('udp',syslog_port , "ip" =>"10.81.0.81" , "port" => "8080")
[]
>> puts Varys.clear('tcp',perftech_port , "ip" =>"10.81.0.81" , "port" => "8080")
[]
```



#### Stopping Varys Listeners
```ruby
>> Varys.stop('udp', varys_port)                                                # byexample: -skip +pass
>> Varys.stop('udp', syslog_port)                                               # byexample: -skip +pass
>> Varys.stop('udp', perftech_port)                                             # byexample: -skip +pass

```
## Reset Arcsight configuration
```shell
dshell> reset /config/global/integration/arcsight/destination_port              # byexample: -skip +pass
dshell> reset /config/global/integration/arcsight/filtering/filter_by_threat    # byexample: -skip +pass
dshell> reset /config/global/integration/arcsight/filtering/include_msrt        # byexample: -skip +pass
dshell> reset /config/global/integration/arcsight/filtering/threats             # byexample: -skip +pass
dshell> reset /config/global/integration/arcsight/hostname                      # byexample: -skip +pass
dshell> reset /config/global/integration/arcsight/publish                       # byexample: -skip +pass
dshell> reset /config/global/integration/arcsight/source_port                   # byexample: -skip +pass

```

## Reset Syslog configuration

```shell
dshell> reset /config/global/integration/syslog/destination_port                # byexample: -skip +pass
dshell> reset /config/global/integration/syslog/hostname                        # byexample: -skip +pass
dshell> reset /config/global/integration/syslog/publish                         # byexample: -skip +pass
dshell> reset /config/global/integration/syslog/send_header                     # byexample: -skip +pass
dshell> reset /config/global/integration/syslog/source_port                     # byexample: -skip +pass

```


## Reset Perftech configuration

```shell
dshell> reset /config/global/integration/perftech/port                          # byexample: -skip +pass
dshell> reset /config/global/integration/perftech/hostname                      # byexample: -skip +pass
dshell> reset /config/global/integration/perftech/publish                       # byexample: -skip +pass

```
-->

## What is Varys and what does it do?
Varys is a service that receives events. A specific port opens for each connection.
Varys stores the messages in a array, which can be accessed through a search.


## What is SIEM?
SIEM (security information and event management) is a technology capable of detecting, responding and neutralizing computer threats.  
Its main objective is the global vision of the security of information technology.  
A SIEM system allows absolute control over the company's IT security. By having information and total management on all the events  
that happen second by second, it is easier to find trends and focus on unusual patterns.
* The SIEMS market leaders are Arcsight, Splunk and others

## More info about integrations

Arcsight Integration:  
https://wiki.atl.damballa/display/ENG/Arcsight+Integration  
Syslog Integration :  
https://wiki.atl.damballa/display/PM/D.+SIEM%2C+3rd+Party%2C+and+Other+Docs?preview=%2F11895583%2F15368278%2FDamballa+Failsafe+Syslog+Integration+5_2.pdf  
PerfTech Integration :  
https://wiki.atl.damballa/display/PM/Damballa+CSP?preview=%2F9047915%2F17596539%2FDamballa+CSP+PerfTech+Integration+Guide+2.1+v.1.1.pdf  
D. SIEM, 3rd Party, and Other Docs:  
https://wiki.atl.damballa/pages/viewpage.action?spaceKey=PM&title=D.+SIEM%2C+3rd+Party%2C+and+Other+Docs  
