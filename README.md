<!--
Load the Harness engine (Ruby)

>> require_relative './harness.rb'               # byexample: +pass +timeout=30
>> Harness::init_test(self)           # byexample: +pass +timeout=30

>> require 'pp'
>> require 'resolv'
>> require 'splunk-sdk-ruby'

-->

<!--
Local Constants

>> SPLUNK_HOST = QA_HP_HELPER
>> SPLUNK_PORT = 8089
>> MC_SIEM_PORT = 1514

>> puts SPLUNK_HOST
<splunk-host>
>> puts SPLUNK_PORT
<splunk-port>
>> puts MC_SIEM_PORT
<mc-siem-port>

-->

<!--
Local Methods

# Given a search string for splunk, returns the result set as an array
# of event hashes
>> def splunk_lookup(search)
..  # connect to splunk
..    splunk = Splunk::connect(scheme: :https,
..                             host: SPLUNK_HOST,
..                             port: SPLUNK_PORT,
..                             username: 'admin',
..                             password: 'password')
..
..    # Perform a oneshot search on Splunk using our search criteria
..    stream = splunk.create_oneshot(search)
..
..    Splunk::ResultsReader.new(stream).each.map { |result| result['_raw'] }
..  end

>>  def wait_for_splunk_lookup(search, timeout)
..    log 'Querying Splunk...'
..    results = []
..
..    wait_until(timeout) do
..      results = splunk_lookup("search #{search}")
..      results.empty? ? nil : results
..    end
..  end

-->

<!--
Sanitization

>>  start_time = timestamp
>>  basic_sanitization

-->

## About Splunk and Arcsight
Both are Security Information and Event Management (SIEM), tools capable of monitoring the state in terms of security of an organization, must be perfectly integrated with all systems and must understand the behavior of the entire ICT infrastructure. Through the collection of login events, access to databases, firewall logs, proxy, IPS, application logs, etc, a SIEM is able to monitor and predict the future behavior of the ICT platform in such a way that in the face of unusual behavior of the platform can generate an alert and / or perform a certain action.
https://www.splunk.com/es_es/products/premium-solutions/splunk-enterprise-security.html
Note: qa-hp-1 contains a raised splunk that keeps listening

### We set the configuration of arcsight from dshell to connect with Splunk

```shell
dshell> expert
Expert mode is now on.
dshell> /config/global/summary_interval = 300
300 (Fixnum)
dshell> /config/global/integration/arcsight/destination_port = <mc-siem-port>    # byexample: +paste
1514 (Fixnum)
dshell> /config/global/integration/arcsight/filtering/filter_by_threat = false
false (FalseClass)
dshell> /config/global/integration/arcsight/filtering/include_msrt = false
false (FalseClass)
dshell> echo > /config/global/integration/arcsight/filtering/threats
dshell> /config/global/integration/arcsight/hostname = <splunk-host>             # byexample: +paste
qa-hp-1.atl.damballa (String)
dshell> /config/global/integration/arcsight/publish = true
true (TrueClass)
dshell> /config/global/integration/arcsight/source_port = 65432
65432 (Fixnum)
```




```ruby

>> sleep 10                                                                      # byexample: +timeout=11
>>  evilhost = "#{start_time}.jameygibson.com"
>>  cef_header_variables = /\|(\d+\.*)+\|\d+\|/
>>  add_sanitization(evilhost, '[EVILHOST]')
>>  add_sanitization(/start=\d+/, 'start=[TIMESTAMP]')
>>  add_sanitization(/end=\d+/, 'end=[TIMESTAMP]')
>>  add_sanitization(cef_header_variables, '[|VERSION|PID|]')

```

### We injected several dns
The DNS "evilhost" (jameygibson.com) should contain the "WDM threat"
The other domains should contain the threat "Conficker.C"

```ruby
>>  p = PFlow.new(Time.now, 0)
>>  domains = ["afgkrwsva.biz", "afmolpiykd.cc", "andqppix.com", "aykbcmtasc.com", "ccnnbnxf.net", "dexnembbp.com", "dfooda.cc", "emolykussqu.net", "ihckxhueod.net", "ihfmkpnf.cc"]
>>  domains.each do |domain|
..    p.dns_lookup(domain, nil, src_ip: '10.0.0.1', dst_ip: '10.0.0.1')
..  end                                                                         # byexample: +timeout=20
>>  p.dns_lookup(evilhost, '1.2.3.4', src_ip: '10.0.0.1', dst_ip: '10.0.0.1')   # byexample: +timeout=10

```
```ruby
>>  replay p                                                                    # byexample: +timeout=10
```

