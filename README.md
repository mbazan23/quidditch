
<!--
Load the Harness engine (Ruby)

>> require_relative './harness.rb'                                                              # byexample: +pass +timeout=30
>> Harness::init_test(self, 'product' => 'csp','active_record_on' => true,'bg_noise' => true)   # byexample: +pass +timeout=30

>> require_relative "lib/csp/csp_stats_kiosk_helpers.rb"
>> require_relative "lib/csp/activerecord_classes.rb"

Grab anything involving frontman for debugging
>> add_custom_grep('/var/log/damballa', 'frontman' => 'frontman')

-->

<!--
We increase the summary interval to 300 to have more response time to see the summary
```shell
dshell> /config/global/summary_interval = 300
300 (Fixnum)
```
-->

##     Generation of reports through stats kiosk

We create a dns lookup, and then we look for the threat WDM in the kb.
```ruby
>> p = PFlow.new(Time.now, 0)
>> p.dns_lookup('jameygibson.com', '1.2.3.4')

```
```ruby
>> old_wdm_threat = Threat.find_by(name: 'WhiteDreamMunchkins')
>> old_wdm_timestamp  = old_wdm_threat ? old_wdm_threat.updated_at : nil

```

When we inject the dns lookup, a new summary should be produced.
```ruby
>> replay p                                                   #byexample: +timeout=10

```
```shell
rshell> sudo rm /opt/damballa/var/stash/*
<...>
rshell> tail -f /var/log/damballa | grep  -q Summarizing      #byexample: +timeout=300

```
We force Creation of reports through the stats kiosk...
From this moment, the reports should contain the updated information
of the new summary generated.
```ruby
>> trigger_csp_stats_kiosk_report :daily                       #byexample: +timeout=10
>> trigger_csp_stats_kiosk_report :frontman                    #byexample: +timeout=10

```
##     Verification that the reports and the database were updated.
Now we go back to look for the threat WDM in the database.
If the reports were generated correctly, the threat should have updated
your date of update.
By last we see that it really is the threat WDM through its id

```ruby
>> threat_id = wait_until(120) do                              #byexample: +timeout 120
..   wdm_threat        = Threat.find_by(name: 'WhiteDreamMunchkins')
..   new_wdm_timestamp = wdm_threat ? wdm_threat.updated_at : nil
..   old_wdm_timestamp == new_wdm_timestamp ? nil : wdm_threat.id
.. end
>>  puts threat_id
7277
```
