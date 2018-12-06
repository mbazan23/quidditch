
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
We increase the summary interval to 300 to have more response time
```shell
dshell> /config/global/summary_interval = 300
300 (Fixnum)
```
-->

Con este test se prueba el funcionamiento de la actualizacion de la base de datos, de la creacion
de reportes y del stats kiosk

We create a dns lookup, y luego buscamos el threat WDM en la kb. 
```ruby
>> p = PFlow.new(Time.now, 0)
>> p.dns_lookup('jameygibson.com', '1.2.3.4')

```
```ruby
>> old_wdm_threat = Threat.find_by(name: 'WhiteDreamMunchkins')
>> old_wdm_timestamp  = old_wdm_threat ? old_wdm_threat.updated_at : nil

```

Cuando inyectamos the dns lookup, se deberia producir un nuevo summary
A partir de este momento, los reportes deberian contener la informacion actualizada
del nuevo summary generado 
Por eso borramos los reportes anteriores y forzamos a crear unos nuevos
(si no deberiamos esperar 24 horas para que se creen los nuevos reportes)

```ruby
>> replay p                                                   #byexample: +timeout=10

```
```shell
rshell> sudo rm /opt/damballa/var/stash/*
<...>
rshell> tail -f /var/log/damballa | grep  -q Summarizing      #byexample: +timeout=300

```
(Creacion de reportes)
```ruby
>> trigger_csp_stats_kiosk_report :daily                       #byexample: +timeout=10
>> trigger_csp_stats_kiosk_report :frontman                    #byexample: +timeout=10

```

We checked that the reports and the database were updated
Ahora volvemos a buscar el threat WDM en la base de datos.
Si los reportes fueron actualizados correctamente, el threat debe tener actualizada 
su fecha de actualizacion. 
El threat tiene que tener la fecha de de actualizacion actualizada, indicando que los reportes
Finalmente comprobamos que realmente se trata del threat WDM a travez de su id

```ruby
>> threat_id = wait_until(120) do                              #byexample: +timeout 120
..   wdm_threat        = Threat.find_by(name: 'WhiteDreamMunchkins')
..   new_wdm_timestamp = wdm_threat ? wdm_threat.updated_at : nil
..   old_wdm_timestamp == new_wdm_timestamp ? nil : wdm_threat.id
.. end

```
```ruby
>>  puts threat_id
7277
```
