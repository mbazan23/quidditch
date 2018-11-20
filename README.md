<!--
Load the Harness engine (Ruby)

>> require_relative './harness.rb'                                                              # byexample: +pass +timeout=30
>> Harness::init_test(self, 'product' => 'csp','active_record_on' => true,'bg_noise' => true)   # byexample: +pass +timeout=30

>> require_relative "lib/csp/csp_stats_kiosk_helpers.rb"
>> require_relative "lib/csp/activerecord_classes.rb"

Grab anything involving frontman for debugging
>> add_custom_grep('/var/log/damballa', 'frontman' => 'frontman')

-->
## We generate a new summary to update the database

#### We create a dns lookup
Then we will inject it to provoke a new summary
```ruby
>> p = PFlow.new(Time.now, 0)
>> p.dns_lookup('jameygibson.com', '1.2.3.4')

```
We increase the summary interval to 300
```shell
dshell> /config/global/summary_interval = 300
300 (Fixnum)
```

#### We look for and keep the WDM threat along with its update time
Later, this threat will be compared to a more up-to-date threat.
```ruby
>> old_wdm_threat = Threat.find_by(name: 'WhiteDreamMunchkins')
>> old_wdm_timestamp  = old_wdm_threat ? old_wdm_threat.updated_at : nil

```

#### We injected the dns lookup
```ruby
>> replay p                                                   #byexample: +timeout=10

```

## We generate reports with updated summaries.

#### We delete all old reportss
There may not be anything in the folder so we capture the message that tells us that
the folder is empty
Then we wait for a new summary to create a new report ...
```shell
rshell> sudo rm /opt/damballa/var/stash/*
<posible-mensaje-de-carpeta-vacia>
rshell> tail -f /var/log/damballa | grep  -q Summarizing      #byexample: +timeout=300

```

#### We create new reports
When we detect a new summary, we generate the reports with this new information.
This normally should take 24 hours but we will accelerate the process
```ruby
>> trigger_csp_stats_kiosk_report :daily                       #byexample: +timeout=10
>> trigger_csp_stats_kiosk_report :frontman                    #byexample: +timeout=10

```

## We checked that the reports and the database were updated
We create a variable with the same threat of the beginning, and verify that the database has been updated.
To check this, the update time of the threats must be different
```ruby
>> threat_id = wait_until(120) do                              #byexample: +timeout 120
..   wdm_threat        = Threat.find_by(name: 'WhiteDreamMunchkins')
..   new_wdm_timestamp = wdm_threat ? wdm_threat.updated_at : nil
..   old_wdm_timestamp == new_wdm_timestamp ? nil : wdm_threat.id
.. end

```

Finally we print the threat id
```ruby
>>  puts threat_id
7277
```
