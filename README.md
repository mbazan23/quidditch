
<!--
Load the Harness engine (Ruby)

>> require_relative './harness.rb'                                              # byexample: +pass +timeout=30
>> Harness::init_test(self)                                                     # byexample: +pass +timeout=30

>> require 'pp'
>> require 'resolv'
>> require 'splunk-sdk-ruby'

-->

<!--
Local Constants

>> SPLUNK_HOST = QA_HP_HELPER
>> SPLUNK_PORT = 8089
>> MC_SIEM_PORT = 1514

>> puts QA_HP_HELPER
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

-->

# Introduction
Failsafe supports integration with different SIEMs by sending events in CEF format (developed by ArcSight, although it is compatible with other SIEMs).
The tool called arcsight that is configured from dShell, simply takes the events that our product detects, and based on these generates CEF events that are sent to a specific Host and Port.  
The receiving SIEMs will receive this CEM event and according to their features can show this data in their UI.
Note: this tool is called arcsight, because arcsight was the first SIEM that was added to the integrations. We could change that name in later fixes.  
https://wiki.atl.damballa/display/ENG/Arcsight+Integration  
https://wiki.atl.damballa/display/PM/D.+SIEM%2C+3rd+Party%2C+and+Other+Docs


## About Splunk and Arcsight
Both are Security Information and Event Management (SIEM), tools capable of monitoring the state in terms of security of an organization. Through the collection of login events,    access to databases, firewall logs, proxy, IPS, application logs, etc. the platforms can generate an alert and/or perform a certain action.  
https://www.splunk.com/es_es/products/premium-solutions/splunk-enterprise-security.html
### The integration of CSP and Splunk consists in when CSP detects a malware it will notify them about it.
Note: currently qa-hp-1 contains a splunk and that's where we connect
https://wiki.atl.damballa/display/ENG/Splunk+automation

## We set the configuration of arcsight from dshell to connect with Splunk

```shell
dshell> expert on
Expert mode is now on.
dshell> /config/global/summary_interval = 300
300 (Fixnum)
dshell> /config/global/integration/arcsight/destination_port = <mc-siem-port>   # byexample: +paste
<mc-siem-port> (Fixnum)
dshell> /config/global/integration/arcsight/filtering/filter_by_threat = false
false (FalseClass)
dshell> /config/global/integration/arcsight/filtering/include_msrt = false
false (FalseClass)
dshell> echo > /config/global/integration/arcsight/filtering/threats
dshell> /config/global/integration/arcsight/hostname = <splunk-host>            # byexample: +paste
<splunk-host> (String)
dshell> /config/global/integration/arcsight/publish = true
true (TrueClass)
dshell> /config/global/integration/arcsight/source_port = 65432
65432 (Fixnum)
```

<!--

```ruby
The 9-second sleep is necessary, otherwise the test will not pass
>>  sleep 9                                                                  # byexample: +timeout=10

```
-->

## We will inject several DNS

The nxdomains should contain the threat "Conficker.C" Note: a DNS query can generate multiple instances of the same threat

The DNS jameygibson.com should contain the "WDM threat"

```ruby
>>  evilhost = "#{timestamp}.jameygibson.com"
>>  p = PFlow.new(Time.now, 0)
>>  nxdomains = ["afgkrwsva.biz", "afmolpiykd.cc", "andqppix.com", "aykbcmtasc.com", "ccnnbnxf.net", "dexnembbp.com", "dfooda.cc", "emolykussqu.net", "ihckxhueod.net", "ihfmkpnf.cc"]
>>  nxdomains.each do |domain|
..    p.dns_lookup(domain, nil, src_ip: '10.0.0.1', dst_ip: '10.0.0.1')
..  end
>>  p.dns_lookup(evilhost, '1.2.3.4', src_ip: '10.0.0.1', dst_ip: '10.0.0.1')
>>  replay p                                                                    # byexample: +timeout=10

```

## Retrieve the jameygibson.com DNS event through Splunk.
We should obtain the information of an event that contains the threat WDM, caused by the dns jameygibson.com
```ruby
>> events = wait_for_splunk_lookup(evilhost, 100)                               # byexample: +timeout=100
Querying Splunk...
>> puts events
<...>cs1=WhiteDreamMunchkins cs1Label=ThreatName<...>destinationDnsDomain=<...>jameygibson.com<...>src=10.0.0.1<...>
```


## Retrieve the nxdomain event through Splunk.
We should obtain the information of an event that contains the threat Conficker.C, caused by a nxdomain(Non-Existent Domain)

```ruby
>> events = wait_for_splunk_lookup(" Conficker.C", 100)                         # byexample: +timeout=100
Querying Splunk...
>> puts events.first
<...>cs1=Conficker.C cs1Label=ThreatName<...>destinationDnsDomain=Non-Existent Domain<...>src=10.0.0.1<...>
```
<!--
## Reset arcsight configuration

```shell
dshell> reset /config/global/integration/arcsight/destination_port              # byexample: +pass
dshell> reset /config/global/integration/arcsight/filtering/filter_by_threat    # byexample: +pass
dshell> reset /config/global/integration/arcsight/filtering/include_msrt        # byexample: +pass
dshell> reset /config/global/integration/arcsight/filtering/threats             # byexample: +pass
dshell> reset /config/global/integration/arcsight/hostname                      # byexample: +pass
dshell> reset /config/global/integration/arcsight/publish                       # byexample: +pass
dshell> reset /config/global/integration/arcsight/source_port                   # byexample: +pass

```
-->
