<!--
Load the Harness engine (Ruby)

>> require_relative './harness.rb'                                                              # byexample: +pass +timeout=30
>> Harness::init_test(self, 'product' => 'csp','active_record_on' => true,'bg_noise' => true)   # byexample: +pass +timeout=30

>> require_relative "lib/csp/csp_stats_kiosk_helpers.rb"
>> require_relative "lib/csp/activerecord_classes.rb"

Grab anything involving frontman for debugging
>> add_custom_grep('/var/log/damballa', 'frontman' => 'frontman')

-->
## Generamos un nuevo summary para actualizar la base de datos
#### Creamos un dns lookup
Luego lo inyectaremos para provocar un nuevo summary
```ruby
>> p = PFlow.new(Time.now, 0)
>> p.dns_lookup('jameygibson.com', '1.2.3.4')

```
Aumentamos el intervalo de los summaryes a 300
```shell
dshell> /config/global/summary_interval = 300
300 (Fixnum)
```

#### Buscamos y guardamos el threat WDM junto con su hora de actualizacion
Este threat luego se comparara con un threat que este más actualizado
```ruby
>> old_wdm_threat = Threat.find_by(name: 'WhiteDreamMunchkins')
>> old_wdm_timestamp  = old_wdm_threat ? old_wdm_threat.updated_at : nil

```

#### Inyectamos el dns loockup
```ruby
>> replay p                                                   #byexample: +timeout=10

```
## Generamos reportes con los summarys actualizados
#### Borramos todos reportes antiguos
Puede que no haya nada en la carpeta por lo tanto capturamos el mensaje que nos dice que
la carpeta esta vacia.
Despues esperamos a que aparezca un nuevo summary para crear un nuevo reporte ...

```shell
rshell> sudo rm /opt/damballa/var/stash/*
<posible-mensaje-de-carpeta-vacia>
rshell> tail -f /var/log/damballa | grep  -q Summarizing      #byexample: +timeout=300

```

#### Creamos los reportes nuevos
Cuando detectamos un nuevo summary, generamos los reportes con esta nueva informacion
Esto normalmente deberia tardar 24 hs pero adelantaremos el proceso

```ruby
>> trigger_csp_stats_kiosk_report :daily                       #byexample: +timeout=10
>> trigger_csp_stats_kiosk_report :frontman                    #byexample: +timeout=10

```

## Comprobamos que los reportes y la base de datos se actualizaron
Creamos una variable con el mismo threat del principio, y comprobamos que se haya actualizado la base de datos.
Para comprobar esto, la hora de actualizacion de los threats deben ser diferentes

```ruby
>> threat_id = wait_until(120) do                              #byexample: +timeout 120
..   wdm_threat        = Threat.find_by(name: 'WhiteDreamMunchkins')
..   new_wdm_timestamp = wdm_threat ? wdm_threat.updated_at : nil
..   old_wdm_timestamp == new_wdm_timestamp ? nil : wdm_threat.id
.. end

```

Por ultimo imprimimos el id del threat
```ruby
>>  puts threat_id
7277
```
