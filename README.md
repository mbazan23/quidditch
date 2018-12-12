<!--
Load the Harness engine (Ruby)

>> require_relative './harness.rb'                                              # byexample: +pass +timeout=30
>> Harness::init_test(self)                                                     # byexample: +pass +timeout=30

>> require 'pflow'
>> require 'pp'
>> require 'resolv'

>> require_relative 'lib/csp/csp_barista/csp_barista.rb'
>> require_relative 'harness.rb'
>> require_relative "lib/shared/dshell_helpers.rb"
>> require_relative "lib/shared/varys.rb"
>> require_relative "lib/shared/debug_log.rb"

-->

<!--
Sanitization and save logs of sent events
>> basic_sanitization
>> add_custom_grep('/var/log/damballa', 'coldcase_kiosk_logs' => 'ColdcaseKiosk')
>> debug_log 'Setting up varys listener'
>> varys_port = Varys.create_listener('udp')
>> add_sanitization(varys_port.to_s, '[ARCSIGHT_DEST_PORT]')
>> add_sanitization('cs1=Testing', 'cs1=[TESTING BOTNET]')
>> add_sanitization(/end=\d+/, 'end=[TIMESTAMP]')
>> add_sanitization(/start=\d+/, 'start=[TIMESTAMP]')
-->

<!--
Local Constants
>> puts QA_HP_HELPER
<varys-host>
>> puts varys_port.to_i
<varys-port>

-->



# About Varys and Arcsight

## We set the configuration of arcsight from dshell to connect with Varys

```shell
dshell> /config/global/summary_interval = 300
300 (Fixnum)
dshell> /config/global/integration/arcsight/destination_port = <varys-port>     # byexample: +paste
<mc-siem-port> (Fixnum)
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
## We injected several dns

The destination 200.2.3.4 belonging to test.damballa.com should generate the threat "Testing"
```ruby
>> traffic = PFlow.new(Time.now, 0)
>> traffic.dns_lookup('test.damballa.com',
..                     '200.2.3.4',
..                     src_ip: '10.2.3.4',
..                     dst_ip: '200.3.4.5',
..                    )

```

The destination 200.2.3.5 belonging to the threat generated by CSP_barista should generate threat SevenLavaFighters (associated with a dns ahobson. <...>. Test.us)
```ruby
>>  CSPBaristaClient.init_barista(mc['ip'],Harness.harness)                   # byexample: +timeout=30
>>  kb_f_threats = CSPBaristaClient.f_secure_threats(mc['ip'])
>>  types = {}
>>  kb_f_threats.each_pair { |k,v| types[v] = CSPBaristaClient.kb_threat(mc['ip'], k) }
>>  types.each_pair do |k,threat|
..    add_sanitization("cs1=#{threat.name}", "cs1=[#{k.upcase} THREAT NAME]")
..    add_sanitization("destinationDnsDomain=#{threat.domains[0]}", "cs1=[#{k.upcase} DOMAIN NAME]")
..  end                                                                       # byexample: +timeout=10
>>  types.each_pair do |k,threat|
..     traffic.dns_lookup(threat.domains[0],
..                       "200.2.3.5",
..                       src_ip: '10.2.3.4',
..                       dst_ip: '200.3.4.5',
..                       )
..  end                                                                       # byexample: +timeout=10

```

```ruby
>>  replay traffic                                                              # byexample: +timeout=10

```

## Pull resulting event from varys
We should get an event that contains:  
destination 200.2.3.5 belonging to the threat generated by SCP_barista  
and the destination 200.2.3.4 belonging to test.damballa.com.

```ruby
>> result = []
>> wait_until(300) do
..   sleep 1
..   result = Varys.fetch('udp', varys_port)
..   result.count > 1
.. end                                                                          # byexample: +timeout=300
>> puts result
<...>cs1=SevenLavaFighters cs1Label=ThreatName<...>destinationDnsDomain=ahobson.<...>.test.us dst=200.2.3.5<...>
<...>cs1=Testing cs1Label=ThreatName<...>destinationDnsDomain=test.damballa.com dst=200.2.3.4<...>
```






## Stopping Varys Listener and Reset arcsight configuration
```ruby
>> Varys.stop('udp', varys_port)

```
```shell
dshell> reset /config/global/integration/arcsight/destination_port
<...> => 514
dshell> reset /config/global/integration/arcsight/filtering/filter_by_threat
/config/global/integration/arcsight/filtering/filter_by_threat: false => false
dshell> reset /config/global/integration/arcsight/filtering/include_msrt
/config/global/integration/arcsight/filtering/include_msrt: false => false
dshell> reset /config/global/integration/arcsight/filtering/threats
/config/global/integration/arcsight/filtering/threats: [] => []
dshell> reset /config/global/integration/arcsight/hostname                      # byexample: +paste
/config/global/integration/arcsight/hostname: <varys-host><...>
dshell> reset /config/global/integration/arcsight/publish
/config/global/integration/arcsight/publish: true => false
dshell> reset /config/global/integration/arcsight/source_port
/config/global/integration/arcsight/source_port: 65432 => 0
```