#### Consult Splunk for the DNS that contains the threat WDM
Deberiamos recibir el evento que contiene 
```ruby
>> events = wait_for_splunk_lookup(evilhost, 330)                               # byexample: +timeout=300
Querying Splunk...
>> add_artifact events, 'resolved-CEF-raw'
>> log events
["CEF:0|Damballa|SP Solution[|VERSION|PID|]classified_domain|8|cat=DNSQuery cnt=1 cs1=WhiteDreamMunchkins cs1Label=ThreatName cs2=Jamey DUDE cs2Label=IndustryName cs4=Multi-Purpose cs4Label=Intent cs5Label=MSThreat cs6=low cs6Label=F-SecureConfidence destinationDnsDomain=[EVILHOST] dst=1.2.3.4 dvchost=[HOST_MC] end=[TIMESTAMP] src=10.0.0.1 start=[TIMESTAMP]\nCEF:0|Damballa|SP Solution[|VERSION|PID|]classified_domain|7|cat=Domain Fluxing cnt=10 cs1=Conficker.C cs1Label=ThreatName cs2Label=IndustryName cs4=Information Stealer cs4Label=Intent cs5Label=MSThreat cs6=low cs6Label=F-SecureConfidence destinationDnsDomain=Non-Existent Domain dvchost=[HOST_MC] end=[TIMESTAMP] src=10.0.0.1 start=[TIMESTAMP]"]
```



```ruby
>>  coldcase_id = events.first.match(/SP_Solution|\d+\.*|(\d+)/).captures.first

```
#### Retrieve the nxdomain event...
```ruby
>> events = wait_for_splunk_lookup("#{coldcase_id} Conficker.C", 330)           # byexample: +timeout=300
Querying Splunk...
>> add_artifact events.first, 'nxdomain-CEF-raw'
>> log events.first
CEF:0|Damballa|SP Solution[|VERSION|PID|]classified_domain|8|cat=DNSQuery cnt=1 cs1=WhiteDreamMunchkins cs1Label=ThreatName cs2=Jamey DUDE cs2Label=IndustryName cs4=Multi-Purpose cs4Label=Intent cs5Label=MSThreat cs6=low cs6Label=F-SecureConfidence destinationDnsDomain=[EVILHOST] dst=1.2.3.4 dvchost=[HOST_MC] end=[TIMESTAMP] src=10.0.0.1 start=[TIMESTAMP]
CEF:0|Damballa|SP Solution[|VERSION|PID|]classified_domain|7|cat=Domain Fluxing cnt=10 cs1=Conficker.C cs1Label=ThreatName cs2Label=IndustryName cs4=Information Stealer cs4Label=Intent cs5Label=MSThreat cs6=low cs6Label=F-SecureConfidence destinationDnsDomain=Non-Existent Domain dvchost=[HOST_MC] end=[TIMESTAMP] src=10.0.0.1 start=[TIMESTAMP]

```

#### reset arcsight

```shell
dshell> reset /config/global/integration/arcsight/destination_port
/config/global/integration/arcsight/destination_port: <mc-siem-port> => 514      # byexample: +paste
dshell> reset /config/global/integration/arcsight/filtering/filter_by_threat
/config/global/integration/arcsight/filtering/filter_by_threat: false => false
dshell> reset /config/global/integration/arcsight/filtering/include_msrt
/config/global/integration/arcsight/filtering/include_msrt: false => false
dshell> reset /config/global/integration/arcsight/filtering/threats
/config/global/integration/arcsight/filtering/threats: [] => []
dshell> reset /config/global/integration/arcsight/hostname
/config/global/integration/arcsight/hostname: qa-hp-1.atl.damballa =>$
dshell> reset /config/global/integration/arcsight/publish
/config/global/integration/arcsight/publish: true => false
dshell> reset /config/global/integration/arcsight/source_port
/config/global/integration/arcsight/source_port: 65432 => 0
```
