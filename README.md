<!--
Load the Harness engine (Ruby)

>> require_relative './harness.rb'                                              # byexample: +pass +timeout=30
>> Harness::init_test(self)                                                     # byexample: +pass +timeout=30

Reset the users (delete any extra user from a previous test)
dshell> expert on                                                               # byexample: +pass
dshell> reset /config/global/access/users                                       # byexample: +pass

We raised a Radius server
$ sudo docker run --rm --name freeradius -p 1812-1813:1812-1813/udp freeradius & sleep 10   # byexample: +fail-fast +timeout=11
<...>
Ready to process requests

-->
## Loggin through Radius Server

A user who does not have a local username and password in the MC attempts to log in.
Since the user does not exist, we will not be able to start a session.

```ruby
>> user_login = "johnDoe"
>> user_password = "johnDoe"
>> login(user_login, user_password)                                             # byexample: +timeout=10
>> find('p').text rescue nil
=> nil
```


### Configuring Radius from the MC
Now we configure the MC so that the user can access via a Radius server that
contains that username and password.

```shell
10.81.0.190 is the snoopdogg server (http://snoopdogg.users.qa.eng.core.sec)
dshell> config/global/admin/radius/primary_hostname = 10.81.0.190
10.81.0.190 (String)
dshell> config/global/admin/radius/primary_port = 1812
1812 (Fixnum)
dshell> config/global/admin/radius/primary_secret = soa
soa (String)
dshell> config/global/admin/radius/enabled = true
true (TrueClass)
```

In this way we initiate session through the Radius server
To prove that this worked, let's try to log in:
```ruby
>> login(user_login, user_password)                                             # byexample: +timeout=10
>> find('p.lead').text rescue nil
=> "Welcome, johnDoe"
```

<!--
$ sudo docker stop freeradius                                                   # byexample: -skip +pass
$ sudo docker rm freeradius                                                     # byexample: -skip +pass

dshell> reset config/global/admin/radius/enabled                                # byexample: -skip +pass
dshell> reset config/global/admin/radius/primary_hostname                       # byexample: -skip +pass
dshell> reset config/global/admin/radius/primary_port                           # byexample: -skip +pass
dshell> reset config/global/admin/radius/primary_secret                         # byexample: -skip +pass
dshell> reset /config/global/access/users                                       # byexample: -skip +pass
dshell> expert off                                                              # byexample: -skip +pass
-->
